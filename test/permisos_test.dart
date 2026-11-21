import 'package:flutter_test/flutter_test.dart';

import 'package:pulso_app/core/permisos.dart';
import 'package:pulso_app/features/auth/models/usuario.dart';

void main() {
  test('solo entrenadores pueden abrir la sección de mediciones', () {
    expect(puedeEntrar(RolUsuario.entrenador, '/coach/mediciones'), isTrue);
    expect(puedeEntrar(RolUsuario.administrador, '/coach/mediciones'), isFalse);
    expect(puedeEntrar(RolUsuario.secretaria, '/coach/mediciones'), isFalse);
    expect(
      puedeEntrar(RolUsuario.entrenador, '/coach/mediciones/historial'),
      isTrue,
    );
    expect(
      puedeEntrar(RolUsuario.administrador, '/coach/mediciones/historial'),
      isFalse,
    );
  });
}
