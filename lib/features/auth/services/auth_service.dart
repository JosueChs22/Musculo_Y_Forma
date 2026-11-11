import '../models/usuario.dart';

/// Error con un mensaje listo para mostrarle al usuario.
class AuthException implements Exception {
  const AuthException(this.mensaje);
  final String mensaje;

  @override
  String toString() => mensaje;
}

/// Contrato del servicio de autenticación. La vista y el controlador solo
/// conocen esta interfaz; la implementación real habla con la API.
abstract class AuthService {
  /// Inicia sesión. Lanza [AuthException] si falla.
  Future<Usuario> iniciarSesion({required String usuario, required String contrasena});

  /// RF-035. Lanza [AuthException] si la contraseña actual es incorrecta o falla algo más.
  Future<void> cambiarContrasena({required String actual, required String nueva});

  void cerrarSesion();
}
