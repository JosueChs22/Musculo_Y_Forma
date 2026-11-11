function validarLogin(body) {
  const errors = [];
  if (!body.usuario || typeof body.usuario !== 'string' || !body.usuario.trim())
    errors.push('usuario: string no vacío requerido');
  if (!body.contrasena || typeof body.contrasena !== 'string')
    errors.push('contrasena: string no vacío requerido');
  return errors;
}

// ¿Es un ObjectId de Mongo? (24 caracteres hexadecimales)
function esIdValido(id) {
  return typeof id === 'string' && /^[0-9a-fA-F]{24}$/.test(id);
}

module.exports = { validarLogin, esIdValido };
