import 'package:flutter/foundation.dart';

import '../../../core/api_exception.dart';
import '../../../core/base_controller.dart';
import '../models/reglamento.dart';
import '../services/reglamentos_service.dart';

/// Reglamento del gimnasio: lista (RF-102), alta (RF-097), edición (RF-098) e
/// inhabilitación (RF-101). Son pocos documentos: se traen todos una vez.
class ReglamentosController extends BaseController {
  ReglamentosController(this._service);

  final ReglamentosService _service;

  List<Reglamento> _todos = const [];
  bool _guardando = false;
  String? _errorGuardar;
  String? _errorAccion;
  final Set<String> _inhabilitando = {};

  List<Reglamento> get reglamentos => _todos;
  bool get guardando => _guardando;
  String? get errorGuardar => _errorGuardar;
  String? get errorAccion => _errorAccion;

  @override
  Future<void> fetch() async {
    _todos = await _service.getReglamentos();
  }

  /// Se llama al abrir el formulario para no mostrar el error de un intento anterior.
  void limpiarErrorGuardar() => _errorGuardar = null;

  void _reemplazar(Reglamento r) {
    _todos = [for (final x in _todos) x.id == r.id ? r : x];
  }

  /// RF-097. Devuelve true si se publicó. Si falla, deja el mensaje en [errorGuardar].
  Future<bool> crearReglamento({required String titulo, required String contenido}) =>
      _guardar(() async {
        final nuevo = await _service.crearReglamento(titulo: titulo, contenido: contenido);
        _todos = [nuevo, ..._todos]; // el más nuevo va primero
      }, 'No se pudo publicar el reglamento. Inténtalo de nuevo.');

  /// RF-098. Devuelve true si se guardó. Si falla, deja el mensaje en [errorGuardar].
  Future<bool> actualizarReglamento({
    required String id,
    required String titulo,
    required String contenido,
  }) =>
      _guardar(() async {
        _reemplazar(await _service.actualizarReglamento(id: id, titulo: titulo, contenido: contenido));
      }, 'No se pudieron guardar los cambios. Inténtalo de nuevo.');

  // REGLA 2: crear y editar no son optimistas porque el servidor valida los datos.
  Future<bool> _guardar(Future<void> Function() accion, String mensajeGenerico) async {
    if (_guardando) return false; // evita doble clic (REGLA 8)
    _guardando = true;
    _errorGuardar = null;
    notify();
    try {
      await accion();
      return true;
    } on ApiException catch (e) {
      _errorGuardar = e.mensaje;
      return false;
    } catch (e) {
      debugPrint('Error inesperado al guardar el reglamento: $e');
      _errorGuardar = mensajeGenerico;
      return false;
    } finally {
      _guardando = false;
      notify();
    }
  }

  /// RF-101. Actualización optimista (REGLA 2): pasa a Inhabilitado en la lista al
  /// instante y, si la API falla, se revierte y queda el mensaje en [errorAccion].
  Future<bool> inhabilitarReglamento(String id) => _cambiarEstado(
        id,
        EstadoReglamento.inhabilitado,
        _service.inhabilitarReglamento,
        'No se pudo inhabilitar el reglamento. Inténtalo de nuevo.',
      );

  /// Vuelve a publicar un reglamento inhabilitado. Misma mecánica que [inhabilitarReglamento].
  Future<bool> habilitarReglamento(String id) => _cambiarEstado(
        id,
        EstadoReglamento.activo,
        _service.habilitarReglamento,
        'No se pudo habilitar el reglamento. Inténtalo de nuevo.',
      );

  Future<bool> _cambiarEstado(
    String id,
    EstadoReglamento nuevoEstado,
    Future<Reglamento> Function(String id) llamar,
    String mensajeGenerico,
  ) async {
    if (_inhabilitando.contains(id)) return false; // evita doble clic (REGLA 8)
    final original = _todos.firstWhere((r) => r.id == id);
    _inhabilitando.add(id);
    _errorAccion = null;
    _reemplazar(original.copyWith(estado: nuevoEstado));
    notify();
    try {
      _reemplazar(await llamar(id));
      return true;
    } on ApiException catch (e) {
      _reemplazar(original);
      _errorAccion = e.mensaje;
      return false;
    } catch (e) {
      debugPrint('Error inesperado al cambiar el estado del reglamento: $e');
      _reemplazar(original);
      _errorAccion = mensajeGenerico;
      return false;
    } finally {
      _inhabilitando.remove(id);
      notify();
    }
  }
}
