class MedicionCliente {
  const MedicionCliente({
    required this.id,
    required this.fecha,
    required this.estado,
    required this.pesoCorporal,
    required this.estatura,
    this.objetivo,
    this.grasaCorporal,
    this.grasaVisceral,
    this.masaMuscular,
    this.imc,
    this.edad,
    this.medidas = const {},
    this.nivelActividadFisica,
    this.frecuenciaSemanal,
    this.observaciones,
  });

  final String id;
  final DateTime fecha;
  final String estado;
  final double pesoCorporal;
  final double estatura;
  final String? objetivo;
  final double? grasaCorporal;
  final double? grasaVisceral;
  final double? masaMuscular;
  final double? imc;
  final int? edad;
  final Map<String, dynamic> medidas;
  final String? nivelActividadFisica;
  final int? frecuenciaSemanal;
  final String? observaciones;

  factory MedicionCliente.fromJson(Map<String, dynamic> json) =>
      MedicionCliente(
        id: json['id'] as String,
        fecha: DateTime.parse(json['fecha'] as String),
        estado: json['estado'] as String,
        pesoCorporal: (json['pesoCorporal'] as num).toDouble(),
        estatura: (json['estatura'] as num).toDouble(),
        objetivo: json['objetivo'] as String?,
        grasaCorporal: (json['grasaCorporal'] as num?)?.toDouble(),
        grasaVisceral: (json['grasaVisceral'] as num?)?.toDouble(),
        masaMuscular: (json['masaMuscular'] as num?)?.toDouble(),
        imc: (json['imc'] as num?)?.toDouble(),
        edad: (json['edad'] as num?)?.toInt(),
        medidas: Map<String, dynamic>.from(
          json['medidas'] as Map? ?? const {},
        ),
        nivelActividadFisica: json['nivelActividadFisica'] as String?,
        frecuenciaSemanal: (json['frecuenciaSemanal'] as num?)?.toInt(),
        observaciones: json['observaciones'] as String?,
      );
}

class PaginaMediciones {
  const PaginaMediciones(this.items, this.nextCursor);

  final List<MedicionCliente> items;
  final String? nextCursor;
}
