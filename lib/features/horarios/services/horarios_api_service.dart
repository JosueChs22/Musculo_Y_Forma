import '../../../core/api_http.dart';
import '../../secretaria/models/clase.dart';
import 'horarios_service.dart';

/// GET /clases (cualquier rol con sesión). Trae todas las páginas.
class HorariosApiService implements HorariosService {
  HorariosApiService({ApiHttp? http}) : _http = http ?? ApiHttp();

  final ApiHttp _http;

  // REGLA 8: una sola petición en curso
  Future<List<Clase>>? _enCurso;

  @override
  Future<List<Clase>> getClases() => _enCurso ??= _traer().whenComplete(() => _enCurso = null);

  Future<List<Clase>> _traer() async {
    final todas = <Clase>[];
    String? cursor;
    do {
      final json = await _http.get('/clases', query: {'limite': '100', if (cursor != null) 'cursor': cursor});
      todas.addAll((json['data'] as List).map((e) => Clase.fromJson(e as Map<String, dynamic>)));
      cursor = json['nextCursor'] as String?;
    } while (cursor != null);
    return todas;
  }
}
