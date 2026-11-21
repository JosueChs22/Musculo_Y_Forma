import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pulso_app/core/api_http.dart';
import 'package:pulso_app/features/secretaria/services/citas_api_service.dart';

void main() {
  test('busca cliente y entrenadores, y envía la cita al API', () async {
    final requests = <http.Request>[];
    final service = CitasApiService(
      http: ApiHttp(
        client: MockClient((request) async {
          requests.add(request);
          if (request.url.path.endsWith('/clientes/C123')) {
            return http.Response(
              jsonEncode({
                'id': 'a' * 24,
                'nombreCompleto': 'Ana Pérez',
                'carne': 'C123',
                'cedula': '10101010',
                'correo': 'ana@example.com',
                'estado': 'Activo',
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          if (request.url.path.endsWith('/entrenadores')) {
            return http.Response(
              jsonEncode({
                'data': [
                  {
                    'id': 'b' * 24,
                    'nombreCompleto': 'Luis Mora',
                  },
                ],
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          if (request.url.path.endsWith('/agenda')) {
            return http.Response(
              jsonEncode({
                'data': [
                  {'fechaHora': '2026-11-15T13:00:00.000Z'},
                ],
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          if (request.method == 'GET' && request.url.path.endsWith('/citas')) {
            return http.Response(
              jsonEncode({
                'data': [
                  {
                    'id': 'c' * 24,
                    'idCliente': 'a' * 24,
                    'clienteNombreCompleto': 'Ana Pérez',
                    'carne': 'C123',
                    'idCoach': 'b' * 24,
                    'entrenadorNombreCompleto': 'Luis Mora',
                    'fechaHora': '2026-11-15T14:30:00.000Z',
                    'estado': 'Agendada',
                  },
                ],
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          if (request.method == 'GET' &&
              request.url.path.endsWith('/citas/entrenador')) {
            return http.Response(
              jsonEncode({
                'data': [
                  {
                    'id': 'c' * 24,
                    'idCliente': 'a' * 24,
                    'clienteNombreCompleto': 'Ana Pérez',
                    'carne': 'C123',
                    'idCoach': 'b' * 24,
                    'entrenadorNombreCompleto': 'Luis Mora',
                    'fechaHora': '2026-11-15T14:30:00.000Z',
                    'estado': 'Agendada',
                  },
                ],
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          if (request.method == 'PUT') {
            return http.Response(
              jsonEncode({
                'id': 'c' * 24,
                'idCliente': 'a' * 24,
                'idCoach': 'b' * 24,
                'fechaHora': '2026-11-16T14:30:00.000Z',
                'estado': 'Agendada',
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          if (request.method == 'PATCH') {
            return http.Response(
              jsonEncode({
                'id': 'c' * 24,
                'idCliente': 'a' * 24,
                'idCoach': 'b' * 24,
                'fechaHora': '2026-11-15T14:30:00.000Z',
                'estado': 'Cancelada',
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response(
            jsonEncode({
              'id': 'c' * 24,
              'idCliente': 'a' * 24,
              'idCoach': 'b' * 24,
              'fechaHora': '2026-11-15T14:30:00.000Z',
              'estado': 'Agendada',
            }),
            201,
            headers: {'content-type': 'application/json'},
          );
        }),
      ),
    );

    final cliente = await service.buscarClientePorCarne(' C123 ');
    final entrenadores = await service.listarEntrenadoresActivos();
    final citasDia = await service.listarCitasAgendadasClienteEnRango(
      idCliente: cliente.id,
      inicio: '2026-11-15T00:00:00-06:00',
      fin: '2026-11-16T00:00:00-06:00',
    );
    final citas = await service.listarCitasPorFecha(
      inicio: '2026-11-15T00:00:00-06:00',
      fin: '2026-11-16T00:00:00-06:00',
    );
    final citasEntrenador = await service.listarCitasEntrenadorPorFecha(
      inicio: '2026-11-15T00:00:00-06:00',
      fin: '2026-11-16T00:00:00-06:00',
    );
    final cita = await service.crearCita(
      idCliente: cliente.id,
      idCoach: entrenadores.single.id,
      fechaHora: '2026-11-15T08:30:00-06:00',
    );

    expect(cliente.nombreCompleto, 'Ana Pérez');
    expect(entrenadores.single.nombreCompleto, 'Luis Mora');
    expect(citasDia, [DateTime.parse('2026-11-15T13:00:00.000Z')]);
    expect(citas.single.clienteNombreCompleto, 'Ana Pérez');
    expect(citas.single.estado, 'Agendada');
    expect(citasEntrenador.single.carne, 'C123');
    expect(requests[2].url.queryParameters, {
      'inicio': '2026-11-15T00:00:00-06:00',
      'fin': '2026-11-16T00:00:00-06:00',
    });
    expect(requests[3].url.path, endsWith('/citas'));
    expect(requests[3].url.queryParameters, {
      'inicio': '2026-11-15T00:00:00-06:00',
      'fin': '2026-11-16T00:00:00-06:00',
    });
    expect(requests[4].url.path, endsWith('/citas/entrenador'));
    expect(requests[4].url.queryParameters, {
      'inicio': '2026-11-15T00:00:00-06:00',
      'fin': '2026-11-16T00:00:00-06:00',
    });
    expect(cita.estado, 'Agendada');
    expect(requests[5].url.path, endsWith('/citas'));
    expect(jsonDecode(requests[5].body), {
      'id_cliente': 'a' * 24,
      'id_coach': 'b' * 24,
      'fecha_hora': '2026-11-15T08:30:00-06:00',
    });

    final actualizada = await service.actualizarCita(
      idCita: 'c' * 24,
      idCoach: 'b' * 24,
      fechaHora: '2026-11-16T08:30:00-06:00',
    );
    expect(actualizada.fechaHora, DateTime.parse('2026-11-16T14:30:00.000Z'));
    expect(jsonDecode(requests.last.body), {
      'id_coach': 'b' * 24,
      'fecha_hora': '2026-11-16T08:30:00-06:00',
    });

    final cancelada = await service.cambiarEstadoCita(
      idCita: 'c' * 24,
      estado: 'Cancelada',
    );
    expect(cancelada.estado, 'Cancelada');
    expect(requests.last.method, 'PATCH');
    expect(requests.last.url.path, endsWith('/citas/${'c' * 24}/estado'));
    expect(jsonDecode(requests.last.body), {'estado': 'Cancelada'});
  });

  test('excluye la propia cita al revisar advertencias durante una edición',
      () async {
    late http.Request request;
    final service = CitasApiService(
      http: ApiHttp(
        client: MockClient((value) async {
          request = value;
          return http.Response(
            jsonEncode({'data': []}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      ),
    );

    await service.listarCitasAgendadasClienteEnRango(
      idCliente: 'a' * 24,
      inicio: '2026-11-15T00:00:00-06:00',
      fin: '2026-11-16T00:00:00-06:00',
      excluirCitaId: 'c' * 24,
    );

    expect(request.url.queryParameters['excluir'], 'c' * 24);
  });

  test('busca las citas más recientes del entrenador por nombre o carné',
      () async {
    late http.Request request;
    final service = CitasApiService(
      http: ApiHttp(
        client: MockClient((value) async {
          request = value;
          return http.Response(
            jsonEncode({
              'data': [
                {
                  'id': 'c' * 24,
                  'idCliente': 'a' * 24,
                  'clienteNombreCompleto': 'Ana Pérez',
                  'carne': 'C123',
                  'idCoach': 'b' * 24,
                  'entrenadorNombreCompleto': 'Luis Mora',
                  'fechaHora': '2026-11-15T14:30:00.000Z',
                  'estado': 'Agendada',
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      ),
    );

    final citas = await service.buscarUltimasCitasEntrenador('  ana pérez  ');

    expect(citas.single.clienteNombreCompleto, 'Ana Pérez');
    expect(request.url.path, endsWith('/citas/entrenador/buscar'));
    expect(request.url.queryParameters, {'q': 'ana pérez'});
  });
}
