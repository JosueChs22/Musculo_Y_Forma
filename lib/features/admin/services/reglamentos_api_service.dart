import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/api_exception.dart';
import '../../../core/api_session.dart';
import '../models/reglamento.dart';
import 'reglamentos_service.dart';

/// Implementación real: llama a /reglamentos (requiere token de Administrador).
class ReglamentosApiService implements ReglamentosService {
  ReglamentosApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  // REGLA 11: el tope es 10 s, pero Render Free hace cold start de ~50 s
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

    if (res.statusCode == 401) {
      // El token venció o la cuenta se inhabilitó: se cierra la sesión
      ApiSession.alExpirar?.call();
    }

    if (res.statusCode >= 400) {
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
  Future<List<Reglamento>> getReglamentos() => _traerTodos('/reglamentos');

  // RF-093: GET /reglamentos/vigentes (cualquier rol con sesión)
  @override
  Future<List<Reglamento>> getReglamentosVigentes() => _traerTodos('/reglamentos/vigentes');

  Future<List<Reglamento>> _traerTodos(String ruta) async {
    // Trae todas las páginas en una sola carga (son pocos reglamentos)
    final List<Reglamento> todos = [];
    String? cursor;

    do {
      final path = cursor == null ? ruta : '$ruta?cursor=$cursor';
      final json = await _enviar(() => _client.get(Uri.parse('$kApiBase$path'), headers: _headers));
      todos.addAll(
        (json['data'] as List).map((e) => Reglamento.fromJson(e as Map<String, dynamic>)),
      );
      cursor = json['nextCursor'] as String?;
    } while (cursor != null);

    return todos;
  }

  @override
  Future<Reglamento> crearReglamento({required String titulo, required String contenido}) async {
    final json = await _enviar(
      () => _client.post(
        Uri.parse('$kApiBase/reglamentos'),
        headers: _headers,
        body: jsonEncode({'titulo': titulo.trim(), 'contenido': contenido.trim()}),
      ),
    );
    return Reglamento.fromJson(json);
  }

  @override
  Future<Reglamento> actualizarReglamento({
    required String id,
    required String titulo,
    required String contenido,
  }) async {
    final json = await _enviar(
      () => _client.put(
        Uri.parse('$kApiBase/reglamentos/$id'),
        headers: _headers,
        body: jsonEncode({'titulo': titulo.trim(), 'contenido': contenido.trim()}),
      ),
    );
    return Reglamento.fromJson(json);
  }

  @override
  Future<Reglamento> inhabilitarReglamento(String id) async {
    final json = await _enviar(
      () => _client.patch(Uri.parse('$kApiBase/reglamentos/$id/inhabilitar'), headers: _headers),
    );
    return Reglamento.fromJson(json);
  }

  @override
  Future<Reglamento> habilitarReglamento(String id) async {
    final json = await _enviar(
      () => _client.patch(Uri.parse('$kApiBase/reglamentos/$id/habilitar'), headers: _headers),
    );
    return Reglamento.fromJson(json);
  }
}
