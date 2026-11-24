import '../../../core/api_http.dart';
import '../models/routine.dart';
import 'rutinas_service.dart';

/// Rutinas del usuario con sesión (GET /mi/rutinas: siempre las del token).
class RutinasApiService implements RutinasService {
  RutinasApiService({ApiHttp? http}) : _http = http ?? ApiHttp();

  final ApiHttp _http;

  // REGLA 8: una sola petición en curso.
  Future<List<Routine>>? _enCurso;

  @override
  Future<List<Routine>> getRoutines() => _enCurso ??= _http.get('/mi/rutinas').then((json) {
        return _lista(json['data']);
      }).whenComplete(() => _enCurso = null);

  @override
  Future<PaginaRutinas> getHistorial({String? cursor, int limite = 20}) async {
    final json = await _http.get('/mi/rutinas/historial', query: {
      'limite': '$limite',
      if (cursor != null) 'cursor': cursor,
    });
    final next = json['nextCursor'];
    return PaginaRutinas(_lista(json['data']), next is String && next.isNotEmpty ? next : null);
  }

  List<Routine> _lista(Object? data) => [
        if (data is List)
          for (final p in data)
            if (p is Map<String, dynamic>) Routine.fromJson(p),
      ];
}
