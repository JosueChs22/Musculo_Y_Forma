import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_exception.dart';
import 'api_session.dart';

/// Cliente HTTP de la API: agrega el token de la sesión y traduce los fallos de
/// red o de la API a [ApiException] con un mensaje listo para el usuario.
///
/// Rendimiento:
/// - Todas las instancias sin `client` propio comparten un solo [http.Client], así se
///   reutilizan las conexiones (keep-alive) en vez de abrir una por servicio.
/// - Compresión: en web el navegador manda `Accept-Encoding` (br/gzip) y descomprime solo
///   (no se puede fijar a mano: es un header prohibido); en móvil `dart:io` manda
///   `Accept-Encoding: gzip` y descomprime por defecto. No hace falta agregarlo aquí.
/// - REGLA 8: un GET idéntico en curso se comparte, y su respuesta se guarda en memoria
///   [ttlCache]. La caché va por sesión (token) y se vacía al cambiar de sesión
///   (login/cerrar sesión) y después de cualquier POST/PUT/PATCH exitoso.
class ApiHttp {
  ApiHttp({http.Client? client}) : _client = client ?? _compartido;

  static final http.Client _compartido = http.Client();

  final http.Client _client;

  /// Vida de una respuesta GET en la caché en memoria.
  static const ttlCache = Duration(seconds: 30);

  static final Map<String, Future<Map<String, dynamic>>> _enCurso = {};
  static int _generacion = 0;
  static final Map<String, ({DateTime vence, Map<String, dynamic> json})> _cache = {};

  /// Borra la caché de respuestas (la llama [ApiSession] al cambiar el token).
  static void limpiarCache() {
    _generacion++;
    _cache.clear();
    _enCurso.clear();
  }

  // Render Free hace cold start de ~50 s
  static const _timeout = Duration(seconds: 60);

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        ...ApiSession.authHeaders,
      };

  Uri _uri(String path, Map<String, String>? query) {
    final uri = Uri.parse('$kApiBase$path');
    return (query == null || query.isEmpty) ? uri : uri.replace(queryParameters: query);
  }

  /// GET con caché corta y sin duplicar peticiones en curso. [sinCache] fuerza ir al servidor.
  Future<Map<String, dynamic>> get(String path, {Map<String, String>? query, bool sinCache = false}) {
    final uri = _uri(path, query);
    // La llave incluye el cliente (las pruebas usan uno propio) y el token (datos por usuario).
    final llave = '${identityHashCode(_client)}|${ApiSession.token ?? ''}|$uri';
    if (!sinCache) {
      final hit = _cache[llave];
      if (hit != null && hit.vence.isAfter(DateTime.now())) return Future.value(hit.json);
      final pendiente = _enCurso[llave];
      if (pendiente != null) return pendiente;
    }
    final gen = _generacion;
    late final Future<Map<String, dynamic>> peticion;
    peticion = _enviar(() => _client.get(uri, headers: _headers)).then((json) {
      // Si la caché se vació mientras esperaba (cierre de sesión o un cambio), no se guarda.
      if (gen == _generacion) _cache[llave] = (vence: DateTime.now().add(ttlCache), json: json);
      return json;
    }).whenComplete(() {
      if (identical(_enCurso[llave], peticion)) _enCurso.remove(llave);
    });
    _enCurso[llave] = peticion;
    return peticion;
  }

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> cuerpo) => _mutar(
        () => _client.post(_uri(path, null), headers: _headers, body: jsonEncode(cuerpo)),
      );

  Future<Map<String, dynamic>> put(String path, Map<String, dynamic> cuerpo) => _mutar(
        () => _client.put(_uri(path, null), headers: _headers, body: jsonEncode(cuerpo)),
      );

  Future<Map<String, dynamic>> patch(String path, [Map<String, dynamic>? cuerpo]) => _mutar(
        () => _client.patch(_uri(path, null), headers: _headers, body: cuerpo == null ? null : jsonEncode(cuerpo)),
      );

  // Un cambio en el servidor deja viejas las respuestas guardadas: se vacía la caché.
  Future<Map<String, dynamic>> _mutar(Future<http.Response> Function() peticion) async {
    try {
      return await _enviar(peticion);
    } finally {
      _generacion++;
      _cache.clear();
      _enCurso.clear();
    }
  }

  Future<Map<String, dynamic>> _enviar(Future<http.Response> Function() peticion) async {
    final conToken = ApiSession.token != null;
    final http.Response res;
    try {
      res = await peticion().timeout(_timeout);
    } on TimeoutException {
      throw const ApiException('El servidor tardó demasiado en responder. Inténtalo de nuevo.');
    } on http.ClientException {
      throw const ApiException('No se pudo conectar con el servidor. Revisa tu conexión.');
    }

    Map<String, dynamic> json = {};
    try {
      final d = jsonDecode(res.body);
      if (d is Map<String, dynamic>) json = d;
    } on FormatException {
      // respuesta que no es JSON: seguimos con el mapa vacío
    }

    // El token venció o la cuenta ya no está activa: se cierra la sesión en toda la app
    if (res.statusCode == 401 && conToken) ApiSession.alExpirar?.call();

    if (res.statusCode == 304) {
      throw const ApiException(
        'El servidor devolvió una respuesta sin datos. Inténtalo de nuevo.',
      );
    }

    if (res.statusCode < 200 || res.statusCode >= 300) {
      // La API responde {error: '...'} o, si falla la validación, {errors: [...]}
      final errores = json['errors'];
      throw ApiException(
        (json['error'] is String ? json['error'] as String : null) ??
            (errores is List && errores.isNotEmpty ? 'Revisa los datos: ${errores.first}' : 'Error ${res.statusCode}'),
      );
    }
    return json;
  }
}
