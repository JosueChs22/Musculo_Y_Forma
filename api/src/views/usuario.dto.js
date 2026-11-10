// Nunca incluye contrasena ni historial_cambios (Regla 20 CLAUDE.md)
function usuarioDto(doc, rol) {
  if (!doc) return null;
  return {
    id: doc._id.toString(),
    rol,
    nombre: doc.nombre,
    primerApellido: doc.primer_apellido,
    segundoApellido: doc.segundo_apellido ?? null,
    correo: doc.correo,
    telefono: doc.telefono,
    usuario: doc.usuario,
    estado: doc.estado,
    fechaIngreso: doc.fecha_ingreso,
    ultimoLogin: doc.ultimo_login ?? null,
  };
}

module.exports = { usuarioDto };
