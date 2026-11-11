const { getDb } = require('../config/db');
const { ObjectId } = require('mongodb');

// Usuarios "administrativos" = el personal que crea el Administrador (RF-096)
const ROLES_ADMINISTRATIVOS = ['Secretaria', 'Entrenador'];

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

module.exports = { listarAdministrativos, obtenerAdministrativo, ROLES_ADMINISTRATIVOS };
