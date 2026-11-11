const { Router } = require('express');
const rateLimit = require('express-rate-limit');
const ctrl = require('../controllers/auth.controller');
const { requerirAuth } = require('../middleware/auth');

const router = Router();

// Límite más estricto para el login: 10 intentos / 15 min por IP
const limitarLogin = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Demasiados intentos, intenta en 15 minutos' },
});

// Con un token robado también se podría intentar adivinar la contraseña actual,
// así que este endpoint lleva su propio límite de intentos.
const limitarCambio = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Demasiados intentos, intenta en 15 minutos' },
});

router.post('/login', limitarLogin, ctrl.login);
router.post('/cambiar-contrasena', requerirAuth, limitarCambio, ctrl.cambiarContrasena);

module.exports = router;
