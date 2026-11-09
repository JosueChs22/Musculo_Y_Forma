import 'package:flutter/foundation.dart';

/// Base para los controladores de cada funcionalidad.
///
/// - Maneja `loading` / `error` de forma uniforme.
/// - REGLA 8: si ya hay una carga en curso, `load()` devuelve la misma
///   petición en lugar de lanzar otra.
abstract class BaseController extends ChangeNotifier {
  bool _loading = true;
  String? _error;
  Future<void>? _inFlight;
  bool _disposed = false;

  bool get loading => _loading;
  String? get error => _error;

  /// Carga los datos de la funcionalidad. Se implementa en cada controlador.
  @protected
  Future<void> fetch();

  Future<void> load() => _inFlight ??= _run().whenComplete(() => _inFlight = null);

  Future<void> _run() async {
    _loading = true;
    _error = null;
    notify();
    try {
      await fetch();
    } catch (e) {
      _error = 'No pudimos cargar la información. Revisa tu conexión e inténtalo de nuevo.';
      debugPrint('Error al cargar datos: $e');
    }
    _loading = false;
    notify();
  }

  /// notifyListeners seguro si el controlador ya fue descartado.
  @protected
  void notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
