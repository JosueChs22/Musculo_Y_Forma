const CATEGORIAS = ['entrenamiento', 'calentamiento', 'estiramiento'];
const ESTADOS = ['Activo', 'Inhabilitado'];
const MAX_EJERCICIOS = 50;

const esEntero = (v, min, max) => Number.isInteger(v) && v >= min && v <= max;
const esNumero = (v, min, max) => typeof v === 'number' && Number.isFinite(v) && v >= min && v <= max;

// ¿Es un ObjectId de Mongo? (24 caracteres hexadecimales)
function esIdValido(id) {
  return typeof id === 'string' && /^[0-9a-fA-F]{24}$/.test(id);
}

// Valida un plan (rutina) con sus ejercicios. Cuerpo en snake_case.
function validarRutina(b = {}) {
  const errors = [];

  if (typeof b.nombre !== 'string' || !b.nombre.trim() || b.nombre.trim().length > 80)
    errors.push('nombre: requerido, máximo 80 caracteres');
  if (!CATEGORIAS.includes(b.categoria))
    errors.push('categoria: debe ser entrenamiento, calentamiento o estiramiento');
  if (b.observaciones != null && (typeof b.observaciones !== 'string' || b.observaciones.trim().length > 1000))
    errors.push('observaciones: texto de máximo 1000 caracteres');
  if (b.dia_semana != null && !esEntero(b.dia_semana, 1, 7))
    errors.push('dia_semana: número del 1 (lunes) al 7 (domingo)');

  if (!Array.isArray(b.ejercicios) || b.ejercicios.length === 0) {
    errors.push('ejercicios: agrega al menos un ejercicio');
  } else if (b.ejercicios.length > MAX_EJERCICIOS) {
    errors.push(`ejercicios: máximo ${MAX_EJERCICIOS} por plan`);
  } else {
    const vistos = new Set();
    b.ejercicios.forEach((e, i) => {
      const n = i + 1;
      if (!e || !esIdValido(e.id_ejercicio)) return errors.push(`ejercicios[${n}].id_ejercicio: inválido`);
      if (vistos.has(e.id_ejercicio)) errors.push(`ejercicios[${n}]: el ejercicio está repetido en el plan`);
      vistos.add(e.id_ejercicio);
      if (!esEntero(e.series, 1, 20)) errors.push(`ejercicios[${n}].series: entero entre 1 y 20`);
      if (!esEntero(e.repeticiones, 1, 500)) errors.push(`ejercicios[${n}].repeticiones: entero entre 1 y 500`);
      if (!esEntero(e.descanso, 0, 1800)) errors.push(`ejercicios[${n}].descanso: segundos entre 0 y 1800`);
      if (e.peso_sugerido != null && !esNumero(e.peso_sugerido, 0, 1000))
        errors.push(`ejercicios[${n}].peso_sugerido: entre 0 y 1000`);
      if (e.nota != null && (typeof e.nota !== 'string' || e.nota.trim().length > 200))
        errors.push(`ejercicios[${n}].nota: texto de máximo 200 caracteres`);
    });
  }

  return errors;
}

module.exports = { CATEGORIAS, ESTADOS, MAX_EJERCICIOS, esIdValido, validarRutina };
