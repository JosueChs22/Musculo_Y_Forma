import '../../../core/api_http.dart';
import '../models/clase.dart';
import '../models/horario_clase.dart';
import 'clases_service.dart';

/// Implementación real: llama a /clases con el token de la sesión
/// (ver: cualquier rol; modificar: Secretaria o Administrador).
class ClasesApiService implements ClasesService {
  ClasesApiService({ApiHttp? http}) : _http = http ?? ApiHttp();

  final ApiHttp _http;

  Future<Clase> _obtener(String id) async => Clase.fromJson(await _http.get('/clases/$id'));

  // ── Clases ────────────────────────────────────────────────────────────────

  @override
  Future<List<Clase>> getClases() async {
    // Trae todas las páginas en una sola carga (el catálogo no es enorme)
    final List<Clase> todas = [];
    String? cursor;

    do {
      final json = await _http.get('/clases', query: {if (cursor != null) 'cursor': cursor});
      todas.addAll((json['data'] as List).map((e) => Clase.fromJson(e as Map<String, dynamic>)));
      cursor = json['nextCursor'] as String?;
    } while (cursor != null);

    return todas;
  }

  @override
  Future<Clase> crearClase({required String nombre, String? descripcion}) async =>
      Clase.fromJson(await _http.post('/clases', {'nombre': nombre, 'descripcion': descripcion}));

  @override
  Future<Clase> actualizarClase(String id, {String? nombre, String? descripcion}) async {
    // El API devuelve {ok:true}; se recarga la clase actualizada
    await _http.put('/clases/$id', {'nombre': nombre, 'descripcion': descripcion});
    return _obtener(id);
  }

  @override
  Future<Clase> inhabilitarClase(String id) async {
    await _http.patch('/clases/$id/inhabilitar');
    return _obtener(id);
  }

  @override
  Future<Clase> reactivarClase(String id) async {
    await _http.patch('/clases/$id/reactivar');
    return _obtener(id);
  }

  // ── Horarios ──────────────────────────────────────────────────────────────

  @override
  Future<Clase> agregarHorario(String idClase, HorarioClase horario) async {
    await _http.post('/clases/$idClase/horarios', {
      'dias': horario.dias,
      'hora_inicio': horario.horaInicio,
      'hora_fin': horario.horaFin,
    });
    return _obtener(idClase);
  }

  @override
  Future<Clase> actualizarHorario(String idClase, int index, HorarioClase horario) async {
    await _http.put('/clases/$idClase/horarios/$index', {
      'dias': horario.dias,
      'hora_inicio': horario.horaInicio,
      'hora_fin': horario.horaFin,
    });
    return _obtener(idClase);
  }

  @override
  Future<Clase> inhabilitarHorario(String idClase, int index) async {
    await _http.patch('/clases/$idClase/horarios/$index/inhabilitar');
    return _obtener(idClase);
  }
}
