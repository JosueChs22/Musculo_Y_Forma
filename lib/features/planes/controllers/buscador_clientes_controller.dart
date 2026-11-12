import 'package:flutter/foundation.dart';

import '../../../core/api_exception.dart';
import '../../../core/debouncer.dart';
import '../models/plan.dart';
import '../services/planes_service.dart';

/// Búsqueda de clientes por nombre para asignarles un plan. Sin texto muestra los
/// primeros; con texto espera 300 ms sin teclear y exige 2 letras (REGLA 9).
class BuscadorClientesController extends ChangeNotifier {
  BuscadorClientesController(this._service);

  static const minimoBusqueda = 2;

  final PlanesService _service;
  final _debouncer = Debouncer();

  List<UsuarioResumen> _items = const [];
  String? _siguiente;
  String _escrito = '';
  bool _cargando = true;
  bool _cargandoMas = false;
  String? _error;
  bool _disposed = false;

  // Cambia con cada búsqueda nueva, para descartar respuestas de una búsqueda anterior.
  int _version = 0;

  List<UsuarioResumen> get items => _items;
  bool get hayMas => _siguiente != null;
  bool get cargando => _cargando;
  bool get cargandoMas => _cargandoMas;
  String? get error => _error;
  bool get textoMuyCorto => _escrito.isNotEmpty && _escrito.length < minimoBusqueda;
  bool get hayTexto => _texto.isNotEmpty;

  String get _texto => _escrito.length < minimoBusqueda ? '' : _escrito;

  Future<void> cargar() async {
    final version = ++_version;
    _cargando = true;
    _error = null;
    _avisar();
    try {
      final pagina = await _service.buscarClientes(texto: _texto);
      if (version != _version) return;
      _items = pagina.items;
      _siguiente = pagina.siguiente;
    } catch (e) {
      if (version != _version) return;
      _items = const [];
      _siguiente = null;
      _error = e is ApiException ? e.mensaje : 'No se pudo buscar. Revisa tu conexión.';
      if (e is! ApiException) debugPrint('Error inesperado al buscar clientes: $e');
    }
    _cargando = false;
    _avisar();
  }

  void buscar(String escrito) {
    final antes = _texto;
    _escrito = escrito.trim();
    if (_texto == antes) {
      _debouncer.cancel();
      _avisar();
    } else {
      _debouncer.run(cargar);
      _avisar();
    }
  }

  Future<void> cargarMas() async {
    if (_siguiente == null || _cargandoMas || _cargando) return;
    final version = _version;
    _cargandoMas = true;
    _avisar();
    try {
      final pagina = await _service.buscarClientes(texto: _texto, cursor: _siguiente);
      if (version == _version) {
        _items = [..._items, ...pagina.items];
        _siguiente = pagina.siguiente;
      }
    } catch (e) {
      debugPrint('Error al cargar más clientes: $e');
    }
    _cargandoMas = false;
    _avisar();
  }

  void _avisar() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _debouncer.dispose();
    super.dispose();
  }
}
