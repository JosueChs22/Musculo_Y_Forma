import 'medicion_cliente.dart';

class IndicadorFisico {
  const IndicadorFisico(this.nombre, this.unidad, this.valor);

  final String nombre;
  final String unidad;
  final num? Function(MedicionCliente) valor;
}

num? _medida(MedicionCliente medicion, String campo, [String? lado]) {
  final valor = medicion.medidas[campo];
  if (lado == null) return valor as num?;
  if (valor == null) return null;
  return (valor as Map)[lado] as num?;
}

final composicionCorporal = <IndicadorFisico>[
  IndicadorFisico('Peso corporal', 'kg', (m) => m.pesoCorporal),
  IndicadorFisico('Estatura', 'cm', (m) => m.estatura),
  IndicadorFisico('IMC', '', (m) => m.imc),
  IndicadorFisico('Grasa corporal', '%', (m) => m.grasaCorporal),
  IndicadorFisico('Grasa visceral', 'nivel', (m) => m.grasaVisceral),
  IndicadorFisico('Masa muscular', 'kg', (m) => m.masaMuscular),
];

final troncoSuperior = <IndicadorFisico>[
  IndicadorFisico('Hombros', 'cm', (m) => _medida(m, 'hombros')),
  IndicadorFisico('Pecho', 'cm', (m) => _medida(m, 'pecho')),
  IndicadorFisico('Espalda', 'cm', (m) => _medida(m, 'espalda')),
];

final troncoInferior = <IndicadorFisico>[
  IndicadorFisico('Cintura', 'cm', (m) => _medida(m, 'cintura')),
  IndicadorFisico('Cadera', 'cm', (m) => _medida(m, 'cadera')),
];

final extremidadesSuperiores = <IndicadorFisico>[
  IndicadorFisico('Brazo izquierdo', 'cm', (m) => _medida(m, 'brazo', 'izq')),
  IndicadorFisico('Brazo derecho', 'cm', (m) => _medida(m, 'brazo', 'der')),
  IndicadorFisico(
      'Antebrazo izquierdo', 'cm', (m) => _medida(m, 'antebrazo', 'izq')),
  IndicadorFisico(
      'Antebrazo derecho', 'cm', (m) => _medida(m, 'antebrazo', 'der')),
];

final extremidadesInferiores = <IndicadorFisico>[
  IndicadorFisico('Muslo izquierdo', 'cm', (m) => _medida(m, 'muslo', 'izq')),
  IndicadorFisico('Muslo derecho', 'cm', (m) => _medida(m, 'muslo', 'der')),
  IndicadorFisico(
      'Pantorrilla izquierdo', 'cm', (m) => _medida(m, 'pantorrilla', 'izq')),
  IndicadorFisico(
      'Pantorrilla derecho', 'cm', (m) => _medida(m, 'pantorrilla', 'der')),
];

final indicadoresFisicos = <IndicadorFisico>[
  ...composicionCorporal,
  ...troncoSuperior,
  ...troncoInferior,
  ...extremidadesSuperiores,
  ...extremidadesInferiores,
];
