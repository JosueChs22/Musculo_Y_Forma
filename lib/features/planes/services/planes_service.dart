import '../models/plan.dart';

/// Contrato de los planes del entrenador y de la búsqueda de clientes para asignarlos.
/// Las operaciones lanzan [ApiException] con un mensaje para el usuario si fallan.
abstract class PlanesService {
  /// Planes del entrenador, del más nuevo al más viejo. [soloActivos] en false
  /// incluye también los inhabilitados.
  Future<PaginaPlanes> listar({
    CategoriaPlan? categoria,
    String? texto,
    bool soloActivos = true,
    String? cursor,
  });

  /// Plan completo, con el detalle de cada ejercicio.
  Future<Plan> obtener(String id);

  /// Crea el plan. Si trae [idUsuario], nace ya asignado a ese cliente.
  Future<Plan> crear(DatosPlan datos, {String? idUsuario});

  /// Actualiza nombre, categoría, día y ejercicios (no cambia a quién está asignado).
  Future<Plan> actualizar(String id, DatosPlan datos);

  /// Asigna el plan a un cliente, o lo deja sin asignar si [idUsuario] es null.
  Future<UsuarioResumen?> asignar(String id, String? idUsuario);

  Future<void> inhabilitar(String id);

  Future<void> reactivar(String id);

  /// Clientes activos cuyo nombre, apellido o usuario contiene [texto].
  Future<PaginaClientes> buscarClientes({String? texto, String? cursor});
}
