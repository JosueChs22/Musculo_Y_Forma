class DatosMedicion {
  const DatosMedicion({
    required this.idUsuario,
    required this.pesoCorporal,
    required this.estatura,
    this.objetivo,
    this.grasaCorporal,
    this.grasaVisceral,
    this.masaMuscular,
    this.edad,
    this.nivelActividadFisica,
    this.frecuenciaSemanal,
    this.observaciones,
    this.estado,
    this.hombros,
    this.pecho,
    this.espalda,
    this.cintura,
    this.cadera,
    this.antebrazoIzq,
    this.antebrazoDer,
    this.brazoIzq,
    this.brazoDer,
    this.musloIzq,
    this.musloDer,
    this.pantorrillaIzq,
    this.pantorrillaDer,
  });

  final String idUsuario;
  final double pesoCorporal;
  final double estatura;
  final String? objetivo;
  final double? grasaCorporal;
  final double? grasaVisceral;
  final double? masaMuscular;
  final int? edad;
  final String? nivelActividadFisica;
  final int? frecuenciaSemanal;
  final String? observaciones;
  final String? estado;
  final double? hombros;
  final double? pecho;
  final double? espalda;
  final double? cintura;
  final double? cadera;
  final double? antebrazoIzq;
  final double? antebrazoDer;
  final double? brazoIzq;
  final double? brazoDer;
  final double? musloIzq;
  final double? musloDer;
  final double? pantorrillaIzq;
  final double? pantorrillaDer;

  Map<String, dynamic> toJson({bool incluirIdUsuario = true}) {
    final json = <String, dynamic>{
      if (incluirIdUsuario) 'id_usuario': idUsuario,
      'peso_corporal': pesoCorporal,
      'estatura': estatura,
      'objetivo': _textoOpcional(objetivo),
      'nivel_actividad_fisica': _textoOpcional(nivelActividadFisica),
      'observaciones': _textoOpcional(observaciones),
      if (estado != null) 'estado': estado,
    };

    final numericos = <String, num?>{
      'grasa_corporal': grasaCorporal,
      'grasa_visceral': grasaVisceral,
      'masa_muscular': masaMuscular,
      'edad': edad,
      'frecuencia_semanal': frecuenciaSemanal,
    };
    for (final entry in numericos.entries) {
      if (entry.value != null) json[entry.key] = entry.value;
    }

    final medidas = <String, dynamic>{
      if (hombros != null) 'hombros': hombros,
      if (pecho != null) 'pecho': pecho,
      if (espalda != null) 'espalda': espalda,
      if (cintura != null) 'cintura': cintura,
      if (cadera != null) 'cadera': cadera,
      if (antebrazoIzq != null || antebrazoDer != null)
        'antebrazo': {
          if (antebrazoIzq != null) 'izq': antebrazoIzq,
          if (antebrazoDer != null) 'der': antebrazoDer,
        },
      if (brazoIzq != null || brazoDer != null)
        'brazo': {
          if (brazoIzq != null) 'izq': brazoIzq,
          if (brazoDer != null) 'der': brazoDer,
        },
      if (musloIzq != null || musloDer != null)
        'muslo': {
          if (musloIzq != null) 'izq': musloIzq,
          if (musloDer != null) 'der': musloDer,
        },
      if (pantorrillaIzq != null || pantorrillaDer != null)
        'pantorrilla': {
          if (pantorrillaIzq != null) 'izq': pantorrillaIzq,
          if (pantorrillaDer != null) 'der': pantorrillaDer,
        },
    };
    if (medidas.isNotEmpty) json['medidas'] = medidas;
    return json;
  }

  String? _textoOpcional(String? texto) {
    final limpio = texto?.trim();
    return limpio == null || limpio.isEmpty ? null : limpio;
  }
}
