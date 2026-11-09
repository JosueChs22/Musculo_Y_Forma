import '../models/clase.dart';
import '../models/horario_clase.dart';

/// Contrato de acceso a datos para la gestión de clases (Secretaria).
abstract class ClasesService {
  Future<List<Clase>> getClases();
  Future<Clase> crearClase({required String nombre, String? descripcion});
  Future<Clase> actualizarClase(String id, {String? nombre, String? descripcion});
  Future<Clase> inhabilitarClase(String id);
  Future<Clase> agregarHorario(String idClase, HorarioClase horario);
  Future<Clase> actualizarHorario(String idClase, int index, HorarioClase horario);
  Future<Clase> inhabilitarHorario(String idClase, int index);
}
