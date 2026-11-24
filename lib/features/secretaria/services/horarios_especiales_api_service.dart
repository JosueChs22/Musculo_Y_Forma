import '../../../core/api_http.dart';
import '../models/horario_especial.dart';

/// Servicio que conecta los horarios especiales con GYM-API.
class HorariosEspecialesApiService {
  HorariosEspecialesApiService({ApiHttp? http}) : _http = http ?? ApiHttp();

  final ApiHttp _http;

  static const String _ruta = '/horarios-especiales';

  /// RF-031: listar todos los horarios especiales.
  /// Recorre las páginas que devuelve la API.
  Future<List<HorarioEspecial>> listar() async {
    final horarios = <HorarioEspecial>[];
    String? cursor;

    do {
      final respuesta = await _http.get(
        _ruta,
        query: {if (cursor != null) 'cursor': cursor},
      );

      final datos = respuesta['data'] as List;

      horarios.addAll(
        datos.map(
          (item) => HorarioEspecial.fromJson(item as Map<String, dynamic>),
        ),
      );

      cursor = respuesta['nextCursor'] as String?;
    } while (cursor != null);

    return horarios;
  }

  /// Consultar un horario especial por ID.
  Future<HorarioEspecial> obtener(String id) async {
    final respuesta = await _http.get('$_ruta/$id');
    return HorarioEspecial.fromJson(respuesta);
  }

  /// RF-016: crear horario especial.
  Future<HorarioEspecial> crear(HorarioEspecial horario) async {
    final respuesta = await _http.post(_ruta, horario.toJson());

    return HorarioEspecial.fromJson(respuesta);
  }

  /// RF-021: actualizar horario especial.
  Future<HorarioEspecial> actualizar(String id, HorarioEspecial horario) async {
    await _http.put('$_ruta/$id', horario.toJson());

    return obtener(id);
  }

  /// RF-026: inhabilitar horario especial.
  Future<HorarioEspecial> inhabilitar(String id) async {
    await _http.patch('$_ruta/$id/inhabilitar');
    return obtener(id);
  }
}
