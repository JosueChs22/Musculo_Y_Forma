const service = require('../services/usuarios.service');
const { usuarioDto, paginadoUsuariosDto } = require('../views/usuario.dto');
const { esIdValido } = require('../models/usuario.model');

async function listar(req, res, next) {
  try {
    const limite = Math.min(parseInt(req.query.limite) || 20, 100);
    const rol = service.ROLES_ADMINISTRATIVOS.includes(req.query.rol) ? req.query.rol : null;
    const estado = ['Activo', 'Inhabilitado'].includes(req.query.estado) ? req.query.estado : null;
    const r = await service.listarAdministrativos({ limite, cursor: req.query.cursor || null, rol, estado });
    res.json(paginadoUsuariosDto(r.items, r.nextCursor));
  } catch (err) { next(err); }
}

async function obtener(req, res, next) {
  try {
    if (!esIdValido(req.params.id)) return res.status(400).json({ error: 'ID inválido' });
    const r = await service.obtenerAdministrativo(req.params.id);
    if (!r) return res.status(404).json({ error: 'Usuario no encontrado' });
    res.json(usuarioDto(r.doc, r.rol));
  } catch (err) { next(err); }
}

module.exports = { listar, obtener };
