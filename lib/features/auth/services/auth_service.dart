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

  /// RF-034, paso 1: pide el código de recuperación. La API responde igual exista
  /// o no el correo, así que éxito no significa que el correo esté registrado.
  Future<void> solicitarRecuperacion(String correo);

  /// RF-034, paso 2: con el código recibido, establece la contraseña nueva.
  /// Lanza [AuthException] si el código es inválido o ya venció.
  Future<void> restablecerContrasena({
    required String correo,
    required String codigo,
    required String nueva,
  });

  void cerrarSesion();
}
