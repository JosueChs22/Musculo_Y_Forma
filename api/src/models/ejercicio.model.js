// Grupos musculares con los que se clasifica el catálogo (parte del cuerpo)
const GRUPOS = [
  'Pecho', 'Espalda', 'Hombros', 'Brazos', 'Antebrazos', 'Abdomen',
  'Muslos', 'Pantorrillas', 'Cardio', 'Cuello',
];

// Campos de texto opcionales y su largo máximo
const OPCIONALES = {
  grupo_muscular: 60,
  herramienta: 80,
  instrucciones: 2000,
  observaciones: 1000,
  recomendaciones: 1000,
};

const ESTADOS = ['Activo', 'Inhabilitado'];

// Minutos. Tope de 10 horas para atajar errores de digitación.
const TIEMPO_MAXIMO = 600;

// El tipo (entrenamiento / calentamiento / estiramiento) es de la rutina, no del
// ejercicio. La colección todavía lo exige, así que todos se guardan con este.
const TIPO_POR_DEFECTO = 'entrenamiento';

// RF-038 / RF-048: valida el cuerpo (snake_case) para crear o actualizar
function validarEjercicio(b = {}) {
  const errors = [];

  if (typeof b.nombre !== 'string' || !b.nombre.trim() || b.nombre.trim().length > 80)
    errors.push('nombre: requerido, máximo 80 caracteres');

  for (const [campo, max] of Object.entries(OPCIONALES)) {
    const v = b[campo];
    if (v != null && (typeof v !== 'string' || v.trim().length > max))
      errors.push(`${campo}: texto de máximo ${max} caracteres`);
  }

  const t = b.tiempo_recomendado;
  if (t != null && (typeof t !== 'number' || !Number.isFinite(t) || t < 0 || t > TIEMPO_MAXIMO))
    errors.push(`tiempo_recomendado: número de minutos entre 0 y ${TIEMPO_MAXIMO}`);

  return errors;
}

// ¿Es un ObjectId de Mongo? (24 caracteres hexadecimales)
function esIdValido(id) {
  return typeof id === 'string' && /^[0-9a-fA-F]{24}$/.test(id);
}

module.exports = { GRUPOS, OPCIONALES, ESTADOS, TIPO_POR_DEFECTO, validarEjercicio, esIdValido };
