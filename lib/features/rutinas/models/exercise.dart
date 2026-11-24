/// Ejercicio dentro de una rutina asignada.
class Exercise {
  const Exercise({
    this.id = '',
    required this.name,
    required this.sets,
    required this.reps,
    required this.restSeconds,
    this.coachNote = '',
    this.pesoSugerido,
    this.grupoMuscular,
    this.instrucciones,
    this.herramienta,
    this.imageUrl,
    this.gifUrl,
  });

  final String id;
  final String name;
  final int sets;
  final String reps;
  final int restSeconds;

  /// Nota del coach ('' si no hay).
  final String coachNote;

  /// Kilogramos (opcional).
  final num? pesoSugerido;
  final String? grupoMuscular;
  final String? instrucciones;
  final String? herramienta;

  /// Miniatura y animación del catálogo (pueden faltar).
  final String? imageUrl;
  final String? gifUrl;

  String get setsLabel => '$sets series';
  String get restLabel => '$restSeconds s descanso';
  String? get pesoLabel => pesoSugerido == null ? null : '$pesoSugerido kg sugeridos';
  String get summary => '$setsLabel · $reps · $restLabel';

  /// Lectura tolerante del ejercicio de un plan (GET /mi/rutinas): los campos
  /// opcionales pueden faltar o venir con otro nombre.
  factory Exercise.fromJson(Map<String, dynamic> j) {
    String? texto(List<String> claves) {
      for (final k in claves) {
        final v = j[k];
        if (v is String && v.trim().isNotEmpty) return v.trim();
      }
      return null;
    }

    int entero(String k, int porDefecto) {
      final v = j[k];
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? porDefecto;
      return porDefecto;
    }

    final rep = j['repeticiones'];
    final peso = j['pesoSugerido'] ?? j['peso_sugerido'];
    return Exercise(
      id: texto(['idEjercicio', 'id', 'id_ejercicio']) ?? '',
      name: texto(['nombre']) ?? 'Ejercicio',
      sets: entero('series', 0),
      reps: rep is num ? '${rep.toInt()} repeticiones' : (rep is String && rep.isNotEmpty ? rep : '—'),
      restSeconds: entero('descanso', 0),
      coachNote: texto(['nota']) ?? '',
      pesoSugerido: peso is num ? peso : (peso is String ? num.tryParse(peso) : null),
      grupoMuscular: texto(['grupoMuscular', 'grupo', 'grupo_muscular']),
      herramienta: texto(['herramienta']),
      instrucciones: texto(['instrucciones', 'descripcion']),
      imageUrl: texto(['imagen', 'imagenUrl']),
      gifUrl: texto(['gif', 'gifUrl']),
    );
  }
}
