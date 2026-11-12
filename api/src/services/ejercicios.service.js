const { ObjectId } = require('mongodb');
const { getDb } = require('../config/db');
const { OPCIONALES, TIPO_POR_DEFECTO } = require('../models/ejercicio.model');

const COL = 'ejercicios';

// Solo los campos que la app necesita (Regla 20 CLAUDE.md)
const PROJ = {
  _id: 1, nombre: 1, herramienta: 1, imagen: 1, tiempo_recomendado: 1,
  instrucciones: 1, observaciones: 1, recomendaciones: 1, grupo_muscular: 1, estado: 1,
};

const escaparRegex = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

// El listado va ordenado por nombre, así que el cursor lleva nombre + _id
// (el _id desempata cuando dos ejercicios se llaman igual).
const codificarCursor = (doc) =>
  Buffer.from(JSON.stringify([doc.nombre, doc._id.toString()])).toString('base64url');

function decodificarCursor(cursor) {
  try {
    const [nombre, id] = JSON.parse(Buffer.from(cursor, 'base64url').toString());
    if (typeof nombre !== 'string') return null;
    return { nombre, _id: new ObjectId(id) };
  } catch {
    return null; // cursor inválido: se ignora y se devuelve la primera página
  }
}

// RF-062 (visualizar) y RF-073 (buscar por nombre)
async function listarEjercicios({ limite = 20, cursor = null, grupo = null, estado = null, q = null } = {}) {
  const tope = Math.min(limite, 100);
  const condiciones = [];

  if (grupo) condiciones.push({ grupo_muscular: grupo });
  if (estado) condiciones.push({ estado });
  if (q) condiciones.push({ nombre: { $regex: escaparRegex(q), $options: 'i' } });

  const desde = cursor ? decodificarCursor(cursor) : null;
  if (desde) {
    condiciones.push({
      $or: [{ nombre: { $gt: desde.nombre } }, { nombre: desde.nombre, _id: { $gt: desde._id } }],
    });
  }

  const items = await getDb().collection(COL)
    .find(condiciones.length ? { $and: condiciones } : {}, { projection: PROJ })
    .sort({ nombre: 1, _id: 1 })
    .limit(tope)
    .toArray();

  const nextCursor = items.length === tope ? codificarCursor(items[items.length - 1]) : null;
  return { items, nextCursor };
}

function obtenerEjercicio(id) {
  return getDb().collection(COL).findOne({ _id: new ObjectId(id) }, { projection: PROJ });
}

// ¿Ya hay otro ejercicio con ese nombre? (sin distinguir mayúsculas)
async function nombreRepetido(nombre, exceptoId = null) {
  const filtro = { nombre: { $regex: `^${escaparRegex(nombre)}$`, $options: 'i' } };
  if (exceptoId) filtro._id = { $ne: exceptoId };
  return (await getDb().collection(COL).findOne(filtro, { projection: { _id: 1 } })) !== null;
}

// Pasa el cuerpo validado a los campos del documento. `tiempo_recomendado` no
// admite null en el esquema: si no viene, el campo no se guarda.
function camposDesde(b) {
  const campos = { nombre: b.nombre.trim() };
  for (const campo of Object.keys(OPCIONALES)) campos[campo] = b[campo]?.trim() || null;
  if (b.tiempo_recomendado != null) campos.tiempo_recomendado = b.tiempo_recomendado;
  return campos;
}

// RF-038. Devuelve { doc } o { duplicado: true }
async function crearEjercicio(b) {
  const doc = { ...camposDesde(b), tipo: TIPO_POR_DEFECTO, imagen: null, estado: 'Activo' };
  if (await nombreRepetido(doc.nombre)) return { duplicado: true };

  const { insertedId } = await getDb().collection(COL).insertOne(doc);
  return { doc: { _id: insertedId, ...doc } };
}

// RF-048. Solo se editan ejercicios activos.
// Devuelve { doc } | { duplicado: true } | { noEncontrado: true }
async function actualizarEjercicio(id, b) {
  const _id = new ObjectId(id);
  const campos = camposDesde(b);

  const actual = await getDb().collection(COL).findOne({ _id, estado: 'Activo' }, { projection: { nombre: 1 } });
  if (!actual) return { noEncontrado: true };
  // Solo se compara si el nombre cambió: el catálogo importado trae algunos nombres repetidos a propósito
  if (actual.nombre.toLowerCase() !== campos.nombre.toLowerCase() && await nombreRepetido(campos.nombre, _id))
    return { duplicado: true };

  const cambio = { $set: campos };
  if (campos.tiempo_recomendado == null) cambio.$unset = { tiempo_recomendado: '' };

  const doc = await getDb().collection(COL).findOneAndUpdate(
    { _id, estado: 'Activo' }, cambio, { returnDocument: 'after', projection: PROJ },
  );
  return doc ? { doc } : { noEncontrado: true };
}

// RF-055 (y su inverso). Devuelve el documento actualizado o null si no estaba en `desde`.
function cambiarEstado(id, desde, hacia) {
  return getDb().collection(COL).findOneAndUpdate(
    { _id: new ObjectId(id), estado: desde },
    { $set: { estado: hacia } },
    { returnDocument: 'after', projection: PROJ },
  );
}

const inhabilitarEjercicio = (id) => cambiarEstado(id, 'Activo', 'Inhabilitado');
const reactivarEjercicio = (id) => cambiarEstado(id, 'Inhabilitado', 'Activo');

module.exports = {
  listarEjercicios, obtenerEjercicio, crearEjercicio, actualizarEjercicio,
  inhabilitarEjercicio, reactivarEjercicio,
};
