const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { ObjectId } = require('mongodb');
const { getDb } = require('../config/db');

// Si el usuario no existe se compara igual contra este hash, para que la
// respuesta tarde lo mismo y no se pueda adivinar qué usuarios existen.
const HASH_RELLENO = bcrypt.hashSync('relleno-no-valido', 10);

const PROJ_LOGIN = {
  _id: 1, id_rol: 1, correo: 1, contrasena: 1, nombre: 1, primer_apellido: 1,
  segundo_apellido: 1, telefono: 1, usuario: 1, estado: 1, fecha_ingreso: 1, ultimo_login: 1,
};

async function autenticar(usuario, contrasena) {
  const db = getDb();
  const u = await db.collection('usuarios')
    .findOne({ usuario: usuario.trim() }, { projection: PROJ_LOGIN });

  const coincide = await bcrypt.compare(contrasena, u?.contrasena ?? HASH_RELLENO);
  if (!u || !coincide) return { motivo: 'credenciales' };
  if (u.estado !== 'Activo') return { motivo: 'inhabilitado' };

  // Independientes entre sí: en paralelo (Regla 10)
  const ahora = new Date();
  const [rolDoc] = await Promise.all([
    db.collection('roles').findOne({ _id: u.id_rol }, { projection: { descripcion: 1 } }),
    db.collection('usuarios').updateOne({ _id: u._id }, { $set: { ultimo_login: ahora } }),
  ]);
  if (!rolDoc) throw new Error('Rol del usuario no encontrado');

  return { usuario: { ...u, ultimo_login: ahora }, rol: rolDoc.descripcion };
}

function firmarToken(u, rol) {
  return jwt.sign({ sub: u._id.toString(), rol }, process.env.JWT_SECRET, {
    algorithm: 'HS256',
    expiresIn: process.env.JWT_EXPIRES_IN || '2h',
  });
}

// RF-035. Devuelve { ok: true } o { motivo: 'no_autorizado' | 'actual_incorrecta' }
async function cambiarContrasena(idUsuario, actual, nueva) {
  const db = getDb();
  const u = await db.collection('usuarios')
    .findOne({ _id: new ObjectId(idUsuario) }, { projection: { contrasena: 1, estado: 1 } });
  if (!u || u.estado !== 'Activo') return { motivo: 'no_autorizado' };

  if (!(await bcrypt.compare(actual, u.contrasena))) return { motivo: 'actual_incorrecta' };

  await db.collection('usuarios').updateOne({ _id: u._id }, {
    $set: { contrasena: await bcrypt.hash(nueva, 10) }, // nunca en texto plano
    // Auditoría: queda registrado que cambió, sin guardar ningún valor de contraseña
    $push: { historial_cambios: { fecha: new Date(), campo: 'contrasena', realizado_por: u._id } },
  });
  return { ok: true };
}

module.exports = { autenticar, firmarToken, cambiarContrasena };
