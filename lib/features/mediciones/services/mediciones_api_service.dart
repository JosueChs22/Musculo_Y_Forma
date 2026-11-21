import '../../../core/api_http.dart';
import '../models/datos_medicion.dart';
import '../models/medicion_cliente.dart';
import 'mediciones_service.dart';

class MedicionesApiService implements MedicionesService {
  MedicionesApiService({ApiHttp? http}) : _http = http ?? ApiHttp();

  final ApiHttp _http;

  @override
  Future<void> crearMedicion(DatosMedicion medicion) async {
    await _http.post('/mediciones', medicion.toJson());
  }

  @override
  Future<PaginaMediciones> listarHistorial(
    String idUsuario, {
    required String estado,
    String? cursor,
  }) async {
    final respuesta = await _http.get(
      '/mediciones/cliente/$idUsuario',
      query: {
        'limite': '20',
        'estado': estado,
        if (cursor != null) 'cursor': cursor,
      },
    );
    final items = (respuesta['data'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(MedicionCliente.fromJson)
        .toList();
    return PaginaMediciones(
      items,
      respuesta['nextCursor'] as String?,
    );
  }

  @override
  Future<MedicionCliente> actualizarMedicion(
    String id,
    DatosMedicion medicion,
  ) async {
    final respuesta = await _http.put(
      '/mediciones/$id',
      medicion.toJson(incluirIdUsuario: false),
    );
    return MedicionCliente.fromJson(respuesta);
  }

  @override
  Future<void> cambiarEstadoMedicion(String id, String estado) async {
    await _http.patch(
      '/mediciones/$id/estado',
      {'estado': estado},
    );
  }
}
