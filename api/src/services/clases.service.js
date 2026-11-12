const { getDb } = require('../config/db');
const { ObjectId } = require('mongodb');

const COL = 'clases';

// Solo los campos que la app necesita (Regla 20 CLAUDE.md)
const PROJ = { _id: 1, nombre: 1, descripcion: 1, estado: 1, fecha_actualizacion: 1, horarios: 1 };

async function listarClases({ limite = 20, cursor = null, estado = null } = {}) {
  const db = getDb();
  const filtro = {};
  if (estado) filtro.estado = estado;
  if (cursor) {
    try { filtro._id = { $gt: new ObjectId(cursor) }; } catch { /* cursor inválido, ignorar */ }
  }

  const items = await db.collection(COL)
    .find(filtro, { projection: PROJ })
    .limit(Math.min(limite, 100))
    .sort({ _id: 1 })
    .toArray();

  const nextCursor = items.length === Math.min(limite, 100)
    ? items[items.length - 1]._id.toString()
    : null;

  return { items, nextCursor };
}

async function obtenerClase(id) {
  const db = getDb();
  return db.collection(COL).findOne({ _id: new ObjectId(id) }, { projection: PROJ });
}

async function crearClase({ nombre, descripcion }) {
  const db = getDb();
  const doc = {
    nombre: nombre.trim(),
    descripcion: descripcion?.trim() || null,
    instructores: [],
    estado: 'Activo',
    fecha_actualizacion: new Date(),
    horarios: [],
  };
  const { insertedId } = await db.collection(COL).insertOne(doc);
  return { _id: insertedId, ...doc };
}

async function actualizarClase(id, { nombre, descripcion }) {
  const db = getDb();
  const $set = { fecha_actualizacion: new Date() };
  if (nombre !== undefined) $set.nombre = nombre.trim();
  if (descripcion !== undefined) $set.descripcion = descripcion?.trim() || null;

  const { matchedCount } = await db.collection(COL).updateOne(
    { _id: new ObjectId(id), estado: 'Activo' }, { $set }
  );
  return matchedCount === 1;
}

async function inhabilitarClase(id) {
  const db = getDb();
  const { matchedCount } = await db.collection(COL).updateOne(
    { _id: new ObjectId(id), estado: 'Activo' },
    { $set: { estado: 'Inhabilitada', fecha_actualizacion: new Date(), 'horarios.$[].estado': 'Inhabilitado' } }
  );
  return matchedCount === 1;
}

async function reactivarClase(id) {
  const db = getDb();
  const { matchedCount } = await db.collection(COL).updateOne(
    { _id: new ObjectId(id), estado: 'Inhabilitada' },
    { $set: { estado: 'Activo', fecha_actualizacion: new Date() } }
  );
  return matchedCount === 1;
}

async function agregarHorario(claseId, h) {
  const db = getDb();
  const horario = { dias: h.dias.map(Number).sort(), hora_inicio: h.hora_inicio, hora_fin: h.hora_fin, estado: 'Activo' };
  const { matchedCount } = await db.collection(COL).updateOne(
    { _id: new ObjectId(claseId), estado: 'Activo' },
    { $push: { horarios: horario }, $set: { fecha_actualizacion: new Date() } }
  );
  return matchedCount === 1 ? horario : null;
}

async function actualizarHorario(claseId, index, h) {
  const db = getDb();
  const $set = {
    fecha_actualizacion: new Date(),
    [`horarios.${index}.dias`]: h.dias.map(Number).sort(),
    [`horarios.${index}.hora_inicio`]: h.hora_inicio,
    [`horarios.${index}.hora_fin`]: h.hora_fin,
  };
  const { matchedCount } = await db.collection(COL).updateOne(
    { _id: new ObjectId(claseId), estado: 'Activo', [`horarios.${index}`]: { $exists: true } },
    { $set }
  );
  return matchedCount === 1;
}

async function inhabilitarHorario(claseId, index) {
  const db = getDb();
  const { matchedCount } = await db.collection(COL).updateOne(
    { _id: new ObjectId(claseId), estado: 'Activo', [`horarios.${index}.estado`]: 'Activo' },
    { $set: { [`horarios.${index}.estado`]: 'Inhabilitado', fecha_actualizacion: new Date() } }
  );
  return matchedCount === 1;
}

module.exports = { listarClases, obtenerClase, crearClase, actualizarClase, inhabilitarClase, reactivarClase, agregarHorario, actualizarHorario, inhabilitarHorario };
