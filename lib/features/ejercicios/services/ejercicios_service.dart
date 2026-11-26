import '../models/ejercicio.dart';

/// Contrato del catálogo de ejercicios.
/// Panel del Entrenador.
abstract class EjerciciosService {
  /// RF-062 / RF-073 / RF-066 / RF-077
  /// Visualizar y buscar ejercicios.
  ///
  /// [tipo] permite filtrar por:
  /// entrenamiento, calentamiento o estiramiento.
  ///
  /// Si [tipo] es null, muestra todos los tipos.
  Future<PaginaEjercicios> listar({
    String? texto,
    String? grupo,
    String? tipo,
    bool soloActivos = true,
    String? cursor,
  });

  /// RF-038 / RF-045
  Future<Ejercicio> crear(
    DatosEjercicio datos,
  );

  /// RF-048 / RF-052
  Future<Ejercicio> actualizar(
    String id,
    DatosEjercicio datos,
  );

  /// RF-055 / RF-059
  Future<Ejercicio> inhabilitar(
    String id,
  );

  Future<Ejercicio> reactivar(
    String id,
  );
}
