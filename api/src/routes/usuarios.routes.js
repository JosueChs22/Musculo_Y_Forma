const { Router } = require('express');
const ctrl = require('../controllers/usuarios.controller');
const { requerirAuth, requerirRol } = require('../middleware/auth');

const router = Router();

// Todo este recurso es solo para el Administrador (se valida en la API, no solo en la app)
router.use(requerirAuth, requerirRol('Administrador'));

router.get('/',    ctrl.listar);
router.get('/:id', ctrl.obtener);
router.post('/',   ctrl.crear);

module.exports = router;
