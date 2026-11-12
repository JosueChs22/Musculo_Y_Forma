import '../../../core/base_controller.dart';
import '../models/user_profile.dart';
import '../services/perfil_service.dart';

class PerfilController extends BaseController {
  PerfilController(this._service);

  final PerfilService _service;

  UserProfile _profile = UserProfile.empty;
  UserProfile get profile => _profile;

  @override
  Future<void> fetch() async {
    _profile = await _service.getProfile();
  }
}
