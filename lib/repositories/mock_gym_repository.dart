import '../models/body_metric.dart';
import '../models/client.dart';
import '../models/exercise.dart';
import '../models/routine.dart';
import 'gym_repository.dart';

Exercise _e(String name, int sets, String reps, int rest, String note) =>
    Exercise(
        name: name, sets: sets, reps: reps, restSeconds: rest, coachNote: note);

class MockGymRepository implements GymRepository {
  Future<T> _fake<T>(T value) =>
      Future.delayed(const Duration(milliseconds: 250), () => value);

  @override
  Future<UserProfile> getProfile() => _fake(const UserProfile(
        name: 'Alex Rivera',
        coachName: 'Carlos Méndez',
        goal: 'Reducir grasa y ganar fuerza',
        streakDays: 12,
        currentWorkout: 'Empuje: pecho y tríceps',
        weekLabel: 'Semana 3',
        lastMeasurementLabel: 'Última medición · 18 mayo',
      ));

  @override
  Future<List<Routine>> getRoutines() => _fake([
        Routine(
          id: 'r1',
          title: 'Pecho y tríceps',
          focus: 'Fuerza de empuje',
          progress: 58,
          exercises: [
            _e('Press de banca', 4, '10 repeticiones', 60,
                'Mantén los pies firmes y controla el descenso.'),
            _e('Press inclinado con mancuernas', 4, '12 repeticiones', 60,
                'No cierres completamente los codos.'),
            _e('Aperturas en polea', 3, '15 repeticiones', 45,
                'Movimiento lento y recorrido completo.'),
            _e('Fondos asistidos', 3, '10 repeticiones', 60,
                'Inclina ligeramente el torso.'),
            _e('Extensión de tríceps', 4, '12 repeticiones', 45,
                'Mantén los codos junto al cuerpo.'),
            _e('Press francés', 3, '12 repeticiones', 45,
                'Evita abrir los codos.'),
            _e('Flexiones', 3, 'Al fallo técnico', 60,
                'Detente si pierdes la postura.'),
          ],
        ),
        Routine(
          id: 'r2',
          title: 'Pierna completa',
          focus: 'Fuerza y estabilidad',
          progress: 25,
          exercises: [
            _e('Sentadilla goblet', 4, '12 repeticiones', 60,
                'Rodillas alineadas con los pies.'),
            _e('Peso muerto rumano', 4, '10 repeticiones', 75,
                'Espalda neutra durante todo el movimiento.'),
            _e('Prensa de pierna', 4, '12 repeticiones', 60,
                'No bloquees las rodillas.'),
            _e('Zancadas estáticas', 3, '10 por lado', 45,
                'Mantén el torso erguido.'),
            _e('Curl femoral', 3, '15 repeticiones', 45,
                'Controla el regreso.'),
            _e('Extensión de cuádriceps', 3, '15 repeticiones', 45,
                'Pausa arriba un segundo.'),
            _e('Elevación de pantorrilla', 4, '18 repeticiones', 30,
                'Busca el recorrido completo.'),
            _e('Plancha', 3, '30 segundos', 30, 'Activa abdomen y glúteos.'),
          ],
        ),
        Routine(
          id: 'r3',
          title: 'Espalda y bíceps',
          focus: 'Tracción y postura',
          progress: 0,
          exercises: [
            _e('Jalón al pecho', 4, '10 repeticiones', 60,
                'Lleva la barra hacia la parte alta del pecho.'),
            _e('Remo con polea', 4, '12 repeticiones', 60,
                'Junta los omóplatos al final.'),
            _e('Remo con mancuerna', 3, '12 por lado', 45,
                'Evita girar el tronco.'),
            _e('Pullover en polea', 3, '15 repeticiones', 45,
                'Brazos casi extendidos.'),
            _e('Curl con barra', 4, '10 repeticiones', 45,
                'No balancees el cuerpo.'),
            _e('Curl martillo', 3, '12 repeticiones', 45,
                'Muñecas en posición neutra.'),
            _e('Face pull', 3, '15 repeticiones', 45,
                'Lleva la cuerda hacia el rostro.'),
          ],
        ),
      ]);

  @override
  Future<List<BodyMetric>> getBodyMetrics() => _fake(const [
        BodyMetric(
          label: 'Peso corporal',
          unit: 'kg',
          value: 78.4,
          decimals: 1,
          changeSinceStart: '-3.2 kg',
          changeVsPrevious: '-1.2 kg',
          history: [81.6, 80.9, 80.2, 79.5, 78.9, 78.4],
        ),
        BodyMetric(
          label: 'Grasa corporal',
          unit: '%',
          value: 21.8,
          decimals: 1,
          changeSinceStart: '-2.6%',
          changeVsPrevious: '-0.8%',
          history: [24.4, 23.9, 23.2, 22.8, 22.1, 21.8],
        ),
        BodyMetric(
          label: 'Masa muscular',
          unit: 'kg',
          value: 34.2,
          decimals: 1,
          changeSinceStart: '+1.4 kg',
          changeVsPrevious: '+0.5 kg',
          history: [32.8, 33.0, 33.3, 33.6, 33.9, 34.2],
        ),
        BodyMetric(
          label: 'Grasa visceral',
          unit: 'nivel',
          value: 8,
          decimals: 0,
          changeSinceStart: '-2 niveles',
          changeVsPrevious: '0 niveles',
          history: [10, 10, 9, 9, 8, 8],
        ),
      ]);

  @override
  Future<List<Measurement>> getMeasurementHistory() => _fake(const [
        Measurement(
            date: '18 may 2025',
            weight: '78.4 kg',
            bodyFat: '21.8%',
            muscle: '34.2 kg',
            visceral: '8'),
        Measurement(
            date: '20 abr 2025',
            weight: '78.9 kg',
            bodyFat: '22.1%',
            muscle: '33.9 kg',
            visceral: '8'),
        Measurement(
            date: '16 mar 2025',
            weight: '79.5 kg',
            bodyFat: '22.8%',
            muscle: '33.6 kg',
            visceral: '9'),
        Measurement(
            date: '15 feb 2025',
            weight: '80.2 kg',
            bodyFat: '23.2%',
            muscle: '33.3 kg',
            visceral: '9'),
      ]);

  @override
  Future<List<Client>> getClients() => _fake(const [
        Client(
            id: 'c1',
            name: 'Alex Rivera',
            goal: 'Reducir grasa y ganar fuerza'),
        Client(id: 'c2', name: 'Mariana López', goal: 'Aumentar masa muscular'),
        Client(id: 'c3', name: 'Diego Torres', goal: 'Mejorar movilidad'),
      ]);

  @override
  Future<List<Exercise>> getExerciseCatalog() => _fake([
        _e('Press de banca', 4, '10 repeticiones', 60, ''),
        _e('Press inclinado con mancuernas', 4, '12 repeticiones', 60, ''),
        _e('Extensión de tríceps', 4, '12 repeticiones', 45, ''),
        _e('Sentadilla goblet', 4, '12 repeticiones', 60, ''),
        _e('Remo con polea', 4, '12 repeticiones', 60, ''),
        _e('Peso muerto rumano', 4, '10 repeticiones', 75, ''),
        _e('Elevación lateral', 3, '15 repeticiones', 45, ''),
      ]);

  @override
  Future<void> assignRoutine({
    required String clientId,
    required String routineTitle,
    required List<String> exercises,
  }) =>
      _fake(null);
}
