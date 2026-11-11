
require('dotenv').config();

const express = require('express');
const cors = require('cors');
const path = require('path');
const conectarDB = require('./db');

const app = express();

// Configuración de Express
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Conexión a MongoDB Atlas
conectarDB();

// Ruta principal
app.get('/', (req, res) => {
  res.json({
    mensaje: 'API del gimnasio funcionando'
  });
});

// Archivos e imágenes
app.use(
  '/uploads',
  express.static(path.join(__dirname, 'uploads'))
);

// Diagnóstico de las peticiones a anuncios
app.use('/api/anuncios', (req, res, next) => {
  console.log(
    'Solicitud recibida:',
    req.method,
    req.originalUrl
  );
  next();
});

// Rutas del módulo de anuncios
const anunciosRoutes = require('./routes/anuncios');
app.use('/api/anuncios', anunciosRoutes);

// Iniciar servidor
const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`Servidor en http://localhost:${PORT}`);
  console.log('Rutas de anuncios habilitadas');
});
