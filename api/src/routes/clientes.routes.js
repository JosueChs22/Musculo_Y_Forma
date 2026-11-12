const { Router } = require('express');
const ctrl = require('../controllers/clientes.controller');
const { requerirAuth, requerirRol } = require('../middleware/auth');

const router = Router();

// Para elegir a quién asignar un plan: solo Entrenador y Administrador
router.use(requerirAuth, requerirRol('Entrenador', 'Administrador'));

router.get('/', ctrl.buscar);

module.exports = router;
