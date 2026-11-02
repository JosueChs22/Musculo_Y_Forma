import '../models/body_metric.dart';
import '../models/client.dart';
import '../models/exercise.dart';
import '../models/routine.dart';

abstract class GymRepository {
  Future<UserProfile> getProfile();
  Future<List<Routine>> getRoutines();
  Future<List<BodyMetric>> getBodyMetrics();
  Future<List<Measurement>> getMeasurementHistory();
  Future<List<Client>> getClients();
  Future<List<Exercise>> getExerciseCatalog();
  Future<void> assignRoutine({
    required String clientId,
    required String routineTitle,
    required List<String> exercises,
  });
}
