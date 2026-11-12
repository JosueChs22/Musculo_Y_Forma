// Carga el catálogo de ejercicios del dataset https://github.com/hasaneyldrm/exercises-dataset
//
//   node scripts/importar-ejercicios.js                 descarga exercises.json de GitHub
//   node scripts/importar-ejercicios.js <ruta.json>     usa una copia local
//   node scripts/importar-ejercicios.js --simular       no escribe, solo muestra qué haría
//
// Se puede correr las veces que haga falta: cada ejercicio se identifica por la ruta
// de su imagen, así que solo agrega los que faltan y no pisa lo que el entrenador editó.
// Los nombres van en español (scripts/datos/nombres-es.json); si un ejercicio ya
// importado sigue con su nombre original en inglés, se renombra.
// Escribe en la base de MONGO_URI (Atlas o local, según tu .env).
require('dotenv').config();
const fs = require('fs');
const path = require('path');
const { conectar, getDb, cerrar } = require('../src/config/db');

// Nombre en español de cada ejercicio, por su id en el dataset
const NOMBRES_ES = JSON.parse(fs.readFileSync(path.join(__dirname, 'datos', 'nombres-es.json'), 'utf8'));

const URL_DATASET = 'https://raw.githubusercontent.com/hasaneyldrm/exercises-dataset/main/data/exercises.json';

const GRUPO = {
  chest: 'Pecho', back: 'Espalda', shoulders: 'Hombros', 'upper arms': 'Brazos', 'lower arms': 'Antebrazos',
  waist: 'Abdomen', 'upper legs': 'Muslos', 'lower legs': 'Pantorrillas', cardio: 'Cardio', neck: 'Cuello',
};

const HERRAMIENTA = {
  'body weight': 'Peso corporal', cable: 'Polea', 'leverage machine': 'Máquina de palanca', assisted: 'Asistido',
  'medicine ball': 'Balón medicinal', 'stability ball': 'Balón de estabilidad', band: 'Banda elástica',
  barbell: 'Barra', rope: 'Cuerda', dumbbell: 'Mancuerna', 'ez barbell': 'Barra EZ', 'sled machine': 'Máquina de trineo',
  'upper body ergometer': 'Ergómetro de brazos', kettlebell: 'Pesa rusa', 'olympic barbell': 'Barra olímpica',
  weighted: 'Con lastre', 'bosu ball': 'Bosu', 'resistance band': 'Banda de resistencia', roller: 'Rodillo',
  'skierg machine': 'Máquina SkiErg', hammer: 'Martillo', 'smith machine': 'Máquina Smith',
  'wheel roller': 'Rueda abdominal', 'stationary bike': 'Bicicleta estática', tire: 'Neumático',
  'trap bar': 'Barra hexagonal', 'elliptical machine': 'Elíptica', 'stepmill machine': 'Escaladora',
};

const MUSCULO = {
  abs: 'Abdominales', quads: 'Cuádriceps', lats: 'Dorsales', calves: 'Pantorrillas', pectorals: 'Pectorales',
  glutes: 'Glúteos', hamstrings: 'Isquiotibiales', adductors: 'Aductores', triceps: 'Tríceps',
  'cardiovascular system': 'Sistema cardiovascular', spine: 'Columna', 'upper back': 'Espalda alta',
  biceps: 'Bíceps', delts: 'Deltoides', forearms: 'Antebrazos', traps: 'Trapecios',
  'serratus anterior': 'Serrato anterior', abductors: 'Abductores', 'levator scapulae': 'Elevador de la escápula',
  rhomboids: 'Romboides', 'hip flexors': 'Flexores de cadera', 'lower back': 'Zona lumbar', shoulders: 'Hombros',
  chest: 'Pecho', core: 'Core', obliques: 'Oblicuos', brachialis: 'Braquial', wrists: 'Muñecas',
  'wrist flexors': 'Flexores de muñeca', 'wrist extensors': 'Extensores de muñeca', ankles: 'Tobillos',
  feet: 'Pies', groin: 'Ingle', hands: 'Manos', 'rear deltoids': 'Deltoides posteriores', sternocleidomastoid: 'Esternocleidomastoideo',
  'rotator cuff': 'Manguito rotador', 'inner thighs': 'Muslos internos', 'ankle stabilizers': 'Estabilizadores del tobillo',
  'upper chest': 'Pecho superior', 'latissimus dorsi': 'Dorsal ancho', trapezius: 'Trapecio', shins: 'Espinillas',
  'hip abductors': 'Abductores de cadera', 'hip adductors': 'Aductores de cadera', 'lower abs': 'Abdomen inferior',
  back: 'Espalda', abdominals: 'Abdominales', 'grip muscles': 'Músculos de agarre', soleus: 'Sóleo',
  'upper abs': 'Abdomen superior', 'serratus': 'Serrato', 'deltoids': 'Deltoides', 'quadriceps': 'Cuádriceps',
};

const faltantes = new Set();
const traducir = (mapa, v) => {
  if (!v) return null;
  const t = mapa[String(v).toLowerCase()];
  if (!t) faltantes.add(v);
  return t ?? String(v);
};
const capitalizar = (s) => s.charAt(0).toUpperCase() + s.slice(1);

function aDocumento(e) {
  const objetivo = traducir(MUSCULO, e.target);
  const secundarios = [...new Set(e.secondary_muscles ?? [])].map((m) => traducir(MUSCULO, m));
  const notas = [
    objetivo && `Músculo objetivo: ${objetivo}.`,
    secundarios.length && `Secundarios: ${secundarios.join(', ')}.`,
  ].filter(Boolean);

  return {
    nombre: (NOMBRES_ES[e.id] ?? capitalizar(String(e.name).trim())).slice(0, 80),
    tipo: 'entrenamiento', // el tipo es de la rutina; la colección todavía lo pide
    grupo_muscular: traducir(GRUPO, e.body_part),
    herramienta: traducir(HERRAMIENTA, e.equipment),
    imagen: e.image, // ruta relativa; la API arma la URL del CDN (y la del GIF)
    instrucciones: (e.instructions?.es || e.instructions?.en || '').trim().slice(0, 2000) || null,
    observaciones: notas.join(' ') || null,
    recomendaciones: null,
    estado: 'Activo',
  };
}

async function main() {
  const simular = process.argv.includes('--simular');
  const ruta = process.argv.slice(2).find((a) => !a.startsWith('--'));

  let crudo;
  if (ruta) {
    crudo = fs.readFileSync(ruta, 'utf8');
  } else {
    console.log('Descargando exercises.json de GitHub...');
    const res = await fetch(URL_DATASET, { signal: AbortSignal.timeout(60000) });
    if (!res.ok) throw new Error(`GitHub respondió ${res.status}`);
    crudo = await res.text();
  }

  const dataset = JSON.parse(crudo).filter((e) => e.image && e.name);
  const docs = dataset.map(aDocumento);
  console.log(`${docs.length} ejercicios en el dataset.`);
  const sinEspanol = dataset.filter((e) => !NOMBRES_ES[e.id]).length;
  if (sinEspanol) console.log(`${sinEspanol} sin nombre en español (quedan en inglés).`);
  if (faltantes.size) console.log('Sin traducción (quedan en inglés):', [...faltantes].join(', '));
  if (simular) return console.log('Simulación: no se escribió nada. Ejemplo:', docs[0]);

  await conectar();
  try {
    const col = getDb().collection('ejercicios');

    // 1. Los ya importados que siguen con el nombre original en inglés pasan a español
    //    (si el entrenador cambió el nombre, ya no coincide y no se toca)
    const renombres = dataset
      .filter((e) => NOMBRES_ES[e.id])
      .map((e) => ({
        updateOne: {
          filter: { imagen: e.image, nombre: capitalizar(String(e.name).trim()).slice(0, 80) },
          update: { $set: { nombre: NOMBRES_ES[e.id].slice(0, 80) } },
        },
      }));
    const ren = await col.bulkWrite(renombres, { ordered: false });

    // 2. Los que faltan se agregan
    const r = await col.bulkWrite(
      docs.map((d) => ({ updateOne: { filter: { imagen: d.imagen }, update: { $setOnInsert: d }, upsert: true } })),
      { ordered: false },
    );
    console.log(`Agregados: ${r.upsertedCount}. Ya existían: ${docs.length - r.upsertedCount}. Renombrados a español: ${ren.modifiedCount}.`);
  } finally {
    await cerrar();
  }
}

main().catch((e) => { console.error('Error:', e.message); process.exitCode = 1; });
