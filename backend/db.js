require('dotenv').config();
const mongoose = require('mongoose');

async function conectarDB() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Conectado a MongoDB Atlas');
  } catch (error) {
    console.error('Error de conexión:', error.message);
    process.exit(1);
  }
}

module.exports = conectarDB;