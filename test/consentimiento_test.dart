import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pulso_app/app.dart';
import 'package:pulso_app/features/auth/controllers/auth_controller.dart';
import 'package:pulso_app/features/auth/models/usuario.dart';
import 'package:pulso_app/features/auth/services/auth_service.dart';
import 'package:pulso_app/features/legal/controllers/consentimiento_controller.dart';
import 'package:pulso_app/features/legal/legal_textos.dart';
import 'package:pulso_app/features/legal/models/consentimiento.dart';
import 'package:pulso_app/features/legal/services/legal_mock_service.dart';
import 'package:pulso_app/features/legal/views/consentimiento_view.dart';
import 'package:pulso_app/features/legal/views/documento_legal_view.dart';
import 'package:pulso_app/features/legal/views/widgets/sin_consentimiento_salud.dart';
import 'package:pulso_app/features/progreso/controllers/progreso_controller.dart';
import 'package:pulso_app/features/progreso/services/progreso_mock_service.dart';
import 'package:pulso_app/features/progreso/views/progreso_view.dart';

/// Espera a que se resuelvan los microtask y futures del mock.
Future<void> _esperar() => Future<void>.delayed(Duration.zero);

void main() {
  group('Consentimiento.requiereAceptar', () {
    test('sin aceptar o con versión vieja pide aceptar', () {
      Consentimiento c(String? v) => Consentimiento(
          version: v, fecha: null, datosSalud: true, fechaDatosSalud: null, versionVigente: kVersionLegal);
      expect(c(null).requiereAceptar, isTrue);
      expect(c('0.9').requiereAceptar, isTrue);
      expect(c(kVersionLegal).requiereAceptar, isFalse);
    });
  });

  group('redirigir (router)', () {
    String? ir(String ruta, {bool auth = true, bool pendiente = false}) => redirigir(
        ruta: ruta, autenticado: auth, rol: RolUsuario.cliente, requiereConsentimiento: pendiente);

    test('privacidad y términos son públicas, con o sin sesión', () {
      for (final r in ['/privacidad', '/terminos']) {
        expect(ir(r, auth: false), isNull);
        expect(ir(r, pendiente: true), isNull);
      }
    });

    test('con consentimiento pendiente todo lleva a /consentimiento', () {
      expect(ir('/', pendiente: true), '/consentimiento');
      expect(ir('/progreso', pendiente: true), '/consentimiento');
      expect(ir('/consentimiento', pendiente: true), isNull);
    });

    test('ya aceptado, /consentimiento vuelve al inicio', () {
      expect(ir('/consentimiento'), '/');
      expect(ir('/progreso'), isNull);
      expect(ir('/', auth: false), '/login');
    });
  });

  group('ConsentimientoController', () {
    test('primer ingreso: requiere aceptar; al aceptar sin salud, no hay datos de salud', () async {
      final servicio = LegalMockService(aceptado: false, datosSalud: false);
      final c = ConsentimientoController(servicio)..usarUsuario('u1');
      await _esperar();
      await c.load();
      expect(c.requiereAceptar, isTrue);
      expect(c.datosSalud, isFalse);

      expect(await c.aceptar(datosSalud: false), isTrue);
      expect(c.requiereAceptar, isFalse);
      expect(c.datosSalud, isFalse);
      expect(servicio.guardados, 1);

      expect(await c.cambiarDatosSalud(true), isTrue);
      expect(c.datosSalud, isTrue);
    });

    test('sin usuario no bloquea', () {
      final c = ConsentimientoController(LegalMockService(aceptado: false));
      expect(c.requiereAceptar, isFalse);
    });
  });

  test('ProgresoController no pide mediciones sin consentimiento de salud', () async {
    final p = ProgresoController(const ProgresoMockService())..usarUsuario('u1');
    await Future<void>.delayed(const Duration(milliseconds: 400));
    expect(p.loading, isFalse);
    expect(p.history, isEmpty);

    p.permitirDatosSalud(true);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    expect(p.history, isNotEmpty);

    p.permitirDatosSalud(false);
    expect(p.history, isEmpty);
  });

  testWidgets('la pantalla de consentimiento exige aceptar y tiene una casilla aparte de salud', (tester) async {
    tester.view.physicalSize = const Size(1280, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final servicio = LegalMockService(aceptado: false, datosSalud: false);
    final c = ConsentimientoController(servicio)..usarUsuario('u1');
    await tester.runAsync(() async {
      await _esperar();
      await c.load();
    });

    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: c),
        ChangeNotifierProvider(create: (_) => AuthController(_SinSesion())),
      ],
      child: const MaterialApp(home: ConsentimientoView()),
    ));

    expect(find.byType(CheckboxListTile), findsNWidgets(2));
    expect(find.text(kAvisoBorrador), findsOneWidget);
    expect(find.textContaining('datos de salud'), findsWidgets);

    // Sin aceptar los términos, Continuar no hace nada
    await tester.tap(find.text('Continuar'));
    await tester.pump();
    expect(servicio.guardados, 0);

    await tester.tap(find.byType(CheckboxListTile).first);
    await tester.pump();
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(servicio.guardados, 1);
    expect(c.requiereAceptar, isFalse);
    expect(c.datosSalud, isFalse); // la casilla de salud no se marcó
  });

  testWidgets('Progreso muestra la explicación si no hay consentimiento de salud', (tester) async {
    final c = ConsentimientoController(LegalMockService(datosSalud: false));
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: c),
        ChangeNotifierProvider(create: (_) => ProgresoController(const ProgresoMockService())),
      ],
      child: const MaterialApp(home: Scaffold(body: ProgresoView())),
    ));
    expect(find.byType(SinConsentimientoSalud), findsOneWidget);
  });

  for (final ancho in [320.0, 1280.0]) {
    testWidgets('Aviso de privacidad legible y con versión ($ancho px)', (tester) async {
      tester.view.physicalSize = Size(ancho, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const MaterialApp(home: DocumentoLegalView(documento: kPoliticaPrivacidad)));
      expect(find.text(kAvisoBorrador), findsOneWidget);
      expect(find.textContaining(kVersionLegal), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}

class _SinSesion implements AuthService {
  @override
  dynamic noSuchMethod(Invocation invocation) => Future<Usuario?>.value(null);
}
