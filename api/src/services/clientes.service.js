const { ObjectId } = require('mongodb');
const { getDb } = require('../config/db');

// Solo lo necesario para elegir a quién asignar un plan (Regla 20 CLAUDE.md)
const PROJ = { _id: 1, nombre: 1, primer_apellido: 1, segundo_apellido: 1, usuario: 1 };

const escaparRegex = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

// Busca clientes activos por nombre. Cada palabra del texto debe aparecer en el
// nombre, algún apellido o el usuario ("juan per" encuentra a "Juan Pérez").
async function buscarClientes({ q = '', limite = 20, cursor = null } = {}) {
  const db = getDb();
  const tope = Math.min(limite, 100);

  const rol = await db.collection('roles').findOne({ descripcion: 'Cliente' }, { projection: { _id: 1 } });
  if (!rol) return { items: [], nextCursor: null };

  const filtro = { id_rol: rol._id, estado: 'Activo' };
  const palabras = q.split(/\s+/).filter(Boolean).slice(0, 5);
  if (palabras.length) {
    filtro.$and = palabras.map((p) => {
      const re = { $regex: escaparRegex(p), $options: 'i' };
      return { $or: [{ nombre: re }, { primer_apellido: re }, { segundo_apellido: re }, { usuario: re }] };
    });
  }
  if (cursor) {
    try { filtro._id = { $gt: new ObjectId(cursor) }; } catch { /* cursor inválido, ignorar */ }
  }

  const items = await db.collection('usuarios')
    .find(filtro, { projection: PROJ })
    .sort({ _id: 1 })
    .limit(tope)
    .toArray();

  const nextCursor = items.length === tope ? String(items[items.length - 1]._id) : null;
  return { items, nextCursor };
}

module.exports = { buscarClientes };
