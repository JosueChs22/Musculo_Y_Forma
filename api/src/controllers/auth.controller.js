const service = require('../services/auth.service');
const { usuarioDto } = require('../views/usuario.dto');
const {
  validarLogin, validarCambioContrasena, validarRecuperacion, validarRestablecer,
} = require('../models/usuario.model');

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

// RF-035: el usuario sale del token (req.usuario), nunca del cuerpo de la petición
async function cambiarContrasena(req, res, next) {
  try {
    const errors = validarCambioContrasena(req.body);
    if (errors.length) return res.status(422).json({ errors });

    const r = await service.cambiarContrasena(
      req.usuario.id, req.body.contrasena_actual, req.body.contrasena_nueva,
    );
    if (r.motivo === 'no_autorizado')
      return res.status(401).json({ error: 'Sesión inválida o expirada' });
    if (r.motivo === 'actual_incorrecta')
      return res.status(400).json({ error: 'La contraseña actual es incorrecta' });

    res.json({ ok: true });
  } catch (err) { next(err); }
}

// RF-034, paso 1. Responde lo mismo exista o no el correo, y el envío sigue en
// segundo plano: así ni el mensaje ni el tiempo de respuesta delatan qué correos existen.
async function recuperar(req, res, next) {
  try {
    const errors = validarRecuperacion(req.body);
    if (errors.length) return res.status(422).json({ errors });

    service.solicitarRecuperacion(req.body.correo)
      .catch((err) => console.error('Error en la recuperación de contraseña:', err.message));
    res.json({ ok: true });
  } catch (err) { next(err); }
}

// RF-034, paso 2
async function restablecer(req, res, next) {
  try {
    const errors = validarRestablecer(req.body);
    if (errors.length) return res.status(422).json({ errors });

    const r = await service.restablecerContrasena(
      req.body.correo, req.body.codigo, req.body.contrasena_nueva,
    );
    if (r.motivo === 'invalido')
      return res.status(400).json({ error: 'El código es inválido o ya venció' });

    res.json({ ok: true });
  } catch (err) { next(err); }
}

module.exports = { login, cambiarContrasena, recuperar, restablecer };
