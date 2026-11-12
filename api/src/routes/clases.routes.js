const { Router } = require('express');
const ctrl = require('../controllers/clases.controller');

const router = Router();

router.get('/',                                        ctrl.listar);
router.get('/:id',                                     ctrl.obtener);
router.post('/',                                       ctrl.crear);
router.put('/:id',                                     ctrl.actualizar);
router.patch('/:id/inhabilitar',                       ctrl.inhabilitar);
router.patch('/:id/reactivar',                         ctrl.reactivar);
router.post('/:id/horarios',                           ctrl.agregarHorario);
router.put('/:id/horarios/:index',                     ctrl.actualizarHorario);
router.patch('/:id/horarios/:index/inhabilitar',       ctrl.inhabilitarHorario);

module.exports = router;
