/// Grupos musculares admitidos por la API.
const gruposMusculares = [
  'Pecho',
  'Espalda',
  'Hombros',
  'Brazos',
  'Antebrazos',
  'Abdomen',
  'Muslos',
  'Pantorrillas',
  'Cardio',
  'Cuello',
];

/// Tipos de ejercicio disponibles.
const tiposEjercicio = [
  'entrenamiento',
  'calentamiento',
  'estiramiento',
];

String etiquetaTipoEjercicio(String tipo) {
  switch (tipo) {
    case 'calentamiento':
      return 'Calentamiento';
    case 'estiramiento':
      return 'Estiramiento';
    default:
      return 'Entrenamiento';
  }
}

/// Ejercicio del catálogo recibido desde la API.
class Ejercicio {
  const Ejercicio({
    required this.id,
    required this.nombre,
    this.tipo = 'entrenamiento',
    this.grupoMuscular,
    this.herramienta,
    this.imagenUrl,
    this.gifUrl,
    this.numeroMaquina,
    this.tiempoRecomendado,
    this.instrucciones,
    this.observaciones,
    this.recomendaciones,
    required this.activo,
  });

  final String id;
  final String nombre;
  final String tipo;
  final String? grupoMuscular;
  final String? herramienta;
  final String? imagenUrl;
  final String? gifUrl;
  final num? numeroMaquina;
  final num? tiempoRecomendado;
  final String? instrucciones;
  final String? observaciones;
  final String? recomendaciones;
  final bool activo;

  String get estado => activo ? 'Activo' : 'Inhabilitado';

  String get tipoEtiqueta => etiquetaTipoEjercicio(tipo);

  bool get esEstiramiento => tipo == 'estiramiento';

  bool get esCalentamiento => tipo == 'calentamiento';

  String get resumen => [
        grupoMuscular,
        herramienta,
        if (tiempoRecomendado != null) '$tiempoRecomendado min',
      ].whereType<String>().join(' · ');

  factory Ejercicio.fromJson(
    Map<String, dynamic> json,
  ) {
    return Ejercicio(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      tipo: json['tipo'] as String? ?? 'entrenamiento',
      grupoMuscular: json['grupoMuscular'] as String?,
      herramienta: json['herramienta'] as String?,
      imagenUrl: json['imagen'] as String?,
      gifUrl: json['gif'] as String?,
      numeroMaquina: json['numeroMaquina'] as num?,
      tiempoRecomendado: json['tiempoRecomendado'] as num?,
      instrucciones: json['instrucciones'] as String?,
      observaciones: json['observaciones'] as String?,
      recomendaciones: json['recomendaciones'] as String?,
      activo: json['estado'] == 'Activo',
    );
  }

  Ejercicio conEstado({
    required bool activo,
  }) {
    return Ejercicio(
      id: id,
      nombre: nombre,
      tipo: tipo,
      grupoMuscular: grupoMuscular,
      herramienta: herramienta,
      imagenUrl: imagenUrl,
      gifUrl: gifUrl,
      numeroMaquina: numeroMaquina,
      tiempoRecomendado: tiempoRecomendado,
      instrucciones: instrucciones,
      observaciones: observaciones,
      recomendaciones: recomendaciones,
      activo: activo,
    );
  }
}

/// Datos enviados al crear o actualizar ejercicios.
class DatosEjercicio {
  const DatosEjercicio({
    required this.nombre,
    this.tipo,
    this.grupoMuscular,
    this.herramienta,
    this.numeroMaquina,
    this.tiempoRecomendado,
    this.instrucciones,
    this.observaciones,
    this.recomendaciones,
  });

  final String nombre;

  /// Opcional para conservar compatibilidad
  /// con formularios existentes.
  final String? tipo;

  final String? grupoMuscular;
  final String? herramienta;
  final num? numeroMaquina;
  final num? tiempoRecomendado;
  final String? instrucciones;
  final String? observaciones;
  final String? recomendaciones;

  static String? _limpio(String? valor) {
    if (valor == null || valor.trim().isEmpty) {
      return null;
    }

    return valor.trim();
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre.trim(),

      // Solo se envía cuando la pantalla
      // especifica el tipo.
      if (tipo != null) 'tipo': tipo,

      'grupo_muscular': _limpio(grupoMuscular),
      'herramienta': _limpio(herramienta),
      if (numeroMaquina != null) 'numero_maquina': numeroMaquina,
      'tiempo_recomendado': tiempoRecomendado,
      'instrucciones': _limpio(instrucciones),
      'observaciones': _limpio(observaciones),
      'recomendaciones': _limpio(recomendaciones),
    };
  }
}

/// Respuesta paginada de ejercicios.
class PaginaEjercicios {
  const PaginaEjercicios(
    this.items,
    this.siguiente,
  );

  final List<Ejercicio> items;
  final String? siguiente;
}
