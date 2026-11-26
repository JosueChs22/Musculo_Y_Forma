import 'package:flutter/foundation.dart';

import '../../../core/api_exception.dart';
import '../../../core/base_controller.dart';
import '../../../core/debouncer.dart';
import '../models/ejercicio.dart';
import '../services/ejercicios_service.dart';

/// Catálogo de ejercicios del Panel del Entrenador.
///
/// Permite listar, buscar, crear, actualizar, inhabilitar,
/// reactivar y filtrar ejercicios por grupo muscular y tipo.
///
/// Sprint 3:
/// RF-045, RF-052, RF-059, RF-066 y RF-077.
class EjerciciosController extends BaseController {
  EjerciciosController(this._service);

  /// REGLA 9: mínimo de caracteres para buscar.
  static const minimoBusqueda = 2;

  final EjerciciosService _service;
  final _debouncer = Debouncer();

  List<Ejercicio> _items = const [];
  String? _siguiente;

  String _escrito = '';
  String _texto = '';

  // Filtros.
  String? _grupo;
  String? _tipo;
  bool _verInhabilitados = false;

  // Permite descartar respuestas de filtros anteriores.
  int _version = 0;

  bool _cargandoMas = false;
  bool _guardando = false;

  String? _errorGuardar;
  String? _aviso;

  // Propiedades públicas.
  List<Ejercicio> get items => _items;

  String get escrito => _escrito;

  bool get hayMas => _siguiente != null;

  bool get cargandoMas => _cargandoMas;

  String? get grupoFiltro => _grupo;

  // Sprint 3: tipo seleccionado.
  String? get tipoFiltro => _tipo;

  bool get verInhabilitados => _verInhabilitados;

  bool get hayFiltros => _texto.isNotEmpty || _grupo != null || _tipo != null;

  bool get textoMuyCorto =>
      _escrito.isNotEmpty && _escrito.length < minimoBusqueda;

  bool get guardando => _guardando;

  String? get errorGuardar => _errorGuardar;

  /// Obtener un aviso pendiente.
  String? tomarAviso() {
    final aviso = _aviso;
    _aviso = null;
    return aviso;
  }

  /// Cargar ejercicios desde la API.
  ///
  /// Conserva búsqueda, grupo, estado y paginación.
  /// Sprint 3: agrega filtro por tipo.
  @override
  Future<void> fetch() async {
    int version;
    PaginaEjercicios pagina;

    do {
      version = _version;

      pagina = await _service.listar(
        texto: _texto,
        grupo: _grupo,
        tipo: _tipo,
        soloActivos: !_verInhabilitados,
      );
    } while (version != _version);

    _items = pagina.items;
    _siguiente = pagina.siguiente;
  }

  /// Recargar el catálogo.
  Future<void> _recargar() {
    _version++;
    return load();
  }

  /// RF-073 / RF-077:
  /// Buscar ejercicios por nombre.
  ///
  /// Espera 300 ms después de escribir.
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

  /// Filtrar por grupo muscular.
  void filtrarGrupo(String? grupo) {
    if (grupo == _grupo) return;

    _grupo = grupo;
    _recargar();
  }

  /// Sprint 3: filtrar por tipo de ejercicio.
  ///
  /// null = todos los ejercicios.
  /// entrenamiento = ejercicios generales.
  /// calentamiento = ejercicios de calentamiento.
  /// estiramiento = ejercicios de estiramiento.
  void filtrarTipo(String? tipo) {
    if (tipo != null && !tiposEjercicio.contains(tipo)) {
      return;
    }

    if (tipo == _tipo) return;

    _tipo = tipo;
    _recargar();
  }

  /// Mostrar u ocultar ejercicios inhabilitados.
  void mostrarInhabilitados(bool ver) {
    if (ver == _verInhabilitados) return;

    _verInhabilitados = ver;
    _recargar();
  }

  /// Cargar la siguiente página.
  ///
  /// Conserva los filtros seleccionados
  /// durante la paginación.
  Future<void> cargarMas() async {
    if (_siguiente == null || _cargandoMas || loading) {
      return;
    }

    final version = _version;

    _cargandoMas = true;
    notify();

    try {
      final pagina = await _service.listar(
        texto: _texto,
        grupo: _grupo,
        tipo: _tipo,
        soloActivos: !_verInhabilitados,
        cursor: _siguiente,
      );

      // No mezclar páginas si cambiaron los filtros.
      if (version == _version) {
        _items = [
          ..._items,
          ...pagina.items,
        ];

        _siguiente = pagina.siguiente;
      }
    } catch (e) {
      _aviso = _mensaje(
        e,
        'No se pudieron cargar más ejercicios.',
      );
    } finally {
      _cargandoMas = false;
      notify();
    }
  }

  /// Limpiar errores anteriores del formulario.
  void limpiarErrorGuardar() {
    _errorGuardar = null;
  }

  /// RF-038 / RF-043 / RF-045:
  /// Crear ejercicios.
  ///
  /// RF-048 / RF-052:
  /// Actualizar ejercicios.
  ///
  /// El tipo se recibe mediante DatosEjercicio.
  Future<bool> guardar(
    DatosEjercicio datos, {
    String? id,
  }) async {
    if (_guardando) return false;

    _guardando = true;
    _errorGuardar = null;
    notify();

    try {
      if (id == null) {
        await _service.crear(datos);

        // Recargar para respetar el orden y filtros.
        _recargar();
      } else {
        final actualizado = await _service.actualizar(id, datos);

        // Conservar el catálogo según el tipo seleccionado.
        // Si el ejercicio cambia de tipo, ya no debe aparecer
        // dentro de un filtro diferente.
        _items = [
          for (final e in _items)
            if (e.id != id)
              e
            else if ((_tipo == null || actualizado.tipo == _tipo) &&
                (_grupo == null || actualizado.grupoMuscular == _grupo) &&
                (_verInhabilitados || actualizado.activo))
              actualizado,
        ];

        notify();
      }

      return true;
    } catch (e) {
      _errorGuardar = _mensaje(
        e,
        'No se pudo guardar el ejercicio. Inténtalo de nuevo.',
      );

      return false;
    } finally {
      _guardando = false;
      notify();
    }
  }

  /// RF-055 / RF-059:
  /// Inhabilitar ejercicios.
  ///
  /// También permite reactivarlos.
  /// Conserva actualización optimista y reversión.
  Future<bool> cambiarEstado(
    Ejercicio ejercicio, {
    required bool activo,
  }) async {
    final i = _items.indexWhere(
      (e) => e.id == ejercicio.id,
    );

    if (i == -1) return false;

    final version = _version;

    final sigueVisible = activo || _verInhabilitados;

    _items = [
      for (final e in _items)
        if (e.id != ejercicio.id)
          e
        else if (sigueVisible)
          e.conEstado(activo: activo),
    ];

    notify();

    try {
      final confirmado = activo
          ? await _service.reactivar(ejercicio.id)
          : await _service.inhabilitar(ejercicio.id);

      _items = [
        for (final e in _items)
          if (e.id == confirmado.id) confirmado else e,
      ];

      notify();
      return true;
    } catch (e) {
      // Revertir si el servidor rechaza la operación.
      if (version == _version) {
        _items = sigueVisible
            ? [
                for (final e in _items)
                  if (e.id == ejercicio.id) ejercicio else e,
              ]
            : ([
                ..._items,
              ]..insert(
                i.clamp(0, _items.length),
                ejercicio,
              ));
      }

      _aviso = _mensaje(
        e,
        'No se pudo ${activo ? 'reactivar' : 'inhabilitar'} '
        'el ejercicio. Los cambios fueron revertidos.',
      );

      notify();
      return false;
    }
  }

  /// Obtener mensaje de error para la interfaz.
  String _mensaje(
    Object e,
    String porDefecto,
  ) {
    if (e is ApiException) {
      return e.mensaje;
    }

    debugPrint(
      'Error inesperado en ejercicios: $e',
    );

    return porDefecto;
  }

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }
}
