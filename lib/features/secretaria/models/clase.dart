import 'horario_clase.dart';

/// Clase del gimnasio. Refleja la colección `clases` de MongoDB.
class Clase {
  const Clase({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.instructores,
    required this.estado,
    this.fechaActualizacion,
    required this.horarios,
  });

  final String id;
  final String nombre;
  final String? descripcion;

  /// IDs de instructores (ObjectId como String).
  final List<String> instructores;

  /// "Activo" | "Inhabilitada"
  final String estado;

  final DateTime? fechaActualizacion;
  final List<HorarioClase> horarios;

  bool get activa => estado == 'Activo';

  List<HorarioClase> get horariosActivos =>
      horarios.where((h) => h.activo).toList();

  factory Clase.fromJson(Map<String, dynamic> json) => Clase(
        // API devuelve 'id'; BD devuelve '_id'
        id: (json['id'] ?? json['_id']) as String,
        nombre: json['nombre'] as String,
        descripcion: json['descripcion'] as String?,
        instructores: List<String>.from(json['instructores'] as List? ?? []),
        estado: json['estado'] as String,
        fechaActualizacion: json['fechaActualizacion'] == null && json['fecha_actualizacion'] == null
            ? null
            : DateTime.parse((json['fechaActualizacion'] ?? json['fecha_actualizacion']) as String),
        horarios: (json['horarios'] as List? ?? [])
            .map((h) => HorarioClase.fromJson(h as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        '_id': id,
        'nombre': nombre,
        'descripcion': descripcion,
        'instructores': instructores,
        'estado': estado,
        'fecha_actualizacion': fechaActualizacion?.toIso8601String(),
        'horarios': horarios.map((h) => h.toJson()).toList(),
      };

  Clase copyWith({
    String? nombre,
    String? descripcion,
    List<String>? instructores,
    String? estado,
    DateTime? fechaActualizacion,
    List<HorarioClase>? horarios,
  }) =>
      Clase(
        id: id,
        nombre: nombre ?? this.nombre,
        descripcion: descripcion ?? this.descripcion,
        instructores: instructores ?? this.instructores,
        estado: estado ?? this.estado,
        fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
        horarios: horarios ?? this.horarios,
      );
}
