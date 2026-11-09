import '../models/exercise.dart';
import '../models/routine.dart';
import 'rutinas_service.dart';

Exercise _e(String name, int sets, String reps, int rest, String note) =>
    Exercise(name: name, sets: sets, reps: reps, restSeconds: rest, coachNote: note);

class RutinasMockService implements RutinasService {
  const RutinasMockService({this.latency = const Duration(milliseconds: 250)});
  final Duration latency;

  @override
  Future<List<Routine>> getRoutines() => Future.delayed(latency, () => [
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
}
