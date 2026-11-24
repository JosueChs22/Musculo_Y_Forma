import 'package:flutter_test/flutter_test.dart';
import 'package:pulso_app/features/horarios/controllers/horarios_controller.dart';
import 'package:pulso_app/features/horarios/services/horarios_service.dart';
import 'package:pulso_app/features/secretaria/models/clase.dart';
import 'package:pulso_app/features/secretaria/models/horario_clase.dart';

HorarioClase _h(List<int> dias, String ini, String fin, {String estado = 'Activo'}) =>
    HorarioClase(dias: dias, horaInicio: ini, horaFin: fin, estado: estado);

Clase _c(String id, String nombre, List<HorarioClase> horarios, {String estado = 'Activo'}) =>
    Clase(id: id, nombre: nombre, instructores: const [], estado: estado, horarios: horarios);

class _Fake implements HorariosService {
  _Fake(this.clases, {this.falla = false});
  final List<Clase> clases;
  final bool falla;

  @override
  Future<List<Clase>> getClases() async {
    if (falla) throw Exception('red');
    return clases;
  }
}

void main() {
  final clases = [
    _c('1', 'Yoga', [_h([1, 3], '18:00', '19:00'), _h([1], '07:00', '08:00')]),
    _c('2', 'Spinning', [_h([3], '06:00', '07:00'), _h([5], '10:00', '11:00', estado: 'Inhabilitado')]),
    _c('3', 'Zumba', [_h([2], '09:00', '10:00')], estado: 'Inhabilitada'),
  ];

  test('agrupa por día, ordena por hora y filtra lo inactivo', () {
    final dias = HorariosController.agrupar(clases, hoy: 1);
    expect(dias.map((d) => d.dia), [1, 3]); // martes (clase inactiva) y viernes (horario inactivo) no salen
    expect(dias[0].sesiones.map((s) => s.horaInicio), ['07:00', '18:00']);
    expect(dias[1].sesiones.map((s) => s.nombre), ['Spinning', 'Yoga']);
  });

  test('el día de hoy va primero y luego en orden circular', () {
    final dias = HorariosController.agrupar(clases, hoy: 3);
    expect(dias.map((d) => d.dia), [3, 1]);
    expect(dias.first.nombre, 'Miércoles');
  });

  test('load usa la fecha inyectada y expone error si falla', () async {
    final c = HorariosController(_Fake(clases), ahora: () => DateTime(2026, 11, 25)); // miércoles
    await c.load();
    expect(c.hoy, 3);
    expect(c.dias.first.dia, 3);
    expect(c.error, isNull);

    final e = HorariosController(_Fake(const [], falla: true));
    await e.load();
    expect(e.error, isNotNull);
    expect(e.dias, isEmpty);
  });
}
