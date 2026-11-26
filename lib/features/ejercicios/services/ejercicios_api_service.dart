import '../../../core/api_http.dart';
import '../models/ejercicio.dart';
import 'ejercicios_service.dart';

/// Implementación real del catálogo de ejercicios.
/// Utiliza la API de GYM-API.
class EjerciciosApiService implements EjerciciosService {
  EjerciciosApiService({
    ApiHttp? http,
  }) : _http = http ?? ApiHttp();

  final ApiHttp _http;

  /// Listar, buscar y filtrar ejercicios.
  @override
  Future<PaginaEjercicios> listar({
    String? texto,
    String? grupo,
    String? tipo,
    bool soloActivos = true,
    String? cursor,
  }) async {
    final json = await _http.get(
      '/ejercicios',
      query: {
        'limite': '30',

        if (texto != null && texto.isNotEmpty) 'q': texto,

        if (grupo != null) 'grupo': grupo,

        // Filtro agregado para Sprint 3.
        if (tipo != null) 'tipo': tipo,

        if (soloActivos) 'estado': 'Activo',

        if (cursor != null) 'cursor': cursor,
      },
    );

    final items = (json['data'] as List)
        .map(
          (e) => Ejercicio.fromJson(
            e as Map<String, dynamic>,
          ),
        )
        .toList();

    return PaginaEjercicios(
      items,
      json['nextCursor'] as String?,
    );
  }

  /// Crear ejercicio.
  @override
  Future<Ejercicio> crear(
    DatosEjercicio datos,
  ) async {
    final respuesta = await _http.post(
      '/ejercicios',
      datos.toJson(),
    );

    return Ejercicio.fromJson(
      respuesta,
    );
  }

  /// Actualizar ejercicio.
  @override
  Future<Ejercicio> actualizar(
    String id,
    DatosEjercicio datos,
  ) async {
    final respuesta = await _http.put(
      '/ejercicios/$id',
      datos.toJson(),
    );

    return Ejercicio.fromJson(
      respuesta,
    );
  }

  /// Inhabilitar ejercicio.
  @override
  Future<Ejercicio> inhabilitar(
    String id,
  ) async {
    final respuesta = await _http.patch(
      '/ejercicios/$id/inhabilitar',
    );

    return Ejercicio.fromJson(
      respuesta,
    );
  }

  /// Reactivar ejercicio.
  @override
  Future<Ejercicio> reactivar(
    String id,
  ) async {
    final respuesta = await _http.patch(
      '/ejercicios/$id/reactivar',
    );

    return Ejercicio.fromJson(
      respuesta,
    );
  }
}
