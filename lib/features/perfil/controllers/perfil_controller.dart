import '../../../core/base_controller.dart';
import '../../../core/datos_del_usuario.dart';
import '../models/user_profile.dart';
import '../services/perfil_service.dart';

class PerfilController extends BaseController with DatosDelUsuario {
  PerfilController(this._service);

  final PerfilService _service;

  UserProfile _profile = UserProfile.empty;
  UserProfile get profile => _profile;

  @override
  Future<void> cargarDatos() async {
    _profile = await _service.getProfile();
  }

  @override
  void limpiar() => _profile = UserProfile.empty;
}
