import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pulso_app/core/api_http.dart';
import 'package:pulso_app/features/secretaria/services/clientes_api_service.dart';

void main() {
  test('el listado de Secretaría solicita el DTO de gestión', () async {
    Uri? uri;
    final service = ClientesApiService(
      http: ApiHttp(
        client: MockClient((request) async {
          uri = request.url;
          return http.Response(
            jsonEncode({'data': [], 'nextCursor': null}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      ),
    );

    await service.listarClientes(busqueda: 'Ana 123');

    expect(uri?.queryParameters['vista'], 'gestion');
    expect(uri?.queryParameters['q'], 'Ana 123');
  });
}
