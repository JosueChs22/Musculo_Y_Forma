import '../../../core/api_http.dart';
import '../models/user_profile.dart';
import 'perfil_service.dart';

/// Perfil del usuario con sesión (GET /mi/perfil: siempre el del token).
class PerfilApiService implements PerfilService {
  PerfilApiService({ApiHttp? http}) : _http = http ?? ApiHttp();

  final ApiHttp _http;

  @override
  Future<UserProfile> getProfile() async => UserProfile.fromJson(await _http.get('/mi/perfil'));
}
