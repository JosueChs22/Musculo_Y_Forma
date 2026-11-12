import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pulso_app/core/almacen_sesion.dart';
import 'package:pulso_app/core/api_exception.dart';
import 'package:pulso_app/core/api_http.dart';
import 'package:pulso_app/core/api_session.dart';
import 'package:pulso_app/features/auth/controllers/auth_controller.dart';
import 'package:pulso_app/features/auth/services/auth_api_service.dart';

class _AlmacenMemoria implements AlmacenSesion {
  String? token;

  @override
  Future<String?> leerToken() async => token;

  @override
  Future<void> guardarToken(String t) async => token = t;

  @override
  Future<void> borrarToken() async => token = null;
}

const _usuarioJson = {
  'id': '000000000000000000000001',
  'rol': 'Entrenador',
  'nombre': 'Elena',
  'primerApellido': 'Rojas',
  'segundoApellido': null,
  'correo': 'elena@gmyf.test',
  'telefono': '87654321',
  'usuario': 'entrenador.local',
  'estado': 'Activo',
  'fechaIngreso': '2026-11-10T00:00:00.000Z',
  'ultimoLogin': null,
};

http.Response _json(int status, Object cuerpo) =>
    http.Response(jsonEncode(cuerpo), status, headers: {'content-type': 'application/json'});

void main() {
  late _AlmacenMemoria almacen;

  setUp(() {
    almacen = _AlmacenMemoria();
    ApiSession.token = null;
  });

  test('el login guarda el token y al reabrir la app se restaura la sesión', () async {
    final cliente = MockClient((req) async {
      if (req.url.path.endsWith('/auth/login')) return _json(200, {'token': 'tok-1', 'usuario': _usuarioJson});
      if (req.url.path.endsWith('/auth/sesion')) {
        return req.headers['Authorization'] == 'Bearer tok-1'
            ? _json(200, {'usuario': _usuarioJson})
            : _json(401, {'error': 'Sesión inválida o expirada'});
      }
      return _json(404, {});
    });

    final primera = AuthController(AuthApiService(client: cliente, almacen: almacen));
    await primera.load();
    expect(primera.autenticado, isFalse); // aún no hay nada guardado
    expect(await primera.iniciarSesion('entrenador.local', 'x'), isTrue);
    expect(almacen.token, 'tok-1');
    primera.dispose();

    // "Recargar": controlador nuevo, sin token en memoria
    ApiSession.token = null;
    final segunda = AuthController(AuthApiService(client: cliente, almacen: almacen));
    await segunda.load();
    expect(segunda.autenticado, isTrue);
    expect(segunda.usuario?.usuario, 'entrenador.local');
    expect(ApiSession.token, 'tok-1');

    segunda.cerrarSesion();
    await Future<void>.delayed(Duration.zero);
    expect(almacen.token, isNull);
    expect(ApiSession.token, isNull);
    segunda.dispose();
  });

  test('un token vencido se descarta al abrir la app', () async {
    almacen.token = 'tok-viejo';
    final c = AuthController(AuthApiService(
      client: MockClient((_) async => _json(401, {'error': 'Sesión inválida o expirada'})),
      almacen: almacen,
    ));
    await c.load();
    expect(c.autenticado, isFalse);
    expect(almacen.token, isNull);
    c.dispose();
  });

  test('sin conexión no inicia sesión pero conserva el token para el próximo intento', () async {
    almacen.token = 'tok-1';
    final c = AuthController(AuthApiService(
      client: MockClient((_) async => throw http.ClientException('sin red')),
      almacen: almacen,
    ));
    await c.load();
    expect(c.autenticado, isFalse);
    expect(almacen.token, 'tok-1');
    c.dispose();
  });

  test('si la API rechaza el token en medio del uso, se cierra la sesión con aviso', () async {
    almacen.token = 'tok-1';
    final auth = AuthController(AuthApiService(
      client: MockClient((_) async => _json(200, {'usuario': _usuarioJson})),
      almacen: almacen,
    ));
    await auth.load();
    expect(auth.autenticado, isTrue);

    final api = ApiHttp(client: MockClient((_) async => _json(401, {'error': 'Sesión inválida o expirada'})));
    await expectLater(api.get('/rutinas'), throwsA(isA<ApiException>()));

    expect(auth.autenticado, isFalse);
    expect(auth.errorLogin, 'Tu sesión expiró. Inicia sesión de nuevo.');
    await Future<void>.delayed(Duration.zero);
    expect(almacen.token, isNull);
    auth.dispose();
  });
}
