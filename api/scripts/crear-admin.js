// Crea el primer Administrador. Se corre UNA vez, a mano:  node scripts/crear-admin.js
require('dotenv').config();
const readline = require('readline');
const bcrypt = require('bcryptjs');
const { MongoClient } = require('mongodb');

const rl = readline.createInterface({ input: process.stdin, output: process.stdout });

// Pregunta normal
const preguntar = (texto) => new Promise((ok) => rl.question(texto, ok));

// Pregunta sin mostrar lo que se escribe (para la contraseña)
function preguntarOculto(texto) {
  return new Promise((ok) => {
    const original = rl._writeToOutput;
    rl._writeToOutput = () => {};          // no imprime las teclas
    process.stdout.write(texto);
    rl.question('', (r) => {
      rl._writeToOutput = original;
      process.stdout.write('\n');
      ok(r);
    });
  });
}

async function main() {
  const usuario = (await preguntar('Usuario: ')).trim();
  const correo = (await preguntar('Correo: ')).trim();
  const nombre = (await preguntar('Nombre: ')).trim();
  const primerApellido = (await preguntar('Primer apellido: ')).trim();
  const telefono = (await preguntar('Teléfono (8 dígitos): ')).trim();
  const contrasena = await preguntarOculto('Contraseña (mín. 8, letras y números): ');

  if (!usuario || !correo || !nombre || !primerApellido || !telefono)
    throw new Error('Todos los campos son obligatorios');
  if (contrasena.length < 8 || !/[A-Za-z]/.test(contrasena) || !/\d/.test(contrasena))
    throw new Error('La contraseña no cumple la política');

  const cliente = new MongoClient(process.env.MONGO_URI);
  await cliente.connect();
  try {
    const db = cliente.db(); // usa la base indicada en MONGO_URI (gimnasio)

    const rol = await db.collection('roles').findOne({ descripcion: 'Administrador' });
    if (!rol) throw new Error('No existe el rol "Administrador" en la colección roles');

    await db.collection('usuarios').insertOne({
      id_rol: rol._id,
      correo,
      contrasena: await bcrypt.hash(contrasena, 10), // nunca en texto plano
      nombre,
      primer_apellido: primerApellido,
      segundo_apellido: null,
      telefono,
      usuario,
      estado: 'Activo',
      fecha_ingreso: new Date(),
    });
    console.log(`Administrador "${usuario}" creado.`);
  } finally {
    await cliente.close();
  }
}

main()
  .catch((e) => {
    // 11000 = índice único violado (usuario o correo ya existen)
    console.error('Error:', e.code === 11000 ? 'Ese usuario o correo ya existe' : e.message);
    process.exitCode = 1;
  })
  .finally(() => rl.close());
