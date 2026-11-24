import '../../secretaria/models/clase.dart';

/// Lectura del catálogo de clases para el panel del usuario (RF-095).
abstract class HorariosService {
  /// Todas las clases con sus horarios (incluye inhabilitadas; el controlador filtra).
  Future<List<Clase>> getClases();
}
