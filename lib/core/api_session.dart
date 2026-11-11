/// URL base de la API. Por defecto apunta a Render; para probar contra la API
/// local se corre la app con:
///   --dart-define=API_BASE=http://localhost:3000/api
const String kApiBase = String.fromEnvironment(
  'API_BASE',
  defaultValue: 'https://musculo-y-forma.onrender.com/api',
);

/// Sesión actual. Guarda el token que devuelve el login (solo en memoria) para
/// que cualquier servicio de la app pueda mandarlo en sus peticiones:
///   headers: {..., ...ApiSession.authHeaders}
class ApiSession {
  ApiSession._();

  static String? token;

  static Map<String, String> get authHeaders =>
      token == null ? const {} : {'Authorization': 'Bearer $token'};
}
