// Las imágenes viven en el repo del dataset y se sirven por CDN. En la BD solo se
// guarda la ruta relativa ("images/0001-xxxx.jpg"); la URL completa se arma aquí.
const MEDIA_BASE = (process.env.MEDIA_BASE_URL || 'https://cdn.jsdelivr.net/gh/hasaneyldrm/exercises-dataset@main/')
  .replace(/\/?$/, '/');

// Miniatura estática (para listas) y animación (para el detalle)
function urlsDeImagen(ruta) {
  if (typeof ruta !== 'string' || !ruta) return { imagen: null, gif: null };
  const gif = ruta.startsWith('images/') ? ruta.replace(/^images\//, 'videos/').replace(/\.jpg$/, '.gif') : null;
  return { imagen: MEDIA_BASE + ruta, gif: gif && MEDIA_BASE + gif };
}

function ejercicioDto(doc) {
  if (!doc) return null;
  return {
    id: doc._id.toString(),
    nombre: doc.nombre,
    grupoMuscular: doc.grupo_muscular ?? null,
    herramienta: doc.herramienta ?? null,
    ...urlsDeImagen(doc.imagen),
    tiempoRecomendado: doc.tiempo_recomendado ?? null,
    instrucciones: doc.instrucciones ?? null,
    observaciones: doc.observaciones ?? null,
    recomendaciones: doc.recomendaciones ?? null,
    estado: doc.estado,
  };
}

function paginadoEjerciciosDto(items, nextCursor) {
  return { data: items.map(ejercicioDto), nextCursor: nextCursor ?? null };
}

module.exports = { ejercicioDto, paginadoEjerciciosDto, urlsDeImagen };
