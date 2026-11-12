import 'package:flutter_test/flutter_test.dart';
import 'package:pulso_app/features/perfil/controllers/perfil_controller.dart';
import 'package:pulso_app/features/perfil/models/user_profile.dart';
import 'package:pulso_app/features/perfil/services/perfil_service.dart';

/// Devuelve un perfil distinto según quién "tiene la sesión".
class _PerfilFalso implements PerfilService {
  String usuarioActual = '';
  int pedidos = 0;

  @override
  Future<UserProfile> getProfile() async {
    pedidos++;
    final quien = usuarioActual;
    await Future<void>.delayed(const Duration(milliseconds: 20));
    return UserProfile(name: quien == 'u1' ? 'Juan Pérez' : 'María López');
  }
}

Future<void> _esperar() => Future<void>.delayed(const Duration(milliseconds: 80));

void main() {
  test('carga al iniciar sesión, borra al cerrarla y recarga con otro usuario', () async {
    final servicio = _PerfilFalso();
    final c = PerfilController(servicio);

    servicio.usuarioActual = 'u1';
    c.usarUsuario('u1');
    await _esperar();
    expect(c.profile.name, 'Juan Pérez');

    c.usarUsuario('u1'); // mismo usuario: no vuelve a pedir
    await _esperar();
    expect(servicio.pedidos, 1);

    c.usarUsuario(null); // cerrar sesión
    expect(c.profile.name, '');
    await _esperar();
    expect(servicio.pedidos, 1);

    servicio.usuarioActual = 'u2';
    c.usarUsuario('u2');
    await _esperar();
    expect(c.profile.name, 'María López');
    c.dispose();
  });

  test('si cambia el usuario mientras carga, termina mostrando al usuario nuevo', () async {
    final servicio = _PerfilFalso()..usuarioActual = 'u1';
    final c = PerfilController(servicio);

    c.usarUsuario('u1');
    await Future<void>.delayed(const Duration(milliseconds: 5)); // la carga de u1 va a medias
    servicio.usuarioActual = 'u2';
    c.usarUsuario('u2');
    await _esperar();

    expect(c.profile.name, 'María López');
    expect(c.loading, isFalse);
    c.dispose();
  });
}
