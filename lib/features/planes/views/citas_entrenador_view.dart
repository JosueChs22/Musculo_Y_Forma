import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api_exception.dart';
import '../../../core/theme.dart';
import '../../../core/widgets.dart';
import '../../secretaria/models/cita.dart';
import '../../secretaria/services/citas_service.dart';
import '../../secretaria/utils/citas_utils.dart';
import 'widgets/menu_entrenador.dart';

class CitasEntrenadorView extends StatefulWidget {
  const CitasEntrenadorView({super.key});

  @override
  State<CitasEntrenadorView> createState() => _CitasEntrenadorViewState();
}

class _CitasEntrenadorViewState extends State<CitasEntrenadorView> {
  final TextEditingController _busquedaController = TextEditingController();
  DateTime _fecha = DateTime.now();
  List<CitaConsulta> _citas = const [];
  String? _error;
  bool _cargando = false;
  bool _consultada = false;
  bool _modoBusqueda = false;

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
    final servicio = context.read<CitasService>();
    final inicio = _fecha;
    final fin = DateTime(_fecha.year, _fecha.month, _fecha.day + 1);
    setState(() {
      _cargando = true;
      _error = null;
      _citas = const [];
      _consultada = false;
      _modoBusqueda = false;
    });
    try {
      final citas = await servicio.listarCitasEntrenadorPorFecha(
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
      debugPrint('Error inesperado al consultar citas del entrenador: $e');
      setState(() => _error = 'No se pudieron consultar tus citas.');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _buscarCitas() async {
    if (_cargando) return;
    final termino = _busquedaController.text.trim();
    if (termino.length < 2) {
      setState(() {
        _error = 'Escribe al menos dos caracteres del nombre o carné.';
        _citas = const [];
        _consultada = true;
        _modoBusqueda = true;
      });
      return;
    }

    final servicio = context.read<CitasService>();
    setState(() {
      _cargando = true;
      _error = null;
      _citas = const [];
      _consultada = false;
      _modoBusqueda = true;
    });
    try {
      final citas = await servicio.buscarUltimasCitasEntrenador(termino);
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
      debugPrint('Error inesperado al buscar citas del entrenador: $e');
      setState(() => _error = 'No se pudieron buscar tus citas.');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) => SliverPage(
        slivers: [
          const Box(
            PageTitle(
              eyebrow: 'Panel del entrenador',
              title: 'Citas',
              subtitle: 'Consulta las citas asignadas a tu agenda.',
            ),
            gapAfter: 16,
          ),
          const Box(MenuEntrenador(seccion: SeccionEntrenador.citas)),
          Box(
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SectionHeader(
                    eyebrow: 'Agenda personal',
                    title: 'Consultar citas',
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Consulta tus citas por día o busca por nombre o carné. '
                    'La búsqueda muestra solo la cita más reciente de cada cliente.',
                    style: ts(14, color: AppColors.pizarra),
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final selector = OutlinedButton.icon(
                        onPressed: _cargando ? null : _elegirFecha,
                        icon: const Icon(Icons.calendar_month_outlined),
                        label: Text(fechaCitaLabel(_fecha)),
                      );
                      final consultar = PrimaryButton(
                        label: 'Consultar citas',
                        icon: Icons.search,
                        busy: _cargando,
                        onPressed: _cargando ? null : _consultarCitas,
                      );
                      if (constraints.maxWidth < 560) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            selector,
                            const SizedBox(height: 12),
                            consultar,
                          ],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(child: selector),
                          const SizedBox(width: 12),
                          consultar,
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _busquedaController,
                    enabled: !_cargando,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _buscarCitas(),
                    decoration: InputDecoration(
                      labelText: 'Buscar citas por cliente',
                      hintText: 'Nombre o número de carné',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _busquedaController.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Limpiar búsqueda',
                              onPressed: _cargando
                                  ? null
                                  : () {
                                      _busquedaController.clear();
                                      setState(() {
                                        _modoBusqueda = false;
                                        _citas = const [];
                                        _consultada = false;
                                      });
                                    },
                              icon: const Icon(Icons.close),
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: PrimaryButton(
                      label: 'Buscar cita más reciente',
                      icon: Icons.search,
                      busy: _cargando && _modoBusqueda,
                      onPressed: _cargando ? null : _buscarCitas,
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      style: ts(
                        14,
                        weight: kSemi,
                        color: AppColors.danger,
                      ),
                    ),
                  ],
                  if (_cargando) ...[
                    const SizedBox(height: 20),
                    const LinearProgressIndicator(),
                  ] else if (_consultada && _citas.isEmpty) ...[
                    const SizedBox(height: 20),
                    Text(
                      _modoBusqueda
                          ? 'No se encontraron citas para ese cliente.'
                          : 'No tienes citas registradas para esta fecha.',
                      style: ts(14, color: AppColors.pizarra),
                    ),
                  ] else if (_citas.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    for (final cita in _citas) ...[
                      _CitaEntrenadorCard(cita: cita),
                      const SizedBox(height: 10),
                    ],
                  ],
                ],
              ),
            ),
            gapAfter: 16,
          ),
        ],
      );
}

class _CitaEntrenadorCard extends StatelessWidget {
  const _CitaEntrenadorCard({required this.cita});

  final CitaConsulta cita;

  @override
  Widget build(BuildContext context) {
    final fechaHora = cita.fechaHora.toLocal();
    return Panel(
      padding: EdgeInsets.zero,
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
                  Text(cita.clienteNombreCompleto, style: ts(16, weight: kSemi)),
                  const SizedBox(height: 2),
                  Text('Carné: ${cita.carne}', style: ts(13)),
                  Text(
                    '${fechaCitaLabel(fechaHora)} · ${horaCitaLabel(fechaHora)}',
                    style: ts(13, color: AppColors.pizarra),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _EstadoCita(cita.estado),
          ],
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
