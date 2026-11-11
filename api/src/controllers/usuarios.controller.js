const service = require('../services/usuarios.service');
const { usuarioDto, paginadoUsuariosDto } = require('../views/usuario.dto');
const { esIdValido, validarNuevoUsuario } = require('../models/usuario.model');

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

// RF-096
async function crear(req, res, next) {
  try {
    const errors = validarNuevoUsuario(req.body);
    if (errors.length) return res.status(422).json({ errors });

    const r = await service.crearAdministrativo(req.body);
    if (r.duplicado === 'usuario')
      return res.status(409).json({ error: 'El nombre de usuario ya está registrado' });
    if (r.duplicado === 'correo')
      return res.status(409).json({ error: 'El correo electrónico ya está registrado' });

    res.status(201).json(usuarioDto(r.doc, r.rol));
  } catch (err) { next(err); }
}

module.exports = { listar, obtener, crear };
