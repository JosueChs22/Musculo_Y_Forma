const service = require('../services/rutinas.service');
const { rutinaDto, paginadoRutinasDto, usuarioResumenDto } = require('../views/rutina.dto');
const { CATEGORIAS, ESTADOS, esIdValido, validarRutina } = require('../models/rutina.model');

const MSG_EJERCICIOS = 'Algún ejercicio ya no existe o está inhabilitado. Quítalo del plan e inténtalo de nuevo.';
const MSG_CLIENTE = 'El usuario no existe, está inhabilitado o no es un cliente';

async function listar(req, res, next) {
  try {
    const limite = Math.min(parseInt(req.query.limite) || 20, 100);
    const categoria = CATEGORIAS.includes(req.query.categoria) ? req.query.categoria : null;
    const estado = ESTADOS.includes(req.query.estado) ? req.query.estado : null;
    const q = typeof req.query.q === 'string' ? req.query.q.trim().slice(0, 80) : '';
    const cursor = typeof req.query.cursor === 'string' ? req.query.cursor : null;

    const r = await service.listarRutinas(req.usuario, { limite, cursor, categoria, estado, q: q || null });
    res.json(paginadoRutinasDto(r.items, r.nextCursor));
  } catch (err) { next(err); }
}

async function obtener(req, res, next) {
  try {
    if (!esIdValido(req.params.id)) return res.status(400).json({ error: 'ID inválido' });
    const r = await service.obtenerRutina(req.usuario, req.params.id);
    if (!r) return res.status(404).json({ error: 'Plan no encontrado' });
    res.json(rutinaDto(r.doc, r.usuario, r.ejercicios));
  } catch (err) { next(err); }
}

async function crear(req, res, next) {
  try {
    const errors = validarRutina(req.body);
    if (req.body?.id_usuario != null && !esIdValido(req.body.id_usuario)) errors.push('id_usuario: inválido');
    if (errors.length) return res.status(422).json({ errors });

    const r = await service.crearRutina(req.usuario, req.body);
    if (r.ejerciciosInvalidos) return res.status(422).json({ error: MSG_EJERCICIOS });
    if (r.clienteInvalido) return res.status(422).json({ error: MSG_CLIENTE });

    const creado = await service.obtenerRutina(req.usuario, r.id);
    res.status(201).json(rutinaDto(creado.doc, creado.usuario, creado.ejercicios));
  } catch (err) { next(err); }
}

async function actualizar(req, res, next) {
  try {
    if (!esIdValido(req.params.id)) return res.status(400).json({ error: 'ID inválido' });
    const errors = validarRutina(req.body);
    if (errors.length) return res.status(422).json({ errors });

    const r = await service.actualizarRutina(req.usuario, req.params.id, req.body);
    if (r.ejerciciosInvalidos) return res.status(422).json({ error: MSG_EJERCICIOS });
    if (r.noEncontrado) return res.status(404).json({ error: 'Plan no encontrado o inhabilitado' });

    const nuevo = await service.obtenerRutina(req.usuario, req.params.id);
    res.json(rutinaDto(nuevo.doc, nuevo.usuario, nuevo.ejercicios));
  } catch (err) { next(err); }
}

// Asigna el plan a un cliente. `id_usuario: null` lo deja sin asignar.
async function asignar(req, res, next) {
  try {
    if (!esIdValido(req.params.id)) return res.status(400).json({ error: 'ID inválido' });
    const idUsuario = req.body?.id_usuario ?? null;
    if (idUsuario !== null && !esIdValido(idUsuario)) return res.status(422).json({ errors: ['id_usuario: inválido'] });

    const r = await service.asignarRutina(req.usuario, req.params.id, idUsuario);
    if (r.clienteInvalido) return res.status(422).json({ error: MSG_CLIENTE });
    if (r.noEncontrado) return res.status(404).json({ error: 'Plan no encontrado o inhabilitado' });
    res.json({ usuario: usuarioResumenDto(r.usuario) });
  } catch (err) { next(err); }
}

async function inhabilitar(req, res, next) {
  try {
    if (!esIdValido(req.params.id)) return res.status(400).json({ error: 'ID inválido' });
    if (!(await service.inhabilitarRutina(req.usuario, req.params.id)))
      return res.status(404).json({ error: 'Plan no encontrado o ya inhabilitado' });
    res.json({ ok: true });
  } catch (err) { next(err); }
}

async function reactivar(req, res, next) {
  try {
    if (!esIdValido(req.params.id)) return res.status(400).json({ error: 'ID inválido' });
    if (!(await service.reactivarRutina(req.usuario, req.params.id)))
      return res.status(404).json({ error: 'Plan no encontrado o ya activo' });
    res.json({ ok: true });
  } catch (err) { next(err); }
}

module.exports = { listar, obtener, crear, actualizar, asignar, inhabilitar, reactivar };
