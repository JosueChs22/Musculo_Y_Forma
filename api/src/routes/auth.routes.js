const { Router } = require('express');
const rateLimit = require('express-rate-limit');
const ctrl = require('../controllers/auth.controller');
const { requerirAuth } = require('../middleware/auth');

const router = Router();

// Límites más estrictos que el general (100 / 15 min por IP) para lo sensible
const limitar = (max) => rateLimit({
  windowMs: 15 * 60 * 1000,
  max,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Demasiados intentos, intenta en 15 minutos' },
});

router.post('/login', limitar(10), ctrl.login);

// Con un token robado también se podría intentar adivinar la contraseña actual
router.post('/cambiar-contrasena', requerirAuth, limitar(10), ctrl.cambiarContrasena);

// Recuperación (públicas, no hay sesión): pedir código y usarlo
router.post('/recuperar', limitar(5), ctrl.recuperar);
router.post('/restablecer', limitar(10), ctrl.restablecer);

module.exports = router;
