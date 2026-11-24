import 'package:flutter/foundation.dart';

import '../../../core/api_exception.dart';
import '../models/horario_especial.dart';
import '../services/horarios_especiales_api_service.dart';

/// Controlador de horarios especiales.
/// RF-016: crear.
/// RF-021: actualizar.
/// RF-026: inhabilitar.
/// RF-031: listar.
class HorariosEspecialesController extends ChangeNotifier {
  HorariosEspecialesController(this._service);

  final HorariosEspecialesApiService _service;

  List<HorarioEspecial> _horarios = [];

  bool _cargando = false;
  bool _busy = false;
  String? _error;

  List<HorarioEspecial> get horarios => List.unmodifiable(_horarios);

  List<HorarioEspecial> get horariosActivos =>
      _horarios.where((h) => h.activo).toList();

  List<HorarioEspecial> get horariosInhabilitados =>
      _horarios.where((h) => !h.activo).toList();

  bool get cargando => _cargando;
  bool get busy => _busy;
  String? get error => _error;

  void limpiarError() {
    _error = null;
    notifyListeners();
  }

  String _mensajeError(Object error) {
    if (error is ApiException) {
      return error.mensaje;
    }

    return 'Ocurrió un error inesperado. Inténtalo de nuevo.';
  }

  /// RF-031: cargar horarios especiales.
  Future<void> cargar() async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      _horarios = await _service.listar();
    } catch (e) {
      _error = _mensajeError(e);
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  /// RF-016: crear horario especial.
  Future<bool> crear(HorarioEspecial horario) async {
    _busy = true;
    _error = null;
    notifyListeners();

    try {
      final nuevo = await _service.crear(horario);
      _horarios = [..._horarios, nuevo];
      return true;
    } catch (e) {
      _error = _mensajeError(e);
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// RF-021: actualizar horario especial.
  Future<bool> actualizar(
    String id,
    HorarioEspecial horario,
  ) async {
    _busy = true;
    _error = null;
    notifyListeners();

    try {
      final actualizado = await _service.actualizar(id, horario);

      _horarios = [
        for (final actual in _horarios)
          if (actual.id == id) actualizado else actual,
      ];

      return true;
    } catch (e) {
      _error = _mensajeError(e);
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// RF-026: inhabilitar horario especial.
  Future<bool> inhabilitar(String id) async {
    _busy = true;
    _error = null;
    notifyListeners();

    try {
      final actualizado = await _service.inhabilitar(id);

      _horarios = [
        for (final actual in _horarios)
          if (actual.id == id) actualizado else actual,
      ];

      return true;
    } catch (e) {
      _error = _mensajeError(e);
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }
}
