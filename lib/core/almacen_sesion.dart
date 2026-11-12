import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Dónde se guarda el token entre aperturas de la app.
abstract class AlmacenSesion {
  Future<String?> leerToken();
  Future<void> guardarToken(String token);
  Future<void> borrarToken();
}

/// Almacenamiento seguro del sistema en cada plataforma: Keychain (iOS, macOS),
/// Keystore (Android), Credential Manager (Windows), libsecret (Linux) y, en web,
/// cifrado en el navegador. Regla de seguridad de CLAUDE.md: tokens fuera de texto plano.
class AlmacenSesionSeguro implements AlmacenSesion {
  const AlmacenSesionSeguro();

  static const _clave = 'gmyf_token';
  // macOS: el llavero clásico no exige perfil de aprovisionamiento ni "Keychain Sharing",
  // así la app de escritorio se puede firmar y distribuir sin cuenta de pago de Apple.
  static const _storage = FlutterSecureStorage(mOptions: MacOsOptions(usesDataProtectionKeychain: false));

  @override
  Future<String?> leerToken() async {
    try {
      return await _storage.read(key: _clave);
    } catch (e) {
      // Si no se puede descifrar (datos dañados o borrados a medias) se descarta
      debugPrint('No se pudo leer la sesión guardada: $e');
      await borrarToken();
      return null;
    }
  }

  @override
  Future<void> guardarToken(String token) => _storage.write(key: _clave, value: token);

  @override
  Future<void> borrarToken() async {
    try {
      await _storage.delete(key: _clave);
    } catch (e) {
      debugPrint('No se pudo borrar la sesión guardada: $e');
    }
  }
}
