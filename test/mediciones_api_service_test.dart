import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pulso_app/core/api_http.dart';
import 'package:pulso_app/features/mediciones/models/datos_medicion.dart';
import 'package:pulso_app/features/mediciones/models/medicion_cliente.dart';
import 'package:pulso_app/features/mediciones/services/mediciones_api_service.dart';

void main() {
  test('registra una medición y envía solo los campos del formulario',
      () async {
    late http.Request request;
    final service = MedicionesApiService(
      http: ApiHttp(
        client: MockClient((value) async {
          request = value;
          return http.Response(
            jsonEncode({
              'id': 'c' * 24,
              'fecha': '2026-11-20T14:00:00.000Z',
              'estado': 'Activo',
            }),
            201,
            headers: {'content-type': 'application/json'},
          );
        }),
      ),
    );

    await service.crearMedicion(
      DatosMedicion(
        idUsuario: 'a' * 24,
        pesoCorporal: 70.5,
        estatura: 170,
        grasaCorporal: 22,
        hombros: 101,
        antebrazoIzq: 25,
      ),
    );

    expect(request.method, 'POST');
    expect(request.url.path, endsWith('/mediciones'));
    expect(jsonDecode(request.body), {
      'id_usuario': 'a' * 24,
      'peso_corporal': 70.5,
      'estatura': 170,
      'objetivo': null,
      'nivel_actividad_fisica': null,
      'observaciones': null,
      'grasa_corporal': 22,
      'medidas': {
        'hombros': 101,
        'antebrazo': {'izq': 25},
      },
    });
  });

  test('consulta el historial ordenado y convierte los registros', () async {
    late http.Request request;
    final service = MedicionesApiService(
      http: ApiHttp(
        client: MockClient((value) async {
          request = value;
          return http.Response(
            jsonEncode({
              'data': [
                {
                  'id': 'c' * 24,
                  'fecha': '2026-11-20T14:00:00.000Z',
                  'estado': 'Activo',
                  'pesoCorporal': 70.5,
                  'estatura': 170,
                  'imc': 24.4,
                  'medidas': {'hombros': 101},
                },
              ],
              'nextCursor': 'cursor-anterior',
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      ),
    );

    final pagina = await service.listarHistorial(
      'a' * 24,
      estado: 'Activo',
      cursor: 'cursor-inicial',
    );

    expect(request.method, 'GET');
    expect(request.url.path, endsWith('/mediciones/cliente/${'a' * 24}'));
    expect(request.url.queryParameters, {
      'limite': '20',
      'estado': 'Activo',
      'cursor': 'cursor-inicial',
    });
    expect(pagina.nextCursor, 'cursor-anterior');
    expect(pagina.items.single, isA<MedicionCliente>());
    expect(pagina.items.single.pesoCorporal, 70.5);
    expect(pagina.items.single.medidas['hombros'], 101);
  });

  test('actualiza mediciones sin enviar cliente ni campos inmutables',
      () async {
    late http.Request request;
    final service = MedicionesApiService(
      http: ApiHttp(
        client: MockClient((value) async {
          request = value;
          return http.Response(
            jsonEncode({
              'id': 'c' * 24,
              'fecha': '2026-11-20T14:00:00.000Z',
              'estado': 'Activo',
              'pesoCorporal': 70.5,
              'estatura': 170,
              'medidas': {'hombros': 101},
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      ),
    );

    final actualizada = await service.actualizarMedicion(
      'c' * 24,
      DatosMedicion(
        idUsuario: 'a' * 24,
        pesoCorporal: 70.5,
        estatura: 170,
        hombros: 101,
        estado: 'Inhabilitado',
      ),
    );

    expect(request.method, 'PUT');
    expect(request.url.path, endsWith('/mediciones/${'c' * 24}'));
    final cuerpo = jsonDecode(request.body) as Map<String, dynamic>;
    expect(cuerpo.containsKey('id_usuario'), isFalse);
    expect(cuerpo.containsKey('fecha'), isFalse);
    expect(cuerpo['estado'], 'Inhabilitado');
    expect(cuerpo['peso_corporal'], 70.5);
    expect(cuerpo['medidas'], {'hombros': 101});
    expect(actualizada.pesoCorporal, 70.5);
  });

  test('cambia el estado de una medición desde la lista', () async {
    late http.Request request;
    final service = MedicionesApiService(
      http: ApiHttp(
        client: MockClient((value) async {
          request = value;
          return http.Response('{}', 200);
        }),
      ),
    );

    await service.cambiarEstadoMedicion('c' * 24, 'Inhabilitado');

    expect(request.method, 'PATCH');
    expect(request.url.path, endsWith('/mediciones/${'c' * 24}/estado'));
    expect(jsonDecode(request.body), {'estado': 'Inhabilitado'});
  });
}
