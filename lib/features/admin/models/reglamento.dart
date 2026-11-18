enum EstadoReglamento {
  activo('Activo'),
  inhabilitado('Inhabilitado');

  const EstadoReglamento(this.valor);
  final String valor;

  static EstadoReglamento desdeTexto(String t) => values.firstWhere(
        (e) => e.valor == t,
        orElse: () => throw FormatException('Estado no válido: $t'),
      );
}

/// Reglamento del gimnasio tal como lo devuelve la API (DTO en camelCase).
class Reglamento {
  const Reglamento({
    required this.id,
    required this.titulo,
    required this.contenido,
    required this.estado,
    required this.fechaCreacion,
    this.fechaActualizacion,
    this.fechaInhabilitacion,
  });

  final String id;
  final String titulo;
  final String contenido;
  final EstadoReglamento estado;
  final DateTime fechaCreacion;
  final DateTime? fechaActualizacion;
  final DateTime? fechaInhabilitacion;

  bool get estaActivo => estado == EstadoReglamento.activo;

  factory Reglamento.fromJson(Map<String, dynamic> json) => Reglamento(
        id: json['id'] as String,
        titulo: json['titulo'] as String,
        contenido: json['contenido'] as String,
        estado: EstadoReglamento.desdeTexto(json['estado'] as String),
        fechaCreacion: DateTime.parse(json['fechaCreacion'] as String),
        fechaActualizacion: json['fechaActualizacion'] == null
            ? null
            : DateTime.parse(json['fechaActualizacion'] as String),
        fechaInhabilitacion: json['fechaInhabilitacion'] == null
            ? null
            : DateTime.parse(json['fechaInhabilitacion'] as String),
      );

  Reglamento copyWith({EstadoReglamento? estado}) => Reglamento(
        id: id,
        titulo: titulo,
        contenido: contenido,
        estado: estado ?? this.estado,
        fechaCreacion: fechaCreacion,
        fechaActualizacion: fechaActualizacion,
        fechaInhabilitacion: fechaInhabilitacion,
      );
}
