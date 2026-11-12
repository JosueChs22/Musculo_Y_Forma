import '../../../core/base_controller.dart';
import '../../../core/datos_del_usuario.dart';
import '../models/routine.dart';
import '../services/rutinas_service.dart';

class RutinasController extends BaseController with DatosDelUsuario {
  RutinasController(this._service);

  final RutinasService _service;

  List<Routine> _routines = const [];
  List<Routine> get routines => _routines;

  int _selectedIndex = 0;
  int get selectedIndex => _selectedIndex;

  Routine? get selected => _routines.isEmpty ? null : _routines[_selectedIndex];

  /// La rutina de hoy (por día de la semana); si no hay una para hoy, la primera.
  Routine? get deHoy {
    if (_routines.isEmpty) return null;
    final hoy = DateTime.now().weekday; // 1 = lunes … 7 = domingo
    return _routines.firstWhere((r) => r.diaSemana == hoy, orElse: () => _routines.first);
  }

  @override
  Future<void> cargarDatos() async {
    _routines = await _service.getRoutines();
    if (_selectedIndex >= _routines.length) _selectedIndex = 0;
  }

  @override
  void limpiar() {
    _routines = const [];
    _selectedIndex = 0;
  }

  void select(int index) {
    if (index == _selectedIndex || index < 0 || index >= _routines.length) return;
    _selectedIndex = index;
    notify();
  }
}
