import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pulso_app/core/api_exception.dart';
import 'package:pulso_app/features/secretaria/controllers/clientes_controller.dart';
import 'package:pulso_app/features/secretaria/models/cliente.dart';
import 'package:pulso_app/features/secretaria/services/clientes_service.dart';

Cliente _cliente(String id, EstadoCliente estado) => Cliente(
      id: id,
      nombre: 'Ana',
      primerApellido: 'Pérez',
      segundoApellido: 'López',
      correo: 'ana$id@example.com',
      cedula: 'CR-$id',
      telefono: '88887777',
      carne: 'carne$id',
      estado: estado,
      fechaIngreso: DateTime(2026, 11, 12),
    );

class _ClientesFake implements ClientesService {
  final List<String?> estadosConsultados = [];
  final List<String?> busquedasConsultadas = [];
  final List<String?> cursoresConsultados = [];
  final Completer<Cliente> cambioEstadoPendiente = Completer<Cliente>();
  bool esperarCambioEstado = false;

  @override
  Future<PaginaClientes> listarClientes(
      {String? estado, String? busqueda, String? cursor}) async {
    estadosConsultados.add(estado);
    busquedasConsultadas.add(busqueda);
    cursoresConsultados.add(cursor);
    if (cursor != null) {
      return PaginaClientes([_cliente('2', EstadoCliente.activo)], null);
    }
    return PaginaClientes([_cliente('1', EstadoCliente.activo)], 'cursor-2');
  }

  @override
  Future<Cliente> crearCliente({
    required String nombre,
    required String primerApellido,
    required String segundoApellido,
    required String correo,
    required String cedula,
    required String telefono,
    required String carne,
    required DateTime fechaIngreso,
  }) async =>
      throw UnimplementedError();

  @override
  Future<Cliente> actualizarCliente(
    String id, {
    required String nombre,
    required String primerApellido,
    required String segundoApellido,
    required String correo,
    required String cedula,
    required String telefono,
    required String carne,
    required DateTime fechaIngreso,
  }) async =>
      throw UnimplementedError();

  @override
  Future<Cliente> cambiarEstadoCliente(String id, EstadoCliente estado) {
    if (esperarCambioEstado) return cambioEstadoPendiente.future;
    return Future.error(const ApiException('Sin conexión'));
  }
}

void main() {
  late _ClientesFake servicio;
  late ClientesController controller;

  setUp(() {
    servicio = _ClientesFake();
    controller = ClientesController(servicio);
  });

  tearDown(() => controller.dispose());

  test('carga clientes por páginas y conserva el filtro de estado', () async {
    await controller.filtrarEstado(EstadoCliente.inhabilitado.valor);
    await controller.cargarClientes();

    expect(controller.clientes.map((cliente) => cliente.id), ['1', '2']);
    expect(servicio.estadosConsultados, [
      EstadoCliente.inhabilitado.valor,
      EstadoCliente.inhabilitado.valor,
    ]);
  });

  test(
      'buscar filtra por nombre o carné y reinicia la paginación con el estado',
      () async {
    await controller.filtrarEstado(EstadoCliente.inhabilitado.valor);
    await controller.cargarClientes();

    controller.buscar('  Ana 123  ');
    await Future<void>.delayed(const Duration(milliseconds: 350));

    expect(servicio.busquedasConsultadas.last, 'Ana 123');
    expect(servicio.estadosConsultados.last, EstadoCliente.inhabilitado.valor);
    expect(servicio.cursoresConsultados.last, isNull);
    expect(controller.clientes.map((cliente) => cliente.id), ['1']);
  });

  test('revierte el cambio optimista si falla la API', () async {
    await controller.cargarClientes(reiniciar: true);
    servicio.esperarCambioEstado = true;

    final request = controller.cambiarEstadoCliente(
      controller.clientes.single,
      EstadoCliente.inhabilitado,
    );
    expect(controller.clientes.single.estado, EstadoCliente.inhabilitado);

    servicio.cambioEstadoPendiente
        .completeError(const ApiException('Sin conexión'));
    expect(await request, isFalse);
    expect(controller.clientes.single.estado, EstadoCliente.activo);
    expect(controller.errorAccion, 'Sin conexión');
  });
}
