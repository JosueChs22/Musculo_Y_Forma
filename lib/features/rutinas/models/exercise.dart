/// Ejercicio dentro de una rutina asignada.
class Exercise {
  const Exercise({
    required this.name,
    required this.sets,
    required this.reps,
    required this.restSeconds,
    this.coachNote = '',
    this.imageUrl,
    this.gifUrl,
  });

  final String name;
  final int sets;
  final String reps;
  final int restSeconds;
  final String coachNote;

  /// Miniatura y animación del catálogo (pueden faltar).
  final String? imageUrl;
  final String? gifUrl;

  String get setsLabel => '$sets series';
  String get restLabel => '$restSeconds s descanso';
  String get summary => '$setsLabel · $reps · $restLabel';
}
