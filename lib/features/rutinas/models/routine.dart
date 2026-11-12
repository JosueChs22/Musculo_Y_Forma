import 'exercise.dart';

class Routine {
  const Routine({
    required this.id,
    required this.title,
    required this.focus,
    required this.progress,
    required this.exercises,
  });

  final String id;
  final String title;
  final String focus;
  final int progress;
  final List<Exercise> exercises;

  String get progressLabel => progress == 0 ? 'Sin iniciar' : '$progress% completado';

  factory Routine.fromJson(Map<String, dynamic> json) => Routine(
        id: json['_id'] as String,
        title: json['title'] as String,
        focus: json['focus'] as String,
        progress: (json['progress'] as num).toInt(),
        exercises: (json['exercises'] as List)
            .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        '_id': id,
        'title': title,
        'focus': focus,
        'progress': progress,
        'exercises': exercises.map((e) => e.toJson()).toList(),
      };
}
