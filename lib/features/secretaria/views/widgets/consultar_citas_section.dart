import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/api_exception.dart';
import '../../../../core/theme.dart';
import '../../../../core/widgets.dart';
import '../../models/cita.dart';
import '../../services/citas_service.dart';
import '../../utils/citas_utils.dart';
import 'editar_cita_dialog.dart';

class ConsultarCitasSection extends StatefulWidget {
  const ConsultarCitasSection({super.key});

  @override
  State<ConsultarCitasSection> createState() => _ConsultarCitasSectionState();
}

class _ConsultarCitasSectionState extends State<ConsultarCitasSection> {
  final TextEditingController _busquedaController = TextEditingController();
  DateTime _fecha = DateTime.now();
  List<CitaConsulta> _citas = const [];
  String? _error;
  bool _cargando = false;
  bool _cambiandoEstado = false;
  bool _consultada = false;

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final ahora = DateTime.now();
    _fecha = DateTime(ahora.year, ahora.month, ahora.day);
    WidgetsBinding.instance.addPostFrameCallback((_) => _consultarCitas());
  }

  Future<void> _elegirFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Selecciona la fecha de consulta',
    );
    if (fecha == null || !mounted) return;
    setState(() {
      _fecha = DateTime(fecha.year, fecha.month, fecha.day);
      _citas = const [];
      _error = null;
      _consultada = false;
    });
    await _consultarCitas();
  }

  Future<void> _consultarCitas() async {
    if (_cargando) return;
    final inicio = _fecha;
    final fin = DateTime(_fecha.year, _fecha.month, _fecha.day + 1);
    setState(() {
      _cargando = true;
      _error = null;
      _citas = const [];
      _consultada = false;
    });
    try {
      final citas = await context.read<CitasService>().listarCitasPorFecha(
            inicio: fechaHoraConZona(inicio),
            fin: fechaHoraConZona(fin),
          );
      if (!mounted) return;
      setState(() {
        _citas = citas;
        _consultada = true;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.mensaje);
    } catch (e) {
      if (!mounted) return;
      debugPrint('Error inesperado al consultar citas: $e');
      setState(() => _error = 'No se pudieron consultar las citas.');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _editarCita(CitaConsulta cita) async {
    final actualizada = await EditarCitaDialog.show(context, cita: cita);
    if (actualizada == null || !mounted) return;
    final fechaLocal = actualizada.fechaHora.toLocal();
    setState(() {
      _fecha = DateTime(fechaLocal.year, fechaLocal.month, fechaLocal.day);
    });
    await _consultarCitas();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cita actualizada correctamente.')),
    );
  }

  Future<void> _cambiarEstado(CitaConsulta cita) async {
    final nuevoEstado = switch (cita.estado) {
      'Agendada' => 'Cancelada',
      'Cancelada' => 'Agendada',
      _ => null,
    };
    if (nuevoEstado == null) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (contextDialog) => AlertDialog(
        title:
            Text(nuevoEstado == 'Cancelada' ? 'Cancelar cita' : 'Agendar cita'),
        content: Text(
          nuevoEstado == 'Cancelada'
              ? '¿Deseas cancelar la cita de ${cita.clienteNombreCompleto}?'
              : '¿Deseas volver a agendar la cita de ${cita.clienteNombreCompleto}? '
                  'Se verificarán nuevamente la disponibilidad y las reglas de agenda.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(contextDialog).pop(false),
            child: const Text('Volver'),
          ),
          TextButton(
            onPressed: () => Navigator.of(contextDialog).pop(true),
            child:
                Text(nuevoEstado == 'Cancelada' ? 'Cancelar cita' : 'Agendar'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;

    final citasService = context.read<CitasService>();
    setState(() {
      _cambiandoEstado = true;
      _error = null;
    });
    try {
      if (nuevoEstado == 'Agendada' &&
          !await _confirmarAgendaDisponible(cita)) {
        return;
      }

      final actualizada = await citasService.cambiarEstadoCita(
        idCita: cita.id,
        estado: nuevoEstado,
      );
      if (!mounted) return;
      setState(() {
        _citas = [
          for (final item in _citas)
            if (item.id == cita.id)
              item.copyWith(estado: actualizada.estado)
            else
              item,
        ];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            actualizada.estado == 'Cancelada'
                ? 'Cita cancelada correctamente.'
                : 'Cita agendada correctamente.',
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.mensaje);
    } catch (e) {
      if (!mounted) return;
      debugPrint('Error inesperado al cambiar el estado de la cita: $e');
      setState(() => _error = 'No se pudo cambiar el estado de la cita.');
    } finally {
      if (mounted) setState(() => _cambiandoEstado = false);
    }
  }

  Future<bool> _confirmarAgendaDisponible(CitaConsulta cita) async {
    final fechaLocal = cita.fechaHora.toLocal();
    final inicio = DateTime(fechaLocal.year, fechaLocal.month, fechaLocal.day);
    final fin = DateTime(inicio.year, inicio.month, inicio.day + 1);
    final citasDia =
        await context.read<CitasService>().listarCitasAgendadasClienteEnRango(
              idCliente: cita.idCliente,
              inicio: fechaHoraConZona(inicio),
              fin: fechaHoraConZona(fin),
            );
    if (!mounted) return false;

    if (citasDia.any((actual) => actual.isAtSameMomentAs(cita.fechaHora))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'El cliente ya tiene otra cita agendada para esa fecha y hora.',
          ),
        ),
      );
      return false;
    }
    if (citasDia.isEmpty) return true;

    final horas =
        citasDia.map((actual) => horaCitaLabel(actual.toLocal())).join(', ');
    return await showDialog<bool>(
          context: context,
          builder: (contextDialog) => AlertDialog(
            title: const Text('Aviso: cita existente'),
            content: Text(
              'El cliente ya tiene otra cita agendada el '
              '${fechaCitaLabel(inicio)} a las $horas. '
              '¿Deseas continuar y volver a agendar esta cita?',
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

  List<CitaConsulta> get _citasFiltradas => _citas
      .where(
          (cita) => coincideCitaConsulta(cita, _busquedaController.text.trim()))
      .toList();

  List<List<CitaConsulta>> _agruparPorEntrenador(
    List<CitaConsulta> citas,
  ) {
    final grupos = <String, List<CitaConsulta>>{};
    for (final cita in citas) {
      grupos.putIfAbsent(cita.idCoach, () => []).add(cita);
    }
    final resultado = grupos.values.toList();
    for (final citas in resultado) {
      citas.sort((a, b) => a.fechaHora.compareTo(b.fechaHora));
    }
    resultado.sort((a, b) => a.first.entrenadorNombreCompleto
        .compareTo(b.first.entrenadorNombreCompleto));
    return resultado;
  }

  @override
  Widget build(BuildContext context) {
    final citasFiltradas = _citasFiltradas;
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(
            eyebrow: 'Agenda del gimnasio',
            title: 'Consultar citas',
          ),
          const SizedBox(height: 20),
          Text(
            'Selecciona una fecha y busca por carné o nombre del cliente. '
            'Se muestran citas de todos los estados.',
            style: ts(14, color: AppColors.pizarra),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _busquedaController,
            decoration: InputDecoration(
              labelText: 'Buscar cliente',
              hintText: 'Número de carné o nombre',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _busquedaController.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Limpiar búsqueda',
                      onPressed: () {
                        _busquedaController.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.close),
                    ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final selector = OutlinedButton.icon(
                onPressed: _cargando ? null : _elegirFecha,
                icon: const Icon(Icons.calendar_month_outlined),
                label: Text(fechaCitaLabel(_fecha)),
              );
              final boton = PrimaryButton(
                label: 'Consultar citas',
                icon: Icons.search,
                busy: _cargando,
                onPressed: _cargando ? null : _consultarCitas,
              );
              if (constraints.maxWidth < 560) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [selector, const SizedBox(height: 12), boton],
                );
              }
              return Row(
                children: [
                  Expanded(child: selector),
                  const SizedBox(width: 12),
                  boton,
                ],
              );
            },
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            _CitaError(_error!),
          ],
          if (_cargando) ...[
            const SizedBox(height: 20),
            const LinearProgressIndicator(),
          ] else if (_consultada && _citas.isEmpty) ...[
            const SizedBox(height: 20),
            const _CitasVacias(),
          ] else if (_consultada && citasFiltradas.isEmpty) ...[
            const SizedBox(height: 20),
            const _CitasVacias(
              mensaje: 'No hay citas que coincidan con la búsqueda.',
            ),
          ] else if (_citas.isNotEmpty) ...[
            const SizedBox(height: 24),
            for (final grupo in _agruparPorEntrenador(citasFiltradas)) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  grupo.first.entrenadorNombreCompleto,
                  style: ts(17, weight: kSemi),
                ),
              ),
              for (final cita in grupo) ...[
                _CitaConsultaCard(
                  cita: cita,
                  onTap: _cargando || _cambiandoEstado
                      ? null
                      : () => _editarCita(cita),
                  onCambiarEstado: _cargando || _cambiandoEstado
                      ? null
                      : () => _cambiarEstado(cita),
                ),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 14),
            ],
          ],
        ],
      ),
    );
  }
}

class _CitaConsultaCard extends StatelessWidget {
  const _CitaConsultaCard({
    required this.cita,
    required this.onTap,
    required this.onCambiarEstado,
  });

  final CitaConsulta cita;
  final VoidCallback? onTap;
  final VoidCallback? onCambiarEstado;

  @override
  Widget build(BuildContext context) {
    final fechaHora = cita.fechaHora.toLocal();
    return Panel(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(kRadiusCard),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Icon(Icons.event_note_outlined, color: AppColors.cobalto),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cita.clienteNombreCompleto,
                        style: ts(16, weight: kSemi)),
                    const SizedBox(height: 2),
                    Text('Carné: ${cita.carne}', style: ts(13)),
                    Text('Entrenador: ${cita.entrenadorNombreCompleto}',
                        style: ts(13)),
                    Text(
                      '${fechaCitaLabel(fechaHora)} · ${horaCitaLabel(fechaHora)}',
                      style: ts(13, color: AppColors.pizarra),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _EstadoCita(cita.estado),
                  const SizedBox(height: 6),
                  const Icon(Icons.edit_outlined,
                      size: 18, color: AppColors.cobalto),
                  if (cita.estado == 'Agendada' || cita.estado == 'Cancelada')
                    TextButton.icon(
                      onPressed: onCambiarEstado,
                      icon: Icon(
                        cita.estado == 'Agendada'
                            ? Icons.event_busy_outlined
                            : Icons.event_available_outlined,
                        size: 16,
                      ),
                      label: Text(
                        cita.estado == 'Agendada' ? 'Cancelar' : 'Agendar',
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EstadoCita extends StatelessWidget {
  const _EstadoCita(this.estado);

  final String estado;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.indigoSoft,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(estado, style: ts(11, weight: kSemi)),
      );
}

class _CitasVacias extends StatelessWidget {
  const _CitasVacias({
    this.mensaje = 'No hay citas registradas para esta fecha.',
  });

  final String mensaje;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          const Icon(Icons.event_busy_outlined,
              size: 42, color: AppColors.pizarra),
          const SizedBox(height: 8),
          Text(mensaje, style: ts(14, color: AppColors.pizarra)),
        ],
      );
}

class _CitaError extends StatelessWidget {
  const _CitaError(this.mensaje);

  final String mensaje;

  @override
  Widget build(BuildContext context) =>
      Text(mensaje, style: ts(14, weight: kSemi, color: AppColors.danger));
}
