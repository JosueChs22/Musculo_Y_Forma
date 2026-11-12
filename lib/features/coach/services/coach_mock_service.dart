import '../../progreso/models/body_metric.dart';
import '../../rutinas/models/exercise.dart';
import '../models/client.dart';
import 'coach_service.dart';

const _catalog = [
  Exercise(name: 'Press de banca', sets: 4, reps: '10 repeticiones', restSeconds: 60),
  Exercise(name: 'Press inclinado con mancuernas', sets: 4, reps: '12 repeticiones', restSeconds: 60),
  Exercise(name: 'Extensión de tríceps', sets: 4, reps: '12 repeticiones', restSeconds: 45),
  Exercise(name: 'Sentadilla goblet', sets: 4, reps: '12 repeticiones', restSeconds: 60),
  Exercise(name: 'Remo con polea', sets: 4, reps: '12 repeticiones', restSeconds: 60),
  Exercise(name: 'Peso muerto rumano', sets: 4, reps: '10 repeticiones', restSeconds: 75),
  Exercise(name: 'Elevación lateral', sets: 3, reps: '15 repeticiones', restSeconds: 45),
];

const _clients = [
  Client(id: 'c1', name: 'Alex Rivera', goal: 'Reducir grasa y ganar fuerza'),
  Client(id: 'c2', name: 'Mariana López', goal: 'Aumentar masa muscular'),
  Client(id: 'c3', name: 'Diego Torres', goal: 'Mejorar movilidad'),
];

const _metricsByClient = <String, List<BodyMetric>>{
  'c1': [
    BodyMetric(label: 'Peso', unit: 'kg', value: 78.4, decimals: 1, changeSinceStart: '-3.2 kg', changeVsPrevious: '-1.2 kg', history: []),
    BodyMetric(label: 'Grasa', unit: '%', value: 21.8, decimals: 1, changeSinceStart: '-2.6%', changeVsPrevious: '-0.8%', history: []),
    BodyMetric(label: 'Músculo', unit: 'kg', value: 34.2, decimals: 1, changeSinceStart: '+1.4 kg', changeVsPrevious: '+0.5 kg', history: []),
  ],
  'c2': [
    BodyMetric(label: 'Peso', unit: 'kg', value: 61.0, decimals: 1, changeSinceStart: '+1.8 kg', changeVsPrevious: '+0.6 kg', history: []),
    BodyMetric(label: 'Grasa', unit: '%', value: 24.5, decimals: 1, changeSinceStart: '-1.1%', changeVsPrevious: '-0.4%', history: []),
    BodyMetric(label: 'Músculo', unit: 'kg', value: 26.9, decimals: 1, changeSinceStart: '+1.2 kg', changeVsPrevious: '+0.4 kg', history: []),
  ],
  'c3': [
    BodyMetric(label: 'Peso', unit: 'kg', value: 84.7, decimals: 1, changeSinceStart: '-0.9 kg', changeVsPrevious: '-0.3 kg', history: []),
    BodyMetric(label: 'Grasa', unit: '%', value: 19.2, decimals: 1, changeSinceStart: '-0.7%', changeVsPrevious: '-0.2%', history: []),
    BodyMetric(label: 'Músculo', unit: 'kg', value: 38.6, decimals: 1, changeSinceStart: '+0.3 kg', changeVsPrevious: '+0.1 kg', history: []),
  ],
};

class CoachMockService implements CoachService {
  const CoachMockService({this.latency = const Duration(milliseconds: 250)});
  final Duration latency;

  Future<T> _fake<T>(T value) => Future.delayed(latency, () => value);

  @override
  Future<List<Client>> getClients({int limit = 20, String? cursor}) => _fake(_clients.take(limit).toList());

  @override
  Future<List<Exercise>> getExerciseCatalog({int limit = 20, String? cursor}) =>
      _fake(_catalog.take(limit).toList());

  @override
  Future<List<Exercise>> searchExercises(String query, {int limit = 20}) {
    final q = _normalize(query);
    return _fake(_catalog.where((e) => _normalize(e.name).contains(q)).take(limit).toList());
  }

  @override
  Future<List<BodyMetric>> getClientMetrics(String clientId) => _fake(_metricsByClient[clientId] ?? const []);

  @override
  Future<void> assignRoutine({
    required String clientId,
    required String routineTitle,
    required List<String> exercises,
  }) =>
      _fake(null);
}

String _normalize(String s) => s
    .toLowerCase()
    .replaceAll('á', 'a')
    .replaceAll('é', 'e')
    .replaceAll('í', 'i')
    .replaceAll('ó', 'o')
    .replaceAll('ú', 'u');
