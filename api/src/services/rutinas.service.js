const { ObjectId } = require('mongodb');
const { getDb } = require('../config/db');

const COL = 'rutinas';

// Solo los campos que la app necesita (Regla 20 CLAUDE.md)
const PROJ = {
  _id: 1, id_usuario: 1, id_coach: 1, nombre: 1, observaciones: 1, estado: 1,
  dia_semana: 1, fecha_creacion: 1, categoria: 1, ejercicios: 1,
};
const PROJ_EJERCICIO = { _id: 1, nombre: 1, imagen: 1, grupo_muscular: 1, herramienta: 1, estado: 1 };
const PROJ_USUARIO = { _id: 1, nombre: 1, primer_apellido: 1, segundo_apellido: 1, usuario: 1 };

const escaparRegex = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

// El Entrenador solo ve y modifica sus propios planes; el Administrador, todos.
const filtroDueno = (u) => (u.rol === 'Administrador' ? {} : { id_coach: new ObjectId(u.id) });

// Los clientes asignables: usuarios activos con rol Cliente
async function buscarCliente(db, idUsuario) {
  const rol = await db.collection('roles').findOne({ descripcion: 'Cliente' }, { projection: { _id: 1 } });
  if (!rol) return null;
  return db.collection('usuarios').findOne(
    { _id: new ObjectId(idUsuario), id_rol: rol._id, estado: 'Activo' }, { projection: PROJ_USUARIO },
  );
}

// Trae de una vez los usuarios de varios planes (Regla 18: sin consultar en un ciclo)
async function usuariosPorId(db, ids) {
  const unicos = [...new Set(ids.filter(Boolean).map(String))].map((i) => new ObjectId(i));
  if (!unicos.length) return new Map();
  const docs = await db.collection('usuarios').find({ _id: { $in: unicos } }, { projection: PROJ_USUARIO }).toArray();
  return new Map(docs.map((d) => [String(d._id), d]));
}

// Planes del entrenador, del más nuevo al más viejo. Devuelve { items: [{ doc, usuario }], nextCursor }
async function listarRutinas(u, { limite = 20, cursor = null, categoria = null, estado = null, q = null } = {}) {
  const db = getDb();
  const tope = Math.min(limite, 100);
  const filtro = { ...filtroDueno(u) };
  if (categoria) filtro.categoria = categoria;
  if (estado) filtro.estado = estado;
  if (q) filtro.nombre = { $regex: escaparRegex(q), $options: 'i' };
  if (cursor) {
    try { filtro._id = { $lt: new ObjectId(cursor) }; } catch { /* cursor inválido, ignorar */ }
  }

  const docs = await db.collection(COL)
    .find(filtro, { projection: PROJ })
    .sort({ _id: -1 })
    .limit(tope)
    .toArray();

  const usuarios = await usuariosPorId(db, docs.map((d) => d.id_usuario));
  const items = docs.map((doc) => ({ doc, usuario: usuarios.get(String(doc.id_usuario)) ?? null }));
  const nextCursor = docs.length === tope ? String(docs[docs.length - 1]._id) : null;
  return { items, nextCursor };
}

// Un plan con el detalle de sus ejercicios. Devuelve { doc, usuario, ejercicios: Map } o null
async function obtenerRutina(u, id) {
  const db = getDb();
  const doc = await db.collection(COL).findOne({ _id: new ObjectId(id), ...filtroDueno(u) }, { projection: PROJ });
  if (!doc) return null;

  const idsEjercicio = (doc.ejercicios ?? []).map((e) => e.id_ejercicio);
  const [usuarios, ejercicios] = await Promise.all([ // independientes entre sí (Regla 10)
    usuariosPorId(db, [doc.id_usuario]),
    idsEjercicio.length
      ? db.collection('ejercicios').find({ _id: { $in: idsEjercicio } }, { projection: PROJ_EJERCICIO }).toArray()
      : [],
  ]);
  return {
    doc,
    usuario: usuarios.get(String(doc.id_usuario)) ?? null,
    ejercicios: new Map(ejercicios.map((e) => [String(e._id), e])),
  };
}

// Verifica que todos los ejercicios existan y estén activos. Devuelve la lista de ids inválidos.
async function ejerciciosInvalidos(db, ejercicios) {
  const ids = ejercicios.map((e) => new ObjectId(e.id_ejercicio));
  const validos = await db.collection('ejercicios')
    .find({ _id: { $in: ids }, estado: 'Activo' }, { projection: { _id: 1 } }).toArray();
  const ok = new Set(validos.map((d) => String(d._id)));
  return ejercicios.map((e) => e.id_ejercicio).filter((id) => !ok.has(String(id)));
}

function ejerciciosDoc(lista) {
  return lista.map((e, i) => {
    const item = {
      id_ejercicio: new ObjectId(e.id_ejercicio),
      orden: i + 1,
      series: e.series,
      repeticiones: e.repeticiones,
      descanso: e.descanso,
      nota: e.nota?.trim() || null,
    };
    if (e.peso_sugerido != null) item.peso_sugerido = e.peso_sugerido;
    return item;
  });
}

// Crea un plan. Si trae id_usuario, nace ya asignado.
// Devuelve { id } | { ejerciciosInvalidos: [...] } | { clienteInvalido: true }
async function crearRutina(u, b) {
  const db = getDb();
  const invalidos = await ejerciciosInvalidos(db, b.ejercicios);
  if (invalidos.length) return { ejerciciosInvalidos: invalidos };

  const doc = {
    id_coach: new ObjectId(u.id),
    nombre: b.nombre.trim(),
    observaciones: b.observaciones?.trim() || null,
    estado: 'Activo',
    fecha_creacion: new Date(),
    categoria: b.categoria,
    ejercicios: ejerciciosDoc(b.ejercicios),
  };
  if (b.dia_semana != null) doc.dia_semana = b.dia_semana;
  if (b.id_usuario) {
    if (!(await buscarCliente(db, b.id_usuario))) return { clienteInvalido: true };
    doc.id_usuario = new ObjectId(b.id_usuario);
  }

  const { insertedId } = await db.collection(COL).insertOne(doc);
  return { id: String(insertedId) };
}

// Actualiza un plan activo (no cambia a quién está asignado).
// Devuelve { ok } | { noEncontrado } | { ejerciciosInvalidos: [...] }
async function actualizarRutina(u, id, b) {
  const db = getDb();
  const invalidos = await ejerciciosInvalidos(db, b.ejercicios);
  if (invalidos.length) return { ejerciciosInvalidos: invalidos };

  const cambio = {
    $set: {
      nombre: b.nombre.trim(),
      observaciones: b.observaciones?.trim() || null,
      categoria: b.categoria,
      ejercicios: ejerciciosDoc(b.ejercicios),
    },
  };
  if (b.dia_semana != null) cambio.$set.dia_semana = b.dia_semana;
  else cambio.$unset = { dia_semana: '' };

  const { matchedCount } = await db.collection(COL).updateOne(
    { _id: new ObjectId(id), estado: 'Activo', ...filtroDueno(u) }, cambio,
  );
  return matchedCount === 1 ? { ok: true } : { noEncontrado: true };
}

// Asigna el plan a un cliente (o lo deja sin asignar con idUsuario = null).
// Devuelve { usuario } | { noEncontrado } | { clienteInvalido }
async function asignarRutina(u, id, idUsuario) {
  const db = getDb();
  let cliente = null;
  if (idUsuario) {
    cliente = await buscarCliente(db, idUsuario);
    if (!cliente) return { clienteInvalido: true };
  }

  const cambio = idUsuario ? { $set: { id_usuario: cliente._id } } : { $unset: { id_usuario: '' } };
  const { matchedCount } = await db.collection(COL).updateOne(
    { _id: new ObjectId(id), estado: 'Activo', ...filtroDueno(u) }, cambio,
  );
  return matchedCount === 1 ? { usuario: cliente } : { noEncontrado: true };
}

async function cambiarEstado(u, id, desde, hacia) {
  const { matchedCount } = await getDb().collection(COL).updateOne(
    { _id: new ObjectId(id), estado: desde, ...filtroDueno(u) }, { $set: { estado: hacia } },
  );
  return matchedCount === 1;
}

const inhabilitarRutina = (u, id) => cambiarEstado(u, id, 'Activo', 'Inhabilitado');
const reactivarRutina = (u, id) => cambiarEstado(u, id, 'Inhabilitado', 'Activo');

module.exports = {
  listarRutinas, obtenerRutina, crearRutina, actualizarRutina, asignarRutina,
  inhabilitarRutina, reactivarRutina,
};
