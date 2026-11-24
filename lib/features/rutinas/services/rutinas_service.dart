import '../models/routine.dart';

/// Una página del historial de rutinas.
class PaginaRutinas {
  const PaginaRutinas(this.items, this.nextCursor);
  final List<Routine> items;

  /// null cuando no hay más páginas.
  final String? nextCursor;
}

/// Acceso a las rutinas asignadas al socio.
abstract class RutinasService {
  /// Rutinas vigentes (todas las categorías; se agrupan en el controlador).
  Future<List<Routine>> getRoutines();

  /// Planes pasados (inhabilitados), paginados por cursor.
  Future<PaginaRutinas> getHistorial({String? cursor, int limite = 20});
}
