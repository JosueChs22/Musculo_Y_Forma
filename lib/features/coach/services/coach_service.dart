import '../../progreso/models/body_metric.dart';
import '../../rutinas/models/exercise.dart';
import '../models/client.dart';

/// Operaciones del panel del coach.
abstract class CoachService {
  /// REGLA 12: listas paginadas.
  Future<List<Client>> getClients({int limit = 20, String? cursor});

  /// Primera página del catálogo de ejercicios.
  Future<List<Exercise>> getExerciseCatalog({int limit = 20, String? cursor});

  /// Búsqueda en el catálogo (se llama con debounce, REGLA 9).
  Future<List<Exercise>> searchExercises(String query, {int limit = 20});

  /// Resumen de métricas de un cliente (solo los campos que muestra el panel, REGLA 20).
  Future<List<BodyMetric>> getClientMetrics(String clientId);

  Future<void> assignRoutine({
    required String clientId,
    required String routineTitle,
    required List<String> exercises,
  });
}
