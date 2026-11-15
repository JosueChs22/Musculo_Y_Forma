import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pulso_app/core/api_exception.dart';
import 'package:pulso_app/core/api_http.dart';

void main() {
  test('304 no se interpreta como una respuesta exitosa vacía', () async {
    final api = ApiHttp(
      client: MockClient((_) async => http.Response('', 304)),
    );

    await expectLater(
      api.get('/clientes'),
      throwsA(isA<ApiException>()),
    );
  });
}
