enum EstadoUsuario {
  activo('Activo'),
  inhabilitado('Inhabilitado');

  const EstadoUsuario(this.valor);
  final String valor;

  static EstadoUsuario desdeTexto(String t) => values.firstWhere(
        (e) => e.valor == t,
        orElse: () => throw FormatException('Estado no válido: $t'),
      );
}

enum RolUsuario {
  administrador('Administrador'),
  secretaria('Secretaria'),
  entrenador('Entrenador'),
  cliente('Cliente');

  const RolUsuario(this.valor);
  final String valor;

  static RolUsuario desdeTexto(String t) => values.firstWhere(
        (e) => e.valor == t,
        orElse: () => throw FormatException('Rol no válido: $t'),
      );
}

/// Usuario tal como lo devuelve la API (DTO en camelCase). Sin contraseña.
class Usuario {
  const Usuario({
    required this.id,
    required this.rol,
    required this.nombre,
    required this.primerApellido,
    this.segundoApellido,
    required this.correo,
    required this.telefono,
    required this.usuario,
    required this.estado,
    required this.fechaIngreso,
    this.ultimoLogin,
  });

  final String id;
  final RolUsuario rol;
  final String nombre;
  final String primerApellido;
  final String? segundoApellido;
  final String correo;
  final String telefono;
  final String usuario;
  final EstadoUsuario estado;
  final DateTime fechaIngreso;
  final DateTime? ultimoLogin;

  bool get estaActivo => estado == EstadoUsuario.activo;

  String get nombreCompleto => [nombre, primerApellido, segundoApellido]
      .whereType<String>()
      .where((s) => s.isNotEmpty)
      .join(' ');

  factory Usuario.fromJson(Map<String, dynamic> json) => Usuario(
        id: json['id'] as String,
        rol: RolUsuario.desdeTexto(json['rol'] as String),
        nombre: json['nombre'] as String,
        primerApellido: json['primerApellido'] as String,
        segundoApellido: json['segundoApellido'] as String?,
        correo: json['correo'] as String,
        telefono: json['telefono'] as String,
        usuario: json['usuario'] as String,
        estado: EstadoUsuario.desdeTexto(json['estado'] as String),
        fechaIngreso: DateTime.parse(json['fechaIngreso'] as String),
        ultimoLogin: json['ultimoLogin'] == null
            ? null
            : DateTime.parse(json['ultimoLogin'] as String),
      );

  Usuario copyWith({
    RolUsuario? rol,
    String? nombre,
    String? primerApellido,
    String? segundoApellido,
    String? correo,
    String? telefono,
    EstadoUsuario? estado,
  }) =>
      Usuario(
        id: id,
        rol: rol ?? this.rol,
        nombre: nombre ?? this.nombre,
        primerApellido: primerApellido ?? this.primerApellido,
        segundoApellido: segundoApellido ?? this.segundoApellido,
        correo: correo ?? this.correo,
        telefono: telefono ?? this.telefono,
        usuario: usuario,
        estado: estado ?? this.estado,
        fechaIngreso: fechaIngreso,
        ultimoLogin: ultimoLogin,
      );
}
