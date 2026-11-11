// Roles que el Administrador puede crear y listar (RF-096 / RF-103)
const ROLES_ADMINISTRATIVOS = ['Secretaria', 'Entrenador'];

const RE_CORREO = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const RE_USUARIO = /^[A-Za-z0-9._-]{3,30}$/;

const texto = (v) => (typeof v === 'string' ? v.trim() : '');

// Política de contraseña (la misma que valida la app): 8+ caracteres, sin
// espacios, con al menos una letra y un número. Máximo 72: bcrypt ignora lo
// que pase de ahí.
function contrasenaValida(c) {
  return typeof c === 'string' && c.length >= 8 && c.length <= 72 &&
    !/\s/.test(c) && /[A-Za-z]/.test(c) && /\d/.test(c);
}

const MSG_POLITICA = '8 a 72 caracteres, sin espacios, con al menos una letra y un número';

function validarLogin(body) {
  const errors = [];
  if (!body.usuario || typeof body.usuario !== 'string' || !body.usuario.trim())
    errors.push('usuario: string no vacío requerido');
  if (!body.contrasena || typeof body.contrasena !== 'string')
    errors.push('contrasena: string no vacío requerido');
  return errors;
}

// RF-096: valida el cuerpo (snake_case) para crear un usuario administrativo
function validarNuevoUsuario(b = {}) {
  const errors = [];

  if (!texto(b.nombre) || texto(b.nombre).length > 60)
    errors.push('nombre: requerido, máximo 60 caracteres');
  if (!texto(b.primer_apellido) || texto(b.primer_apellido).length > 60)
    errors.push('primer_apellido: requerido, máximo 60 caracteres');

  // El segundo apellido es opcional
  if (b.segundo_apellido != null && b.segundo_apellido !== '' &&
      (typeof b.segundo_apellido !== 'string' || b.segundo_apellido.trim().length > 60))
    errors.push('segundo_apellido: máximo 60 caracteres');

  if (!RE_CORREO.test(texto(b.correo)) || texto(b.correo).length > 100)
    errors.push('correo: correo electrónico válido requerido');
  if (!/^\d{8}$/.test(texto(b.telefono)))
    errors.push('telefono: debe tener 8 dígitos');
  if (!ROLES_ADMINISTRATIVOS.includes(b.rol))
    errors.push('rol: debe ser Secretaria o Entrenador');
  if (!RE_USUARIO.test(texto(b.usuario)))
    errors.push('usuario: de 3 a 30 caracteres (letras, números, punto, guion o guion bajo)');
  if (!contrasenaValida(b.contrasena))
    errors.push(`contrasena: ${MSG_POLITICA}`);

  return errors;
}

// RF-035: valida el cuerpo (snake_case) para cambiar la contraseña
function validarCambioContrasena(b = {}) {
  const errors = [];
  if (typeof b.contrasena_actual !== 'string' || !b.contrasena_actual)
    errors.push('contrasena_actual: requerida');
  if (!contrasenaValida(b.contrasena_nueva))
    errors.push(`contrasena_nueva: ${MSG_POLITICA}`);
  else if (b.contrasena_nueva === b.contrasena_actual)
    errors.push('contrasena_nueva: debe ser distinta a la actual');
  return errors;
}

// ¿Es un ObjectId de Mongo? (24 caracteres hexadecimales)
function esIdValido(id) {
  return typeof id === 'string' && /^[0-9a-fA-F]{24}$/.test(id);
}

module.exports = {
  ROLES_ADMINISTRATIVOS,
  validarLogin,
  validarNuevoUsuario,
  validarCambioContrasena,
  esIdValido,
};
