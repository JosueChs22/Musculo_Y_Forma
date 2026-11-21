import '../models/medicion_cliente.dart';
import 'mediciones_service.dart';

Future<List<MedicionCliente>> cargarHistorialCompleto(
  MedicionesService service,
  String idUsuario,
) async {
  final mediciones = <MedicionCliente>[];
  final cursores = <String>{};
  String? cursor;
  do {
    final pagina = await service.listarHistorial(
      idUsuario,
      estado: 'Activo',
      cursor: cursor,
    );
    mediciones.addAll(pagina.items);
    cursor = pagina.nextCursor;
    if (cursor != null && !cursores.add(cursor)) {
      throw StateError('El API devolvió un cursor de historial repetido.');
    }
  } while (cursor != null);
  return mediciones;
}
