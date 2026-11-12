/// Qué tipo de sesión es el plan. Es del plan, no de cada ejercicio: un
/// calentamiento y un entrenamiento se arman con los mismos ejercicios del catálogo.
enum CategoriaPlan {
  entrenamiento('entrenamiento', 'Entrenamiento'),
  calentamiento('calentamiento', 'Calentamiento'),
  estiramiento('estiramiento', 'Estiramiento');

  const CategoriaPlan(this.valor, this.etiqueta);

  /// Como lo guarda la API.
  final String valor;

  /// Como se le muestra al usuario.
  final String etiqueta;

  static CategoriaPlan desdeTexto(String t) => values.firstWhere(
        (e) => e.valor == t,
        orElse: () => throw FormatException('Categoría de plan no válida: $t'),
      );
}

/// Día de la semana de un plan: 1 = lunes … 7 = domingo.
const diasSemana = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];

/// Cliente al que se asigna un plan (solo lo necesario para mostrarlo y elegirlo).
class UsuarioResumen {
  const UsuarioResumen({required this.id, required this.nombre, required this.usuario});

  final String id;
  final String nombre;
  final String usuario;

  String get iniciales {
    final partes = nombre.split(' ').where((p) => p.isNotEmpty).take(2);
    return partes.map((p) => p[0]).join().toUpperCase();
  }

  factory UsuarioResumen.fromJson(Map<String, dynamic> json) => UsuarioResumen(
        id: json['id'] as String,
        nombre: json['nombre'] as String,
        usuario: json['usuario'] as String,
      );
}

/// Un ejercicio dentro de un plan, con su dosificación.
class PlanEjercicio {
  const PlanEjercicio({
    required this.idEjercicio,
    required this.nombre,
    this.imagenUrl,
    this.gifUrl,
    this.grupoMuscular,
    this.activo = true,
    this.series = 3,
    this.repeticiones = 10,
    this.descanso = 60,
    this.pesoSugerido,
    this.nota,
  });

  final String idEjercicio;
  final String nombre;
  final String? imagenUrl;
  final String? gifUrl;
  final String? grupoMuscular;

  /// false si el ejercicio se inhabilitó después de armar el plan.
  final bool activo;
  final int series;
  final int repeticiones;

  /// Segundos.
  final int descanso;

  /// Kilogramos.
  final num? pesoSugerido;
  final String? nota;

  String get resumen => '$series series · $repeticiones reps · $descanso s de descanso';

  factory PlanEjercicio.fromJson(Map<String, dynamic> json) => PlanEjercicio(
        idEjercicio: json['idEjercicio'] as String,
        nombre: json['nombre'] as String,
        imagenUrl: json['imagen'] as String?,
        gifUrl: json['gif'] as String?,
        grupoMuscular: json['grupoMuscular'] as String?,
        activo: json['activo'] as bool? ?? true,
        series: (json['series'] as num).toInt(),
        repeticiones: (json['repeticiones'] as num).toInt(),
        descanso: (json['descanso'] as num).toInt(),
        pesoSugerido: json['pesoSugerido'] as num?,
        nota: json['nota'] as String?,
      );

  /// Cuerpo de la petición, en snake_case como pide la API.
  Map<String, dynamic> toJson() => {
        'id_ejercicio': idEjercicio,
        'series': series,
        'repeticiones': repeticiones,
        'descanso': descanso,
        'peso_sugerido': pesoSugerido,
        'nota': (nota == null || nota!.trim().isEmpty) ? null : nota!.trim(),
      };

  PlanEjercicio copyWith({
    int? series,
    int? repeticiones,
    int? descanso,
    num? pesoSugerido,
    bool quitarPeso = false,
    String? nota,
  }) =>
      PlanEjercicio(
        idEjercicio: idEjercicio,
        nombre: nombre,
        imagenUrl: imagenUrl,
        gifUrl: gifUrl,
        grupoMuscular: grupoMuscular,
        activo: activo,
        series: series ?? this.series,
        repeticiones: repeticiones ?? this.repeticiones,
        descanso: descanso ?? this.descanso,
        pesoSugerido: quitarPeso ? null : (pesoSugerido ?? this.pesoSugerido),
        nota: nota ?? this.nota,
      );
}

/// Plan de entrenamiento (rutina) del entrenador, asignado o no a un cliente.
class Plan {
  const Plan({
    required this.id,
    required this.nombre,
    required this.categoria,
    this.observaciones,
    this.diaSemana,
    required this.activo,
    this.usuario,
    required this.totalEjercicios,
    this.ejercicios = const [],
  });

  final String id;
  final String nombre;
  final CategoriaPlan categoria;
  final String? observaciones;
  final int? diaSemana;
  final bool activo;
  final UsuarioResumen? usuario;
  final int totalEjercicios;

  /// Solo viene en el detalle; en las listas está vacía y se usa [totalEjercicios].
  final List<PlanEjercicio> ejercicios;

  String? get dia => diaSemana == null ? null : diasSemana[diaSemana! - 1];

  factory Plan.fromJson(Map<String, dynamic> json) => Plan(
        id: json['id'] as String,
        nombre: json['nombre'] as String,
        categoria: CategoriaPlan.desdeTexto(json['categoria'] as String),
        observaciones: json['observaciones'] as String?,
        diaSemana: (json['diaSemana'] as num?)?.toInt(),
        activo: json['estado'] == 'Activo',
        usuario: json['usuario'] == null ? null : UsuarioResumen.fromJson(json['usuario'] as Map<String, dynamic>),
        totalEjercicios: (json['totalEjercicios'] as num).toInt(),
        ejercicios: (json['ejercicios'] as List? ?? [])
            .map((e) => PlanEjercicio.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Plan copyWith({bool? activo, UsuarioResumen? usuario, bool quitarUsuario = false}) => Plan(
        id: id,
        nombre: nombre,
        categoria: categoria,
        observaciones: observaciones,
        diaSemana: diaSemana,
        activo: activo ?? this.activo,
        usuario: quitarUsuario ? null : (usuario ?? this.usuario),
        totalEjercicios: totalEjercicios,
        ejercicios: ejercicios,
      );
}

/// Lo que el entrenador llena al crear o actualizar un plan.
class DatosPlan {
  const DatosPlan({
    required this.nombre,
    required this.categoria,
    this.observaciones,
    this.diaSemana,
    required this.ejercicios,
  });

  final String nombre;
  final CategoriaPlan categoria;
  final String? observaciones;
  final int? diaSemana;
  final List<PlanEjercicio> ejercicios;

  /// Cuerpo de la petición, en snake_case como pide la API.
  Map<String, dynamic> toJson() => {
        'nombre': nombre.trim(),
        'categoria': categoria.valor,
        'observaciones': (observaciones == null || observaciones!.trim().isEmpty) ? null : observaciones!.trim(),
        'dia_semana': diaSemana,
        'ejercicios': [for (final e in ejercicios) e.toJson()],
      };
}

/// Una página de planes. [siguiente] es null cuando ya no hay más.
class PaginaPlanes {
  const PaginaPlanes(this.items, this.siguiente);
  final List<Plan> items;
  final String? siguiente;
}

/// Una página de clientes. [siguiente] es null cuando ya no hay más.
class PaginaClientes {
  const PaginaClientes(this.items, this.siguiente);
  final List<UsuarioResumen> items;
  final String? siguiente;
}
