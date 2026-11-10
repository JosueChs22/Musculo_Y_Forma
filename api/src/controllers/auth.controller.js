const service = require('../services/auth.service');
const { usuarioDto } = require('../views/usuario.dto');
const { validarLogin } = require('../models/usuario.model');

async function login(req, res, next) {
  try {
    const errors = validarLogin(req.body);
    if (errors.length) return res.status(422).json({ errors });

    const r = await service.autenticar(req.body.usuario, req.body.contrasena);
    if (r.motivo === 'credenciales')
      return res.status(401).json({ error: 'Usuario o contraseña incorrectos' });
    if (r.motivo === 'inhabilitado')
      return res.status(403).json({ error: 'Su cuenta está inhabilitada' });

    res.json({
      token: service.firmarToken(r.usuario, r.rol),
      usuario: usuarioDto(r.usuario, r.rol),
    });
  } catch (err) { next(err); }
}

module.exports = { login };
