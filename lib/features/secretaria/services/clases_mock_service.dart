import '../models/clase.dart';
import '../models/horario_clase.dart';
import 'clases_service.dart';

class ClasesMockService implements ClasesService {
  ClasesMockService({this.latency = const Duration(milliseconds: 300)});
  final Duration latency;

  // Estado mutable en memoria para simular el CRUD.
  final List<Clase> _clases = [
    Clase(
      id: 'c1',
      nombre: 'Spinning',
      descripcion: 'Clase de ciclismo indoor de alta intensidad.',
      instructores: [],
      estado: 'Activo',
      fechaActualizacion: DateTime(2026, 10, 1),
      horarios: [
        HorarioClase(dias: [1, 3, 5], horaInicio: '06:00', horaFin: '07:00', estado: 'Activo'),
        HorarioClase(dias: [2, 4], horaInicio: '18:00', horaFin: '19:00', estado: 'Activo'),
      ],
    ),
    Clase(
      id: 'c2',
      nombre: 'Yoga',
      descripcion: 'Sesiones de yoga para flexibilidad y relajación.',
      instructores: [],
      estado: 'Activo',
      fechaActualizacion: DateTime(2026, 9, 15),
      horarios: [
        HorarioClase(dias: [2, 4, 6], horaInicio: '07:00', horaFin: '08:00', estado: 'Activo'),
      ],
    ),
    Clase(
      id: 'c3',
      nombre: 'Zumba',
      descripcion: 'Baile fitness con ritmos latinos.',
      instructores: [],
      estado: 'Activo',
      fechaActualizacion: DateTime(2026, 11, 1),
      horarios: [
        HorarioClase(dias: [1, 3], horaInicio: '17:00', horaFin: '18:00', estado: 'Activo'),
        HorarioClase(dias: [6], horaInicio: '09:00', horaFin: '10:00', estado: 'Inhabilitado'),
      ],
    ),
    Clase(
      id: 'c4',
      nombre: 'Body Pump',
      descripcion: null,
      instructores: [],
      estado: 'Inhabilitada',
      fechaActualizacion: DateTime(2026, 8, 20),
      horarios: [],
    ),
  ];

  int _nextId = 5;

  @override
  Future<List<Clase>> getClases() =>
      Future.delayed(latency, () => List.unmodifiable(_clases));

  @override
  Future<Clase> crearClase({required String nombre, String? descripcion}) =>
      Future.delayed(latency, () {
        final nueva = Clase(
          id: 'c${_nextId++}',
          nombre: nombre,
          descripcion: descripcion,
          instructores: [],
          estado: 'Activo',
          fechaActualizacion: DateTime.now(),
          horarios: [],
        );
        _clases.add(nueva);
        return nueva;
      });

  @override
  Future<Clase> actualizarClase(String id, {String? nombre, String? descripcion}) =>
      Future.delayed(latency, () {
        final i = _indexOf(id);
        final actualizada = _clases[i].copyWith(
          nombre: nombre,
          descripcion: descripcion,
          fechaActualizacion: DateTime.now(),
        );
        _clases[i] = actualizada;
        return actualizada;
      });

  @override
  Future<Clase> inhabilitarClase(String id) =>
      Future.delayed(latency, () {
        final i = _indexOf(id);
        final actualizada = _clases[i].copyWith(
          estado: 'Inhabilitada',
          fechaActualizacion: DateTime.now(),
        );
        _clases[i] = actualizada;
        return actualizada;
      });

  @override
  Future<Clase> agregarHorario(String idClase, HorarioClase horario) =>
      Future.delayed(latency, () {
        final i = _indexOf(idClase);
        final nuevosHorarios = [..._clases[i].horarios, horario];
        final actualizada = _clases[i].copyWith(
          horarios: nuevosHorarios,
          fechaActualizacion: DateTime.now(),
        );
        _clases[i] = actualizada;
        return actualizada;
      });

  @override
  Future<Clase> actualizarHorario(String idClase, int index, HorarioClase horario) =>
      Future.delayed(latency, () {
        final i = _indexOf(idClase);
        final nuevosHorarios = [..._clases[i].horarios];
        nuevosHorarios[index] = horario;
        final actualizada = _clases[i].copyWith(
          horarios: nuevosHorarios,
          fechaActualizacion: DateTime.now(),
        );
        _clases[i] = actualizada;
        return actualizada;
      });

  @override
  Future<Clase> inhabilitarHorario(String idClase, int index) =>
      Future.delayed(latency, () {
        final i = _indexOf(idClase);
        final nuevosHorarios = [..._clases[i].horarios];
        nuevosHorarios[index] = nuevosHorarios[index].copyWith(estado: 'Inhabilitado');
        final actualizada = _clases[i].copyWith(
          horarios: nuevosHorarios,
          fechaActualizacion: DateTime.now(),
        );
        _clases[i] = actualizada;
        return actualizada;
      });

  int _indexOf(String id) {
    final i = _clases.indexWhere((c) => c.id == id);
    if (i == -1) throw StateError('Clase $id no encontrada');
    return i;
  }
}
