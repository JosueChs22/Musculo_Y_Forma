import 'medicion_cliente.dart';
import 'indicadores_fisicos.dart';

class ComparacionIndicador {
  const ComparacionIndicador({
    required this.nombre,
    required this.unidad,
    required this.anterior,
    required this.actual,
  });

  final String nombre;
  final String unidad;
  final num? anterior;
  final num? actual;

  double? get diferenciaAbsoluta => anterior == null || actual == null
      ? null
      : (actual! - anterior!).abs().toDouble();

  double? get variacionPorcentual =>
      anterior == null || actual == null || anterior == 0
          ? null
          : ((actual! - anterior!) / anterior!) * 100;
}

List<ComparacionIndicador> compararMediciones(
  MedicionCliente anterior,
  MedicionCliente actual,
) {
  return [
    for (final indicador in indicadoresFisicos)
      ComparacionIndicador(
        nombre: indicador.nombre,
        unidad: indicador.unidad,
        anterior: indicador.valor(anterior),
        actual: indicador.valor(actual),
      ),
  ];
}
