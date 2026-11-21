import 'comparacion_mediciones.dart';
import 'indicadores_fisicos.dart';
import 'medicion_cliente.dart';

DateTime inicioDia(DateTime fecha) =>
    DateTime(fecha.year, fecha.month, fecha.day);

DateTime restarMeses(DateTime fecha, int meses) {
  final mes = DateTime(fecha.year, fecha.month - meses, 1);
  final ultimoDia = DateTime(mes.year, mes.month + 1, 0).day;
  return DateTime(
      mes.year, mes.month, fecha.day > ultimoDia ? ultimoDia : fecha.day);
}

List<MedicionCliente> filtrarPeriodo(
  List<MedicionCliente> mediciones,
  DateTime? desde,
  DateTime? hasta,
) {
  final inicio = desde == null ? null : inicioDia(desde);
  final fin =
      hasta == null ? null : DateTime(hasta.year, hasta.month, hasta.day + 1);
  final resultado = mediciones.where((m) {
    final fecha = m.fecha.toLocal();
    return (inicio == null || !fecha.isBefore(inicio)) &&
        (fin == null || fecha.isBefore(fin));
  }).toList();
  resultado.sort((a, b) {
    final orden = a.fecha.compareTo(b.fecha);
    return orden != 0 ? orden : a.id.compareTo(b.id);
  });
  return resultado;
}

class ResumenIndicador {
  const ResumenIndicador({
    required this.indicador,
    required this.comparacion,
    required this.fechaInicial,
    required this.fechaFinal,
    required this.cantidadValores,
  });

  final IndicadorFisico indicador;
  final ComparacionIndicador comparacion;
  final DateTime? fechaInicial;
  final DateTime? fechaFinal;
  final int cantidadValores;
}

List<ResumenIndicador> resumirPeriodo(List<MedicionCliente> cronologicas) => [
      for (final indicador in indicadoresFisicos)
        _resumen(indicador, cronologicas),
    ];

ResumenIndicador _resumen(
  IndicadorFisico indicador,
  List<MedicionCliente> cronologicas,
) {
  final disponibles =
      cronologicas.where((m) => indicador.valor(m) != null).toList();
  final inicial = disponibles.isEmpty ? null : disponibles.first;
  final finalMedicion = disponibles.isEmpty ? null : disponibles.last;
  return ResumenIndicador(
    indicador: indicador,
    comparacion: ComparacionIndicador(
      nombre: indicador.nombre,
      unidad: indicador.unidad,
      anterior: inicial == null ? null : indicador.valor(inicial),
      actual: finalMedicion == null ? null : indicador.valor(finalMedicion),
    ),
    fechaInicial: inicial?.fecha,
    fechaFinal: finalMedicion?.fecha,
    cantidadValores: disponibles.length,
  );
}
