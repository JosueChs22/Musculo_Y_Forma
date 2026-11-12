import 'package:flutter/foundation.dart';

import '../../../core/api_exception.dart';
import '../../ejercicios/models/ejercicio.dart';
import '../models/plan.dart';
import '../services/planes_service.dart';

/// Estado del editor de un plan (nuevo o existente): datos generales, ejercicios
/// con su dosificación y a quién se asigna. Lo crea la pantalla del editor.
class PlanEditorController extends ChangeNotifier {
  PlanEditorController(this._service, {this.id});

  /// null cuando se está creando un plan nuevo.
  final String? id;
  final PlanesService _service;

  static const maxEjercicios = 50;

  bool _cargando = false;
  String? _errorCarga;
  bool _guardando = false;
  String? _errorGuardar;
  bool _disposed = false;

  String _nombre = '';
  CategoriaPlan _categoria = CategoriaPlan.entrenamiento;
  int? _diaSemana;
  String _observaciones = '';
  List<PlanEjercicio> _ejercicios = const [];
  UsuarioResumen? _cliente;
  UsuarioResumen? _clienteOriginal;
  bool _activo = true;

  bool get esNuevo => id == null;
  bool get cargando => _cargando;
  String? get errorCarga => _errorCarga;
  bool get guardando => _guardando;
  String? get errorGuardar => _errorGuardar;

  String get nombre => _nombre;
  CategoriaPlan get categoria => _categoria;
  int? get diaSemana => _diaSemana;
  String get observaciones => _observaciones;
  List<PlanEjercicio> get ejercicios => _ejercicios;
  UsuarioResumen? get cliente => _cliente;

  /// Un plan inhabilitado se ve pero no se edita.
  bool get editable => _activo;
  bool get puedeAgregar => _ejercicios.length < maxEjercicios;
  bool tieneEjercicio(String idEjercicio) => _ejercicios.any((e) => e.idEjercicio == idEjercicio);

  /// Carga el plan existente. En uno nuevo no hace nada.
  Future<void> cargar() async {
    if (id == null) return;
    _cargando = true;
    _errorCarga = null;
    _avisar();
    try {
      final plan = await _service.obtener(id!);
      _nombre = plan.nombre;
      _categoria = plan.categoria;
      _diaSemana = plan.diaSemana;
      _observaciones = plan.observaciones ?? '';
      _ejercicios = plan.ejercicios;
      _cliente = _clienteOriginal = plan.usuario;
      _activo = plan.activo;
    } catch (e) {
      _errorCarga = _mensaje(e, 'No pudimos cargar el plan. Revisa tu conexión e inténtalo de nuevo.');
    }
    _cargando = false;
    _avisar();
  }

  void cambiarNombre(String v) => _nombre = v; // sin notificar: lo muestra el propio campo

  void cambiarObservaciones(String v) => _observaciones = v;

  void cambiarCategoria(CategoriaPlan c) {
    _categoria = c;
    _avisar();
  }

  void cambiarDia(int? dia) {
    _diaSemana = dia;
    _avisar();
  }

  void cambiarCliente(UsuarioResumen? c) {
    _cliente = c;
    _avisar();
  }

  /// Agrega el ejercicio del catálogo con valores por defecto. Devuelve false si ya
  /// estaba en el plan o se llegó al máximo.
  bool agregar(Ejercicio e) {
    if (tieneEjercicio(e.id) || !puedeAgregar) return false;
    _ejercicios = [
      ..._ejercicios,
      PlanEjercicio(idEjercicio: e.id, nombre: e.nombre, imagenUrl: e.imagenUrl, grupoMuscular: e.grupoMuscular),
    ];
    _avisar();
    return true;
  }

  void quitar(String idEjercicio) {
    _ejercicios = [for (final e in _ejercicios) if (e.idEjercicio != idEjercicio) e];
    _avisar();
  }

  /// Sube (-1) o baja (+1) un ejercicio en el orden del plan.
  void mover(String idEjercicio, int delta) {
    final i = _ejercicios.indexWhere((e) => e.idEjercicio == idEjercicio);
    final j = i + delta;
    if (i == -1 || j < 0 || j >= _ejercicios.length) return;
    final copia = [..._ejercicios];
    final e = copia.removeAt(i);
    copia.insert(j, e);
    _ejercicios = copia;
    _avisar();
  }

  /// Cambia la dosificación de un ejercicio. No notifica: lo muestran los propios campos.
  void actualizarEjercicio(String idEjercicio, PlanEjercicio Function(PlanEjercicio) cambio) {
    _ejercicios = [for (final e in _ejercicios) e.idEjercicio == idEjercicio ? cambio(e) : e];
  }

  /// Valida y guarda. Devuelve true si se guardó. Si falla, deja el mensaje en [errorGuardar].
  Future<bool> guardar() async {
    if (_guardando || !_activo) return false; // evita doble clic (REGLA 8)

    final faltan = _ejercicios.where((e) => !e.activo).toList();
    final error = _nombre.trim().isEmpty
        ? 'Ponle un nombre al plan.'
        : _ejercicios.isEmpty
            ? 'Agrega al menos un ejercicio.'
            : faltan.isNotEmpty
                ? 'El ejercicio "${faltan.first.nombre}" está inhabilitado. Quítalo del plan para guardarlo.'
                : null;
    if (error != null) {
      _errorGuardar = error;
      _avisar();
      return false;
    }

    _guardando = true;
    _errorGuardar = null;
    _avisar();
    try {
      final datos = DatosPlan(
        nombre: _nombre,
        categoria: _categoria,
        observaciones: _observaciones,
        diaSemana: _diaSemana,
        ejercicios: _ejercicios,
      );
      if (id == null) {
        await _service.crear(datos, idUsuario: _cliente?.id);
      } else {
        await _service.actualizar(id!, datos);
        if (_cliente?.id != _clienteOriginal?.id) await _service.asignar(id!, _cliente?.id);
      }
      return true;
    } catch (e) {
      _errorGuardar = _mensaje(e, 'No se pudo guardar el plan. Inténtalo de nuevo.');
      return false;
    } finally {
      _guardando = false;
      _avisar();
    }
  }

  String _mensaje(Object e, String porDefecto) {
    if (e is ApiException) return e.mensaje;
    debugPrint('Error inesperado en el editor de planes: $e');
    return porDefecto;
  }

  void _avisar() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
