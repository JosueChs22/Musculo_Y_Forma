function validarLogin(body) {
  const errors = [];
  if (!body.usuario || typeof body.usuario !== 'string' || !body.usuario.trim())
    errors.push('usuario: string no vacío requerido');
  if (!body.contrasena || typeof body.contrasena !== 'string')
    errors.push('contrasena: string no vacío requerido');
  return errors;
}

module.exports = { validarLogin };
