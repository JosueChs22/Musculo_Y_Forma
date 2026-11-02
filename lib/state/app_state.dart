import 'package:flutter/foundation.dart';

import '../models/body_metric.dart';
import '../models/client.dart';
import '../models/exercise.dart';
import '../models/routine.dart';
import '../repositories/gym_repository.dart';

class AppState extends ChangeNotifier {
  AppState(this._repo);

  final GymRepository _repo;

  bool loading = true;
  String? error;

  UserProfile profile = UserProfile.empty;
  List<Routine> routines = const [];
  List<BodyMetric> metrics = const [];
  List<Measurement> history = const [];
  List<Client> clients = const [];
  List<Exercise> catalog = const [];

  Future<void> load() async {
    try {
      profile = await _repo.getProfile();
      routines = await _repo.getRoutines();
      metrics = await _repo.getBodyMetrics();
      history = await _repo.getMeasurementHistory();
      clients = await _repo.getClients();
      catalog = await _repo.getExerciseCatalog();
    } catch (e) {
      error = e.toString();
    }
    loading = false;
    notifyListeners();
  }

  Future<void> assignRoutine({
    required String clientId,
    required String routineTitle,
    required List<String> exercises,
  }) =>
      _repo.assignRoutine(clientId: clientId, routineTitle: routineTitle, exercises: exercises);
}
