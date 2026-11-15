import '../models/cliente.dart';

/// Contrato para registrar clientes desde el panel de Secretaría.
abstract class ClientesService {
  Future<PaginaClientes> listarClientes({
    String? estado,
    String? busqueda,
    String? cursor,
  });

  Future<Cliente> crearCliente({
    required String nombre,
    required String primerApellido,
    required String segundoApellido,
    required String correo,
    required String cedula,
    required String telefono,
    required String carne,
    required DateTime fechaIngreso,
  });

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
  });

  Future<Cliente> cambiarEstadoCliente(String id, EstadoCliente estado);
}
