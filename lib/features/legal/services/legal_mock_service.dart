import '../legal_textos.dart';
import '../models/consentimiento.dart';
import 'legal_service.dart';

/// Implementación en memoria para pruebas y demos.
class LegalMockService implements LegalService {
  LegalMockService({bool aceptado = true, bool datosSalud = true})
      : _actual = Consentimiento(
          version: aceptado ? kVersionLegal : null,
          fecha: aceptado ? DateTime(2026, 11, 24) : null,
          datosSalud: datosSalud,
          fechaDatosSalud: null,
          versionVigente: kVersionLegal,
        );

  Consentimiento _actual;
  int guardados = 0;
  int solicitudes = 0;

  @override
  Future<Consentimiento> obtenerConsentimiento() async => _actual;

  @override
  Future<Consentimiento> guardarConsentimiento(
      {required String version, required bool datosSalud}) async {
    guardados++;
    return _actual = Consentimiento(
      version: version,
      fecha: DateTime.now(),
      datosSalud: datosSalud,
      fechaDatosSalud: DateTime.now(),
      versionVigente: kVersionLegal,
    );
  }

  @override
  Future<String> exportarDatos() async => '{"cuenta": {}}';

  @override
  Future<String> solicitarSupresion({String? motivo}) async {
    solicitudes++;
    return 'Recibimos tu solicitud.';
  }
}
