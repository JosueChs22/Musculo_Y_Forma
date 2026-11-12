const { Router } = require('express');
const ctrl = require('../controllers/clases.controller');
const { requerirAuth, requerirRol } = require('../middleware/auth');

const router = Router();

// Ver clases: cualquier usuario con sesión. Modificarlas: Secretaria o Administrador.
router.use(requerirAuth);
const gestion = requerirRol('Secretaria', 'Administrador');

router.get('/',                                        ctrl.listar);
router.get('/:id',                                     ctrl.obtener);
router.post('/',                                       gestion, ctrl.crear);
router.put('/:id',                                     gestion, ctrl.actualizar);
router.patch('/:id/inhabilitar',                       gestion, ctrl.inhabilitar);
router.patch('/:id/reactivar',                         gestion, ctrl.reactivar);
router.post('/:id/horarios',                           gestion, ctrl.agregarHorario);
router.put('/:id/horarios/:index',                     gestion, ctrl.actualizarHorario);
router.patch('/:id/horarios/:index/inhabilitar',       gestion, ctrl.inhabilitarHorario);

module.exports = router;
