const { ObjectId } = require('mongodb');
const { getDb } = require('../config/db');

// Datos del propio usuario (el del token). Nunca se recibe un id de otro usuario.

const PROJ_USUARIO = {
  _id: 1, id_rol: 1, correo: 1, nombre: 1, primer_apellido: 1, segundo_apellido: 1,
  telefono: 1, usuario: 1, estado: 1, fecha_ingreso: 1, ultimo_login: 1,
};
const PROJ_NOMBRE = { _id: 1, nombre: 1, primer_apellido: 1, segundo_apellido: 1, usuario: 1 };
const PROJ_RUTINA = {
  _id: 1, id_usuario: 1, id_coach: 1, nombre: 1, observaciones: 1, estado: 1,
  dia_semana: 1, fecha_creacion: 1, categoria: 1, ejercicios: 1,
};
const PROJ_EJERCICIO = { _id: 1, nombre: 1, imagen: 1, grupo_muscular: 1, herramienta: 1, instrucciones: 1, estado: 1 };
// Datos de salud: solo lo que muestra la app (Regla 20)
const PROJ_MEDICION = {
  _id: 1, fecha: 1, objetivo: 1, peso_corporal: 1, grasa_corporal: 1, grasa_visceral: 1,
  masa_muscular: 1, imc: 1, edad: 1, estatura: 1, nivel_actividad_fisica: 1, frecuencia_semanal: 1,
};

// Perfil: datos de la cuenta, su coach, su objetivo y la fecha de su última medición
async function perfil(idUsuario) {
  const db = getDb();
  const _id = new ObjectId(idUsuario);

  // Independientes entre sí (Regla 10)
  const [u, asignacion, ultima, ultimaRutina] = await Promise.all([
    db.collection('usuarios').findOne({ _id }, { projection: PROJ_USUARIO }),
    db.collection('usuarios_coach').findOne({ id_usuario: _id, estado: 'Activo' }, { projection: { id_coach: 1 } }),
    db.collection('mediciones').findOne(
      { id_usuario: _id, estado: 'Activo' },
      { projection: { fecha: 1, objetivo: 1 }, sort: { fecha: -1 } },
    ),
    db.collection('rutinas').findOne(
      { id_usuario: _id, estado: 'Activo' },
      { projection: { id_coach: 1 }, sort: { _id: -1 } },
    ),
  ]);
  if (!u || u.estado !== 'Activo') return null;

  // El coach es el asignado formalmente; si no hay, el que le armó su plan más reciente
  const idCoach = asignacion?.id_coach ?? ultimaRutina?.id_coach ?? null;
  const [rol, coach] = await Promise.all([
    db.collection('roles').findOne({ _id: u.id_rol }, { projection: { descripcion: 1 } }),
    idCoach ? db.collection('usuarios').findOne({ _id: idCoach }, { projection: PROJ_NOMBRE }) : null,
  ]);

  return { usuario: u, rol: rol?.descripcion ?? null, coach, ultimaMedicion: ultima };
}

// Planes activos asignados al usuario, con el detalle de cada ejercicio y el nombre del coach
async function rutinas(idUsuario) {
  const db = getDb();
  const docs = await db.collection('rutinas')
    .find({ id_usuario: new ObjectId(idUsuario), estado: 'Activo' }, { projection: PROJ_RUTINA })
    .sort({ _id: 1 })
    .limit(50)
    .toArray();
  // De lunes a domingo; los que no tienen día fijo, al final
  docs.sort((a, b) => (a.dia_semana ?? 8) - (b.dia_semana ?? 8));

  // Todo lo relacionado de una vez con $in (Regla 18: sin consultas en un ciclo)
  const idsEjercicio = [...new Set(docs.flatMap((d) => (d.ejercicios ?? []).map((e) => String(e.id_ejercicio))))];
  const idsCoach = [...new Set(docs.map((d) => String(d.id_coach)))];
  const [ejercicios, coaches] = await Promise.all([
    idsEjercicio.length
      ? db.collection('ejercicios').find({ _id: { $in: idsEjercicio.map((i) => new ObjectId(i)) } }, { projection: PROJ_EJERCICIO }).toArray()
      : [],
    idsCoach.length
      ? db.collection('usuarios').find({ _id: { $in: idsCoach.map((i) => new ObjectId(i)) } }, { projection: PROJ_NOMBRE }).toArray()
      : [],
  ]);

  return {
    docs,
    ejercicios: new Map(ejercicios.map((e) => [String(e._id), e])),
    coaches: new Map(coaches.map((c) => [String(c._id), c])),
  };
}

// Historial de mediciones, de la más reciente a la más vieja. El cursor lleva fecha + _id.
const codificarCursor = (doc) =>
  Buffer.from(JSON.stringify([doc.fecha.toISOString(), String(doc._id)])).toString('base64url');

function decodificarCursor(cursor) {
  try {
    const [fecha, id] = JSON.parse(Buffer.from(cursor, 'base64url').toString());
    const f = new Date(fecha);
    if (Number.isNaN(f.getTime())) return null;
    return { fecha: f, _id: new ObjectId(id) };
  } catch {
    return null;
  }
}

async function mediciones(idUsuario, { limite = 20, cursor = null } = {}) {
  const tope = Math.min(limite, 100);
  const filtro = { id_usuario: new ObjectId(idUsuario), estado: 'Activo' };
  const desde = cursor ? decodificarCursor(cursor) : null;
  if (desde) filtro.$or = [{ fecha: { $lt: desde.fecha } }, { fecha: desde.fecha, _id: { $lt: desde._id } }];

  const items = await getDb().collection('mediciones')
    .find(filtro, { projection: PROJ_MEDICION })
    .sort({ fecha: -1, _id: -1 })
    .limit(tope)
    .toArray();

  return { items, nextCursor: items.length === tope ? codificarCursor(items[items.length - 1]) : null };
}

module.exports = { perfil, rutinas, mediciones };
