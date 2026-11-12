import 'exercise.dart';

/// Rutina (plan) asignada al usuario por su entrenador.
class Routine {
  const Routine({
    required this.id,
    required this.title,
    required this.focus,
    required this.progress,
    required this.exercises,
    this.diaSemana,
    this.coachName,
    this.observaciones,
  });

  final String id;
  final String title;

  /// "Entrenamiento · Lunes"
  final String focus;
  final int progress;
  final List<Exercise> exercises;

  /// 1 = lunes … 7 = domingo; null si no tiene día fijo.
  final int? diaSemana;
  final String? coachName;
  final String? observaciones;

  String get progressLabel => progress == 0 ? 'Sin iniciar' : '$progress% completado';
}
