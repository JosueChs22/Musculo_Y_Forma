import '../models/reglamento.dart';

/// Contrato del servicio del reglamento del gimnasio (panel del Administrador).
abstract class ReglamentosService {
  /// RF-102: todos los reglamentos, activos e inhabilitados, del más nuevo al más viejo.
  Future<List<Reglamento>> getReglamentos();

  /// RF-093: lo que ven los clientes: solo los reglamentos activos, del más nuevo al más viejo.
  Future<List<Reglamento>> getReglamentosVigentes();

  /// RF-097: publica un reglamento (queda Activo).
  Future<Reglamento> crearReglamento({required String titulo, required String contenido});

  /// RF-098: modifica el título y el contenido. Devuelve el reglamento actualizado.
  Future<Reglamento> actualizarReglamento({
    required String id,
    required String titulo,
    required String contenido,
  });

  /// RF-101: cambia el estado a Inhabilitado (no borra nada). Devuelve el reglamento actualizado.
  Future<Reglamento> inhabilitarReglamento(String id);

  /// Vuelve a publicar un reglamento inhabilitado. Devuelve el reglamento actualizado.
  Future<Reglamento> habilitarReglamento(String id);
}
