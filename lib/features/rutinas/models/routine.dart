import '../../planes/models/plan.dart' show CategoriaPlan, diasSemana;
import 'exercise.dart';

/// Rutina (plan) asignada al usuario por su entrenador.
class Routine {
  const Routine({
    required this.id,
    required this.title,
    required this.focus,
    required this.progress,
    required this.exercises,
    this.categoria = CategoriaPlan.entrenamiento,
    this.activa = true,
    this.diaSemana,
    this.coachName,
    this.observaciones,
    int? totalEjercicios,
  }) : _total = totalEjercicios;

  final String id;
  final String title;

  /// "Entrenamiento · Lunes"
  final String focus;
  final int progress;
  final List<Exercise> exercises;
  final CategoriaPlan categoria;

  /// false si el plan fue inhabilitado (historial).
  final bool activa;

  /// 1 = lunes … 7 = domingo; null si no tiene día fijo.
  final int? diaSemana;
  final String? coachName;
  final String? observaciones;
  final int? _total;

  /// En el historial la API manda ejercicios vacíos y solo el conteo.
  int get totalEjercicios => _total ?? exercises.length;

  String get progressLabel => progress == 0 ? 'Sin iniciar' : '$progress% completado';

  /// Lectura tolerante de un plan de GET /mi/rutinas o /mi/rutinas/historial.
  factory Routine.fromJson(Map<String, dynamic> j) {
    final cat = CategoriaPlan.values.firstWhere(
      (c) => c.valor == (j['categoria'] as String?)?.toLowerCase(),
      orElse: () => CategoriaPlan.entrenamiento,
    );
    final d = j['diaSemana'] ?? j['dia_semana'];
    final dia = d is num && d >= 1 && d <= 7 ? d.toInt() : null;
    final coach = j['coach'];
    final estado = j['estado'];
    final activa = estado is bool
        ? estado
        : estado is String
            ? !const ['inhabilitado', 'inhabilitada', 'inactivo', 'inactiva'].contains(estado.toLowerCase())
            : (j['activo'] as bool? ?? true);
    final obs = j['observaciones'];
    final ejercicios = j['ejercicios'];
    return Routine(
      id: '${j['id'] ?? j['_id'] ?? ''}',
      title: (j['nombre'] as String?)?.trim().isNotEmpty == true ? (j['nombre'] as String).trim() : 'Rutina',
      focus: [cat.etiqueta, if (dia != null) diasSemana[dia - 1]].join(' · '),
      progress: 0, // el avance de cada sesión aún no se registra
      categoria: cat,
      activa: activa,
      diaSemana: dia,
      coachName: coach is Map ? coach['nombre'] as String? : (coach is String ? coach : null),
      totalEjercicios: (j['totalEjercicios'] as num?)?.toInt(),
      observaciones: obs is String && obs.trim().isNotEmpty ? obs.trim() : null,
      exercises: [
        if (ejercicios is List)
          for (final e in ejercicios)
            if (e is Map<String, dynamic>) Exercise.fromJson(e),
      ],
    );
  }
}
