import '../../../core/base_controller.dart';
import '../../../core/datos_del_usuario.dart';
import '../../planes/models/plan.dart' show CategoriaPlan;
import '../models/routine.dart';
import '../services/rutinas_service.dart';

/// Pestañas de la pantalla de rutinas: una por categoría y el historial.
enum RutinasTab {
  entrenamiento('Entrenamiento', CategoriaPlan.entrenamiento),
  calentamiento('Calentamiento', CategoriaPlan.calentamiento),
  estiramiento('Estiramiento', CategoriaPlan.estiramiento),
  historial('Historial', null);

  const RutinasTab(this.etiqueta, this.categoria);
  final String etiqueta;
  final CategoriaPlan? categoria;
}

class RutinasController extends BaseController with DatosDelUsuario {
  RutinasController(this._service, {this.tamanoPagina = 20});

  final RutinasService _service;
  final int tamanoPagina;

  // ---- Rutinas vigentes (una sola petición, agrupadas aquí) ----
  List<Routine> _routines = const [];

  /// Todas las rutinas vigentes (Inicio las usa sin filtrar).
  List<Routine> get routines => _routines;

  Map<CategoriaPlan, List<Routine>> _porCategoria = const {};
  List<Routine> porCategoria(CategoriaPlan c) => _porCategoria[c] ?? const [];

  RutinasTab _tab = RutinasTab.entrenamiento;
  RutinasTab get tab => _tab;

  /// Rutinas de la pestaña actual (vacío en Historial).
  List<Routine> get visibles => _tab.categoria == null ? const [] : porCategoria(_tab.categoria!);

  int _selectedIndex = 0;
  int get selectedIndex => _selectedIndex;

  Routine? get selected {
    final v = visibles;
    return v.isEmpty ? null : v[_selectedIndex.clamp(0, v.length - 1)];
  }

  /// La rutina de entrenamiento de hoy (por día de la semana); si no hay, la primera.
  Routine? get deHoy {
    final base =
        porCategoria(CategoriaPlan.entrenamiento).isNotEmpty ? porCategoria(CategoriaPlan.entrenamiento) : _routines;
    if (base.isEmpty) return null;
    final hoy = DateTime.now().weekday; // 1 = lunes … 7 = domingo
    return base.firstWhere((r) => r.diaSemana == hoy, orElse: () => base.first);
  }

  @override
  Future<void> cargarDatos() async {
    _routines = await _service.getRoutines();
    _porCategoria = {
      for (final c in CategoriaPlan.values)
        c: [
          for (final r in _routines)
            if (r.categoria == c) r
        ],
    };
    if (_selectedIndex >= visibles.length) _selectedIndex = 0;
  }

  @override
  void limpiar() {
    _routines = const [];
    _porCategoria = const {};
    _selectedIndex = 0;
    _tab = RutinasTab.entrenamiento;
    _limpiarHistorial();
  }

  void setTab(RutinasTab t) {
    if (t == _tab) return;
    _tab = t;
    _selectedIndex = 0;
    notify();
    if (t == RutinasTab.historial && !_historialCargado && !_historialLoading) cargarHistorial();
  }

  void select(int index) {
    if (index == _selectedIndex || index < 0 || index >= visibles.length) return;
    _selectedIndex = index;
    notify();
  }

  // ---- Historial (RF-091): paginado por cursor, con su propio estado ----
  List<Routine> _historial = const [];
  List<Routine> get historial => _historial;
  String? _cursor;
  bool _historialCargado = false;
  bool _historialLoading = false;
  bool _cargandoMas = false;
  String? _historialError;
  int _generacion = 0; // descarta respuestas de otro usuario

  bool get historialLoading => _historialLoading;
  bool get cargandoMas => _cargandoMas;
  String? get historialError => _historialError;
  bool get hayMasHistorial => _historialCargado && _cursor != null;

  void _limpiarHistorial() {
    _generacion++;
    _historial = const [];
    _cursor = null;
    _historialCargado = false;
    _historialLoading = false;
    _cargandoMas = false;
    _historialError = null;
  }

  /// Primera página (o reintento tras un error).
  Future<void> cargarHistorial() async {
    if (_historialLoading) return;
    final gen = ++_generacion;
    _historialLoading = true;
    _historialError = null;
    _cargandoMas = false;
    notify();
    try {
      final p = await _service.getHistorial(limite: tamanoPagina);
      if (gen != _generacion) return;
      _historial = p.items;
      _cursor = p.nextCursor;
      _historialCargado = true;
    } catch (_) {
      if (gen != _generacion) return;
      _historialError = 'No pudimos cargar tu historial de rutinas. Inténtalo de nuevo.';
    }
    _historialLoading = false;
    notify();
  }

  /// Siguiente página (scroll infinito). No repite peticiones en curso.
  Future<void> cargarMasHistorial() async {
    if (!hayMasHistorial || _cargandoMas || _historialLoading) return;
    final gen = _generacion;
    _cargandoMas = true;
    notify();
    try {
      final p = await _service.getHistorial(cursor: _cursor, limite: tamanoPagina);
      if (gen != _generacion) return;
      _historial = [..._historial, ...p.items];
      _cursor = p.nextCursor;
    } catch (_) {
      // se puede volver a intentar al seguir bajando
      if (gen != _generacion) return;
    }
    _cargandoMas = false;
    notify();
  }
}
