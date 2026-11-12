const { Router } = require('express');
const ctrl = require('../controllers/rutinas.controller');
const { requerirAuth, requerirRol } = require('../middleware/auth');

const router = Router();

// Planes de entrenamiento del panel del Entrenador (el Administrador ve todos)
router.use(requerirAuth, requerirRol('Entrenador', 'Administrador'));

router.get('/',                   ctrl.listar);
router.get('/:id',                ctrl.obtener);
router.post('/',                  ctrl.crear);
router.put('/:id',                ctrl.actualizar);
router.patch('/:id/asignar',      ctrl.asignar);
router.patch('/:id/inhabilitar',  ctrl.inhabilitar);
router.patch('/:id/reactivar',    ctrl.reactivar);

module.exports = router;
