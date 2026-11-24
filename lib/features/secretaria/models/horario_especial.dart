/// Horario especial del gimnasio.
/// Compatible con el DTO de GYM-API.
class HorarioEspecial {
  const HorarioEspecial({
    this.id = '',
    required this.motivo,
    required this.fecha,
    required this.cierreTotal,
    this.estado = 'Activo',
    this.horaApertura,
    this.horaCierre,
    this.observaciones,
    this.fechaCreacion,
    this.fechaActualizacion,
  });

  final String id;
  final String motivo;

  /// Fecha del horario especial en formato YYYY-MM-DD.
  final String fecha;

  /// Horas en formato HH:mm.
  /// Son nulas cuando existe cierre total.
  final String? horaApertura;
  final String? horaCierre;

  final bool cierreTotal;
  final String? observaciones;

  /// Activo | Inhabilitado.
  final String estado;

  final DateTime? fechaCreacion;
  final DateTime? fechaActualizacion;

  bool get activo => estado == 'Activo';

  String get descripcionHorario {
    if (cierreTotal) {
      return 'Cierre total';
    }

    return '${horaApertura ?? '--:--'} - ${horaCierre ?? '--:--'}';
  }

  factory HorarioEspecial.fromJson(Map<String, dynamic> json) {
    return HorarioEspecial(
      id: json['id'] as String,
      motivo: json['motivo'] as String,
      fecha: json['fecha'] as String,
      horaApertura: json['horaApertura'] as String?,
      horaCierre: json['horaCierre'] as String?,
      cierreTotal: json['cierreTotal'] as bool,
      observaciones: json['observaciones'] as String?,
      estado: json['estado'] as String,
      fechaCreacion: _parseFecha(json['fechaCreacion']),
      fechaActualizacion: _parseFecha(json['fechaActualizacion']),
    );
  }

  static DateTime? _parseFecha(dynamic valor) {
    if (valor == null) return null;
    return DateTime.tryParse(valor.toString());
  }

  /// Cuerpo para crear o actualizar un horario especial.
  /// Utiliza los nombres esperados por GYM-API.
  Map<String, dynamic> toJson() {
    return {
      'motivo': motivo,
      'fecha': fecha,
      'cierre_total': cierreTotal,
      'hora_apertura': cierreTotal ? null : horaApertura,
      'hora_cierre': cierreTotal ? null : horaCierre,
      'observaciones': observaciones,
    };
  }
}
