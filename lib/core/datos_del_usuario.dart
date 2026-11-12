import 'dart:async';

import 'package:flutter/foundation.dart';

import 'base_controller.dart';

/// Para controladores con datos propios del usuario con sesión (perfil, rutinas,
/// mediciones). Al cambiar de usuario (login, cerrar sesión, sesión restaurada)
/// se borran los datos del anterior y se cargan los del nuevo, así nadie ve lo
/// de otra persona. Se conecta en main.dart con un ChangeNotifierProxyProvider.
mixin DatosDelUsuario on BaseController {
  String? _idUsuario;
  String? _cargadoPara;

  String? get idUsuario => _idUsuario;

  /// Carga los datos del usuario actual. La implementa cada controlador.
  @protected
  Future<void> cargarDatos();

  /// Deja el controlador sin datos (al cerrar sesión o antes de cargar a otro usuario).
  @protected
  void limpiar();

  @override
  Future<void> fetch() async {
    final id = _idUsuario;
    await cargarDatos();
    _cargadoPara = id;
  }

  void usarUsuario(String? id) {
    if (id == _idUsuario) return;
    _idUsuario = id;
    limpiar();
    // Fuera del build del proveedor, que es donde se llama
    if (id != null) unawaited(Future.microtask(_cargarDelUsuarioActual));
  }

  Future<void> _cargarDelUsuarioActual() async {
    await load(); // si había una carga de otro usuario en curso, termina primero...
    final id = _idUsuario;
    if (id != null && _cargadoPara != id) await load(); // ...y se vuelve a pedir para el actual
  }
}
