const { Router } = require('express');
const clasesRoutes = require('./clases.routes');
const authRoutes = require('./auth.routes');
const usuariosRoutes = require('./usuarios.routes');
const ejerciciosRoutes = require('./ejercicios.routes');

const router = Router();

router.use('/clases', clasesRoutes);
router.use('/auth', authRoutes);
router.use('/usuarios', usuariosRoutes);
router.use('/ejercicios', ejerciciosRoutes);
router.use('/rutinas', require('./rutinas.routes'));
router.use('/clientes', require('./clientes.routes'));
router.use('/mi', require('./mi.routes'));

// Health check para Render
router.get('/health', (_req, res) => res.json({ status: 'ok', ts: new Date() }));

module.exports = router;
