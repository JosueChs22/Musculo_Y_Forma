const { ObjectId } = require('mongodb');

function validarHorario(h) {
  const errors = [];
  if (!Array.isArray(h.dias) || h.dias.length === 0)
    errors.push('dias: array no vacío requerido');
  if (h.dias?.some((d) => d < 1 || d > 7))
    errors.push('dias: valores entre 1 y 7');
  if (!/^([01][0-9]|2[0-3]):[0-5][0-9]$/.test(h.hora_inicio))
    errors.push('hora_inicio: formato HH:mm requerido');
  if (!/^([01][0-9]|2[0-3]):[0-5][0-9]$/.test(h.hora_fin))
    errors.push('hora_fin debe ser posterior a hora_inicio');
  if (h.hora_fin <= h.hora_inicio)
    errors.push('hora_fin debe ser posterior a hora_inicio');
  return errors;
}

function validarClase(body) {
  const errors = [];
  if (!body.nombre || typeof body.nombre !== 'string' || !body.nombre.trim())
    errors.push('nombre: string no vacío requerido');
  if (body.descripcion !== undefined && body.descripcion !== null && typeof body.descripcion !== 'string')
    errors.push('descripcion: debe ser string o null');
  return errors;
}

function parsearId(id) {
  try { return new ObjectId(id); } catch { return null; }
}

module.exports = { validarHorario, validarClase, parsearId };
