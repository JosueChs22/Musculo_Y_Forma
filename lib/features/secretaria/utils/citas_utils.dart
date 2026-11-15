import '../models/cita.dart';

List<String> horasDisponiblesCita(DateTime? fecha, {DateTime? ahora}) {
  if (fecha == null) return const [];
  final momento = ahora ?? DateTime.now();
  final hoy = fecha.year == momento.year &&
      fecha.month == momento.month &&
      fecha.day == momento.day;
  return [
    for (var minutos = 0; minutos < 24 * 60; minutos += 30)
      if (!hoy ||
          DateTime(fecha.year, fecha.month, fecha.day, minutos ~/ 60,
                  minutos % 60)
              .isAfter(momento))
        '${(minutos ~/ 60).toString().padLeft(2, '0')}:${(minutos % 60).toString().padLeft(2, '0')}',
  ];
}

String fechaCitaLabel(DateTime fecha) =>
    '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';

String horaCitaLabel(DateTime fechaHora) =>
    '${fechaHora.hour.toString().padLeft(2, '0')}:${fechaHora.minute.toString().padLeft(2, '0')}';

String fechaHoraConZona(DateTime fechaHora) {
  final offset = fechaHora.timeZoneOffset;
  final minutos = offset.inMinutes.abs();
  final signo = offset.isNegative ? '-' : '+';
  return '${fechaHora.year.toString().padLeft(4, '0')}-'
      '${fechaHora.month.toString().padLeft(2, '0')}-'
      '${fechaHora.day.toString().padLeft(2, '0')}T'
      '${fechaHora.hour.toString().padLeft(2, '0')}:'
      '${fechaHora.minute.toString().padLeft(2, '0')}:00'
      '$signo${(minutos ~/ 60).toString().padLeft(2, '0')}:'
      '${(minutos % 60).toString().padLeft(2, '0')}';
}

bool coincideCitaConsulta(CitaConsulta cita, String busqueda) {
  final termino = _normalizarTextoCita(busqueda);
  if (termino.isEmpty) return true;
  return _normalizarTextoCita(cita.carne).contains(termino) ||
      _normalizarTextoCita(cita.clienteNombreCompleto).contains(termino);
}

String _normalizarTextoCita(String texto) => texto
    .toLowerCase()
    .replaceAll('á', 'a')
    .replaceAll('é', 'e')
    .replaceAll('í', 'i')
    .replaceAll('ó', 'o')
    .replaceAll('ú', 'u')
    .replaceAll('ü', 'u')
    .replaceAll('ñ', 'n');
