/// Horario embebido dentro de una Clase. Refleja el subdocumento de MongoDB.
class HorarioClase {
  const HorarioClase({
    required this.dias,
    required this.horaInicio,
    required this.horaFin,
    required this.estado,
  });

  /// Días de la semana: 1 = lunes … 7 = domingo.
  final List<int> dias;

  /// Formato "HH:MM" (24 h).
  final String horaInicio;
  final String horaFin;

  /// "Activo" | "Inhabilitado"
  final String estado;

  bool get activo => estado == 'Activo';

  String get diasLabel {
    const nombres = ['', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    return dias.map((d) => nombres[d]).join(', ');
  }

  String get rangoHora => '$horaInicio – $horaFin';

  factory HorarioClase.fromJson(Map<String, dynamic> json) => HorarioClase(
        dias: List<int>.from(json['dias'] as List),
        horaInicio: json['hora_inicio'] as String,
        horaFin: json['hora_fin'] as String,
        estado: json['estado'] as String,
      );

  Map<String, dynamic> toJson() => {
        'dias': dias,
        'hora_inicio': horaInicio,
        'hora_fin': horaFin,
        'estado': estado,
      };

  HorarioClase copyWith({
    List<int>? dias,
    String? horaInicio,
    String? horaFin,
    String? estado,
  }) =>
      HorarioClase(
        dias: dias ?? this.dias,
        horaInicio: horaInicio ?? this.horaInicio,
        horaFin: horaFin ?? this.horaFin,
        estado: estado ?? this.estado,
      );
}
