import 'package:flutter/foundation.dart';

import '../../../core/base_controller.dart';
import '../models/usuario.dart';
import '../services/auth_service.dart';

/// Estado de la sesión: quién está logueado y el estado del formulario de login.
class AuthController extends BaseController {
  AuthController(this._service);

  final AuthService _service;

  Usuario? _usuario;
  bool _enviando = false;
  String? _errorLogin;

  Usuario? get usuario => _usuario;
  bool get autenticado => _usuario != null;
  bool get enviando => _enviando;
  String? get errorLogin => _errorLogin;

  // Aún no se guarda la sesión en disco, así que al abrir la app no hay nada
  // que restaurar. Cuando se persista el token, se restaura aquí.
  @override
  Future<void> fetch() async {}

  /// Devuelve true si el login fue exitoso. Si falla, deja el mensaje en [errorLogin].
  Future<bool> iniciarSesion(String usuario, String contrasena) async {
    if (_enviando) return false; // evita doble clic (REGLA 8)
    _enviando = true;
    _errorLogin = null;
    notify();
    try {
      _usuario = await _service.iniciarSesion(
        usuario: usuario.trim(),
        contrasena: contrasena,
      );
      return true;
    } on AuthException catch (e) {
      _errorLogin = e.mensaje;
      return false;
    } catch (e) {
      debugPrint('Error inesperado en login: $e');
      _errorLogin = 'No se pudo iniciar sesión. Inténtalo de nuevo.';
      return false;
    } finally {
      _enviando = false;
      notify(); // al cambiar _usuario, el router redirige solo
    }
  }

  void cerrarSesion() {
    _service.cerrarSesion();
    _usuario = null;
    notify();
  }
}
