const bcrypt = require('bcryptjs');
const { getDb } = require('../config/db');
const { ObjectId } = require('mongodb');
const { ROLES_ADMINISTRATIVOS } = require('../models/usuario.model');

// Solo los campos que la app necesita. Nunca contrasena ni historial_cambios.
const PROJ = {
  _id: 1, id_rol: 1, correo: 1, nombre: 1, primer_apellido: 1, segundo_apellido: 1,
  telefono: 1, usuario: 1, estado: 1, fecha_ingreso: 1, ultimo_login: 1,
};

// Roles administrativos (o solo uno) como lista de { _id, descripcion }
function buscarRoles(db, soloRol) {
  return db.collection('roles')
    .find({ descripcion: { $in: soloRol ? [soloRol] : ROLES_ADMINISTRATIVOS } },
      { projection: { descripcion: 1 } })
    .toArray();
}

async function listarAdministrativos({ limite = 20, cursor = null, rol = null, estado = null } = {}) {
  const db = getDb();
  const tope = Math.min(limite, 100);
  const roles = await buscarRoles(db, rol);

  const filtro = { id_rol: { $in: roles.map((r) => r._id) } };
  if (estado) filtro.estado = estado;
  if (cursor) {
    try { filtro._id = { $gt: new ObjectId(cursor) }; } catch { /* cursor inválido, ignorar */ }
  }

  const docs = await db.collection('usuarios')
    .find(filtro, { projection: PROJ })
    .sort({ _id: 1 })
    .limit(tope)
    .toArray();

  const nombrePorId = new Map(roles.map((r) => [r._id.toString(), r.descripcion]));
  const items = docs.map((doc) => ({ doc, rol: nombrePorId.get(doc.id_rol.toString()) }));
  const nextCursor = docs.length === tope ? docs[docs.length - 1]._id.toString() : null;

  return { items, nextCursor };
}

// Devuelve { doc, rol } o null si no existe o no es un usuario administrativo
async function obtenerAdministrativo(id) {
  const db = getDb();
  const doc = await db.collection('usuarios').findOne({ _id: new ObjectId(id) }, { projection: PROJ });
  if (!doc) return null;

  const rolDoc = await db.collection('roles').findOne({ _id: doc.id_rol }, { projection: { descripcion: 1 } });
  if (!rolDoc || !ROLES_ADMINISTRATIVOS.includes(rolDoc.descripcion)) return null;

  return { doc, rol: rolDoc.descripcion };
}

// RF-096. Devuelve { doc, rol } o { duplicado: 'usuario' | 'correo' }
async function crearAdministrativo(d) {
  const db = getDb();
  const rolDoc = await db.collection('roles').findOne({ descripcion: d.rol }, { projection: { _id: 1 } });
  if (!rolDoc) throw new Error(`El rol "${d.rol}" no existe en la colección roles`);

  const doc = {
    id_rol: rolDoc._id,
    correo: d.correo.trim().toLowerCase(), // en minúscula para que no se dupliquen por mayúsculas
    contrasena: await bcrypt.hash(d.contrasena, 10), // nunca en texto plano
    nombre: d.nombre.trim(),
    primer_apellido: d.primer_apellido.trim(),
    segundo_apellido: d.segundo_apellido?.trim() || null,
    telefono: d.telefono.trim(),
    usuario: d.usuario.trim(),
    estado: 'Activo',
    fecha_ingreso: new Date(),
  };

  try {
    const { insertedId } = await db.collection('usuarios').insertOne(doc);
    return { doc: { _id: insertedId, ...doc }, rol: d.rol };
  } catch (err) {
    // 11000 = índice único violado (uq_usuario o uq_correo). Lo decide Mongo, sin carreras.
    if (err.code === 11000) return { duplicado: err.keyPattern?.correo ? 'correo' : 'usuario' };
    throw err;
  }
}

module.exports = { listarAdministrativos, obtenerAdministrativo, crearAdministrativo, ROLES_ADMINISTRATIVOS };
