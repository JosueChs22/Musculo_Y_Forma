require('dotenv').config();

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const rateLimit = require('express-rate-limit');

const { conectar } = require('./src/config/db');
const routes = require('./src/routes/index');
const errorHandler = require('./src/middleware/errorHandler');

const app = express();

// Seguridad y compresión (Reglas 14 y seguridad CLAUDE.md)
app.use(helmet());
app.use(compression());

// CORS — si CORS_ORIGINS='*' se permite todo; si no, lista separada por coma
const corsEnv = process.env.CORS_ORIGINS || '*';
const corsOrigin = corsEnv.trim() === '*'
  ? '*'
  : corsEnv.split(',').map((o) => o.trim()).filter(Boolean);
app.use(cors({ origin: corsOrigin }));

// Body parser
app.use(express.json({ limit: '100kb' }));

// Rate limiting: 100 req / 15 min por IP (seguridad CLAUDE.md)
app.use(
  '/api',
  rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 100,
    standardHeaders: true,
    legacyHeaders: false,
    message: { error: 'Demasiadas peticiones, intenta en 15 minutos' },
  })
);

// Rutas
app.use('/api', routes);

// 404
app.use((_req, res) => res.status(404).json({ error: 'Ruta no encontrada' }));

// Manejador de errores global
app.use(errorHandler);

// Arranque
const PORT = process.env.PORT || 3000;

conectar()
  .then(() => {
    app.listen(PORT, () => console.log(`API corriendo en http://localhost:${PORT}`));
  })
  .catch((err) => {
    console.error('No se pudo conectar a MongoDB:', err.message);
    process.exit(1);
  });
