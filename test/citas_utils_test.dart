import 'package:flutter_test/flutter_test.dart';
import 'package:pulso_app/features/secretaria/models/cita.dart';
import 'package:pulso_app/features/secretaria/utils/citas_utils.dart';

void main() {
  final cita = CitaConsulta(
    id: 'cita-1',
    idCliente: 'cliente-1',
    clienteNombreCompleto: 'Ana Pérez Muñoz',
    carne: 'MF-1234',
    idCoach: 'coach-1',
    entrenadorNombreCompleto: 'Luis Mora',
    fechaHora: DateTime.utc(2026, 11, 15, 14, 30),
    estado: 'Agendada',
  );

  test('busca citas por fragmento de carné sin distinguir mayúsculas', () {
    expect(coincideCitaConsulta(cita, 'mf-12'), isTrue);
  });

  test('busca por nombre completo sin exigir tildes', () {
    expect(coincideCitaConsulta(cita, 'ana perez munoz'), isTrue);
  });

  test('no coincide con una búsqueda distinta', () {
    expect(coincideCitaConsulta(cita, 'C999'), isFalse);
  });
}
