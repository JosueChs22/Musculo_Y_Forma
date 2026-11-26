import '../models/consentimiento.dart';

/// Consentimiento y derechos ARCO del usuario con sesión (Ley 8968). Siempre sobre
/// el usuario del token: la API nunca recibe el id de otra persona.
abstract class LegalService {
  Future<Consentimiento> obtenerConsentimiento();

  /// Acepta la versión [version] del aviso y decide sobre los datos de salud.
  Future<Consentimiento> guardarConsentimiento(
      {required String version, required bool datosSalud});

  /// Copia de todos sus datos (derecho de acceso / portabilidad), como JSON legible.
  Future<String> exportarDatos();

  /// Registra la solicitud de eliminación de la cuenta. Devuelve el mensaje de la API.
  Future<String> solicitarSupresion({String? motivo});
}
