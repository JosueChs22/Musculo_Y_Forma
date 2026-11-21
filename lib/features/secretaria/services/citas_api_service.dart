import '../../../core/api_http.dart';
import '../models/cita.dart';
import 'citas_service.dart';

class CitasApiService implements CitasService {
  CitasApiService({ApiHttp? http}) : _http = http ?? ApiHttp();

  final ApiHttp _http;

  @override
  Future<ClienteCita> buscarClientePorCarne(String carne) async =>
      ClienteCita.fromJson(
        await _http.get('/citas/clientes/${Uri.encodeComponent(carne.trim())}'),
      );

  @override
  Future<List<EntrenadorCita>> listarEntrenadoresActivos() async {
    final json = await _http.get('/citas/entrenadores');
    return [
      for (final entrenador in json['data'] as List)
        EntrenadorCita.fromJson(entrenador as Map<String, dynamic>),
    ];
  }

  @override
  Future<List<CitaConsulta>> listarCitasPorFecha({
    required String inicio,
    required String fin,
  }) async {
    final json =
        await _http.get('/citas', query: {'inicio': inicio, 'fin': fin});
    return [
      for (final cita in json['data'] as List)
        CitaConsulta.fromJson(cita as Map<String, dynamic>),
    ];
  }

  @override
  Future<List<CitaConsulta>> listarCitasEntrenadorPorFecha({
    required String inicio,
    required String fin,
  }) async {
    final json = await _http.get(
      '/citas/entrenador',
      query: {'inicio': inicio, 'fin': fin},
    );
    return [
      for (final cita in json['data'] as List)
        CitaConsulta.fromJson(cita as Map<String, dynamic>),
    ];
  }

  @override
  Future<List<CitaConsulta>> buscarUltimasCitasEntrenador(String termino) async {
    final json = await _http.get(
      '/citas/entrenador/buscar',
      query: {'q': termino.trim()},
    );
    return [
      for (final cita in json['data'] as List)
        CitaConsulta.fromJson(cita as Map<String, dynamic>),
    ];
  }

  @override
  Future<List<DateTime>> listarCitasAgendadasClienteEnRango({
    required String idCliente,
    required String inicio,
    required String fin,
    String? excluirCitaId,
  }) async {
    final query = {'inicio': inicio, 'fin': fin};
    if (excluirCitaId != null) query['excluir'] = excluirCitaId;
    final json = await _http.get(
      '/citas/clientes/${Uri.encodeComponent(idCliente)}/agenda',
      query: query,
    );
    return [
      for (final cita in json['data'] as List)
        DateTime.parse((cita as Map<String, dynamic>)['fechaHora'] as String),
    ];
  }

  @override
  Future<CitaAgendada> crearCita({
    required String idCliente,
    required String idCoach,
    required String fechaHora,
  }) async =>
      CitaAgendada.fromJson(await _http.post('/citas', {
        'id_cliente': idCliente,
        'id_coach': idCoach,
        'fecha_hora': fechaHora,
      }));

  @override
  Future<CitaAgendada> actualizarCita({
    required String idCita,
    required String idCoach,
    required String fechaHora,
  }) async =>
      CitaAgendada.fromJson(await _http.put(
        '/citas/${Uri.encodeComponent(idCita)}',
        {'id_coach': idCoach, 'fecha_hora': fechaHora},
      ));

  @override
  Future<CitaAgendada> cambiarEstadoCita({
    required String idCita,
    required String estado,
  }) async =>
      CitaAgendada.fromJson(await _http.patch(
        '/citas/${Uri.encodeComponent(idCita)}/estado',
        {'estado': estado},
      ));
}
