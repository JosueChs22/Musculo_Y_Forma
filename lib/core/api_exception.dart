/// Error de la API con un mensaje listo para mostrarle al usuario.
class ApiException implements Exception {
  const ApiException(this.mensaje);
  final String mensaje;

  @override
  String toString() => mensaje;
}
