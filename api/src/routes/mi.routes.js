const { Router } = require('express');
const ctrl = require('../controllers/mi.controller');
const { requerirAuth } = require('../middleware/auth');

const router = Router();

// Datos propios: cualquier rol con sesión (un entrenador también puede tener su plan y sus mediciones)
router.use(requerirAuth);

router.get('/perfil',      ctrl.perfil);
router.get('/rutinas',     ctrl.rutinas);
router.get('/mediciones',  ctrl.mediciones);

module.exports = router;
