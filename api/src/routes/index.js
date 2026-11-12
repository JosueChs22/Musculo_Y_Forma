const { Router } = require('express');
const clasesRoutes = require('./clases.routes');

const router = Router();

router.use('/clases', clasesRoutes);

// Health check para Render
router.get('/health', (_req, res) => res.json({ status: 'ok', ts: new Date() }));

module.exports = router;
