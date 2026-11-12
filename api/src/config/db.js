const dns = require('dns');
const { MongoClient } = require('mongodb');

let client = null;
let db = null;

// En algunas PC con Windows, Node no logra consultar registros SRV con el DNS del
// sistema (querySrv ECONNREFUSED) aunque Windows sí los resuelve. Si pasa, se usa
// un DNS público solo para encontrar el clúster de Atlas.
async function asegurarDnsSrv(uri) {
  if (!uri.startsWith('mongodb+srv://')) return;
  const host = new URL(uri).hostname;
  try {
    await dns.promises.resolveSrv(`_mongodb._tcp.${host}`);
  } catch {
    dns.setServers(['8.8.8.8', '1.1.1.1']);
    console.warn('DNS del sistema sin respuesta para Atlas: se usa DNS público');
  }
}

// Pool único para toda la API (Regla 16 CLAUDE.md)
async function conectar() {
  if (db) return db;
  await asegurarDnsSrv(process.env.MONGO_URI);

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
