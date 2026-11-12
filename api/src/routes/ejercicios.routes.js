const { Router } = require('express');
const ctrl = require('../controllers/ejercicios.controller');
const { requerirAuth, requerirRol } = require('../middleware/auth');

const router = Router();

// Catálogo del panel del Entrenador (el Administrador también puede gestionarlo)
router.use(requerirAuth, requerirRol('Entrenador', 'Administrador'));

router.get('/',                   ctrl.listar);
router.get('/:id',                ctrl.obtener);
router.post('/',                  ctrl.crear);
router.put('/:id',                ctrl.actualizar);
router.patch('/:id/inhabilitar',  ctrl.inhabilitar);
router.patch('/:id/reactivar',    ctrl.reactivar);

module.exports = router;
