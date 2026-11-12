/// Partes del cuerpo con las que se clasifica el catálogo (las mismas que valida la API).
const gruposMusculares = [
  'Pecho', 'Espalda', 'Hombros', 'Brazos', 'Antebrazos', 'Abdomen',
  'Muslos', 'Pantorrillas', 'Cardio', 'Cuello',
];

/// Ejercicio del catálogo tal como lo devuelve la API (DTO en camelCase).
class Ejercicio {
  const Ejercicio({
    required this.id,
    required this.nombre,
    this.grupoMuscular,
    this.herramienta,
    this.imagenUrl,
    this.gifUrl,
    this.tiempoRecomendado,
    this.instrucciones,
    this.observaciones,
    this.recomendaciones,
    required this.activo,
  });

  final String id;
  final String nombre;
  final String? grupoMuscular;
  final String? herramienta;

  /// Miniatura estática (para listas) y animación (para el detalle).
  final String? imagenUrl;
  final String? gifUrl;

  /// En minutos.
  final num? tiempoRecomendado;
  final String? instrucciones;
  final String? observaciones;
  final String? recomendaciones;
  final bool activo;

  String get estado => activo ? 'Activo' : 'Inhabilitado';

  /// "Cuádriceps · Barra · 5 min", solo con los datos que existan.
  String get resumen => [
        grupoMuscular,
        herramienta,
        if (tiempoRecomendado != null) '$tiempoRecomendado min',
      ].whereType<String>().join(' · ');

  factory Ejercicio.fromJson(Map<String, dynamic> json) => Ejercicio(
        id: json['id'] as String,
        nombre: json['nombre'] as String,
        grupoMuscular: json['grupoMuscular'] as String?,
        herramienta: json['herramienta'] as String?,
        imagenUrl: json['imagen'] as String?,
        gifUrl: json['gif'] as String?,
        tiempoRecomendado: json['tiempoRecomendado'] as num?,
        instrucciones: json['instrucciones'] as String?,
        observaciones: json['observaciones'] as String?,
        recomendaciones: json['recomendaciones'] as String?,
        activo: json['estado'] == 'Activo',
      );

  Ejercicio conEstado({required bool activo}) => Ejercicio(
        id: id,
        nombre: nombre,
        grupoMuscular: grupoMuscular,
        herramienta: herramienta,
        imagenUrl: imagenUrl,
        gifUrl: gifUrl,
        tiempoRecomendado: tiempoRecomendado,
        instrucciones: instrucciones,
        observaciones: observaciones,
        recomendaciones: recomendaciones,
        activo: activo,
      );
}

/// Lo que el entrenador llena en el formulario para crear o actualizar.
class DatosEjercicio {
  const DatosEjercicio({
    required this.nombre,
    this.grupoMuscular,
    this.herramienta,
    this.tiempoRecomendado,
    this.instrucciones,
    this.observaciones,
    this.recomendaciones,
  });

  final String nombre;
  final String? grupoMuscular;
  final String? herramienta;
  final num? tiempoRecomendado;
  final String? instrucciones;
  final String? observaciones;
  final String? recomendaciones;

  static String? _limpio(String? v) => (v == null || v.trim().isEmpty) ? null : v.trim();

  /// Cuerpo de la petición, en snake_case como pide la API.
  Map<String, dynamic> toJson() => {
        'nombre': nombre.trim(),
        'grupo_muscular': _limpio(grupoMuscular),
        'herramienta': _limpio(herramienta),
        'tiempo_recomendado': tiempoRecomendado,
        'instrucciones': _limpio(instrucciones),
        'observaciones': _limpio(observaciones),
        'recomendaciones': _limpio(recomendaciones),
      };
}

/// Una página del catálogo. [siguiente] es null cuando ya no hay más.
class PaginaEjercicios {
  const PaginaEjercicios(this.items, this.siguiente);
  final List<Ejercicio> items;
  final String? siguiente;
}
