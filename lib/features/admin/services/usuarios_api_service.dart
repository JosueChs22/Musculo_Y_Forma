import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/api_session.dart';
import '../../auth/models/usuario.dart';
import 'usuarios_service.dart';

/// Implementación real: llama a GET /usuarios (requiere token de Administrador).
class UsuariosApiService implements UsuariosService {
  UsuariosApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  // Render Free hace cold start de ~50 s
  static const _timeout = Duration(seconds: 60);

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        ...ApiSession.authHeaders, // Authorization: Bearer <token>
      };

  @override
  Future<List<Usuario>> getUsuarios() async {
    // Trae todas las páginas en una sola carga (el personal no es enorme)
    final List<Usuario> todos = [];
    String? cursor;

    do {
      final path = cursor == null ? '/usuarios' : '/usuarios?cursor=$cursor';
      final res = await _client.get(Uri.parse('$kApiBase$path'), headers: _headers).timeout(_timeout);
      final json = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode >= 400) {
        throw Exception(json['error'] as String? ?? 'Error ${res.statusCode}');
      }

      todos.addAll(
        (json['data'] as List).map((e) => Usuario.fromJson(e as Map<String, dynamic>)),
      );
      cursor = json['nextCursor'] as String?;
    } while (cursor != null);

    return todos;
  }
}
