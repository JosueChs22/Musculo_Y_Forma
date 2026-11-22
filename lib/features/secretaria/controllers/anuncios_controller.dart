import 'package:flutter/foundation.dart';

import '../../../core/api_exception.dart';
import '../../../core/base_controller.dart';
import '../models/anuncio.dart';
import '../services/anuncios_service.dart';

/// Anuncios del panel de la Secretaria: lista (RF-032), alta (RF-017), edición (RF-022)
/// e inhabilitación (RF-027). La lista es paginada (REGLA 12): se piden más con [cargarMas].
class AnunciosController extends BaseController {
  AnunciosController(this._service);

  final AnunciosService _service;

  List<Anuncio> _todos = const [];
  String? _siguiente;
  bool _cargandoMas = false;
  bool _guardando = false;
  String? _errorGuardar;
  String? _errorAccion;
  final Set<String> _cambiando = {};

  List<Anuncio> get anuncios => _todos;
  bool get hayMas => _siguiente != null;
  bool get cargandoMas => _cargandoMas;
  bool get guardando => _guardando;
  String? get errorGuardar => _errorGuardar;
  String? get errorAccion => _errorAccion;

  @override
  Future<void> fetch() async {
    final pagina = await _service.getAnuncios();
    _todos = pagina.anuncios;
    _siguiente = pagina.siguiente;
  }

  /// Pide la página que sigue y la agrega al final. Si falla, deja el mensaje en [errorAccion].
  Future<void> cargarMas() async {
    if (_cargandoMas || _siguiente == null) return;
    _cargandoMas = true;
    _errorAccion = null;
    notify();
    try {
      final pagina = await _service.getAnuncios(cursor: _siguiente);
      _todos = [..._todos, ...pagina.anuncios];
      _siguiente = pagina.siguiente;
    } on ApiException catch (e) {
      _errorAccion = e.mensaje;
    } catch (e) {
      debugPrint('Error inesperado al cargar más anuncios: $e');
      _errorAccion = 'No se pudieron cargar más anuncios. Inténtalo de nuevo.';
    } finally {
      _cargandoMas = false;
      notify();
    }
  }

  /// RF-032 #6: el anuncio completo, con su imagen. No cambia la lista: lo usa el detalle.
  Future<Anuncio> obtenerAnuncio(String id) => _service.getAnuncio(id);

  /// Se llama al abrir el formulario para no mostrar el error de un intento anterior.
  void limpiarErrorGuardar() => _errorGuardar = null;

  void _reemplazar(Anuncio a) {
    _todos = [for (final x in _todos) x.id == a.id ? a : x];
  }

  /// RF-017. Devuelve true si se publicó. Si falla, deja el mensaje en [errorGuardar].
  Future<bool> crearAnuncio({
    required String titulo,
    required String contenido,
    required String clasificacion,
    required DateTime fechaPublicacion,
    DateTime? fechaFin,
    String? imagen,
  }) =>
      _guardar(() async {
        final nuevo = await _service.crearAnuncio(
          titulo: titulo,
          contenido: contenido,
          clasificacion: clasificacion,
          fechaPublicacion: fechaPublicacion,
          fechaFin: fechaFin,
          imagen: imagen,
        );
        _todos = [nuevo, ..._todos]; // el más nuevo va primero
      }, 'No se pudo publicar el anuncio. Inténtalo de nuevo.');

  /// RF-022. Devuelve true si se guardó. Si falla, deja el mensaje en [errorGuardar].
  Future<bool> actualizarAnuncio({
    required String id,
    required String titulo,
    required String contenido,
    required String clasificacion,
    required DateTime fechaPublicacion,
    DateTime? fechaFin,
    String? imagen,
    bool cambiarImagen = false,
  }) =>
      _guardar(() async {
        _reemplazar(await _service.actualizarAnuncio(
          id: id,
          titulo: titulo,
          contenido: contenido,
          clasificacion: clasificacion,
          fechaPublicacion: fechaPublicacion,
          fechaFin: fechaFin,
          imagen: imagen,
          cambiarImagen: cambiarImagen,
        ));
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
      debugPrint('Error inesperado al guardar el anuncio: $e');
      _errorGuardar = mensajeGenerico;
      return false;
    } finally {
      _guardando = false;
      notify();
    }
  }

  /// RF-027. Actualización optimista (REGLA 2): pasa a Inhabilitado en la lista al
  /// instante y, si la API falla, se revierte y queda el mensaje en [errorAccion].
  Future<bool> inhabilitarAnuncio(String id) => _cambiarEstado(
        id,
        EstadoAnuncio.inhabilitado,
        _service.inhabilitarAnuncio,
        'No se pudo inhabilitar el anuncio. Inténtalo de nuevo.',
      );

  /// Vuelve a publicar un anuncio inhabilitado. Misma mecánica que [inhabilitarAnuncio].
  Future<bool> habilitarAnuncio(String id) => _cambiarEstado(
        id,
        EstadoAnuncio.activo,
        _service.habilitarAnuncio,
        'No se pudo habilitar el anuncio. Inténtalo de nuevo.',
      );

  Future<bool> _cambiarEstado(
    String id,
    EstadoAnuncio nuevoEstado,
    Future<Anuncio> Function(String id) llamar,
    String mensajeGenerico,
  ) async {
    if (_cambiando.contains(id)) return false; // evita doble clic (REGLA 8)
    final original = _todos.firstWhere((a) => a.id == id);
    _cambiando.add(id);
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
      debugPrint('Error inesperado al cambiar el estado del anuncio: $e');
      _reemplazar(original);
      _errorAccion = mensajeGenerico;
      return false;
    } finally {
      _cambiando.remove(id);
      notify();
    }
  }
}
