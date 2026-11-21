import '../models/cita.dart';

abstract class CitasService {
  Future<ClienteCita> buscarClientePorCarne(String carne);

  Future<List<EntrenadorCita>> listarEntrenadoresActivos();

  Future<List<CitaConsulta>> listarCitasPorFecha({
    required String inicio,
    required String fin,
  });

  Future<List<CitaConsulta>> listarCitasEntrenadorPorFecha({
    required String inicio,
    required String fin,
  });

  Future<List<CitaConsulta>> buscarUltimasCitasEntrenador(String termino);

  Future<List<DateTime>> listarCitasAgendadasClienteEnRango({
    required String idCliente,
    required String inicio,
    required String fin,
    String? excluirCitaId,
  });

  Future<CitaAgendada> crearCita({
    required String idCliente,
    required String idCoach,
    required String fechaHora,
  });

  Future<CitaAgendada> actualizarCita({
    required String idCita,
    required String idCoach,
    required String fechaHora,
  });

  Future<CitaAgendada> cambiarEstadoCita({
    required String idCita,
    required String estado,
  });
}
