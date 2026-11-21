import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulso_app/features/mediciones/models/datos_medicion.dart';
import 'package:pulso_app/features/mediciones/models/evolucion_mediciones.dart';
import 'package:pulso_app/features/mediciones/models/indicadores_fisicos.dart';
import 'package:pulso_app/features/mediciones/models/medicion_cliente.dart';
import 'package:pulso_app/features/mediciones/services/historial_completo.dart';
import 'package:pulso_app/features/mediciones/services/mediciones_service.dart';
import 'package:pulso_app/features/mediciones/views/evolucion_mediciones_view.dart';
import 'package:pulso_app/features/mediciones/views/grafico_evolucion.dart';
import 'package:pulso_app/features/planes/models/plan.dart';

MedicionCliente medicion(String id, DateTime fecha,
        {double? grasa, Map<String, dynamic> medidas = const {}}) =>
    MedicionCliente(
      id: id,
      fecha: fecha,
      estado: 'Activo',
      pesoCorporal: 70,
      estatura: 170,
      grasaCorporal: grasa,
      medidas: medidas,
    );

class ServicioHistorial implements MedicionesService {
  ServicioHistorial(this.paginas);
  final Map<String?, PaginaMediciones> paginas;
  final List<String?> solicitudes = [];

  @override
  Future<PaginaMediciones> listarHistorial(String idUsuario,
      {required String estado, String? cursor}) async {
    expect(estado, 'Activo');
    solicitudes.add(cursor);
    return paginas[cursor]!;
  }

  @override
  Future<void> crearMedicion(DatosMedicion medicion) =>
      throw UnimplementedError();
  @override
  Future<MedicionCliente> actualizarMedicion(
          String id, DatosMedicion medicion) =>
      throw UnimplementedError();
  @override
  Future<void> cambiarEstadoMedicion(String id, String estado) =>
      throw UnimplementedError();
}

void main() {
  test('recorre todas las páginas activas y detecta cursores repetidos',
      () async {
    final uno = medicion('1', DateTime(2026, 1, 1));
    final dos = medicion('2', DateTime(2025, 1, 1));
    final servicio = ServicioHistorial({
      null: PaginaMediciones([uno], 'siguiente'),
      'siguiente': PaginaMediciones([dos], null),
    });
    expect(await cargarHistorialCompleto(servicio, 'cliente'), [uno, dos]);
    expect(servicio.solicitudes, [null, 'siguiente']);

    final bucle = ServicioHistorial({
      null: PaginaMediciones([uno], 'repetido'),
      'repetido': PaginaMediciones([dos], 'repetido'),
    });
    await expectLater(
      cargarHistorialCompleto(bucle, 'cliente'),
      throwsStateError,
    );
  });

  test('filtra fechas inclusivas y compara valores disponibles del período',
      () {
    final items = [
      medicion('3', DateTime(2026, 3, 10, 23, 59), grasa: 20, medidas: {
        'brazo': {'izq': 31}
      }),
      medicion('1', DateTime(2026, 3, 1), grasa: 0),
      medicion('2', DateTime(2026, 3, 5), medidas: {
        'brazo': {'izq': 29}
      }),
      medicion('4', DateTime(2026, 3, 11)),
    ];
    final periodo =
        filtrarPeriodo(items, DateTime(2026, 3, 1), DateTime(2026, 3, 10));
    expect(periodo.map((m) => m.id), ['1', '2', '3']);
    final resumen = {
      for (final item in resumirPeriodo(periodo)) item.indicador.nombre: item,
    };
    expect(resumen['Brazo izquierdo']!.comparacion.anterior, 29);
    expect(resumen['Brazo izquierdo']!.comparacion.actual, 31);
    expect(resumen['Brazo izquierdo']!.fechaInicial, items[2].fecha);
    expect(resumen['Brazo izquierdo']!.comparacion.diferenciaAbsoluta, 2);
    expect(resumen['Grasa corporal']!.comparacion.variacionPorcentual, isNull);
    expect(restarMeses(DateTime(2024, 5, 31), 3), DateTime(2024, 2, 29));
    final uno = resumirPeriodo([items.first]).first;
    expect(uno.cantidadValores, 1);
    expect(uno.comparacion.anterior, uno.comparacion.actual);
  });

  testWidgets(
      'gráfico permite ocultar series y su tooltip contiene todos los valores visibles',
      (tester) async {
    final items = [
      medicion('1', DateTime(2026, 1, 1, 12),
          medidas: {'hombros': 90, 'pecho': 100}),
      medicion('2', DateTime(2026, 2, 1, 12),
          medidas: {'hombros': 91, 'pecho': 101}),
    ];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child:
              GraficoEvolucion(mediciones: items, indicadores: troncoSuperior),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    var chart = tester.widget<LineChart>(find.byType(LineChart));
    expect(chart.data.lineBarsData.length, 2);
    var bar = chart.data.lineBarsData.first;
    var tooltip = chart.data.lineTouchData.touchTooltipData
        .getTooltipItems([
          LineBarSpot(bar, 0, bar.spots.first),
        ])
        .first!
        .text;
    expect(tooltip, contains('01/01/2026'));
    expect(tooltip, contains('Hombros: 90'));
    expect(tooltip, contains('Pecho: 100'));
    expect(tooltip, contains('Espalda: —'));
    final grafico = tester.getRect(find.byType(LineChart));
    await tester.tapAt(Offset(grafico.left + 49, grafico.center.dy));
    await tester.pump();
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Pecho'));
    await tester.pumpAndSettle();
    chart = tester.widget<LineChart>(find.byType(LineChart));
    expect(chart.data.lineBarsData.length, 1);
    bar = chart.data.lineBarsData.first;
    tooltip = chart.data.lineTouchData.touchTooltipData
        .getTooltipItems([
          LineBarSpot(bar, 0, bar.spots.first),
        ])
        .first!
        .text;
    expect(tooltip, isNot(contains('Pecho:')));
    expect(tester.takeException(), isNull);
  });

  testWidgets('vista actualiza solo al solicitarlo y limita el calendario',
      (tester) async {
    final hoy = DateTime.now();
    final primera = inicioDia(hoy.subtract(const Duration(days: 400)));
    final ultima = inicioDia(hoy.subtract(const Duration(days: 200)));
    final servicio = ServicioHistorial({
      null: PaginaMediciones([medicion('2', ultima)], 'anterior'),
      'anterior': PaginaMediciones([medicion('1', primera)], null),
    });
    await tester.pumpWidget(MaterialApp(
      home: EvolucionMedicionesView(
        cliente:
            const UsuarioResumen(id: '1', nombre: 'Cliente', usuario: '123'),
        service: servicio,
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('2 evaluaciones en el período'), findsOneWidget);
    expect(servicio.solicitudes, [null, 'anterior']);
    await tester.tap(find.text('3 meses'));
    await tester.pumpAndSettle();
    expect(find.text('0 evaluaciones en el período'), findsOneWidget);
    await tester.tap(find.widgetWithText(
        OutlinedButton, 'Desde: ${_fecha(restarMeses(inicioDia(hoy), 3))}'));
    await tester.pumpAndSettle();
    final selector =
        tester.widget<DatePickerDialog>(find.byType(DatePickerDialog));
    expect(selector.firstDate, primera);
    expect(selector.lastDate, ultima);
    expect(selector.initialDate, ultima);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('1 evaluaciones en el período'), findsOneWidget);
    servicio.paginas[null] = PaginaMediciones(
      [medicion('3', hoy), medicion('2', hoy)],
      null,
    );
    await tester.pump(const Duration(minutes: 1));
    await tester.pumpAndSettle();
    expect(servicio.solicitudes, [null, 'anterior']);
    await tester.tap(find.byTooltip('Actualizar historial'));
    await tester.pumpAndSettle();
    expect(servicio.solicitudes, [null, 'anterior', null]);
    expect(find.text('2 evaluaciones en el período'), findsOneWidget);
    await tester.tap(find.widgetWithText(
        OutlinedButton, 'Desde: ${_fecha(inicioDia(hoy))}'));
    await tester.pumpAndSettle();
    final actualizado =
        tester.widget<DatePickerDialog>(find.byType(DatePickerDialog));
    expect(actualizado.firstDate, inicioDia(hoy));
    expect(actualizado.lastDate, inicioDia(hoy));
    expect(actualizado.initialDate, inicioDia(hoy));
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('deshabilita fechas sin mediciones y permite un único día',
      (tester) async {
    final hoy = inicioDia(DateTime.now());
    final servicio = ServicioHistorial({
      null: PaginaMediciones([], null),
    });
    await tester.pumpWidget(MaterialApp(
      home: EvolucionMedicionesView(
        cliente:
            const UsuarioResumen(id: '1', nombre: 'Cliente', usuario: '123'),
        service: servicio,
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('0 evaluaciones en el período'), findsOneWidget);
    final desde = find.widgetWithText(OutlinedButton, 'Desde: Sin mediciones');
    final hasta = find.widgetWithText(OutlinedButton, 'Hasta: Sin mediciones');
    expect(tester.widget<OutlinedButton>(desde).onPressed, isNull);
    expect(tester.widget<OutlinedButton>(hasta).onPressed, isNull);
    servicio.paginas[null] = PaginaMediciones([medicion('1', hoy)], null);
    await tester.tap(find.byTooltip('Actualizar historial'));
    await tester.pumpAndSettle();
    expect(find.text('1 evaluaciones en el período'), findsOneWidget);
    await tester
        .tap(find.widgetWithText(OutlinedButton, 'Hasta: ${_fecha(hoy)}'));
    await tester.pumpAndSettle();
    final selector =
        tester.widget<DatePickerDialog>(find.byType(DatePickerDialog));
    expect(selector.firstDate, hoy);
    expect(selector.lastDate, hoy);
    expect(selector.initialDate, hoy);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    servicio.paginas[null] = PaginaMediciones([], null);
    await tester.tap(find.byTooltip('Actualizar historial'));
    await tester.pumpAndSettle();
    expect(tester.widget<OutlinedButton>(desde).onPressed, isNull);
    expect(tester.widget<OutlinedButton>(hasta).onPressed, isNull);
    expect(find.text('0 evaluaciones en el período'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

String _fecha(DateTime fecha) =>
    '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
