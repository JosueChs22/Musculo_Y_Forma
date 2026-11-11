const crypto = require('crypto');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { ObjectId } = require('mongodb');
const { getDb } = require('../config/db');
const { enviarCodigoRecuperacion, MINUTOS_VALIDEZ } = require('./correo.service');

const MAX_INTENTOS_CODIGO = 5;
// Intentos fallidos de código por usuario (en memoria). Al llegar al máximo se
// invalida el código vigente, para que no se pueda adivinar probando uno por uno.
const intentosFallidos = new Map();

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

// RF-034, paso 1: genera un código de 6 dígitos y lo envía al correo.
// Si el correo no existe (o la cuenta está inhabilitada) no hace nada: el
// controlador responde igual en todos los casos para no revelar qué correos existen.
async function solicitarRecuperacion(correo) {
  const db = getDb();
  const u = await db.collection('usuarios')
    .findOne({ correo: correo.trim().toLowerCase() }, { projection: { _id: 1, estado: 1, correo: 1 } });
  if (!u || u.estado !== 'Activo') return;

  const codigo = String(crypto.randomInt(0, 1_000_000)).padStart(6, '0');
  const col = db.collection('recuperaciones_contrasena');

  // Un solo código vigente por usuario: los anteriores se invalidan
  await col.updateMany({ id_usuario: u._id, estado: 'Pendiente' }, { $set: { estado: 'Usado' } });
  await col.insertOne({
    id_usuario: u._id,
    codigo: await bcrypt.hash(codigo, 10), // el código se guarda hasheado, como una contraseña
    fecha_expiracion: new Date(Date.now() + MINUTOS_VALIDEZ * 60 * 1000),
    estado: 'Pendiente',
  });
  intentosFallidos.delete(u._id.toString());

  await enviarCodigoRecuperacion(u.correo, codigo);
}

// RF-034, paso 2: comprueba el código y cambia la contraseña.
// Devuelve { ok: true } o { motivo: 'invalido' } (código malo, vencido o ya usado).
async function restablecerContrasena(correo, codigo, nueva) {
  const db = getDb();
  const u = await db.collection('usuarios')
    .findOne({ correo: correo.trim().toLowerCase() }, { projection: { _id: 1, estado: 1 } });
  if (!u || u.estado !== 'Activo') return { motivo: 'invalido' };

  const col = db.collection('recuperaciones_contrasena');
  const clave = u._id.toString();

  const rec = await col.findOne(
    { id_usuario: u._id, estado: 'Pendiente', fecha_expiracion: { $gt: new Date() } },
    { sort: { fecha_expiracion: -1 } },
  );
  if (!rec) return { motivo: 'invalido' };

  if (!(await bcrypt.compare(codigo, rec.codigo))) {
    const n = (intentosFallidos.get(clave) ?? 0) + 1;
    intentosFallidos.set(clave, n);
    if (n >= MAX_INTENTOS_CODIGO) {
      await col.updateOne({ _id: rec._id }, { $set: { estado: 'Usado' } });
      intentosFallidos.delete(clave);
    }
    return { motivo: 'invalido' };
  }

  // El código se "gasta" primero y de forma atómica: si llegan dos peticiones a
  // la vez con el mismo código, solo una consigue cambiar la contraseña.
  const { modifiedCount } = await col.updateOne(
    { _id: rec._id, estado: 'Pendiente' },
    { $set: { estado: 'Usado' } },
  );
  if (modifiedCount !== 1) return { motivo: 'invalido' };

  await db.collection('usuarios').updateOne({ _id: u._id }, {
    $set: { contrasena: await bcrypt.hash(nueva, 10) },
    $push: { historial_cambios: { fecha: new Date(), campo: 'contrasena', realizado_por: u._id } },
  });
  intentosFallidos.delete(clave);
  return { ok: true };
}

module.exports = {
  autenticar, firmarToken, cambiarContrasena, solicitarRecuperacion, restablecerContrasena,
};
