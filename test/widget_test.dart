import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pulso_app/core/skeleton.dart';
import 'package:pulso_app/features/auth/models/usuario.dart';
import 'package:pulso_app/features/auth/services/auth_service.dart';
import 'package:pulso_app/features/perfil/services/perfil_mock_service.dart';
import 'package:pulso_app/features/progreso/services/progreso_mock_service.dart';
import 'package:pulso_app/features/rutinas/services/rutinas_mock_service.dart';
import 'package:pulso_app/main.dart';

/// Simula un cliente que ya tiene su sesión iniciada.
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
  Future<Usuario> iniciarSesion(
          {required String usuario, required String contrasena}) =>
      throw UnimplementedError();
  @override
  Future<void> cambiarContrasena(
      {required String actual, required String nueva}) async {}
  @override
  Future<void> solicitarRecuperacion(String correo) async {}
  @override
  Future<void> restablecerContrasena(
      {required String correo,
      required String codigo,
      required String nueva}) async {}
  @override
  Future<void> cerrarSesion() async {}
}

/// Simula un usuario sin una sesión guardada.
class _SesionSinIniciar extends _SesionCliente {
  @override
  Future<Usuario?> restaurarSesion() async => null;
}

Future<void> _loadFonts() async {
  final barlow = FontLoader('Barlow')
    ..addFont(rootBundle.load('assets/fonts/Barlow-Regular.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Barlow-SemiBold.ttf'));

  final condensed = FontLoader('BarlowCondensed')
    ..addFont(rootBundle.load('assets/fonts/BarlowCondensed-ExtraBold.ttf'));

  await Future.wait([barlow.load(), condensed.load()]);
}

AppRoot _appCon(AuthService auth) => AppRoot(
      services: AppServices(
        auth: auth,
        perfil: const PerfilMockService(),
        rutinas: const RutinasMockService(),
        progreso: const ProgresoMockService(),
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await _loadFonts();
  });

  testWidgets('La aplicación muestra el formulario de inicio de sesión',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_appCon(_SesionSinIniciar()));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('Ingresar'), findsOneWidget);
  });

  testWidgets('La sesión de cliente restaurada muestra el inicio',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_appCon(_SesionCliente()));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.textContaining(RegExp('hola, alex', caseSensitive: false)),
        findsOneWidget);
    expect(find.text('Carlos Méndez'), findsOneWidget);
    expect(find.byType(SkeletonScope), findsNothing);
  });

  for (final ancho in [320.0, 360.0, 1280.0]) {
    testWidgets('Navegación propia del gimnasio ($ancho px)', (tester) async {
      tester.view.physicalSize = Size(ancho, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_appCon(_SesionCliente()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      final tabs = ancho >= 1000
          ? [
              'Inicio',
              'Rutinas',
              'Progreso',
              'Horarios',
              'Anuncios',
              'Reglamento',
              'Perfil'
            ]
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
        expect(find.text('Gimnasio'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Perfil').last);
      await tester.pumpAndSettle();
      expect(find.text('Horarios de clases'), findsNothing);
      expect(find.text('Reglamento del gimnasio'), findsNothing);
    });
  }
}
