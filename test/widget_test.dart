import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulso_app/core/skeleton.dart';
import 'package:pulso_app/main.dart';

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

    await tester.pumpWidget(const AppRoot());

    // REGLA 1: mientras carga se ven skeletons, no spinners.
    expect(find.byType(SkeletonScope), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    // Los servicios mock responden en 250 ms y en paralelo.
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('HOLA, ALEX'), findsOneWidget);
    expect(find.text('Carlos Méndez'), findsOneWidget);
    expect(find.byType(SkeletonScope), findsNothing);
  });

}
