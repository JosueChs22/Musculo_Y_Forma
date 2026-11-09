import '../models/user_profile.dart';

/// Acceso a los datos del perfil del socio.
/// Implementaciones: [PerfilMockService] (hoy) y una de API (pendiente).
abstract class PerfilService {
  Future<UserProfile> getProfile();
}
