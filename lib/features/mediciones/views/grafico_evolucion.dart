import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../secretaria/utils/citas_utils.dart';
import '../models/indicadores_fisicos.dart';
import '../models/medicion_cliente.dart';

class GraficoEvolucion extends StatefulWidget {
  const GraficoEvolucion({
    super.key,
    required this.mediciones,
    required this.indicadores,
  });

  final List<MedicionCliente> mediciones;
  final List<IndicadorFisico> indicadores;

  @override
  State<GraficoEvolucion> createState() => _GraficoEvolucionState();
}

class _GraficoEvolucionState extends State<GraficoEvolucion> {
  static const _colores = [
    AppColors.cobalto,
    AppColors.ambarOscuro, // WCAG 1.4.11: el ámbar puro no llega a 3:1 sobre blanco
    AppColors.indigo,
    AppColors.pizarra,
  ];
  late Set<String> _visibles;

  @override
  void initState() {
    super.initState();
    _reiniciar();
  }

  @override
  void didUpdateWidget(covariant GraficoEvolucion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.indicadores != widget.indicadores) _reiniciar();
  }

  void _reiniciar() {
    _visibles = widget.indicadores.map((i) => i.nombre).toSet();
  }

  String _fecha(DateTime fecha) {
    final local = fecha.toLocal();
    return '${fechaCitaLabel(local)} · ${horaCitaLabel(local)}';
  }

  String _resumen(List<IndicadorFisico> series) {
    final partes = <String>[];
    for (final ind in series) {
      final vals = [
        for (final m in widget.mediciones)
          if (ind.valor(m) != null) ind.valor(m)!,
      ];
      if (vals.isEmpty) continue;
      partes.add('${ind.nombre}: de ${vals.first} a ${vals.last} ${ind.unidad}');
    }
    return 'Gráfica de evolución, ${widget.mediciones.length} evaluaciones. ${partes.join('. ')}';
  }

  @override
  Widget build(BuildContext context) {
    final visibles =
        widget.indicadores.where((i) => _visibles.contains(i.nombre)).toList();
    final conDatos = visibles
        .where((i) => widget.mediciones.any((m) => i.valor(m) != null))
        .toList();
    final valores = [
      for (final indicador in conDatos)
        for (final medicion in widget.mediciones)
          if (indicador.valor(medicion) != null)
            indicador.valor(medicion)!.toDouble(),
    ];
    final min = valores.isEmpty ? 0.0 : valores.reduce(math.min);
    final max = valores.isEmpty ? 1.0 : valores.reduce(math.max);
    final margen = math.max((max - min) * .1, 1.0);
    final maxX = math.max(widget.mediciones.length - 1, 1).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (var i = 0; i < widget.indicadores.length; i++)
              FilterChip(
                selected: _visibles.contains(widget.indicadores[i].nombre),
                avatar: CircleAvatar(
                  backgroundColor: _colores[i % _colores.length],
                  radius: 7,
                ),
                label: Text(widget.indicadores[i].nombre),
                onSelected: (seleccionado) => setState(() {
                  if (seleccionado) {
                    _visibles.add(widget.indicadores[i].nombre);
                  } else {
                    _visibles.remove(widget.indicadores[i].nombre);
                  }
                }),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (conDatos.isEmpty)
          Text(
            visibles.isEmpty
                ? 'Selecciona al menos una serie.'
                : 'No hay datos para las series seleccionadas en este período.',
            style: ts(14, color: AppColors.pizarra),
          )
        else ...[
          Semantics(
            // WCAG 1.1.1: alternativa de texto de la gráfica
            label: _resumen(conDatos),
            child: ExcludeSemantics(
              child: SizedBox(
            height: 280,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: maxX,
                minY: min - margen,
                maxY: max + margen,
                gridData: const FlGridData(show: true, drawVerticalLine: false),
                borderData: FlBorderData(show: false),
                titlesData: const FlTitlesData(
                  topTitles: AxisTitles(),
                  rightTitles: AxisTitles(),
                  bottomTitles: AxisTitles(),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 48),
                  ),
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    maxContentWidth: 250,
                    getTooltipItems: (spots) {
                      if (spots.isEmpty) return [];
                      final index = spots.first.x.round();
                      if (index < 0 || index >= widget.mediciones.length) {
                        return List.filled(spots.length, null);
                      }
                      final m = widget.mediciones[index];
                      final texto = [
                        _fecha(m.fecha),
                        for (final indicador in visibles)
                          '${indicador.nombre}: '
                              '${indicador.valor(m) ?? '—'} ${indicador.unidad}',
                      ].join('\n');
                      return [
                        LineTooltipItem(
                          texto,
                          const TextStyle(color: Colors.white, fontSize: 13),
                        ),
                        for (var i = 1; i < spots.length; i++) null,
                      ];
                    },
                  ),
                ),
                lineBarsData: [
                  for (final indicador in conDatos)
                    LineChartBarData(
                      color: _colores[widget.indicadores.indexOf(indicador) %
                          _colores.length],
                      barWidth: 2,
                      isCurved: false,
                      dotData: const FlDotData(show: true),
                      spots: [
                        for (var i = 0; i < widget.mediciones.length; i++)
                          if (indicador.valor(widget.mediciones[i]) == null)
                            FlSpot.nullSpot
                          else
                            FlSpot(
                                i.toDouble(),
                                indicador
                                    .valor(widget.mediciones[i])!
                                    .toDouble()),
                      ],
                    ),
                ],
              ),
            ),
          ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                fechaCitaLabel(widget.mediciones.first.fecha.toLocal()),
                style: ts(12, color: AppColors.pizarra),
              ),
              if (widget.mediciones.length > 1)
                Text(
                  fechaCitaLabel(widget.mediciones.last.fecha.toLocal()),
                  style: ts(12, color: AppColors.pizarra),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Evaluaciones en orden cronológico (separación uniforme). '
            'Selecciona un punto para ver su fecha y los valores visibles.',
            style: ts(12, color: AppColors.pizarra),
          ),
        ],
      ],
    );
  }
}
