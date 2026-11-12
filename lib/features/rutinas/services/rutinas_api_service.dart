import '../../../core/api_http.dart';
import '../../planes/models/plan.dart';
import '../models/exercise.dart';
import '../models/routine.dart';
import 'rutinas_service.dart';

/// Rutinas asignadas al usuario con sesión (GET /mi/rutinas: siempre las del token).
class RutinasApiService implements RutinasService {
  RutinasApiService({ApiHttp? http}) : _http = http ?? ApiHttp();

  final ApiHttp _http;

  @override
  Future<List<Routine>> getRoutines() async {
    final json = await _http.get('/mi/rutinas');
    return [for (final p in json['data'] as List) _rutina(p as Map<String, dynamic>)];
  }

  Routine _rutina(Map<String, dynamic> p) {
    final plan = Plan.fromJson(p); // mismo DTO que los planes del entrenador
    final coach = p['coach'] as Map<String, dynamic>?;
    return Routine(
      id: plan.id,
      title: plan.nombre,
      focus: [plan.categoria.etiqueta, if (plan.dia != null) plan.dia!].join(' · '),
      progress: 0, // el avance de cada sesión aún no se registra
      diaSemana: plan.diaSemana,
      coachName: coach?['nombre'] as String?,
      observaciones: plan.observaciones,
      exercises: [
        for (final e in plan.ejercicios)
          Exercise(
            name: e.nombre,
            sets: e.series,
            reps: '${e.repeticiones} repeticiones',
            restSeconds: e.descanso,
            coachNote: [
              if (e.pesoSugerido != null) 'Peso sugerido: ${e.pesoSugerido} kg.',
              if (e.nota != null && e.nota!.isNotEmpty) e.nota!,
            ].join(' '),
            imageUrl: e.imagenUrl,
            gifUrl: e.gifUrl,
          ),
      ],
    );
  }
}
