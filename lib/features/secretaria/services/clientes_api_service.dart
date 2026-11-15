import '../../../core/api_http.dart';
import '../models/cliente.dart';
import 'clientes_service.dart';

/// Implementación real: administra clientes en /clientes con la sesión actual.
class ClientesApiService implements ClientesService {
  ClientesApiService({ApiHttp? http}) : _http = http ?? ApiHttp();

  final ApiHttp _http;

  @override
  Future<PaginaClientes> listarClientes({
    String? estado,
    String? busqueda,
    String? cursor,
  }) async {
    final json = await _http.get('/clientes', query: {
      'limite': '20',
      'vista': 'gestion',
      if (busqueda != null && busqueda.isNotEmpty) 'q': busqueda,
      if (estado != null) 'estado': estado,
      if (cursor != null) 'cursor': cursor,
    });
    return PaginaClientes(
      (json['data'] as List)
          .map((item) => Cliente.fromJson(item as Map<String, dynamic>))
          .toList(),
      json['nextCursor'] as String?,
    );
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
      Cliente.fromJson(await _http.post(
          '/clientes',
          _cuerpo({
            'nombre': nombre,
            'primer_apellido': primerApellido,
            'segundo_apellido': segundoApellido,
            'correo': correo,
            'cedula': cedula,
            'telefono': telefono,
            'usuario': carne,
            'fecha_ingreso': _fechaApi(fechaIngreso),
          })));

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
      Cliente.fromJson(await _http.put(
          '/clientes/$id',
          _cuerpo({
            'nombre': nombre,
            'primer_apellido': primerApellido,
            'segundo_apellido': segundoApellido,
            'correo': correo,
            'cedula': cedula,
            'telefono': telefono,
            'usuario': carne,
            'fecha_ingreso': _fechaApi(fechaIngreso),
          })));

  @override
  Future<Cliente> cambiarEstadoCliente(String id, EstadoCliente estado) async =>
      Cliente.fromJson(
          await _http.patch('/clientes/$id/estado', {'estado': estado.valor}));

  Map<String, dynamic> _cuerpo(Map<String, String> campos) =>
      campos.map((campo, valor) => MapEntry(campo, valor.trim()));

  String _fechaApi(DateTime fecha) =>
      '${fecha.year.toString().padLeft(4, '0')}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';
}
