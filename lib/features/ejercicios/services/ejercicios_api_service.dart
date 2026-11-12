import '../../../core/api_http.dart';
import '../models/ejercicio.dart';
import 'ejercicios_service.dart';

/// Implementación real: llama a /ejercicios (token de Entrenador o Administrador).
class EjerciciosApiService implements EjerciciosService {
  EjerciciosApiService({ApiHttp? http}) : _http = http ?? ApiHttp();

  final ApiHttp _http;

  @override
  Future<PaginaEjercicios> listar({
    String? texto,
    String? grupo,
    bool soloActivos = true,
    String? cursor,
  }) async {
    final json = await _http.get('/ejercicios', query: {
      'limite': '30',
      if (texto != null && texto.isNotEmpty) 'q': texto,
      if (grupo != null) 'grupo': grupo,
      if (soloActivos) 'estado': 'Activo',
      if (cursor != null) 'cursor': cursor,
    });
    return PaginaEjercicios(
      (json['data'] as List).map((e) => Ejercicio.fromJson(e as Map<String, dynamic>)).toList(),
      json['nextCursor'] as String?,
    );
  }

  @override
  Future<Ejercicio> crear(DatosEjercicio datos) async =>
      Ejercicio.fromJson(await _http.post('/ejercicios', datos.toJson()));

  @override
  Future<Ejercicio> actualizar(String id, DatosEjercicio datos) async =>
      Ejercicio.fromJson(await _http.put('/ejercicios/$id', datos.toJson()));

  @override
  Future<Ejercicio> inhabilitar(String id) async =>
      Ejercicio.fromJson(await _http.patch('/ejercicios/$id/inhabilitar'));

  @override
  Future<Ejercicio> reactivar(String id) async =>
      Ejercicio.fromJson(await _http.patch('/ejercicios/$id/reactivar'));
}
