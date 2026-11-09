// DTOs: solo los campos que el cliente necesita (Regla 0 CLAUDE.md)

function claseDto(doc) {
  if (!doc) return null;
  return {
    id: doc._id.toString(),
    nombre: doc.nombre,
    descripcion: doc.descripcion ?? null,
    estado: doc.estado,
    fechaActualizacion: doc.fecha_actualizacion ?? null,
    horarios: (doc.horarios ?? []).map(horarioDto),
  };
}

function horarioDto(h) {
  return { dias: h.dias, horaInicio: h.hora_inicio, horaFin: h.hora_fin, estado: h.estado };
}

function paginadoDto(items, nextCursor) {
  return { data: items.map(claseDto), nextCursor: nextCursor ?? null };
}

module.exports = { claseDto, horarioDto, paginadoDto };
