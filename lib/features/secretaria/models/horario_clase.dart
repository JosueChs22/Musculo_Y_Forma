/// Horario embebido dentro de una Clase.
/// Refleja el subdocumento de MongoDB que devuelve GYM-API.
class HorarioClase {
  const HorarioClase({
    required this.dias,
    required this.horaInicio,
    required this.horaFin,
    required this.estado,
    this.fechaInicio,
    this.fechaFin,
  });

  /// Días de la semana: 1 = lunes ... 7 = domingo.
  final List<int> dias;

  /// Formato HH:mm (24 horas).
  final String horaInicio;
  final String horaFin;

  /// Formato YYYY-MM-DD. Null cuando no hay fecha definida.
  final String? fechaInicio;
  final String? fechaFin;

  /// Activo | Inhabilitado.
  final String estado;

  bool get activo => estado == 'Activo';

  String get diasLabel {
    const nombres = [
      '',
      'Lun',
      'Mar',
      'Mié',
      'Jue',
      'Vie',
      'Sáb',
      'Dom',
    ];

    return dias.map((d) => nombres[d]).join(', ');
  }

  String get rangoHora => '$horaInicio – $horaFin';

  factory HorarioClase.fromJson(Map<String, dynamic> json) {
    return HorarioClase(
      dias: List<int>.from(json['dias'] as List),
      horaInicio: (json['horaInicio'] ?? json['hora_inicio']) as String,
      horaFin: (json['horaFin'] ?? json['hora_fin']) as String,
      fechaInicio: (json['fechaInicio'] ?? json['fecha_inicio']) as String?,
      fechaFin: (json['fechaFin'] ?? json['fecha_fin']) as String?,
      estado: json['estado'] as String,
    );
  }

  /// Datos que se envían al backend.
  /// No enviamos estado porque lo administra GYM-API.
  Map<String, dynamic> toJson() => {
        'dias': dias,
        'hora_inicio': horaInicio,
        'hora_fin': horaFin,
        if (fechaInicio != null) 'fecha_inicio': fechaInicio,
        if (fechaFin != null) 'fecha_fin': fechaFin,
      };

  HorarioClase copyWith({
    List<int>? dias,
    String? horaInicio,
    String? horaFin,
    String? fechaInicio,
    String? fechaFin,
    String? estado,
  }) {
    return HorarioClase(
      dias: dias ?? this.dias,
      horaInicio: horaInicio ?? this.horaInicio,
      horaFin: horaFin ?? this.horaFin,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFin: fechaFin ?? this.fechaFin,
      estado: estado ?? this.estado,
    );
  }
}
