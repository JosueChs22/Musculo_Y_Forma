import '../../auth/models/usuario.dart';

/// Contrato del servicio de usuarios administrativos (panel del Administrador).
abstract class UsuariosService {
  /// Secretarias y entrenadores. Solo responde si el token es de un Administrador.
  Future<List<Usuario>> getUsuarios();

  /// RF-096: crea una Secretaria o un Entrenador (queda Activo).
  /// Lanza [ApiException] si el usuario o el correo ya existen, o si hay otro error.
  Future<Usuario> crearUsuario({
    required String nombre,
    required String primerApellido,
    String? segundoApellido,
    required String correo,
    required String telefono,
    required RolUsuario rol,
    required String usuario,
    required String contrasena,
  });
}
