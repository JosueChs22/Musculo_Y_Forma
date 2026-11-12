const service = require('../services/clases.service');
const { claseDto, horarioDto, paginadoDto } = require('../views/clase.dto');
const { validarClase, validarHorario, parsearId } = require('../models/clase.model');

async function listar(req, res, next) {
  try {
    const limite = Math.min(parseInt(req.query.limite) || 20, 100);
    const estado = ['Activo', 'Inhabilitada'].includes(req.query.estado) ? req.query.estado : null;
    const result = await service.listarClases({ limite, cursor: req.query.cursor || null, estado });
    res.json(paginadoDto(result.items, result.nextCursor));
  } catch (err) { next(err); }
}

async function obtener(req, res, next) {
  try {
    if (!parsearId(req.params.id)) return res.status(400).json({ error: 'ID inválido' });
    const clase = await service.obtenerClase(req.params.id);
    if (!clase) return res.status(404).json({ error: 'Clase no encontrada' });
    res.json(claseDto(clase));
  } catch (err) { next(err); }
}

async function crear(req, res, next) {
  try {
    const errors = validarClase(req.body);
    if (errors.length) return res.status(422).json({ errors });
    const clase = await service.crearClase({ nombre: req.body.nombre, descripcion: req.body.descripcion });
    res.status(201).json(claseDto(clase));
  } catch (err) { next(err); }
}

async function actualizar(req, res, next) {
  try {
    if (!parsearId(req.params.id)) return res.status(400).json({ error: 'ID inválido' });
    const errors = validarClase(req.body);
    if (errors.length) return res.status(422).json({ errors });
    const ok = await service.actualizarClase(req.params.id, { nombre: req.body.nombre, descripcion: req.body.descripcion });
    if (!ok) return res.status(404).json({ error: 'Clase no encontrada o ya inhabilitada' });
    res.json({ ok: true });
  } catch (err) { next(err); }
}

async function inhabilitar(req, res, next) {
  try {
    if (!parsearId(req.params.id)) return res.status(400).json({ error: 'ID inválido' });
    const ok = await service.inhabilitarClase(req.params.id);
    if (!ok) return res.status(404).json({ error: 'Clase no encontrada o ya inhabilitada' });
    res.json({ ok: true });
  } catch (err) { next(err); }
}

async function reactivar(req, res, next) {
  try {
    if (!parsearId(req.params.id)) return res.status(400).json({ error: 'ID inválido' });
    const ok = await service.reactivarClase(req.params.id);
    if (!ok) return res.status(404).json({ error: 'Clase no encontrada o ya activa' });
    res.json({ ok: true });
  } catch (err) { next(err); }
}

async function agregarHorario(req, res, next) {
  try {
    if (!parsearId(req.params.id)) return res.status(400).json({ error: 'ID inválido' });
    const errors = validarHorario(req.body);
    if (errors.length) return res.status(422).json({ errors });
    const horario = await service.agregarHorario(req.params.id, req.body);
    if (!horario) return res.status(404).json({ error: 'Clase no encontrada o inhabilitada' });
    res.status(201).json(horarioDto(horario));
  } catch (err) { next(err); }
}

async function actualizarHorario(req, res, next) {
  try {
    if (!parsearId(req.params.id)) return res.status(400).json({ error: 'ID inválido' });
    const index = parseInt(req.params.index);
    if (isNaN(index) || index < 0) return res.status(400).json({ error: 'Índice inválido' });
    const errors = validarHorario(req.body);
    if (errors.length) return res.status(422).json({ errors });
    const ok = await service.actualizarHorario(req.params.id, index, req.body);
    if (!ok) return res.status(404).json({ error: 'Clase u horario no encontrado' });
    res.json({ ok: true });
  } catch (err) { next(err); }
}

async function inhabilitarHorario(req, res, next) {
  try {
    if (!parsearId(req.params.id)) return res.status(400).json({ error: 'ID inválido' });
    const index = parseInt(req.params.index);
    if (isNaN(index) || index < 0) return res.status(400).json({ error: 'Índice inválido' });
    const ok = await service.inhabilitarHorario(req.params.id, index);
    if (!ok) return res.status(404).json({ error: 'Horario no encontrado o ya inhabilitado' });
    res.json({ ok: true });
  } catch (err) { next(err); }
}

module.exports = { listar, obtener, crear, actualizar, inhabilitar, reactivar, agregarHorario, actualizarHorario, inhabilitarHorario };
