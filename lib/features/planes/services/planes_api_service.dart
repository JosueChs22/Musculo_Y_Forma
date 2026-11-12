import '../../../core/api_http.dart';
import '../models/plan.dart';
import 'planes_service.dart';

/// Implementación real: llama a /rutinas y /clientes (token de Entrenador o Administrador).
class PlanesApiService implements PlanesService {
  PlanesApiService({ApiHttp? http}) : _http = http ?? ApiHttp();

  final ApiHttp _http;

  @override
  Future<PaginaPlanes> listar({
    CategoriaPlan? categoria,
    String? texto,
    bool soloActivos = true,
    String? cursor,
  }) async {
    final json = await _http.get('/rutinas', query: {
      'limite': '20',
      if (categoria != null) 'categoria': categoria.valor,
      if (texto != null && texto.isNotEmpty) 'q': texto,
      if (soloActivos) 'estado': 'Activo',
      if (cursor != null) 'cursor': cursor,
    });
    return PaginaPlanes(
      (json['data'] as List).map((e) => Plan.fromJson(e as Map<String, dynamic>)).toList(),
      json['nextCursor'] as String?,
    );
  }

  @override
  Future<Plan> obtener(String id) async => Plan.fromJson(await _http.get('/rutinas/$id'));

  @override
  Future<Plan> crear(DatosPlan datos, {String? idUsuario}) async => Plan.fromJson(
        await _http.post('/rutinas', {...datos.toJson(), if (idUsuario != null) 'id_usuario': idUsuario}),
      );

  @override
  Future<Plan> actualizar(String id, DatosPlan datos) async =>
      Plan.fromJson(await _http.put('/rutinas/$id', datos.toJson()));

  @override
  Future<UsuarioResumen?> asignar(String id, String? idUsuario) async {
    final json = await _http.patch('/rutinas/$id/asignar', {'id_usuario': idUsuario});
    final u = json['usuario'];
    return u == null ? null : UsuarioResumen.fromJson(u as Map<String, dynamic>);
  }

  @override
  Future<void> inhabilitar(String id) async {
    await _http.patch('/rutinas/$id/inhabilitar');
  }

  @override
  Future<void> reactivar(String id) async {
    await _http.patch('/rutinas/$id/reactivar');
  }

  @override
  Future<PaginaClientes> buscarClientes({String? texto, String? cursor}) async {
    final json = await _http.get('/clientes', query: {
      'limite': '20',
      if (texto != null && texto.isNotEmpty) 'q': texto,
      if (cursor != null) 'cursor': cursor,
    });
    return PaginaClientes(
      (json['data'] as List).map((e) => UsuarioResumen.fromJson(e as Map<String, dynamic>)).toList(),
      json['nextCursor'] as String?,
    );
  }
}
