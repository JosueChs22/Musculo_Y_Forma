enum EstadoUsuario {
  activo('Activo'),
  inhabilitado('Inhabilitado');

  const EstadoUsuario(this.valor);
  final String valor;

  static EstadoUsuario desdeTexto(String texto) => values.firstWhere(
        (e) => e.valor == texto,
        orElse: () => throw FormatException('Estado no válido: $texto'),
      );
}

enum RolUsuario {
  administrador('Administrador'),
  secretaria('Secretaria'),
  entrenador('Entrenador'),
  cliente('Cliente');

  const RolUsuario(this.valor);
  final String valor;

  static RolUsuario desdeTexto(String texto) => values.firstWhere(
        (e) => e.valor == texto,
        orElse: () => throw FormatException('Rol no válido: $texto'),
      );
}

class Usuario {
  const Usuario({
    this.id,
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

  final String? id;
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
        id: json['_id'] as String?,
        rol: RolUsuario.desdeTexto(json['rol'] as String),
        nombre: json['nombre'] as String,
        primerApellido: json['primer_apellido'] as String,
        segundoApellido: json['segundo_apellido'] as String?,
        correo: json['correo'] as String,
        telefono: json['telefono'] as String,
        usuario: json['usuario'] as String,
        estado: EstadoUsuario.desdeTexto(json['estado'] as String),
        fechaIngreso: DateTime.parse(json['fecha_ingreso'] as String).toLocal(),
        ultimoLogin: json['ultimo_login'] == null
            ? null
            : DateTime.parse(json['ultimo_login'] as String).toLocal(),
      );

  Map<String, dynamic> toJson() => {
        if (id != null) '_id': id,
        'rol': rol.valor,
        'nombre': nombre,
        'primer_apellido': primerApellido,
        if (segundoApellido != null) 'segundo_apellido': segundoApellido,
        'correo': correo,
        'telefono': telefono,
        'usuario': usuario,
        'estado': estado.valor,
        'fecha_ingreso': fechaIngreso.toUtc().toIso8601String(),
      };
}
