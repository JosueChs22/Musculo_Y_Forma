import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_exception.dart';
import 'api_session.dart';

/// Cliente HTTP de la API: agrega el token de la sesión y traduce los fallos de
/// red o de la API a [ApiException] con un mensaje listo para el usuario.
class ApiHttp {
  ApiHttp({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

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

  Future<Map<String, dynamic>> get(String path, {Map<String, String>? query}) =>
      _enviar(() => _client.get(_uri(path, query), headers: _headers));

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> cuerpo) =>
      _enviar(() => _client.post(_uri(path, null), headers: _headers, body: jsonEncode(cuerpo)));

  Future<Map<String, dynamic>> put(String path, Map<String, dynamic> cuerpo) =>
      _enviar(() => _client.put(_uri(path, null), headers: _headers, body: jsonEncode(cuerpo)));

  Future<Map<String, dynamic>> patch(String path, [Map<String, dynamic>? cuerpo]) => _enviar(
        () => _client.patch(_uri(path, null), headers: _headers, body: cuerpo == null ? null : jsonEncode(cuerpo)),
      );

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

    if (res.statusCode >= 400) {
      // La API responde {error: '...'} o, si falla la validación, {errors: [...]}
      final errores = json['errors'];
      throw ApiException(
        json['error'] as String? ??
            (errores is List && errores.isNotEmpty ? 'Revisa los datos: ${errores.first}' : 'Error ${res.statusCode}'),
      );
    }
    return json;
  }
}
