const { MongoClient } = require('mongodb');

let client = null;
let db = null;

// Pool único para toda la API (Regla 16 CLAUDE.md)
async function conectar() {
  if (db) return db;

  client = new MongoClient(process.env.MONGO_URI, {
    maxPoolSize: parseInt(process.env.MONGO_MAX_POOL || '10'),
    minPoolSize: parseInt(process.env.MONGO_MIN_POOL || '2'),
    maxIdleTimeMS: parseInt(process.env.MONGO_MAX_IDLE_MS || '30000'),
    serverSelectionTimeoutMS: 5000,
  });

  await client.connect();
  db = client.db('gimnasio');
  console.log('MongoDB conectado:', process.env.MONGO_URI.replace(/\/\/.*@/, '//***@'));
  return db;
}

function getDb() {
  if (!db) throw new Error('BD no inicializada. Llama conectar() primero.');
  return db;
}

async function cerrar() {
  if (client) { await client.close(); client = null; db = null; }
}

module.exports = { conectar, getDb, cerrar };
