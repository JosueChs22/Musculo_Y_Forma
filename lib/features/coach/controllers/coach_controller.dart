import 'dart:async';

import '../../../core/base_controller.dart';
import '../../../core/debouncer.dart';
import '../../progreso/models/body_metric.dart';
import '../../rutinas/models/exercise.dart';
import '../models/client.dart';
import '../services/coach_service.dart';

enum AssignStatus { unsaved, saved }

class CoachController extends BaseController {
  CoachController(this._service, {Debouncer? debouncer}) : _debouncer = debouncer ?? Debouncer();

  final CoachService _service;
  final Debouncer _debouncer;

  static const minQueryLength = 2;
  static const routineTitle = 'Pecho y tríceps';

  // --- Clientes ---
  List<Client> _clients = const [];
  List<Client> get clients => _clients;

  int _selectedClient = 0;
  int get selectedClient => _selectedClient;
  Client? get client => _clients.isEmpty ? null : _clients[_selectedClient];

  List<BodyMetric> _clientMetrics = const [];
  List<BodyMetric> get clientMetrics => _clientMetrics;
  bool _metricsLoading = false;
  bool get metricsLoading => _metricsLoading;
  int _metricsRequest = 0;

  // --- Constructor de rutina ---
  List<Exercise> _catalog = const [];
  List<Exercise> _assigned = const [];
  List<Exercise> get assigned => _assigned;

  AssignStatus _status = AssignStatus.unsaved;
  AssignStatus get status => _status;

  // --- Búsqueda (REGLA 9) ---
  String _query = '';
  String get query => _query;
  List<Exercise> _results = const [];
  bool _searching = false;
  bool get searching => _searching;
  int _searchRequest = 0;

  /// Ejercicios que se pueden agregar: resultados de búsqueda sin los ya asignados.
  /// Se memoriza para que la vista no se reconstruya sin cambios reales (REGLA 3).
  List<Exercise> get available {
    if (!identical(_availableFrom, _results) || !identical(_availableMinus, _assigned)) {
      final taken = {for (final e in _assigned) e.name};
      _available = [for (final e in _results) if (!taken.contains(e.name)) e];
      _availableFrom = _results;
      _availableMinus = _assigned;
    }
    return _available;
  }

  List<Exercise> _available = const [];
  List<Exercise>? _availableFrom;
  List<Exercise>? _availableMinus;

  @override
  Future<void> fetch() async {
    // REGLA 10: clientes y catálogo no dependen entre sí.
    final (clients, catalog) = await (
      _service.getClients(),
      _service.getExerciseCatalog(),
    ).wait;
    _clients = clients;
    _catalog = catalog;
    _results = catalog;
    if (_assigned.isEmpty) _assigned = catalog.take(3).toList();
    if (_selectedClient >= _clients.length) _selectedClient = 0;
    if (_clients.isNotEmpty) unawaited(_loadClientMetrics());
  }

  void selectClient(int index) {
    if (index == _selectedClient || index < 0 || index >= _clients.length) return;
    _selectedClient = index;
    _status = AssignStatus.unsaved;
    notify();
    unawaited(_loadClientMetrics());
  }

  Future<void> _loadClientMetrics() async {
    final request = ++_metricsRequest;
    final id = _clients[_selectedClient].id;
    _metricsLoading = true;
    notify();
    try {
      final metrics = await _service.getClientMetrics(id);
      if (request != _metricsRequest) return; // llegó una respuesta vieja
      _clientMetrics = metrics;
    } catch (_) {
      if (request != _metricsRequest) return;
      _clientMetrics = const [];
    }
    _metricsLoading = false;
    notify();
  }

  void addExercise(Exercise e) {
    if (_assigned.any((a) => a.name == e.name)) return;
    _assigned = [..._assigned, e];
    _status = AssignStatus.unsaved;
    notify();
  }

  void removeExerciseAt(int index) {
    _assigned = [..._assigned]..removeAt(index);
    _status = AssignStatus.unsaved;
    notify();
  }

  /// REGLA 9: espera 300 ms sin teclear; no busca con menos de 2 caracteres.
  void onQueryChanged(String value) {
    _query = value.trim();
    if (_query.isEmpty) {
      _debouncer.cancel();
      _searchRequest++;
      _results = _catalog;
      _searching = false;
      notify();
      return;
    }
    if (_query.length < minQueryLength) {
      _debouncer.cancel();
      notify(); // la vista muestra "escribe al menos 2 letras"
      return;
    }
    _debouncer.run(_search);
  }

  Future<void> _search() async {
    final request = ++_searchRequest;
    final q = _query;
    _searching = true;
    notify();
    try {
      final results = await _service.searchExercises(q);
      if (request != _searchRequest) return; // se descarta una búsqueda anterior
      _results = results;
    } catch (_) {
      if (request != _searchRequest) return;
      _results = const [];
    }
    _searching = false;
    notify();
  }

  /// REGLA 2: actualización optimista. Marca la rutina como asignada de
  /// inmediato y, si el servidor falla, revierte y devuelve `false`.
  Future<bool> save() async {
    final c = client;
    if (c == null || _status == AssignStatus.saved) return true;
    _status = AssignStatus.saved;
    notify();
    try {
      await _service.assignRoutine(
        clientId: c.id,
        routineTitle: routineTitle,
        exercises: [for (final e in _assigned) e.name],
      );
      return true;
    } catch (_) {
      _status = AssignStatus.unsaved;
      notify();
      return false;
    }
  }

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }
}
