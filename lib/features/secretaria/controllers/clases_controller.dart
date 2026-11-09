import '../../../core/base_controller.dart';
import '../models/clase.dart';
import '../models/horario_clase.dart';
import '../services/clases_service.dart';

class ClasesController extends BaseController {
  ClasesController(this._service);

  final ClasesService _service;

  List<Clase> _clases = const [];
  List<Clase> get clases => _clases;

  List<Clase> get clasesActivas => _clases.where((c) => c.activa).toList();
  List<Clase> get clasesInhabilitadas => _clases.where((c) => !c.activa).toList();

  @override
  Future<void> fetch() async {
    _clases = await _service.getClases();
  }

  // ── Clases ────────────────────────────────────────────────────────────────

  Future<void> crearClase({required String nombre, String? descripcion}) async {
    _setBusy(true);
    try {
      final nueva = await _service.crearClase(nombre: nombre, descripcion: descripcion);
      _clases = [..._clases, nueva];
    } catch (_) {
      _setError('No se pudo crear la clase. Inténtalo de nuevo.');
    }
    _setBusy(false);
  }

  Future<void> actualizarClase(String id, {String? nombre, String? descripcion}) async {
    _setBusy(true);
    try {
      final actualizada = await _service.actualizarClase(id, nombre: nombre, descripcion: descripcion);
      _clases = [for (final c in _clases) c.id == id ? actualizada : c];
    } catch (_) {
      _setError('No se pudo actualizar la clase. Inténtalo de nuevo.');
    }
    _setBusy(false);
  }

  Future<void> inhabilitarClase(String id) async {
    // Actualización optimista (REGLA 2).
    final original = _clases.firstWhere((c) => c.id == id);
    _clases = [for (final c in _clases) c.id == id ? c.copyWith(estado: 'Inhabilitada') : c];
    notify();

    try {
      final confirmada = await _service.inhabilitarClase(id);
      _clases = [for (final c in _clases) c.id == id ? confirmada : c];
    } catch (_) {
      // Revertir si falla.
      _clases = [for (final c in _clases) c.id == id ? original : c];
      _setError('No se pudo inhabilitar la clase. Los cambios fueron revertidos.');
    }
    notify();
  }

  // ── Horarios ──────────────────────────────────────────────────────────────

  Future<void> agregarHorario(String idClase, HorarioClase horario) async {
    _setBusy(true);
    try {
      final actualizada = await _service.agregarHorario(idClase, horario);
      _clases = [for (final c in _clases) c.id == idClase ? actualizada : c];
    } catch (_) {
      _setError('No se pudo agregar el horario. Inténtalo de nuevo.');
    }
    _setBusy(false);
  }

  Future<void> actualizarHorario(String idClase, int index, HorarioClase horario) async {
    _setBusy(true);
    try {
      final actualizada = await _service.actualizarHorario(idClase, index, horario);
      _clases = [for (final c in _clases) c.id == idClase ? actualizada : c];
    } catch (_) {
      _setError('No se pudo actualizar el horario. Inténtalo de nuevo.');
    }
    _setBusy(false);
  }

  Future<void> inhabilitarHorario(String idClase, int index) async {
    // Actualización optimista (REGLA 2).
    final claseActual = _clases.firstWhere((c) => c.id == idClase);
    final horariosOpt = [...claseActual.horarios];
    horariosOpt[index] = horariosOpt[index].copyWith(estado: 'Inhabilitado');
    _clases = [for (final c in _clases) c.id == idClase ? c.copyWith(horarios: horariosOpt) : c];
    notify();

    try {
      final confirmada = await _service.inhabilitarHorario(idClase, index);
      _clases = [for (final c in _clases) c.id == idClase ? confirmada : c];
    } catch (_) {
      _clases = [for (final c in _clases) c.id == idClase ? claseActual : c];
      _setError('No se pudo inhabilitar el horario. Los cambios fueron revertidos.');
    }
    notify();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  bool _busy = false;
  bool get busy => _busy;

  void _setBusy(bool value) {
    _busy = value;
    notify();
  }

  void _setError(String msg) {
    // Reutiliza el campo error de BaseController mediante reflexión mínima.
    // ignore: invalid_use_of_protected_member
    notify();
    // Propaga el mensaje como SnackBar desde la vista.
    _lastActionError = msg;
  }

  String? _lastActionError;
  String? get lastActionError {
    final e = _lastActionError;
    _lastActionError = null;
    return e;
  }

  void clearError() {
    _lastActionError = null;
    notify();
  }
}
