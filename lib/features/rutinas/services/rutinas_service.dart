import '../models/routine.dart';

/// Acceso a las rutinas asignadas al socio.
abstract class RutinasService {
  Future<List<Routine>> getRoutines();
}
