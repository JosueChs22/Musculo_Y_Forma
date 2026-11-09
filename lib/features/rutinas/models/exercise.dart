/// Ejercicio dentro de una rutina o del catálogo.
class Exercise {
  const Exercise({
    required this.name,
    required this.sets,
    required this.reps,
    required this.restSeconds,
    this.coachNote = '',
  });

  final String name;
  final int sets;
  final String reps;
  final int restSeconds;
  final String coachNote;

  String get setsLabel => '$sets series';
  String get restLabel => '$restSeconds s descanso';
  String get summary => '$setsLabel · $reps · $restLabel';

  factory Exercise.fromJson(Map<String, dynamic> json) => Exercise(
        name: json['name'] as String,
        sets: (json['sets'] as num).toInt(),
        reps: json['reps'] as String,
        restSeconds: (json['restSeconds'] as num).toInt(),
        coachNote: (json['coachNote'] as String?) ?? '',
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'sets': sets,
        'reps': reps,
        'restSeconds': restSeconds,
        'coachNote': coachNote,
      };
}
