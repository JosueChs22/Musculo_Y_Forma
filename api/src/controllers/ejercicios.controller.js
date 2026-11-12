const service = require('../services/ejercicios.service');
const { ejercicioDto, paginadoEjerciciosDto } = require('../views/ejercicio.dto');
const { GRUPOS, ESTADOS, validarEjercicio, esIdValido } = require('../models/ejercicio.model');

const MSG_DUPLICADO = 'Ya existe un ejercicio con ese nombre';

// RF-062 / RF-073
async function listar(req, res, next) {
  try {
    const limite = Math.min(parseInt(req.query.limite) || 20, 100);
    const grupo = GRUPOS.includes(req.query.grupo) ? req.query.grupo : null;
    const estado = ESTADOS.includes(req.query.estado) ? req.query.estado : null;
    const q = typeof req.query.q === 'string' ? req.query.q.trim().slice(0, 80) : '';
    const cursor = typeof req.query.cursor === 'string' ? req.query.cursor : null;

    const r = await service.listarEjercicios({ limite, cursor, grupo, estado, q: q || null });
    res.json(paginadoEjerciciosDto(r.items, r.nextCursor));
  } catch (err) { next(err); }
}

async function obtener(req, res, next) {
  try {
    if (!esIdValido(req.params.id)) return res.status(400).json({ error: 'ID inválido' });
    const doc = await service.obtenerEjercicio(req.params.id);
    if (!doc) return res.status(404).json({ error: 'Ejercicio no encontrado' });
    res.json(ejercicioDto(doc));
  } catch (err) { next(err); }
}

// RF-038
async function crear(req, res, next) {
  try {
    const errors = validarEjercicio(req.body);
    if (errors.length) return res.status(422).json({ errors });

    const r = await service.crearEjercicio(req.body);
    if (r.duplicado) return res.status(409).json({ error: MSG_DUPLICADO });
    res.status(201).json(ejercicioDto(r.doc));
  } catch (err) { next(err); }
}

// RF-048
async function actualizar(req, res, next) {
  try {
    if (!esIdValido(req.params.id)) return res.status(400).json({ error: 'ID inválido' });
    const errors = validarEjercicio(req.body);
    if (errors.length) return res.status(422).json({ errors });

    const r = await service.actualizarEjercicio(req.params.id, req.body);
    if (r.duplicado) return res.status(409).json({ error: MSG_DUPLICADO });
    if (r.noEncontrado) return res.status(404).json({ error: 'Ejercicio no encontrado o inhabilitado' });
    res.json(ejercicioDto(r.doc));
  } catch (err) { next(err); }
}

// RF-055
async function inhabilitar(req, res, next) {
  try {
    if (!esIdValido(req.params.id)) return res.status(400).json({ error: 'ID inválido' });
    const doc = await service.inhabilitarEjercicio(req.params.id);
    if (!doc) return res.status(404).json({ error: 'Ejercicio no encontrado o ya inhabilitado' });
    res.json(ejercicioDto(doc));
  } catch (err) { next(err); }
}

async function reactivar(req, res, next) {
  try {
    if (!esIdValido(req.params.id)) return res.status(400).json({ error: 'ID inválido' });
    const doc = await service.reactivarEjercicio(req.params.id);
    if (!doc) return res.status(404).json({ error: 'Ejercicio no encontrado o ya activo' });
    res.json(ejercicioDto(doc));
  } catch (err) { next(err); }
}

module.exports = { listar, obtener, crear, actualizar, inhabilitar, reactivar };
