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
  bool _cambiando = false;
  String? _errorCambio;

  bool _recuperando = false;
  String? _errorRecuperacion;

  bool get recuperando => _recuperando;
  String? get errorRecuperacion => _errorRecuperacion;
  bool get cambiando => _cambiando;
  String? get errorCambio => _errorCambio;
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

  /// RF-035. Devuelve true si se cambió. Si falla, deja el mensaje en [errorCambio].
  Future<bool> cambiarContrasena(String actual, String nueva) async {
    if (_cambiando) return false; // evita doble clic (REGLA 8)
    _cambiando = true;
    _errorCambio = null;
    notify();
    try {
      await _service.cambiarContrasena(actual: actual, nueva: nueva);
      return true;
    } on AuthException catch (e) {
      _errorCambio = e.mensaje;
      return false;
    } catch (e) {
      debugPrint('Error inesperado al cambiar contraseña: $e');
      _errorCambio = 'No se pudo cambiar la contraseña. Inténtalo de nuevo.';
      return false;
    } finally {
      _cambiando = false;
      notify();
    }
  }

  /// Se llama al abrir el formulario para no mostrar el error de un intento anterior.
  void limpiarErrorCambio() => _errorCambio = null;

  /// RF-034, paso 1. Devuelve true si la solicitud se envió (no confirma que el correo exista).
  Future<bool> solicitarRecuperacion(String correo) =>
      _recuperar(() => _service.solicitarRecuperacion(correo.trim()));

  /// RF-034, paso 2. Devuelve true si la contraseña se restableció.
  Future<bool> restablecerContrasena({
    required String correo,
    required String codigo,
    required String nueva,
  }) =>
      _recuperar(() => _service.restablecerContrasena(
            correo: correo.trim(),
            codigo: codigo.trim(),
            nueva: nueva,
          ));

  /// Se llama al abrir la pantalla para no mostrar el error de un intento anterior.
  void limpiarErrorRecuperacion() => _errorRecuperacion = null;

  // Los dos pasos de la recuperación comparten el mismo manejo de estado y errores
  Future<bool> _recuperar(Future<void> Function() accion) async {
    if (_recuperando) return false; // evita doble clic (REGLA 8)
    _recuperando = true;
    _errorRecuperacion = null;
    notify();
    try {
      await accion();
      return true;
    } on AuthException catch (e) {
      _errorRecuperacion = e.mensaje;
      return false;
    } catch (e) {
      debugPrint('Error inesperado en la recuperación de contraseña: $e');
      _errorRecuperacion = 'No se pudo completar la solicitud. Inténtalo de nuevo.';
      return false;
    } finally {
      _recuperando = false;
      notify();
    }
  }

  void cerrarSesion() {
    _service.cerrarSesion();
    _usuario = null;
    notify();
  }
}
