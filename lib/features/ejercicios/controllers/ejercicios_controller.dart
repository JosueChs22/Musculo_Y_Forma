import 'package:flutter/foundation.dart';

import '../../../core/api_exception.dart';
import '../../../core/base_controller.dart';
import '../../../core/debouncer.dart';
import '../models/ejercicio.dart';
import '../services/ejercicios_service.dart';

/// Catálogo de ejercicios del panel del Entrenador: listar, buscar, crear,
/// actualizar e inhabilitar. La búsqueda y los filtros los resuelve la API
/// (el catálogo puede ser grande), una página a la vez.
class EjerciciosController extends BaseController {
  EjerciciosController(this._service);

  /// REGLA 9: no se busca con menos letras que estas.
  static const minimoBusqueda = 2;

  final EjerciciosService _service;
  final _debouncer = Debouncer();

  List<Ejercicio> _items = const [];
  String? _siguiente;

  String _escrito = ''; // lo que hay en el campo de búsqueda
  String _texto = ''; // lo que realmente se le pidió a la API
  String? _grupo; // null = todos
  bool _verInhabilitados = false;

  // Cambia con cada filtro nuevo, para descartar respuestas de un filtro anterior.
  int _version = 0;

  bool _cargandoMas = false;
  bool _guardando = false;
  String? _errorGuardar;
  String? _aviso;

  List<Ejercicio> get items => _items;
  String get escrito => _escrito;
  bool get hayMas => _siguiente != null;
  bool get cargandoMas => _cargandoMas;
  String? get grupoFiltro => _grupo;
  bool get verInhabilitados => _verInhabilitados;
  bool get hayFiltros => _texto.isNotEmpty || _grupo != null;
  bool get textoMuyCorto => _escrito.isNotEmpty && _escrito.length < minimoBusqueda;
  bool get guardando => _guardando;
  String? get errorGuardar => _errorGuardar;

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
    PaginaEjercicios pagina;
    do {
      version = _version;
      pagina = await _service.listar(texto: _texto, grupo: _grupo, soloActivos: !_verInhabilitados);
    } while (version != _version);
    _items = pagina.items;
    _siguiente = pagina.siguiente;
  }

  Future<void> _recargar() {
    _version++;
    return load();
  }

  /// RF-073. Espera 300 ms sin teclear antes de consultar (REGLA 9).
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

  void filtrarGrupo(String? grupo) {
    if (grupo == _grupo) return;
    _grupo = grupo;
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
        grupo: _grupo,
        soloActivos: !_verInhabilitados,
        cursor: _siguiente,
      );
      if (version == _version) {
        _items = [..._items, ...pagina.items];
        _siguiente = pagina.siguiente;
      }
    } catch (e) {
      _aviso = _mensaje(e, 'No se pudieron cargar más ejercicios.');
    }
    _cargandoMas = false;
    notify();
  }

  /// Se llama al abrir el formulario para no mostrar el error de un intento anterior.
  void limpiarErrorGuardar() => _errorGuardar = null;

  /// RF-038 / RF-043 (sin [id]) y RF-048 (con [id]).
  /// Devuelve true si se guardó. Si falla, deja el mensaje en [errorGuardar].
  Future<bool> guardar(DatosEjercicio datos, {String? id}) async {
    if (_guardando) return false; // evita doble clic (REGLA 8)
    _guardando = true;
    _errorGuardar = null;
    notify();
    try {
      if (id == null) {
        await _service.crear(datos);
        _recargar(); // el nuevo entra en su lugar del orden alfabético
      } else {
        final actualizado = await _service.actualizar(id, datos);
        _items = [for (final e in _items) e.id == id ? actualizado : e];
      }
      return true;
    } catch (e) {
      _errorGuardar = _mensaje(e, 'No se pudo guardar el ejercicio. Inténtalo de nuevo.');
      return false;
    } finally {
      _guardando = false;
      notify();
    }
  }

  /// RF-055 y su inverso, con actualización optimista (REGLA 2).
  /// Devuelve true si el servidor lo confirmó; si no, revierte y deja un aviso.
  Future<bool> cambiarEstado(Ejercicio ejercicio, {required bool activo}) async {
    final i = _items.indexWhere((e) => e.id == ejercicio.id);
    if (i == -1) return false;
    final version = _version;
    final sigueVisible = activo || _verInhabilitados;

    _items = [
      for (final e in _items)
        if (e.id != ejercicio.id) e else if (sigueVisible) e.conEstado(activo: activo),
    ];
    notify();

    try {
      final confirmado = activo
          ? await _service.reactivar(ejercicio.id)
          : await _service.inhabilitar(ejercicio.id);
      _items = [for (final e in _items) e.id == confirmado.id ? confirmado : e];
      notify();
      return true;
    } catch (e) {
      // Si entre tanto se recargó la lista, ya trae el estado real del servidor.
      if (version == _version) {
        _items = sigueVisible
            ? [for (final e in _items) e.id == ejercicio.id ? ejercicio : e]
            : ([..._items]..insert(i.clamp(0, _items.length), ejercicio));
      }
      _aviso = _mensaje(
        e,
        'No se pudo ${activo ? 'reactivar' : 'inhabilitar'} el ejercicio. Los cambios fueron revertidos.',
      );
      notify();
      return false;
    }
  }

  String _mensaje(Object e, String porDefecto) {
    if (e is ApiException) return e.mensaje;
    debugPrint('Error inesperado en ejercicios: $e');
    return porDefecto;
  }

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }
}
