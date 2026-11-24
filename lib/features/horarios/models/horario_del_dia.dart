/// Una clase en un día concreto de la semana (RF-095). Valor derivado de
/// `Clase` + `HorarioClase` (secretaria/models), listo para pintar.
class SesionClase {
  const SesionClase({
    required this.idClase,
    required this.nombre,
    this.descripcion,
    required this.horaInicio,
    required this.horaFin,
  });

  final String idClase;
  final String nombre;
  final String? descripcion;

  /// "HH:MM" (24 h).
  final String horaInicio;
  final String horaFin;

  String get rangoHora => '$horaInicio – $horaFin';
}

/// Clases de un día de la semana, ordenadas por hora de inicio.
class HorarioDelDia {
  const HorarioDelDia({required this.dia, required this.sesiones});

  /// 1 = lunes … 7 = domingo.
  final int dia;
  final List<SesionClase> sesiones;

  static const nombres = ['', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];

  String get nombre => nombres[dia];
}
