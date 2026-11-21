import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulso_app/core/api_exception.dart';
import 'package:pulso_app/features/mediciones/models/comparacion_mediciones.dart';
import 'package:pulso_app/features/mediciones/models/datos_medicion.dart';
import 'package:pulso_app/features/mediciones/models/medicion_cliente.dart';
import 'package:pulso_app/features/mediciones/services/mediciones_service.dart';
import 'package:pulso_app/features/mediciones/views/comparacion_mediciones_view.dart';
import 'package:pulso_app/features/planes/models/plan.dart';

MedicionCliente medicion({
  required String id,
  required double peso,
  double? grasa,
  Map<String, dynamic> medidas = const {},
}) =>
    MedicionCliente(
      id: id,
      fecha: DateTime.utc(2026, 11, id == 'actual' ? 21 : 20, 12),
      estado: 'Activo',
      pesoCorporal: peso,
      estatura: 170,
      grasaCorporal: grasa,
      medidas: medidas,
    );

class ServicioMedicionesPrueba implements MedicionesService {
  ServicioMedicionesPrueba(this.items);

  final List<MedicionCliente> items;
  String? estadoSolicitado;
  String? clienteSolicitado;
  bool fallar = false;

  @override
  Future<PaginaMediciones> listarHistorial(
    String idUsuario, {
    required String estado,
    String? cursor,
  }) async {
    estadoSolicitado = estado;
    clienteSolicitado = idUsuario;
    if (fallar) throw const ApiException('Error de prueba');
    return PaginaMediciones(items, null);
  }

  @override
  Future<void> crearMedicion(DatosMedicion medicion) =>
      throw UnimplementedError();

  @override
  Future<MedicionCliente> actualizarMedicion(
    String id,
    DatosMedicion medicion,
  ) =>
      throw UnimplementedError();

  @override
  Future<void> cambiarEstadoMedicion(String id, String estado) =>
      throw UnimplementedError();
}

void main() {
  test('compara valores, diferencias y variaciones sin interpretar cambios',
      () {
    final anterior = medicion(
      id: 'anterior',
      peso: 100,
      grasa: 0,
      medidas: {
        'hombros': 90,
        'brazo': {'izq': 30},
      },
    );
    final actual = medicion(
      id: 'actual',
      peso: 90,
      grasa: 10,
      medidas: {
        'hombros': 99,
        'brazo': {'der': 34},
      },
    );
    final indicadores = compararMediciones(anterior, actual);
    final porNombre = {for (final item in indicadores) item.nombre: item};

    expect(porNombre.length, 19);
    expect(porNombre['Peso corporal']!.anterior, 100);
    expect(porNombre['Peso corporal']!.actual, 90);
    expect(porNombre['Peso corporal']!.diferenciaAbsoluta, 10);
    expect(porNombre['Peso corporal']!.variacionPorcentual, -10);
    expect(porNombre['Hombros']!.variacionPorcentual, 10);
    expect(porNombre['Grasa corporal']!.diferenciaAbsoluta, 10);
    expect(porNombre['Grasa corporal']!.variacionPorcentual, isNull);
    expect(porNombre['Brazo izquierdo']!.anterior, 30);
    expect(porNombre['Brazo izquierdo']!.actual, isNull);
    expect(porNombre['Brazo izquierdo']!.diferenciaAbsoluta, isNull);
    expect(porNombre['Brazo derecho']!.variacionPorcentual, isNull);
  });

  testWidgets(
      'consulta activos y muestra ambas mediciones en pantalla estrecha',
      (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final servicio = ServicioMedicionesPrueba([
      medicion(id: 'actual', peso: 90, grasa: 20),
      medicion(id: 'anterior', peso: 100, grasa: 25),
    ]);

    await tester.pumpWidget(MaterialApp(
      home: ComparacionMedicionesView(
        cliente: const UsuarioResumen(
          id: 'cliente',
          nombre: 'Cliente de prueba',
          usuario: '123',
        ),
        service: servicio,
      ),
    ));
    await tester.pumpAndSettle();

    expect(servicio.clienteSolicitado, 'cliente');
    expect(servicio.estadoSolicitado, 'Activo');
    expect(find.text('Cliente de prueba'), findsOneWidget);
    expect(find.text('Peso corporal'), findsOneWidget);
    expect(find.text('100.00 kg'), findsOneWidget);
    expect(find.text('90.00 kg'), findsOneWidget);
    expect(find.text('10.00 kg'), findsOneWidget);
    expect(find.text('-10.00 %'), findsOneWidget);
    expect(find.text('5.00 p.p.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('informa si no hay dos mediciones y permite reintentar un error',
      (tester) async {
    final servicio = ServicioMedicionesPrueba([
      medicion(id: 'actual', peso: 90),
    ]);
    servicio.fallar = true;
    await tester.pumpWidget(MaterialApp(
      home: ComparacionMedicionesView(
        cliente: const UsuarioResumen(
          id: 'cliente',
          nombre: 'Cliente',
          usuario: '123',
        ),
        service: servicio,
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Error de prueba'), findsOneWidget);
    servicio.fallar = false;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(
      find.text('Se necesitan al menos dos mediciones activas para comparar.'),
      findsOneWidget,
    );
  });
}
