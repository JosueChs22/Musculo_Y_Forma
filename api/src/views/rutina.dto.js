const { urlsDeImagen } = require('./ejercicio.dto');

function usuarioResumenDto(u) {
  if (!u) return null;
  return {
    id: u._id.toString(),
    nombre: [u.nombre, u.primer_apellido, u.segundo_apellido].filter(Boolean).join(' '),
    usuario: u.usuario,
  };
}

// `ejercicios` (Map id -> doc de ejercicios) solo viene en el detalle; en las listas
// se devuelve únicamente el total.
function rutinaDto(doc, usuario, ejercicios = null) {
  if (!doc) return null;
  const lista = doc.ejercicios ?? [];
  return {
    id: doc._id.toString(),
    nombre: doc.nombre,
    categoria: doc.categoria,
    observaciones: doc.observaciones ?? null,
    diaSemana: doc.dia_semana ?? null,
    estado: doc.estado,
    fechaCreacion: doc.fecha_creacion,
    usuario: usuarioResumenDto(usuario),
    totalEjercicios: lista.length,
    ejercicios: ejercicios
      ? lista.map((e) => {
          const ej = ejercicios.get(String(e.id_ejercicio));
          return {
            idEjercicio: String(e.id_ejercicio),
            orden: e.orden,
            series: e.series ?? 3,
            repeticiones: e.repeticiones ?? 10,
            descanso: e.descanso ?? 60,
            pesoSugerido: e.peso_sugerido ?? null,
            nota: e.nota ?? null,
            // Si el ejercicio ya no existe, el plan sigue mostrándose
            nombre: ej?.nombre ?? 'Ejercicio no disponible',
            grupoMuscular: ej?.grupo_muscular ?? null,
            activo: ej?.estado === 'Activo',
            ...urlsDeImagen(ej?.imagen),
          };
        })
      : [],
  };
}

function paginadoRutinasDto(items, nextCursor) {
  return { data: items.map(({ doc, usuario }) => rutinaDto(doc, usuario)), nextCursor: nextCursor ?? null };
}

module.exports = { rutinaDto, paginadoRutinasDto, usuarioResumenDto };
