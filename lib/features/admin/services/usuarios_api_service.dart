import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/api_exception.dart';
import '../../../core/api_session.dart';
import '../../auth/models/usuario.dart';
import 'usuarios_service.dart';

/// Implementación real: llama a /usuarios (requiere token de Administrador).
class UsuariosApiService implements UsuariosService {
  UsuariosApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  // Render Free hace cold start de ~50 s
  static const _timeout = Duration(seconds: 60);

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        ...ApiSession.authHeaders, // Authorization: Bearer <token>
      };

  // Envía la petición y traduce los fallos de red a mensajes legibles.
  Future<Map<String, dynamic>> _enviar(Future<http.Response> Function() peticion) async {
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

    if (res.statusCode >= 400) {
      // La API responde {error: '...'} o, si falla la validación, {errors: [...]}
      throw ApiException(
        json['error'] as String? ??
            (json['errors'] != null
                ? 'Revisa los datos ingresados.'
                : 'Error ${res.statusCode}'),
      );
    }
    return json;
  }

  @override
  Future<List<Usuario>> getUsuarios() async {
    // Trae todas las páginas en una sola carga (el personal no es enorme)
    final List<Usuario> todos = [];
    String? cursor;

    do {
      final path = cursor == null ? '/usuarios' : '/usuarios?cursor=$cursor';
      final json = await _enviar(() => _client.get(Uri.parse('$kApiBase$path'), headers: _headers));
      todos.addAll(
        (json['data'] as List).map((e) => Usuario.fromJson(e as Map<String, dynamic>)),
      );
      cursor = json['nextCursor'] as String?;
    } while (cursor != null);

    return todos;
  }

  @override
  Future<Usuario> crearUsuario({
    required String nombre,
    required String primerApellido,
    String? segundoApellido,
    required String correo,
    required String telefono,
    required RolUsuario rol,
    required String usuario,
    required String contrasena,
  }) async {
    // El cuerpo va en snake_case, como pide la API
    final cuerpo = {
      'nombre': nombre.trim(),
      'primer_apellido': primerApellido.trim(),
      'segundo_apellido':
          (segundoApellido == null || segundoApellido.trim().isEmpty) ? null : segundoApellido.trim(),
      'correo': correo.trim(),
      'telefono': telefono.trim(),
      'rol': rol.valor,
      'usuario': usuario.trim(),
      'contrasena': contrasena,
    };
    final json = await _enviar(
      () => _client.post(Uri.parse('$kApiBase/usuarios'), headers: _headers, body: jsonEncode(cuerpo)),
    );
    return Usuario.fromJson(json);
  }
}
