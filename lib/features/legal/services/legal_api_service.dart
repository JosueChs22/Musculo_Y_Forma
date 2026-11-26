import 'dart:convert';

import '../../../core/api_http.dart';
import '../models/consentimiento.dart';
import 'legal_service.dart';

class LegalApiService implements LegalService {
  LegalApiService({ApiHttp? http}) : _http = http ?? ApiHttp();

  final ApiHttp _http;
  Future<Consentimiento>? _pendiente; // REGLA 8: una sola consulta en curso

  @override
  Future<Consentimiento> obtenerConsentimiento() => _pendiente ??= _http
      .get('/mi/consentimiento')
      .then(Consentimiento.fromJson)
      .whenComplete(() => _pendiente = null);

  @override
  Future<Consentimiento> guardarConsentimiento(
          {required String version, required bool datosSalud}) async =>
      Consentimiento.fromJson(await _http.put('/mi/consentimiento', {
        'version': version,
        'aceptaTerminos': true,
        'datosSalud': datosSalud,
      }));

  @override
  Future<String> exportarDatos() async =>
      const JsonEncoder.withIndent('  ').convert(await _http.get('/mi/datos'));

  @override
  Future<String> solicitarSupresion({String? motivo}) async {
    final r = await _http.post('/mi/solicitud-supresion', {
      if (motivo != null && motivo.trim().isNotEmpty) 'motivo': motivo.trim(),
    });
    return (r['mensaje'] as String?) ?? 'Recibimos tu solicitud.';
  }
}
