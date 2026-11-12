
require('dotenv').config();
const mongoose = require('mongoose');

async function conectarDB() {
  try {
    const uri = process.env.MONGODB_URI;

    if (!uri) {
      throw new Error('No se encontró MONGODB_URI');
    }

    const baseConfigurada = new URL(uri).pathname.slice(1);

    // Protección para el entorno de pruebas
    if (process.env.NODE_ENV === 'test') {
      if (baseConfigurada !== 'gimnasio_pruebas_eduardo') {
        throw new Error(
          'SEGURIDAD: las pruebas deben usar gimnasio_pruebas_eduardo'
        );
      }
    }

    await mongoose.connect(uri);

    console.log('Conectado a MongoDB Atlas');
    console.log('Base de datos:', mongoose.connection.name);
    console.log('Entorno:', process.env.NODE_ENV || 'development');

  } catch (error) {
    console.error('Error de conexión:', error.message);
    process.exit(1);
  }
}

module.exports = conectarDB;
