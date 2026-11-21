import 'package:flutter/material.dart';

import '../../../core/api_exception.dart';
import '../../../core/theme.dart';
import '../../../core/widgets.dart';
import '../../planes/models/plan.dart';
import '../../secretaria/utils/citas_utils.dart';
import '../models/evolucion_mediciones.dart';
import '../models/indicadores_fisicos.dart';
import '../models/medicion_cliente.dart';
import '../services/historial_completo.dart';
import '../services/mediciones_service.dart';
import 'grafico_evolucion.dart';

class EvolucionMedicionesView extends StatefulWidget {
  const EvolucionMedicionesView({
    super.key,
    required this.cliente,
    required this.service,
  });

  final UsuarioResumen cliente;
  final MedicionesService service;

  @override
  State<EvolucionMedicionesView> createState() =>
      _EvolucionMedicionesViewState();
}

class _EvolucionMedicionesViewState extends State<EvolucionMedicionesView> {
  final _categorias = <String, List<IndicadorFisico>>{
    'Composición corporal': composicionCorporal,
    'Tronco superior': troncoSuperior,
    'Tronco inferior': troncoInferior,
    'Extremidades superiores': extremidadesSuperiores,
    'Extremidades inferiores': extremidadesInferiores,
  };
  List<MedicionCliente>? _mediciones;
  String? _error;
  bool _cargando = false;
  DateTime? _desde;
  DateTime? _hasta;
  String _periodo = 'Todo';
  String _categoria = 'Composición corporal';
  String _composicion = 'Peso corporal';
  @override
  void initState() {
    super.initState();
    _cargar();
  }

  List<MedicionCliente> get _cronologicas =>
      filtrarPeriodo(_mediciones ?? [], null, null);

  DateTime _dentroDeLimites(DateTime fecha, DateTime primera, DateTime ultima) {
    if (fecha.isBefore(primera)) return primera;
    if (fecha.isAfter(ultima)) return ultima;
    return fecha;
  }

  Future<void> _cargar() async {
    if (_cargando) return;
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final mediciones =
          await cargarHistorialCompleto(widget.service, widget.cliente.id);
      if (!mounted) return;
      setState(() {
        _mediciones = mediciones;
        final cronologicas = _cronologicas;
        if (_periodo == 'Personalizado' && cronologicas.isNotEmpty) {
          final primera = inicioDia(cronologicas.first.fecha.toLocal());
          final ultima = inicioDia(cronologicas.last.fecha.toLocal());
          _desde = _dentroDeLimites(_desde ?? primera, primera, ultima);
          _hasta = _dentroDeLimites(_hasta ?? ultima, primera, ultima);
        } else {
          _asignarPeriodo(_periodo == 'Personalizado' ? 'Todo' : _periodo);
        }
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.mensaje);
    } catch (e) {
      if (!mounted) return;
      debugPrint('Error al cargar evolución de mediciones: $e');
      setState(() => _error = 'No se pudo cargar el historial completo.');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _periodoRapido(String periodo) {
    setState(() => _asignarPeriodo(periodo));
  }

  void _asignarPeriodo(String periodo) {
    final hoy = inicioDia(DateTime.now());
    final cronologicas = _cronologicas;
    _periodo = periodo;
    _desde = switch (periodo) {
      '3 meses' => restarMeses(hoy, 3),
      '6 meses' => restarMeses(hoy, 6),
      '1 año' => restarMeses(hoy, 12),
      _ => cronologicas.isEmpty
          ? null
          : inicioDia(cronologicas.first.fecha.toLocal()),
    };
    _hasta = periodo == 'Todo'
        ? (cronologicas.isEmpty
            ? null
            : inicioDia(cronologicas.last.fecha.toLocal()))
        : hoy;
  }

  Future<void> _elegirFecha({required bool desde}) async {
    final cronologicas = _cronologicas;
    if (cronologicas.isEmpty) return;
    final primera = inicioDia(cronologicas.first.fecha.toLocal());
    final ultima = inicioDia(cronologicas.last.fecha.toLocal());
    final inicio = _dentroDeLimites(_desde ?? primera, primera, ultima);
    final fin = _dentroDeLimites(_hasta ?? ultima, primera, ultima);
    final elegida = await showDatePicker(
      context: context,
      initialDate: desde ? inicio : fin,
      firstDate: primera,
      lastDate: ultima,
      helpText:
          desde ? 'Selecciona la fecha desde' : 'Selecciona la fecha hasta',
    );
    if (elegida == null || !mounted) return;
    if ((desde && elegida.isAfter(fin)) ||
        (!desde && elegida.isBefore(inicio))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Desde no puede ser posterior a Hasta.')),
      );
      return;
    }
    setState(() {
      _desde = desde ? elegida : inicio;
      _hasta = desde ? fin : elegida;
      _periodo = 'Personalizado';
    });
  }

  String _valor(num? valor, String unidad) {
    if (valor == null) return '—';
    return '${valor.toStringAsFixed(2)}${unidad.isEmpty ? '' : ' $unidad'}';
  }

  String _valorConFecha(num? valor, DateTime? fecha, String unidad) {
    if (valor == null || fecha == null) return '—';
    return '${_valor(valor, unidad)}\n${fechaCitaLabel(fecha.toLocal())}';
  }

  Widget _tabla(List<MedicionCliente> periodo) => Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Comparación del período', style: ts(18, weight: kSemi)),
            const SizedBox(height: 8),
            Text(
              'Se usa el primer y último valor disponible de cada indicador. '
              'Con un solo valor no se calcula el cambio. La diferencia es una '
              'magnitud sin signo; la variación se calcula respecto al valor inicial.',
              style: ts(13, color: AppColors.pizarra),
            ),
            const SizedBox(height: 8),
            Text(
              '— indica un dato ausente o un porcentaje no calculable con valor '
              'inicial cero. La diferencia de grasa corporal se expresa en puntos porcentuales (p.p.).',
              style: ts(13, color: AppColors.pizarra),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Indicador')),
                  DataColumn(label: Text('Inicial')),
                  DataColumn(label: Text('Final')),
                  DataColumn(label: Text('Diferencia absoluta')),
                  DataColumn(label: Text('Variación')),
                ],
                rows: [
                  for (final resumen in resumirPeriodo(periodo))
                    DataRow(cells: [
                      DataCell(Text(resumen.indicador.nombre)),
                      DataCell(Text(_valorConFecha(
                        resumen.comparacion.anterior,
                        resumen.fechaInicial,
                        resumen.indicador.unidad,
                      ))),
                      DataCell(Text(_valorConFecha(
                        resumen.comparacion.actual,
                        resumen.fechaFinal,
                        resumen.indicador.unidad,
                      ))),
                      DataCell(Text(_valor(
                        resumen.cantidadValores < 2
                            ? null
                            : resumen.comparacion.diferenciaAbsoluta,
                        resumen.indicador.unidad == '%'
                            ? 'p.p.'
                            : resumen.indicador.unidad,
                      ))),
                      DataCell(Text(resumen.cantidadValores < 2 ||
                              resumen.comparacion.variacionPorcentual == null
                          ? '—'
                          : '${resumen.comparacion.variacionPorcentual! >= 0 ? '+' : ''}'
                              '${resumen.comparacion.variacionPorcentual!.toStringAsFixed(2)} %')),
                    ]),
                ],
              ),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final mediciones = _mediciones;
    final hayMediciones = mediciones != null && mediciones.isNotEmpty;
    final periodo = filtrarPeriodo(mediciones ?? [], _desde, _hasta);
    final indicadores = _categoria == 'Composición corporal'
        ? composicionCorporal.where((i) => i.nombre == _composicion).toList()
        : _categorias[_categoria]!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Evolución de mediciones'),
        actions: [
          IconButton(
            tooltip: 'Actualizar historial',
            onPressed: _cargando ? null : _cargar,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SliverPage(slivers: [
        Box(
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(widget.cliente.nombre, style: ts(18, weight: kSemi)),
                Text('Carné ${widget.cliente.usuario}',
                    style: ts(14, color: AppColors.pizarra)),
                const SizedBox(height: 12),
                Text('Período', style: ts(15, weight: kSemi)),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final opcion in [
                      '3 meses',
                      '6 meses',
                      '1 año',
                      'Todo'
                    ])
                      ChoiceChip(
                        label: Text(opcion),
                        selected: _periodo == opcion,
                        onSelected: (_) => _periodoRapido(opcion),
                      ),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: hayMediciones
                          ? () => _elegirFecha(desde: true)
                          : null,
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: Text(
                          'Desde: ${!hayMediciones || _desde == null ? 'Sin mediciones' : fechaCitaLabel(_desde!)}'),
                    ),
                    OutlinedButton.icon(
                      onPressed: hayMediciones
                          ? () => _elegirFecha(desde: false)
                          : null,
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: Text(
                          'Hasta: ${!hayMediciones || _hasta == null ? 'Sin mediciones' : fechaCitaLabel(_hasta!)}'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Solo mediciones activas. Las fechas personalizadas se limitan '
                  'a la primera y última medición. Los períodos rápidos se cuentan '
                  'desde hoy. Usa actualizar para consultar los cambios.',
                  style: ts(13, color: AppColors.pizarra),
                ),
              ],
            ),
          ),
          gapAfter: 16,
        ),
        if (_error != null)
          Box(
            ErrorPanel(
              message: mediciones == null
                  ? _error!
                  : 'No se pudo actualizar el historial: $_error. Se muestran datos anteriores.',
              onRetry: _cargar,
            ),
            gapAfter: 16,
          ),
        if (mediciones == null && _cargando)
          const Box(Center(child: CircularProgressIndicator()), gapAfter: 16),
        if (mediciones != null) ...[
          Box(
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Historial gráfico', style: ts(18, weight: kSemi)),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _categoria,
                    decoration: const InputDecoration(labelText: 'Categoría'),
                    items: [
                      for (final categoria in _categorias.keys)
                        DropdownMenuItem(
                            value: categoria, child: Text(categoria)),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _categoria = value);
                    },
                  ),
                  if (_categoria == 'Composición corporal') ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _composicion,
                      decoration: const InputDecoration(labelText: 'Indicador'),
                      items: [
                        for (final indicador in composicionCorporal)
                          DropdownMenuItem(
                            value: indicador.nombre,
                            child: Text(indicador.nombre),
                          ),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => _composicion = value);
                      },
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text('${periodo.length} evaluaciones en el período',
                      style: ts(13, color: AppColors.pizarra)),
                  const SizedBox(height: 12),
                  if (periodo.isEmpty)
                    Text('No hay mediciones activas en este período.',
                        style: ts(14, color: AppColors.pizarra))
                  else
                    GraficoEvolucion(
                      key: ValueKey('$_categoria-$_composicion'),
                      mediciones: periodo,
                      indicadores: indicadores,
                    ),
                ],
              ),
            ),
            gapAfter: 16,
          ),
          Box(_tabla(periodo), gapAfter: 16),
        ],
      ]),
    );
  }
}
