import 'package:flutter/foundation.dart';

import '../../../core/api_exception.dart';
import '../../../core/base_controller.dart';
import '../../secretaria/models/anuncio.dart';
import '../../secretaria/services/anuncios_service.dart';

/// RF-092: anuncios vigentes que ve el cliente. Paginado: se piden más con [cargarMas].
class AnunciosClienteController extends BaseController {
  AnunciosClienteController(this._service);

  final AnunciosService _service;

  List<Anuncio> _todos = const [];
  String? _siguiente;
  bool _cargandoMas = false;
  String? _errorMas;

  List<Anuncio> get anuncios => _todos;
  bool get hayMas => _siguiente != null;
  bool get cargandoMas => _cargandoMas;
  String? get errorMas => _errorMas;

  @override
  Future<void> fetch() async {
    final pagina = await _service.getAnunciosVigentes();
    _todos = pagina.anuncios;
    _siguiente = pagina.siguiente;
  }

  Future<void> cargarMas() async {
    if (_cargandoMas || _siguiente == null) return;
    _cargandoMas = true;
    _errorMas = null;
    notify();
    try {
      final pagina = await _service.getAnunciosVigentes(cursor: _siguiente);
      _todos = [..._todos, ...pagina.anuncios];
      _siguiente = pagina.siguiente;
    } on ApiException catch (e) {
      _errorMas = e.mensaje;
    } catch (e) {
      debugPrint('Error inesperado al cargar más anuncios: $e');
      _errorMas = 'No se pudieron cargar más anuncios. Inténtalo de nuevo.';
    } finally {
      _cargandoMas = false;
      notify();
    }
  }
}
