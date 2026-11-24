import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulso_app/core/skeleton.dart';
import 'package:pulso_app/features/auth/models/usuario.dart';
import 'package:pulso_app/features/auth/services/auth_service.dart';
import 'package:pulso_app/features/perfil/services/perfil_mock_service.dart';
import 'package:pulso_app/features/progreso/services/progreso_mock_service.dart';
import 'package:pulso_app/features/rutinas/services/rutinas_mock_service.dart';
import 'package:pulso_app/main.dart';

/// Sesión falsa de un cliente ya iniciada (la app arranca directo en Inicio).
class _SesionCliente implements AuthService {
  @override
  Future<Usuario?> restaurarSesion() async => Usuario(
        id: 'u1',
        rol: RolUsuario.cliente,
        nombre: 'Alex',
        primerApellido: 'Rivera',
        correo: 'alex@ejemplo.com',
        telefono: '88887777',
        usuario: 'alex',
        estado: EstadoUsuario.activo,
        fechaIngreso: DateTime(2026),
      );
  @override
  Future<Usuario> iniciarSesion({required String usuario, required String contrasena}) => throw UnimplementedError();
  @override
  Future<void> cambiarContrasena({required String actual, required String nueva}) async {}
  @override
  Future<void> solicitarRecuperacion(String correo) async {}
  @override
  Future<void> restablecerContrasena({required String correo, required String codigo, required String nueva}) async {}
  @override
  Future<void> cerrarSesion() async {}
}

Future<void> _loadFonts() async {
  final barlow = FontLoader('Barlow')
    ..addFont(rootBundle.load('assets/fonts/Barlow-Regular.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Barlow-SemiBold.ttf'));
  final condensed = FontLoader('BarlowCondensed')
    ..addFont(rootBundle.load('assets/fonts/BarlowCondensed-ExtraBold.ttf'));
  await Future.wait([barlow.load(), condensed.load()]);
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await _loadFonts();
  });

  testWidgets('Inicio muestra skeletons y luego los datos del socio', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(AppRoot(
      services: AppServices(
        auth: _SesionCliente(),
        perfil: const PerfilMockService(),
        rutinas: const RutinasMockService(),
        progreso: const ProgresoMockService(),
      ),
    ));
    await tester.pump(); // restaura la sesión y entra a Inicio

    // REGLA 1: mientras carga se ven skeletons, no spinners.
    expect(find.byType(SkeletonScope), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    // Los servicios mock responden en 250 ms y en paralelo.
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.textContaining(RegExp('hola, alex', caseSensitive: false)), findsOneWidget);
    expect(find.text('Carlos Méndez'), findsOneWidget);
    expect(find.byType(SkeletonScope), findsNothing);
  });


  for (final ancho in [320.0, 360.0, 1280.0]) {
    testWidgets('Navegación propia del gimnasio ($ancho px)', (tester) async {
      tester.view.physicalSize = Size(ancho, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(AppRoot(
        services: AppServices(
          auth: _SesionCliente(),
          perfil: const PerfilMockService(),
          rutinas: const RutinasMockService(),
          progreso: const ProgresoMockService(),
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // Móvil: 5 pestañas (iOS recomienda máximo 5) y "Gimnasio" agrupa las tres secciones.
      // Escritorio: la barra lateral las muestra todas.
      final tabs = ancho >= 1000
          ? ['Inicio', 'Rutinas', 'Progreso', 'Horarios', 'Anuncios', 'Reglamento', 'Perfil']
          : ['Inicio', 'Rutinas', 'Progreso', 'Gimnasio', 'Perfil'];
      for (final tab in tabs) {
        expect(find.text(tab), findsWidgets, reason: tab);
      }
      if (ancho < 1000) {
        await tester.tap(find.text('Gimnasio'));
        await tester.pumpAndSettle();
        for (final seccion in ['Horarios', 'Anuncios', 'Reglamento']) {
          expect(find.text(seccion), findsOneWidget, reason: seccion);
        }
        await tester.tap(find.text('Reglamento'));
        await tester.pumpAndSettle();
        expect(find.text('Gimnasio'), findsOneWidget); // la pestaña sigue marcada
      }
      expect(tester.takeException(), isNull); // sin desbordes en la barra

      // En Perfil ya no hay accesos a esas pantallas
      await tester.tap(find.text('Perfil').last);
      await tester.pumpAndSettle();
      expect(find.text('Horarios de clases'), findsNothing);
      expect(find.text('Reglamento del gimnasio'), findsNothing);
    });
  }

}
