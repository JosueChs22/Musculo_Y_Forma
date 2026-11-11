import '../../auth/models/usuario.dart';

/// Contrato del servicio de usuarios administrativos (panel del Administrador).
abstract class UsuariosService {
  /// Secretarias y entrenadores. Solo responde si el token es de un Administrador.
  Future<List<Usuario>> getUsuarios();
}
