import '../models/ejercicio.dart';

/// Contrato del catálogo de ejercicios (panel del Entrenador).
/// Las operaciones lanzan [ApiException] con un mensaje para el usuario si fallan.
abstract class EjerciciosService {
  /// RF-062 / RF-073. [soloActivos] en false incluye también los inhabilitados.
  Future<PaginaEjercicios> listar({
    String? texto,
    String? grupo,
    bool soloActivos = true,
    String? cursor,
  });

  /// RF-038.
  Future<Ejercicio> crear(DatosEjercicio datos);

  /// RF-048.
  Future<Ejercicio> actualizar(String id, DatosEjercicio datos);

  /// RF-055.
  Future<Ejercicio> inhabilitar(String id);

  Future<Ejercicio> reactivar(String id);
}
