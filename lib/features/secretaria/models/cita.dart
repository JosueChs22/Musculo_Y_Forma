class ClienteCita {
  const ClienteCita({
    required this.id,
    required this.nombreCompleto,
    required this.carne,
    required this.cedula,
    required this.correo,
    required this.estado,
  });

  final String id;
  final String nombreCompleto;
  final String carne;
  final String cedula;
  final String correo;
  final String estado;

  factory ClienteCita.fromJson(Map<String, dynamic> json) => ClienteCita(
        id: json['id'] as String,
        nombreCompleto: json['nombreCompleto'] as String,
        carne: json['carne'] as String,
        cedula: json['cedula'] as String,
        correo: json['correo'] as String,
        estado: json['estado'] as String,
      );
}

class EntrenadorCita {
  const EntrenadorCita({
    required this.id,
    required this.nombreCompleto,
  });

  final String id;
  final String nombreCompleto;

  factory EntrenadorCita.fromJson(Map<String, dynamic> json) => EntrenadorCita(
        id: json['id'] as String,
        nombreCompleto: json['nombreCompleto'] as String,
      );
}

class CitaAgendada {
  const CitaAgendada({
    required this.id,
    required this.idCliente,
    required this.idCoach,
    required this.fechaHora,
    required this.estado,
  });

  final String id;
  final String idCliente;
  final String idCoach;
  final DateTime fechaHora;
  final String estado;

  factory CitaAgendada.fromJson(Map<String, dynamic> json) => CitaAgendada(
        id: json['id'] as String,
        idCliente: json['idCliente'] as String,
        idCoach: json['idCoach'] as String,
        fechaHora: DateTime.parse(json['fechaHora'] as String),
        estado: json['estado'] as String,
      );
}

class CitaConsulta {
  const CitaConsulta({
    required this.id,
    required this.idCliente,
    required this.clienteNombreCompleto,
    required this.carne,
    required this.idCoach,
    required this.entrenadorNombreCompleto,
    required this.fechaHora,
    required this.estado,
  });

  final String id;
  final String idCliente;
  final String clienteNombreCompleto;
  final String carne;
  final String idCoach;
  final String entrenadorNombreCompleto;
  final DateTime fechaHora;
  final String estado;

  factory CitaConsulta.fromJson(Map<String, dynamic> json) => CitaConsulta(
        id: json['id'] as String,
        idCliente: json['idCliente'] as String,
        clienteNombreCompleto: json['clienteNombreCompleto'] as String,
        carne: json['carne'] as String,
        idCoach: json['idCoach'] as String,
        entrenadorNombreCompleto: json['entrenadorNombreCompleto'] as String,
        fechaHora: DateTime.parse(json['fechaHora'] as String),
        estado: json['estado'] as String,
      );

  CitaConsulta copyWith({String? estado}) => CitaConsulta(
        id: id,
        idCliente: idCliente,
        clienteNombreCompleto: clienteNombreCompleto,
        carne: carne,
        idCoach: idCoach,
        entrenadorNombreCompleto: entrenadorNombreCompleto,
        fechaHora: fechaHora,
        estado: estado ?? this.estado,
      );
}
