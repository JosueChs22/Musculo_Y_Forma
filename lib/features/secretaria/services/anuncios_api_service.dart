import '../../../core/api_http.dart';
import '../models/anuncio.dart';
import 'anuncios_service.dart';

/// Implementación real: llama a /anuncios con el token de la sesión
/// (Secretaria o Administrador).
class AnunciosApiService implements AnunciosService {
  AnunciosApiService({ApiHttp? http}) : _http = http ?? ApiHttp();

  final ApiHttp _http;

  /// "AAAA-MM-DD" con el día que eligió la persona (la API lo toma como hora de Costa Rica).
  static String _dia(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Future<PaginaAnuncios> getAnuncios({String? cursor}) async {
    final json = await _http.get('/anuncios', query: {if (cursor != null) 'cursor': cursor});
    return PaginaAnuncios(
      (json['data'] as List).map((e) => Anuncio.fromJson(e as Map<String, dynamic>)).toList(),
      json['nextCursor'] as String?,
    );
  }

  @override
  Future<Anuncio> getAnuncio(String id) async => Anuncio.fromJson(await _http.get('/anuncios/$id'));

  @override
  Future<Anuncio> crearAnuncio({
    required String titulo,
    required String contenido,
    required String clasificacion,
    required DateTime fechaPublicacion,
    DateTime? fechaFin,
    String? imagen,
  }) async =>
      Anuncio.fromJson(await _http.post('/anuncios', {
        'titulo': titulo.trim(),
        'contenido': contenido.trim(),
        'clasificacion': clasificacion,
        'fecha_publicacion': _dia(fechaPublicacion),
        'fecha_fin': fechaFin == null ? null : _dia(fechaFin),
        'imagen': imagen,
      }));

  @override
  Future<Anuncio> actualizarAnuncio({
    required String id,
    required String titulo,
    required String contenido,
    required String clasificacion,
    required DateTime fechaPublicacion,
    DateTime? fechaFin,
    String? imagen,
    bool cambiarImagen = false,
  }) async =>
      Anuncio.fromJson(await _http.put('/anuncios/$id', {
        'titulo': titulo.trim(),
        'contenido': contenido.trim(),
        'clasificacion': clasificacion,
        'fecha_publicacion': _dia(fechaPublicacion),
        'fecha_fin': fechaFin == null ? null : _dia(fechaFin),
        // Sin esta clave la API conserva la imagen que ya tiene (y no hay que reenviarla)
        if (cambiarImagen) 'imagen': imagen,
      }));

  @override
  Future<Anuncio> inhabilitarAnuncio(String id) async =>
      Anuncio.fromJson(await _http.patch('/anuncios/$id/inhabilitar'));

  @override
  Future<Anuncio> habilitarAnuncio(String id) async =>
      Anuncio.fromJson(await _http.patch('/anuncios/$id/habilitar'));
}
