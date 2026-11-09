import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/clase.dart';
import '../models/horario_clase.dart';
import 'clases_service.dart';

/// Implementación real del servicio: llama a la API en Render.
class ClasesApiService implements ClasesService {
  ClasesApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  // En web/emulador apunta al API de Render; en tests se puede inyectar otro.
  static const _base = 'https://musculo-y-forma.onrender.com/api';

  // Render Free hace cold start de ~50 seg; escrituras usan timeout extendido
  static const _timeout = Duration(seconds: 10);
  static const _timeoutWrite = Duration(seconds: 60);

  // ── Helpers ───────────────────────────────────────────────────────────────

  Uri _uri(String path) => Uri.parse('$_base$path');

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  Future<Map<String, dynamic>> _get(String path) async {
    final res = await _client.get(_uri(path), headers: _headers).timeout(_timeout);
    return _parse(res);
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    final res = await _client
        .post(_uri(path), headers: _headers, body: jsonEncode(body))
        .timeout(_timeoutWrite);
    return _parse(res);
  }

  Future<Map<String, dynamic>> _put(String path, Map<String, dynamic> body) async {
    final res = await _client
        .put(_uri(path), headers: _headers, body: jsonEncode(body))
        .timeout(_timeoutWrite);
    return _parse(res);
  }

  Future<Map<String, dynamic>> _patch(String path) async {
    final res = await _client.patch(_uri(path), headers: _headers).timeout(_timeoutWrite);
    return _parse(res);
  }

  Map<String, dynamic> _parse(http.Response res) {
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 400) {
      final msg = body['error'] as String? ?? 'Error ${res.statusCode}';
      throw Exception(msg);
    }
    return body;
  }

  // ── Clases ────────────────────────────────────────────────────────────────

  @override
  Future<List<Clase>> getClases() async {
    // Trae todas las páginas en una sola carga (el catálogo no es enorme)
    final List<Clase> todas = [];
    String? cursor;

    do {
      final path = cursor == null ? '/clases' : '/clases?cursor=$cursor';
      final json = await _get(path);
      final items = (json['data'] as List).map((e) => Clase.fromJson(e as Map<String, dynamic>)).toList();
      todas.addAll(items);
      cursor = json['nextCursor'] as String?;
    } while (cursor != null);

    return todas;
  }

  @override
  Future<Clase> crearClase({required String nombre, String? descripcion}) async {
    final json = await _post('/clases', {'nombre': nombre, 'descripcion': descripcion});
    return Clase.fromJson(json);
  }

  @override
  Future<Clase> actualizarClase(String id, {String? nombre, String? descripcion}) async {
    await _put('/clases/$id', {'nombre': nombre, 'descripcion': descripcion});
    // El API devuelve {ok:true}; recargamos la clase actualizada
    final json = await _get('/clases/$id');
    return Clase.fromJson(json);
  }

  @override
  Future<Clase> inhabilitarClase(String id) async {
    await _patch('/clases/$id/inhabilitar');
    final json = await _get('/clases/$id');
    return Clase.fromJson(json);
  }

  // ── Horarios ──────────────────────────────────────────────────────────────

  @override
  Future<Clase> agregarHorario(String idClase, HorarioClase horario) async {
    await _post('/clases/$idClase/horarios', {
      'dias': horario.dias,
      'hora_inicio': horario.horaInicio,
      'hora_fin': horario.horaFin,
    });
    final json = await _get('/clases/$idClase');
    return Clase.fromJson(json);
  }

  @override
  Future<Clase> actualizarHorario(String idClase, int index, HorarioClase horario) async {
    await _put('/clases/$idClase/horarios/$index', {
      'dias': horario.dias,
      'hora_inicio': horario.horaInicio,
      'hora_fin': horario.horaFin,
    });
    final json = await _get('/clases/$idClase');
    return Clase.fromJson(json);
  }

  @override
  Future<Clase> inhabilitarHorario(String idClase, int index) async {
    await _patch('/clases/$idClase/horarios/$index/inhabilitar');
    final json = await _get('/clases/$idClase');
    return Clase.fromJson(json);
  }
}
