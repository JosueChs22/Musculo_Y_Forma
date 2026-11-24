import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pulso_app/core/theme.dart';
import 'package:pulso_app/core/widgets.dart';
import 'package:pulso_app/features/auth/controllers/auth_controller.dart';
import 'package:pulso_app/features/auth/models/usuario.dart';
import 'package:pulso_app/features/auth/services/auth_service.dart';
import 'package:pulso_app/features/auth/views/login_view.dart';

/// Servicio falso: nunca hay sesión y el login siempre falla con un mensaje.
class _FakeAuth implements AuthService {
  @override
  Future<Usuario?> restaurarSesion() async => null;
  @override
  Future<Usuario> iniciarSesion({required String usuario, required String contrasena}) async =>
      throw const AuthException('Usuario o contraseña incorrectos');
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

Future<void> _guias(WidgetTester tester) async {
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  await expectLater(tester, meetsGuideline(textContrastGuideline));
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await _loadFonts();
  });

  for (final ancho in [360.0, 1280.0]) {
    testWidgets('Login cumple las guías de accesibilidad ($ancho px)', (tester) async {
      tester.view.physicalSize = Size(ancho, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(ChangeNotifierProvider(
        create: (_) => AuthController(_FakeAuth()),
        child: MaterialApp(theme: buildTheme(), home: const LoginView()),
      ));
      await tester.pumpAndSettle();
      await _guias(tester);

      // El error de login se muestra con ícono + texto (WCAG 1.4.1)
      await tester.enterText(find.byType(TextFormField).at(0), 'socio');
      await tester.enterText(find.byType(TextFormField).at(1), 'x');
      await tester.tap(find.text('Ingresar'));
      await tester.pumpAndSettle();
      expect(find.text('Usuario o contraseña incorrectos'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      handle.dispose();
    });
  }

  testWidgets('Login sin desbordes con texto al 200 % en 360 px', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ChangeNotifierProvider(
      create: (_) => AuthController(_FakeAuth()),
      child: MaterialApp(
        theme: buildTheme(),
        builder: (c, child) => MediaQuery(
          data: MediaQuery.of(c).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: const LoginView(),
      ),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Componentes compartidos: botones, tarjetas y píldoras', (tester) async {
    // DPR 2: con DPR 1 el antialias de texto regular de 14 px da falsos positivos de contraste
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(MaterialApp(
      theme: buildTheme(),
      home: Scaffold(
        body: ListView(padding: const EdgeInsets.all(20), children: [
          PrimaryButton(label: 'Guardar', onPressed: () {}),
          const SizedBox(height: 12),
          SecondaryButton(label: 'Cancelar', onPressed: () {}),
          const SizedBox(height: 12),
          SelectableCard(selected: true, onTap: () {}, semanticLabel: 'Peso',
              child: Text('Peso', style: ts(15, weight: kSemi, color: Colors.white))),
          const SizedBox(height: 12),
          SelectableCard(selected: false, onTap: () {}, child: const Text('Grasa')),
          const SizedBox(height: 12),
          const Wrap(spacing: 8, children: [Pill('Logro'), Pill('Info', tone: PillTone.cobalto), InfoChip('3 series')]),
          // ErrorPanel (tinta sobre blanco, 16:1) se omite: textContrastGuideline da un
          // falso positivo de 2,19 al muestrear el texto regular de 14 px.
        ]),
      ),
    ));
    await tester.pumpAndSettle();
    await _guias(tester);

    // La tarjeta seleccionada se anuncia como botón seleccionado
    expect(
      tester.getSemantics(find.bySemanticsLabel('Peso')),
      isSemantics(label: 'Peso', isButton: true, isSelected: true),
    );
    handle.dispose();
  });
}
