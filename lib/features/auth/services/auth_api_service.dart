import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/api_session.dart';
import '../models/usuario.dart';
import 'auth_service.dart';

/// Implementación real: llama a /auth/login y /auth/cambiar-contrasena de la API.
class AuthApiService implements AuthService {
  AuthApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  // Render Free hace cold start de ~50 s: se espera hasta 60 s.
  static const _timeout = Duration(seconds: 60);

  // Envía la petición y traduce los fallos de red y de la API a [AuthException].
  Future<Map<String, dynamic>> _enviar(Future<http.Response> Function() peticion) async {
    final http.Response res;
    try {
      res = await peticion().timeout(_timeout);
    } on TimeoutException {
      throw const AuthException('El servidor tardó demasiado en responder. Inténtalo de nuevo.');
    } on http.ClientException {
      throw const AuthException('No se pudo conectar con el servidor. Revisa tu conexión.');
    }

    final body = _decodificar(res.body);

    if (res.statusCode >= 400) {
      // La API responde {error: '...'} (400, 401, 403, 429...) o {errors: [...]} (422)
      throw AuthException(
        body['error'] as String? ??
            (body['errors'] != null
                ? 'Revisa los datos ingresados.'
                : 'No se pudo completar la solicitud (${res.statusCode}).'),
      );
    }
    return body;
  }

  @override
  Future<Usuario> iniciarSesion({
    required String usuario,
    required String contrasena,
  }) async {
    final body = await _enviar(
      () => _client.post(
        Uri.parse('$kApiBase/auth/login'),
        headers: const {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({'usuario': usuario, 'contrasena': contrasena}),
      ),
    );

    ApiSession.token = body['token'] as String;
    return Usuario.fromJson(body['usuario'] as Map<String, dynamic>);
  }

  @override
  Future<void> cambiarContrasena({required String actual, required String nueva}) async {
    await _enviar(
      () => _client.post(
        Uri.parse('$kApiBase/auth/cambiar-contrasena'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          ...ApiSession.authHeaders, // Authorization: Bearer <token>
        },
        body: jsonEncode({'contrasena_actual': actual, 'contrasena_nueva': nueva}),
      ),
    );
  }

  @override
  void cerrarSesion() => ApiSession.token = null;

  // Si el servidor devuelve algo que no es JSON, no reventamos: devolvemos vacío.
  Map<String, dynamic> _decodificar(String texto) {
    try {
      final json = jsonDecode(texto);
      return json is Map<String, dynamic> ? json : {};
    } on FormatException {
      return {};
    }
  }
}
