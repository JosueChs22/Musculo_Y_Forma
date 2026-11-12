const { usuarioDto } = require('./usuario.dto');
const { rutinaDto, usuarioResumenDto } = require('./rutina.dto');

function perfilDto({ usuario, rol, coach, ultimaMedicion }) {
  return {
    usuario: usuarioDto(usuario, rol),
    coach: usuarioResumenDto(coach),
    objetivo: ultimaMedicion?.objetivo ?? null,
    ultimaMedicion: ultimaMedicion?.fecha ?? null,
  };
}

// Planes del usuario: el detalle completo de cada uno y el nombre de quien lo armó
function misRutinasDto({ docs, ejercicios, coaches }) {
  return {
    data: docs.map((doc) => ({
      ...rutinaDto(doc, null, ejercicios),
      coach: usuarioResumenDto(coaches.get(String(doc.id_coach))),
    })),
  };
}

function medicionDto(m) {
  return {
    id: m._id.toString(),
    fecha: m.fecha,
    objetivo: m.objetivo ?? null,
    peso: m.peso_corporal ?? null,
    grasaCorporal: m.grasa_corporal ?? null,
    grasaVisceral: m.grasa_visceral ?? null,
    masaMuscular: m.masa_muscular ?? null,
    imc: m.imc ?? null,
    edad: m.edad ?? null,
    estatura: m.estatura ?? null,
    nivelActividad: m.nivel_actividad_fisica ?? null,
    frecuenciaSemanal: m.frecuencia_semanal ?? null,
  };
}

function paginadoMedicionesDto(items, nextCursor) {
  return { data: items.map(medicionDto), nextCursor: nextCursor ?? null };
}

module.exports = { perfilDto, misRutinasDto, paginadoMedicionesDto };
