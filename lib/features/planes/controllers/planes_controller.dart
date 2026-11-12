import 'package:flutter/foundation.dart';

import '../../../core/api_exception.dart';
import '../../../core/base_controller.dart';
import '../../../core/debouncer.dart';
import '../models/plan.dart';
import '../services/planes_service.dart';

/// Lista de planes del entrenador: buscar por nombre, filtrar por categoría,
/// asignar a un cliente e inhabilitar. La búsqueda y los filtros los resuelve la
/// API, una página a la vez.
class PlanesController extends BaseController {
  PlanesController(this._service);

  /// REGLA 9: no se busca con menos letras que estas.
  static const minimoBusqueda = 2;

  final PlanesService _service;
  final _debouncer = Debouncer();

  List<Plan> _items = const [];
  String? _siguiente;

  String _escrito = ''; // lo que hay en el campo de búsqueda
  String _texto = ''; // lo que realmente se le pidió a la API
  CategoriaPlan? _categoria; // null = todas
  bool _verInhabilitados = false;

  // Cambia con cada filtro nuevo, para descartar respuestas de un filtro anterior.
  int _version = 0;

  bool _cargandoMas = false;
  String? _aviso;

  List<Plan> get items => _items;
  bool get hayMas => _siguiente != null;
  bool get cargandoMas => _cargandoMas;
  String get escrito => _escrito;
  CategoriaPlan? get categoriaFiltro => _categoria;
  bool get verInhabilitados => _verInhabilitados;
  bool get hayFiltros => _texto.isNotEmpty || _categoria != null;
  bool get textoMuyCorto => _escrito.isNotEmpty && _escrito.length < minimoBusqueda;

  /// Mensaje pendiente de mostrar (se entrega una sola vez).
  String? tomarAviso() {
    final a = _aviso;
    _aviso = null;
    return a;
  }

  @override
  Future<void> fetch() async {
    // Si los filtros cambian mientras llega la respuesta, se vuelve a pedir.
    int version;
    PaginaPlanes pagina;
    do {
      version = _version;
      pagina = await _service.listar(texto: _texto, categoria: _categoria, soloActivos: !_verInhabilitados);
    } while (version != _version);
    _items = pagina.items;
    _siguiente = pagina.siguiente;
  }

  Future<void> _recargar() {
    _version++;
    return load();
  }

  /// Espera 300 ms sin teclear antes de consultar (REGLA 9).
  void buscar(String escrito) {
    _escrito = escrito.trim();
    final texto = _escrito.length < minimoBusqueda ? '' : _escrito;
    if (texto == _texto) {
      _debouncer.cancel();
    } else {
      _debouncer.run(() {
        _texto = texto;
        _recargar();
      });
    }
    notify();
  }

  void filtrarCategoria(CategoriaPlan? categoria) {
    if (categoria == _categoria) return;
    _categoria = categoria;
    _recargar();
  }

  void mostrarInhabilitados(bool ver) {
    if (ver == _verInhabilitados) return;
    _verInhabilitados = ver;
    _recargar();
  }

  Future<void> cargarMas() async {
    if (_siguiente == null || _cargandoMas || loading) return;
    final version = _version;
    _cargandoMas = true;
    notify();
    try {
      final pagina = await _service.listar(
        texto: _texto,
        categoria: _categoria,
        soloActivos: !_verInhabilitados,
        cursor: _siguiente,
      );
      if (version == _version) {
        _items = [..._items, ...pagina.items];
        _siguiente = pagina.siguiente;
      }
    } catch (e) {
      _aviso = _mensaje(e, 'No se pudieron cargar más planes.');
    }
    _cargandoMas = false;
    notify();
  }

  /// Asigna el plan a [cliente] (o lo deja sin asignar si es null), con
  /// actualización optimista (REGLA 2). Devuelve true si el servidor lo confirmó.
  Future<bool> asignar(Plan plan, UsuarioResumen? cliente) async {
    _reemplazar(plan.id, (p) => cliente == null ? p.copyWith(quitarUsuario: true) : p.copyWith(usuario: cliente));
    notify();
    try {
      final confirmado = await _service.asignar(plan.id, cliente?.id);
      _reemplazar(plan.id, (p) => confirmado == null ? p.copyWith(quitarUsuario: true) : p.copyWith(usuario: confirmado));
      notify();
      return true;
    } catch (e) {
      _reemplazar(plan.id, (_) => plan);
      _aviso = _mensaje(e, 'No se pudo asignar el plan. Los cambios fueron revertidos.');
      notify();
      return false;
    }
  }

  /// Inhabilitar o reactivar, con actualización optimista (REGLA 2).
  /// Devuelve true si el servidor lo confirmó; si no, revierte y deja un aviso.
  Future<bool> cambiarEstado(Plan plan, {required bool activo}) async {
    final i = _items.indexWhere((p) => p.id == plan.id);
    if (i == -1) return false;
    final version = _version;
    final sigueVisible = activo || _verInhabilitados;

    _items = [
      for (final p in _items)
        if (p.id != plan.id) p else if (sigueVisible) p.copyWith(activo: activo),
    ];
    notify();

    try {
      if (activo) {
        await _service.reactivar(plan.id);
      } else {
        await _service.inhabilitar(plan.id);
      }
      return true;
    } catch (e) {
      // Si entre tanto se recargó la lista, ya trae el estado real del servidor.
      if (version == _version) {
        _items = sigueVisible
            ? [for (final p in _items) p.id == plan.id ? plan : p]
            : ([..._items]..insert(i.clamp(0, _items.length), plan));
      }
      _aviso = _mensaje(
        e,
        'No se pudo ${activo ? 'reactivar' : 'inhabilitar'} el plan. Los cambios fueron revertidos.',
      );
      notify();
      return false;
    }
  }

  void _reemplazar(String id, Plan Function(Plan) cambio) {
    _items = [for (final p in _items) p.id == id ? cambio(p) : p];
  }

  String _mensaje(Object e, String porDefecto) {
    if (e is ApiException) return e.mensaje;
    debugPrint('Error inesperado en planes: $e');
    return porDefecto;
  }

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }
}
