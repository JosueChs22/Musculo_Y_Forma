/// URL base de la API. Por defecto apunta a Render; para probar contra la API
/// local se corre la app con:
///   --dart-define=API_BASE=http://localhost:3000/api
const String kApiBase = String.fromEnvironment(
  'API_BASE',
  defaultValue: 'https://musculo-y-forma.onrender.com/api',
);

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
