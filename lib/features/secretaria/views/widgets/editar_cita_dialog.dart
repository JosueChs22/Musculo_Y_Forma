import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/api_exception.dart';
import '../../../../core/theme.dart';
import '../../../../core/widgets.dart';
import '../../models/cita.dart';
import '../../services/citas_service.dart';
import '../../utils/citas_utils.dart';

class EditarCitaDialog extends StatefulWidget {
  const EditarCitaDialog({super.key, required this.cita});

  final CitaConsulta cita;

  static Future<CitaAgendada?> show(
    BuildContext context, {
    required CitaConsulta cita,
  }) =>
      showDialog<CitaAgendada>(
        context: context,
        builder: (_) => EditarCitaDialog(cita: cita),
      );

  @override
  State<EditarCitaDialog> createState() => _EditarCitaDialogState();
}

class _EditarCitaDialogState extends State<EditarCitaDialog> {
  List<EntrenadorCita> _entrenadores = const [];
  DateTime? _fecha;
  String? _hora;
  String? _idCoach;
  String? _error;
  bool _cargandoEntrenadores = true;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    final actual = widget.cita.fechaHora.toLocal();
    _fecha = DateTime(actual.year, actual.month, actual.day);
    final horaActual = horaCitaLabel(actual);
    if (horasDisponiblesCita(_fecha).contains(horaActual)) {
      _hora = horaActual;
    }
    _idCoach = widget.cita.idCoach;
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargarEntrenadores());
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
        _error = e.mensaje;
        _cargandoEntrenadores = false;
      });
    } catch (e) {
      if (!mounted) return;
      debugPrint(
          'Error inesperado al cargar entrenadores para editar cita: $e');
      setState(() {
        _error = 'No se pudo cargar la lista de entrenadores.';
        _cargandoEntrenadores = false;
      });
    }
  }

  Future<void> _elegirFecha() async {
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    final actual = _fecha;
    final inicial = actual == null || actual.isBefore(hoy) ? hoy : actual;
    final fecha = await showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: hoy,
      lastDate: DateTime(2100),
      helpText: 'Selecciona la fecha de la cita',
    );
    if (fecha == null || !mounted) return;
    final nuevoDia = DateTime(fecha.year, fecha.month, fecha.day);
    setState(() {
      _fecha = nuevoDia;
      if (!horasDisponiblesCita(nuevoDia).contains(_hora)) _hora = null;
      _error = null;
    });
  }

  Future<void> _guardar() async {
    final cita = widget.cita;
    final coach = _idCoach;
    final fecha = _fecha;
    final hora = _hora;
    if (coach == null || fecha == null || hora == null) {
      setState(() => _error = 'Selecciona un entrenador, fecha y hora.');
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
    if (partesHora[1] % 30 != 0) {
      setState(
          () => _error = 'La hora debe estar en intervalos de 30 minutos.');
      return;
    }
    if (!fechaHoraLocal.isAfter(DateTime.now())) {
      setState(() => _error = 'La fecha y hora debe ser futura.');
      return;
    }

    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      final inicioDia = DateTime(fecha.year, fecha.month, fecha.day);
      final inicioDiaSiguiente =
          DateTime(fecha.year, fecha.month, fecha.day + 1);
      final citasDia =
          await context.read<CitasService>().listarCitasAgendadasClienteEnRango(
                idCliente: cita.idCliente,
                inicio: fechaHoraConZona(inicioDia),
                fin: fechaHoraConZona(inicioDiaSiguiente),
                excluirCitaId: cita.id,
              );
      if (!mounted) return;

      if (citasDia.any((actual) => actual.isAtSameMomentAs(fechaHoraLocal))) {
        setState(() {
          _error =
              'El cliente ya tiene otra cita agendada para esa fecha y hora.';
        });
        return;
      }
      if (citasDia.isNotEmpty) {
        final continuar = await _confirmarCitaMismoDia(fecha, citasDia);
        if (!mounted || !continuar) return;
      }

      final actualizada = await context.read<CitasService>().actualizarCita(
            idCita: cita.id,
            idCoach: coach,
            fechaHora: fechaHoraConZona(fechaHoraLocal),
          );
      if (mounted) Navigator.of(context).pop(actualizada);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.mensaje);
    } catch (e) {
      if (!mounted) return;
      debugPrint('Error inesperado al actualizar la cita: $e');
      setState(() => _error = 'No se pudo actualizar la cita.');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<bool> _confirmarCitaMismoDia(
    DateTime fecha,
    List<DateTime> citasDia,
  ) async {
    final horas =
        citasDia.map((cita) => horaCitaLabel(cita.toLocal())).join(', ');
    return await showDialog<bool>(
          context: context,
          builder: (contextDialog) => AlertDialog(
            title: const Text('Aviso: cita existente'),
            content: Text(
              'El cliente ya tiene otra cita agendada el ${fechaCitaLabel(fecha)} '
              'a las $horas. ¿Deseas continuar con la modificación?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(contextDialog).pop(false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.of(contextDialog).pop(true),
                child: const Text('Continuar'),
              ),
            ],
          ),
        ) ==
        true;
  }

  @override
  Widget build(BuildContext context) {
    final entrenadorActual = widget.cita.entrenadorNombreCompleto;
    final fechaHoraActual = widget.cita.fechaHora.toLocal();
    final entrenadorSeleccionado =
        _entrenadores.any((entrenador) => entrenador.id == _idCoach)
            ? _idCoach
            : null;
    final horas = horasDisponiblesCita(_fecha);

    return AlertDialog(
      title: Text('Modificar cita', style: display(24)),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Cliente',
                  style: ts(13, weight: kSemi, color: AppColors.pizarra)),
              const SizedBox(height: 4),
              Text(widget.cita.clienteNombreCompleto,
                  style: ts(16, weight: kSemi)),
              Text('Carné: ${widget.cita.carne}', style: ts(14)),
              const SizedBox(height: 14),
              Text('Entrenador actual: $entrenadorActual', style: ts(14)),
              Text(
                'Fecha y hora actual: ${fechaCitaLabel(fechaHoraActual)} · ${horaCitaLabel(fechaHoraActual)}',
                style: ts(14),
              ),
              const SizedBox(height: 8),
              if (_cargandoEntrenadores)
                const LinearProgressIndicator()
              else if (_entrenadores.isEmpty && _error == null)
                const _MensajeCita('No hay entrenadores activos disponibles.')
              else
                DropdownButtonFormField<String>(
                  initialValue: entrenadorSeleccionado,
                  decoration: const InputDecoration(
                    labelText: 'Entrenador',
                    prefixIcon: Icon(Icons.fitness_center),
                  ),
                  hint: const Text('Selecciona un entrenador activo'),
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
                            _error = null;
                          }),
                ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final fecha = OutlinedButton.icon(
                    onPressed: _guardando ? null : _elegirFecha,
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: Text(
                      _fecha == null
                          ? 'Seleccionar fecha'
                          : fechaCitaLabel(_fecha!),
                    ),
                  );
                  final hora = DropdownButtonFormField<String>(
                    initialValue: horas.contains(_hora) ? _hora : null,
                    decoration: const InputDecoration(
                      labelText: 'Hora',
                      prefixIcon: Icon(Icons.schedule),
                    ),
                    hint: const Text('Selecciona una hora'),
                    items: [
                      for (final valor in horas)
                        DropdownMenuItem(value: valor, child: Text(valor)),
                    ],
                    onChanged: _guardando || horas.isEmpty
                        ? null
                        : (valor) => setState(() {
                              _hora = valor;
                              _error = null;
                            }),
                  );
                  if (constraints.maxWidth < 420) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [fecha, const SizedBox(height: 10), hora],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: fecha),
                      const SizedBox(width: 10),
                      Expanded(child: hora),
                    ],
                  );
                },
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                _MensajeCita(_error!),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _guardando ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        PrimaryButton(
          label: 'Guardar cambios',
          icon: Icons.save_outlined,
          busy: _guardando,
          onPressed:
              _guardando || _cargandoEntrenadores || _entrenadores.isEmpty
                  ? null
                  : _guardar,
        ),
      ],
    );
  }
}

class _MensajeCita extends StatelessWidget {
  const _MensajeCita(this.mensaje);

  final String mensaje;

  @override
  Widget build(BuildContext context) => Text(
        mensaje,
        style: ts(14, weight: kSemi, color: AppColors.danger),
      );
}
