import '../../../core/base_controller.dart';
import '../models/routine.dart';
import '../services/rutinas_service.dart';

class RutinasController extends BaseController {
  RutinasController(this._service);

  final RutinasService _service;

  List<Routine> _routines = const [];
  List<Routine> get routines => _routines;

  int _selectedIndex = 0;
  int get selectedIndex => _selectedIndex;

  Routine? get selected => _routines.isEmpty ? null : _routines[_selectedIndex];

  @override
  Future<void> fetch() async {
    _routines = await _service.getRoutines();
    if (_selectedIndex >= _routines.length) _selectedIndex = 0;
  }

  void select(int index) {
    if (index == _selectedIndex || index < 0 || index >= _routines.length) return;
    _selectedIndex = index;
    notify();
  }
}
