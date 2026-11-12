const service = require('../services/mi.service');
const { perfilDto, misRutinasDto, paginadoMedicionesDto } = require('../views/mi.dto');

// Siempre el usuario del token (req.usuario.id): nadie puede pedir los datos de otro.

async function perfil(req, res, next) {
  try {
    const r = await service.perfil(req.usuario.id);
    if (!r) return res.status(401).json({ error: 'Sesión inválida o expirada' });
    res.json(perfilDto(r));
  } catch (err) { next(err); }
}

async function rutinas(req, res, next) {
  try {
    res.json(misRutinasDto(await service.rutinas(req.usuario.id)));
  } catch (err) { next(err); }
}

async function mediciones(req, res, next) {
  try {
    const limite = Math.min(parseInt(req.query.limite) || 20, 100);
    const cursor = typeof req.query.cursor === 'string' ? req.query.cursor : null;
    const r = await service.mediciones(req.usuario.id, { limite, cursor });
    res.json(paginadoMedicionesDto(r.items, r.nextCursor));
  } catch (err) { next(err); }
}

module.exports = { perfil, rutinas, mediciones };
