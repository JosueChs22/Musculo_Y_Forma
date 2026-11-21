import '../models/datos_medicion.dart';
import '../models/medicion_cliente.dart';

abstract class MedicionesService {
  Future<void> crearMedicion(DatosMedicion medicion);

  Future<PaginaMediciones> listarHistorial(
    String idUsuario, {
    required String estado,
    String? cursor,
  });

  Future<MedicionCliente> actualizarMedicion(String id, DatosMedicion medicion);

  Future<void> cambiarEstadoMedicion(String id, String estado);
}
