/// URL base de la API. Por defecto apunta a Render; para probar contra la API
/// local se corre la app con:
///   --dart-define=API_BASE=http://localhost:3000/api
/// Seguridad (MASVS-NETWORK-1): solo HTTPS. Se admite http únicamente hacia la
/// máquina local (localhost, 127.0.0.1, 10.0.2.2 del emulador de Android); cualquier
/// otro valor de API_BASE se ignora y se usa la URL de producción.
const String _kApiBaseDefinida = String.fromEnvironment(
  'API_BASE',
  defaultValue: _kApiBaseProduccion,
);
const String _kApiBaseProduccion = 'https://musculo-y-forma.onrender.com/api';

final String kApiBase = apiBaseSegura(_kApiBaseDefinida);

/// Devuelve [valor] si es una URL https (o http local); si no, la de producción.
String apiBaseSegura(String valor) {
  final uri = Uri.tryParse(valor.trim());
  if (uri == null || uri.host.isEmpty || uri.hasQuery || uri.hasFragment || uri.userInfo.isNotEmpty) {
    return _kApiBaseProduccion;
  }
  const locales = {'localhost', '127.0.0.1', '10.0.2.2', '::1'};
  final valida = uri.scheme == 'https' || (uri.scheme == 'http' && locales.contains(uri.host));
  if (!valida) return _kApiBaseProduccion;
  final texto = uri.toString();
  return texto.endsWith('/') ? texto.substring(0, texto.length - 1) : texto;
}

/// Sesión actual. Guarda en memoria el token de la sesión activa para que
/// cualquier servicio pueda mandarlo en sus peticiones:
///   headers: {..., ...ApiSession.authHeaders}
/// La copia que sobrevive a recargar la app la maneja el servicio de auth.
class ApiSession {
  ApiSession._();

  static String? token;

  /// Se llama cuando la API rechaza el token (venció o la cuenta se inhabilitó).
  /// Lo registra el controlador de la sesión para cerrarla.
  static void Function()? alExpirar;

  static Map<String, String> get authHeaders =>
      token == null ? const {} : {'Authorization': 'Bearer $token'};
}
