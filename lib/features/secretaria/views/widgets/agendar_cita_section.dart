import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/api_exception.dart';
import '../../../../core/theme.dart';
import '../../../../core/widgets.dart';
import '../../models/cita.dart';
import '../../services/citas_service.dart';
import '../../utils/citas_utils.dart';

class AgendarCitaSection extends StatefulWidget {
  const AgendarCitaSection({super.key});

  @override
  State<AgendarCitaSection> createState() => _AgendarCitaSectionState();
}

class _AgendarCitaSectionState extends State<AgendarCitaSection> {
  final _carne = TextEditingController();

  List<EntrenadorCita> _entrenadores = const [];
  ClienteCita? _cliente;
  String? _idCoach;
  DateTime? _fecha;
  String? _hora;
  String? _errorCliente;
  String? _errorEntrenadores;
  String? _errorCita;
  bool _buscandoCliente = false;
  bool _cargandoEntrenadores = true;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargarEntrenadores());
  }

  @override
  void dispose() {
    _carne.dispose();
    super.dispose();
  }

  Future<void> _cargarEntrenadores() async {
    try {
      final entrenadores =
          await context.read<CitasService>().listarEntrenadoresActivos();
      if (!mounted) return;
      setState(() {
        _entrenadores = entrenadores;
        _cargandoEntrenadores = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorEntrenadores = e.mensaje;
        _cargandoEntrenadores = false;
      });
    } catch (e) {
      if (!mounted) return;
      debugPrint('Error inesperado al cargar entrenadores para citas: $e');
      setState(() {
        _errorEntrenadores = 'No se pudo cargar la lista de entrenadores.';
        _cargandoEntrenadores = false;
      });
    }
  }

  Future<void> _buscarCliente() async {
    if (_buscandoCliente) return;
    final carne = _carne.text.trim();
    if (carne.isEmpty) {
      setState(() => _errorCliente = 'Ingresa el número de carné del cliente.');
      return;
    }

    setState(() {
      _buscandoCliente = true;
      _cliente = null;
      _errorCliente = null;
      _errorCita = null;
      _idCoach = null;
      _fecha = null;
      _hora = null;
    });
    try {
      final cliente =
          await context.read<CitasService>().buscarClientePorCarne(carne);
      if (!mounted) return;
      setState(() => _cliente = cliente);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _errorCliente = e.mensaje);
    } catch (e) {
      if (!mounted) return;
      debugPrint('Error inesperado al buscar cliente por carné: $e');
      setState(() =>
          _errorCliente = 'No se pudo buscar el cliente. Inténtalo de nuevo.');
    } finally {
      if (mounted) setState(() => _buscandoCliente = false);
    }
  }

  void _cambiarCarne(String _) {
    if (_cliente == null && _errorCliente == null) return;
    setState(() {
      _cliente = null;
      _errorCliente = null;
      _errorCita = null;
      _idCoach = null;
      _fecha = null;
      _hora = null;
    });
  }

  Future<void> _elegirFecha() async {
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    final inicial = _fecha != null && !_fecha!.isBefore(hoy) ? _fecha! : hoy;
    final fecha = await showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: hoy,
      lastDate: DateTime(2100),
      helpText: 'Selecciona la fecha de la cita',
    );
    if (fecha == null || !mounted) return;
    setState(() {
      _fecha = DateTime(fecha.year, fecha.month, fecha.day);
      if (!horasDisponiblesCita(_fecha).any((hora) => hora == _hora)) {
        _hora = null;
      }
      _errorCita = null;
    });
  }

  Future<void> _guardarCita() async {
    final cliente = _cliente;
    final coach = _idCoach;
    final fecha = _fecha;
    final hora = _hora;
    if (cliente == null) {
      setState(
          () => _errorCita = 'Busca y confirma primero un cliente activo.');
      return;
    }
    if (coach == null || fecha == null || hora == null) {
      setState(
          () => _errorCita = 'Completa el entrenador, la fecha y la hora.');
      return;
    }

    final partesHora = hora.split(':').map(int.parse).toList();
    final fechaHoraLocal = DateTime(
      fecha.year,
      fecha.month,
      fecha.day,
      partesHora[0],
      partesHora[1],
    );
    if (!fechaHoraLocal.isAfter(DateTime.now())) {
      setState(() {
        _hora = null;
        _errorCita =
            'La fecha y hora debe ser futura. Selecciona otro horario.';
      });
      return;
    }

    setState(() {
      _guardando = true;
      _errorCita = null;
    });
    try {
      final puedeContinuar = await _validarCitaMismoDia(
        cliente.id,
        fecha,
        fechaHoraLocal,
      );
      if (!mounted || !puedeContinuar) return;

      await context.read<CitasService>().crearCita(
            idCliente: cliente.id,
            idCoach: coach,
            fechaHora: fechaHoraConZona(fechaHoraLocal),
          );
      if (!mounted) return;
      setState(() {
        _cliente = null;
        _idCoach = null;
        _fecha = null;
        _hora = null;
        _errorCita = null;
      });
      _carne.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cita registrada correctamente.')),
      );
    } on ApiException catch (e) {
      if (mounted) setState(() => _errorCita = e.mensaje);
    } catch (e) {
      if (!mounted) return;
      debugPrint('Error inesperado al registrar la cita: $e');
      setState(() =>
          _errorCita = 'No se pudo registrar la cita. Inténtalo de nuevo.');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<bool> _validarCitaMismoDia(
    String idCliente,
    DateTime fecha,
    DateTime fechaHoraLocal,
  ) async {
    final inicioDia = DateTime(fecha.year, fecha.month, fecha.day);
    final inicioDiaSiguiente = DateTime(fecha.year, fecha.month, fecha.day + 1);
    final citasDia =
        await context.read<CitasService>().listarCitasAgendadasClienteEnRango(
              idCliente: idCliente,
              inicio: fechaHoraConZona(inicioDia),
              fin: fechaHoraConZona(inicioDiaSiguiente),
            );
    if (!mounted) return false;

    if (citasDia.any((cita) => cita.isAtSameMomentAs(fechaHoraLocal))) {
      setState(() {
        _errorCita =
            'Este cliente ya tiene una cita agendada para esa fecha y hora.';
      });
      return false;
    }
    if (citasDia.isEmpty) return true;

    final horasExistentes =
        citasDia.map((cita) => horaCitaLabel(cita.toLocal())).join(', ');
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Aviso: cita existente'),
            content: Text(
              'Este cliente ya tiene una cita agendada el ${fechaCitaLabel(fecha)} '
              'a las $horasExistentes. ¿Deseas continuar con otra cita?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Continuar'),
              ),
            ],
          ),
        ) ==
        true;
  }

  @override
  Widget build(BuildContext context) => Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionHeader(
              eyebrow: 'Agenda de citas',
              title: 'Agendar cita',
            ),
            const SizedBox(height: 20),
            Text(
              'Busca al cliente por carné para comenzar.',
              style: ts(14, color: AppColors.pizarra),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final campo = TextField(
                  controller: _carne,
                  enabled: !_buscandoCliente,
                  onChanged: _cambiarCarne,
                  onSubmitted: (_) => _buscarCliente(),
                  textInputAction: TextInputAction.search,
                  decoration: const InputDecoration(
                    labelText: 'Número de carné',
                    hintText: 'Escribe el carné del cliente',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                );
                final boton = PrimaryButton(
                  label: 'Buscar cliente',
                  icon: Icons.search,
                  busy: _buscandoCliente,
                  onPressed: _buscandoCliente ? null : _buscarCliente,
                );
                if (constraints.maxWidth < 560) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [campo, const SizedBox(height: 12), boton],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: campo),
                    const SizedBox(width: 12),
                    boton,
                  ],
                );
              },
            ),
            if (_errorCliente != null) ...[
              const SizedBox(height: 8),
              _MensajeError(_errorCliente!),
            ],
            if (_cliente case final cliente?) ...[
              const SizedBox(height: 20),
              _ClienteConfirmacion(cliente: cliente),
              const SizedBox(height: 24),
              Text('Entrenador', style: ts(14, weight: kSemi)),
              const SizedBox(height: 8),
              if (_cargandoEntrenadores)
                const LinearProgressIndicator()
              else if (_errorEntrenadores != null)
                _MensajeError(_errorEntrenadores!)
              else if (_entrenadores.isEmpty)
                const _MensajeError('No hay entrenadores activos disponibles.')
              else
                DropdownButtonFormField<String>(
                  initialValue: _idCoach,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.fitness_center),
                    hintText: 'Selecciona un entrenador activo',
                  ),
                  items: [
                    for (final entrenador in _entrenadores)
                      DropdownMenuItem(
                        value: entrenador.id,
                        child: Text(entrenador.nombreCompleto),
                      ),
                  ],
                  onChanged: _guardando
                      ? null
                      : (id) => setState(() {
                            _idCoach = id;
                            _errorCita = null;
                          }),
                ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final fecha = OutlinedButton.icon(
                    onPressed: _guardando ? null : _elegirFecha,
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: Text(_fecha == null
                        ? 'Seleccionar fecha'
                        : fechaCitaLabel(_fecha!)),
                  );
                  final horas = horasDisponiblesCita(_fecha);
                  final hora = DropdownButtonFormField<String>(
                    initialValue: horas.contains(_hora) ? _hora : null,
                    decoration: const InputDecoration(
                      labelText: 'Hora',
                      prefixIcon: Icon(Icons.schedule),
                    ),
                    hint: Text(_fecha == null
                        ? 'Primero selecciona una fecha'
                        : 'Selecciona una hora'),
                    items: [
                      for (final valor in horas)
                        DropdownMenuItem(value: valor, child: Text(valor)),
                    ],
                    onChanged: _guardando || _fecha == null || horas.isEmpty
                        ? null
                        : (valor) => setState(() {
                              _hora = valor;
                              _errorCita = null;
                            }),
                  );
                  if (constraints.maxWidth < 560) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [fecha, const SizedBox(height: 12), hora],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: fecha),
                      const SizedBox(width: 12),
                      Expanded(child: hora),
                    ],
                  );
                },
              ),
              if (_errorCita != null) ...[
                const SizedBox(height: 8),
                _MensajeError(_errorCita!),
              ],
              const SizedBox(height: 8),
              PrimaryButton(
                label: 'Confirmar cita',
                icon: Icons.event_available_outlined,
                busy: _guardando,
                onPressed:
                    _guardando || _cargandoEntrenadores || _entrenadores.isEmpty
                        ? null
                        : _guardarCita,
              ),
            ],
          ],
        ),
      );
}

class _ClienteConfirmacion extends StatelessWidget {
  const _ClienteConfirmacion({required this.cliente});

  final ClienteCita cliente;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.indigoSoft,
          borderRadius: BorderRadius.circular(kRadiusControl),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.verified_user_outlined,
                    color: AppColors.success),
                const SizedBox(width: 8),
                Text('Confirma los datos del cliente',
                    style: ts(14, weight: kSemi)),
              ],
            ),
            const SizedBox(height: 12),
            Text(cliente.nombreCompleto, style: ts(18, weight: kSemi)),
            const SizedBox(height: 4),
            Text('Carné: ${cliente.carne} · Cédula: ${cliente.cedula}',
                style: ts(14)),
            Text(cliente.correo, style: ts(14, color: AppColors.pizarra)),
            Text('Estado: ${cliente.estado}', style: ts(14, weight: kSemi)),
          ],
        ),
      );
}

class _MensajeError extends StatelessWidget {
  const _MensajeError(this.mensaje);

  final String mensaje;

  @override
  Widget build(BuildContext context) => Text(
        mensaje,
        style: ts(14, weight: kSemi, color: AppColors.danger),
      );
}
