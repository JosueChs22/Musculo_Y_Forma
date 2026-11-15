enum EstadoCliente {
  activo('Activo'),
  inhabilitado('Inhabilitado');

  const EstadoCliente(this.valor);
  final String valor;

  static EstadoCliente desdeTexto(String texto) => values.firstWhere(
        (estado) => estado.valor == texto,
        orElse: () => throw FormatException('Estado no válido: $texto'),
      );
}

class Cliente {
  const Cliente({
    required this.id,
    required this.nombre,
    required this.primerApellido,
    required this.segundoApellido,
    required this.correo,
    required this.cedula,
    required this.telefono,
    required this.carne,
    required this.estado,
    required this.fechaIngreso,
  });

  final String id;
  final String nombre;
  final String primerApellido;
  final String segundoApellido;
  final String correo;
  final String cedula;
  final String telefono;
  final String carne;
  final EstadoCliente estado;
  final DateTime fechaIngreso;

  String get nombreCompleto => [nombre, primerApellido, segundoApellido]
      .where((parte) => parte.isNotEmpty)
      .join(' ');

  Cliente copyWith({
    String? nombre,
    String? primerApellido,
    String? segundoApellido,
    String? correo,
    String? cedula,
    String? telefono,
    String? carne,
    EstadoCliente? estado,
    DateTime? fechaIngreso,
  }) =>
      Cliente(
        id: id,
        nombre: nombre ?? this.nombre,
        primerApellido: primerApellido ?? this.primerApellido,
        segundoApellido: segundoApellido ?? this.segundoApellido,
        correo: correo ?? this.correo,
        cedula: cedula ?? this.cedula,
        telefono: telefono ?? this.telefono,
        carne: carne ?? this.carne,
        estado: estado ?? this.estado,
        fechaIngreso: fechaIngreso ?? this.fechaIngreso,
      );

  factory Cliente.fromJson(Map<String, dynamic> json) => Cliente(
        id: json['id'] as String,
        nombre: json['nombre'] as String,
        primerApellido: json['primerApellido'] as String,
        segundoApellido: json['segundoApellido'] as String? ?? '',
        correo: json['correo'] as String,
        cedula: json['cedula'] as String? ?? '',
        telefono: json['telefono'] as String,
        carne: json['carne'] as String,
        estado: EstadoCliente.desdeTexto(json['estado'] as String),
        fechaIngreso: DateTime.parse(json['fechaIngreso'] as String),
      );
}

class PaginaClientes {
  const PaginaClientes(this.items, this.nextCursor);

  final List<Cliente> items;
  final String? nextCursor;
}
