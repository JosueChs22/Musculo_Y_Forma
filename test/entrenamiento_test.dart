import 'package:fake_async/fake_async.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pulso_app/features/auth/models/usuario.dart';
import 'package:pulso_app/features/auth/services/auth_service.dart';
import 'package:pulso_app/features/perfil/services/perfil_mock_service.dart';
import 'package:pulso_app/features/progreso/services/progreso_mock_service.dart';
import 'package:pulso_app/features/rutinas/controllers/entrenamiento_controller.dart';
import 'package:pulso_app/features/rutinas/models/exercise.dart';
import 'package:pulso_app/features/rutinas/models/routine.dart';
import 'package:pulso_app/features/rutinas/services/rutinas_mock_service.dart';
import 'package:pulso_app/features/rutinas/views/entrenamiento_view.dart';
import 'package:pulso_app/main.dart';

const _rutina = Routine(
  id: 'r1',
  title: 'Tren superior',
  focus: 'Fuerza',
  progress: 0,
  exercises: [
    Exercise(name: 'Press de banca', sets: 2, reps: '10', restSeconds: 30),
    Exercise(name: 'Remo', sets: 1, reps: '12', restSeconds: 20),
  ],
);

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
  final condensed = FontLoader('BarlowCondensed')..addFont(rootBundle.load('assets/fonts/BarlowCondensed-ExtraBold.ttf'));
  await Future.wait([barlow.load(), condensed.load()]);
}

void main() {
  group('EntrenamientoController', () {
    test('completar una serie arranca el descanso y al terminar sigue en el mismo ejercicio', () {
      fakeAsync((async) {
        final c = EntrenamientoController(_rutina);
        c.completarSerie();
        expect(c.hechasActual, 1);
        expect(c.descanso, 30);
        async.elapse(const Duration(seconds: 10));
        expect(c.descanso, 20);
        async.elapse(const Duration(seconds: 20));
        expect(c.descansando, isFalse);
        expect(c.indice, 0); // aún queda una serie
        c.dispose();
      });
    });

    test('la última serie de un ejercicio pasa al siguiente tras el descanso', () {
      fakeAsync((async) {
        final c = EntrenamientoController(_rutina);
        c
          ..completarSerie()
          ..saltarDescanso()
          ..completarSerie();
        expect(c.ejercicioCompleto, isTrue);
        expect(c.indice, 0);
        async.elapse(const Duration(seconds: 30));
        expect(c.indice, 1);
        c.dispose();
      });
    });

    test('+15 s, deshacer y progreso', () {
      fakeAsync((async) {
        final c = EntrenamientoController(_rutina);
        c.completarSerie();
        c.sumarDescanso();
        expect(c.descanso, 45);
        expect(c.progreso, closeTo(1 / 3, .001));
        c.deshacerSerie();
        expect(c.hechasActual, 0);
        expect(c.descansando, isFalse);
        expect(c.progreso, 0);
        c.dispose();
      });
    });

    test('terminar fija la duración y el resumen', () {
      var ahora = DateTime(2026, 1, 1, 8);
      final c = EntrenamientoController(_rutina, reloj: () => ahora);
      c
        ..completarSerie()
        ..saltarDescanso()
        ..completarSerie()
        ..saltarDescanso()
        ..completarSerie(); // última serie del último ejercicio: sin descanso
      expect(c.descansando, isFalse);
      expect(c.seriesCompletadas, 3);
      expect(c.ejerciciosCompletos, 2);
      ahora = ahora.add(const Duration(minutes: 25, seconds: 7));
      c.terminar();
      ahora = ahora.add(const Duration(minutes: 10));
      expect(c.terminado, isTrue);
      expect(c.duracion, const Duration(minutes: 25, seconds: 7));
      c.dispose();
    });
  });

  testWidgets('Empezar rutina desde Inicio abre el modo entrenamiento y llega al resumen', (tester) async {
    await _loadFonts();
    tester.view.physicalSize = const Size(390, 844);
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

    await tester.tap(find.textContaining('Continuar rutina'));
    await tester.pumpAndSettle();
    expect(find.byType(EntrenamientoView), findsOneWidget);
    expect(find.textContaining('Ejercicio 1 de'), findsOneWidget);
    expect(find.text('Gimnasio'), findsNothing); // sin barra de pestañas

    await tester.tap(find.textContaining('Completar serie 1'));
    await tester.pump();
    expect(find.text('Saltar'), findsOneWidget); // descanso en curso
    await tester.tap(find.text('Saltar'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Completar serie 2'), findsOneWidget);

    // Salir a mitad pide confirmación
    await tester.tap(find.byTooltip('Salir del entrenamiento'));
    await tester.pumpAndSettle();
    expect(find.text('¿Salir del entrenamiento?'), findsOneWidget);
    await tester.tap(find.text('Seguir entrenando'));
    await tester.pumpAndSettle();

    // Terminar desde el último ejercicio muestra el resumen
    final c = tester.element(find.textContaining('Completar serie 2')).read<EntrenamientoController>();
    c.irA(c.ejercicios.length - 1);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Terminar rutina'));
    await tester.pumpAndSettle();
    expect(find.text('¡RUTINA TERMINADA!'), findsOneWidget);
    await tester.tap(find.text('Volver a mis rutinas'));
    await tester.pumpAndSettle();
    expect(find.text('MIS RUTINAS'), findsOneWidget);
  });
}
