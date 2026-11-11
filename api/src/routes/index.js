const { Router } = require('express');
const clasesRoutes = require('./clases.routes');
const authRoutes = require('./auth.routes');
const usuariosRoutes = require('./usuarios.routes');

const router = Router();

router.use('/clases', clasesRoutes);
router.use('/auth', authRoutes);
router.use('/usuarios', usuariosRoutes);

// Health check para Render
router.get('/health', (_req, res) => res.json({ status: 'ok', ts: new Date() }));

module.exports = router;
