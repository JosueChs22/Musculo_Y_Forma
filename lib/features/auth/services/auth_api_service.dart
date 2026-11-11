import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/api_session.dart';
import '../models/usuario.dart';
import 'auth_service.dart';

/// Implementación real: llama a POST /auth/login de la API.
class AuthApiService implements AuthService {
  AuthApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  // Render Free hace cold start de ~50 s: el login espera hasta 60 s.
  static const _timeout = Duration(seconds: 60);

  @override
  Future<Usuario> iniciarSesion({
    required String usuario,
    required String contrasena,
  }) async {
    final http.Response res;
    try {
      res = await _client
          .post(
            Uri.parse('$kApiBase/auth/login'),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'usuario': usuario, 'contrasena': contrasena}),
          )
          .timeout(_timeout);
    } on TimeoutException {
      throw const AuthException('El servidor tardó demasiado en responder. Inténtalo de nuevo.');
    } on http.ClientException {
      throw const AuthException('No se pudo conectar con el servidor. Revisa tu conexión.');
    }

    final body = _decodificar(res.body);

    if (res.statusCode >= 400) {
      // La API responde {error: '...'} (401, 403, 429...)
      throw AuthException(
        body['error'] as String? ?? 'No se pudo iniciar sesión (${res.statusCode}).',
      );
    }

    ApiSession.token = body['token'] as String;
    return Usuario.fromJson(body['usuario'] as Map<String, dynamic>);
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
