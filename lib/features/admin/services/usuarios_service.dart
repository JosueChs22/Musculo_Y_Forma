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

  /// RF-099: modifica los datos de un usuario administrativo. Si [contrasena] es
  /// null o vacía, la contraseña no cambia. Devuelve el usuario ya actualizado.
  Future<Usuario> actualizarUsuario({
    required String id,
    required String nombre,
    required String primerApellido,
    String? segundoApellido,
    required String correo,
    required String telefono,
    required RolUsuario rol,
    required String usuario,
    String? contrasena,
  });

  /// RF-100: cambia el estado a Inhabilitado (no borra nada). Devuelve el usuario actualizado.
  Future<Usuario> inhabilitarUsuario(String id);

  /// Reactiva a un usuario inhabilitado. Devuelve el usuario actualizado.
  Future<Usuario> habilitarUsuario(String id);
}
