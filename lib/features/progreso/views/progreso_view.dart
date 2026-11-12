import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/skeleton.dart';
import '../../../core/theme.dart';
import '../../../core/widgets.dart';
import '../controllers/progreso_controller.dart';
import '../models/body_metric.dart';
import '../models/inbody_summary.dart';

const _tableBreakpoint = 760.0;

class ProgresoView extends StatelessWidget {
  const ProgresoView({super.key});

  @override
  Widget build(BuildContext context) {
    final loading = context.select<ProgresoController, bool>((c) => c.loading);
    final error = context.select<ProgresoController, String?>((c) => c.error);
    final history = context.select<ProgresoController, List<Measurement>>((c) => c.history);
    final tableMode = MediaQuery.sizeOf(context).width >= _tableBreakpoint + 252;

    if (error != null) {
      return SliverPage(slivers: [
        const Box(_Header(), gapAfter: 24),
        Box(ErrorPanel(message: error, onRetry: () => context.read<ProgresoController>().load())),
      ]);
    }

    if (loading) {
      return const SliverPage(slivers: [
        Box(SkeletonScope(child: SkeletonTitle()), gapAfter: 28),
        Box(
          SkeletonScope(
            child: ResponsiveGrid(desktopCols: 4, children: [
              SkeletonCard(height: 130),
              SkeletonCard(height: 130),
              SkeletonCard(height: 130),
              SkeletonCard(height: 130),
            ]),
          ),
          gapAfter: 24,
        ),
        Box(SkeletonScope(child: SkeletonBox(height: 340, radius: 18)), gapAfter: 24),
        Box(SkeletonScope(child: Column(children: [SkeletonRow(), SkeletonRow(), SkeletonRow()]))),
      ]);
    }

    if (history.isEmpty) {
      return SliverPage(slivers: [
        const Box(_Header(), gapAfter: 24),
        Box(Panel(
          child: Row(children: [
            const Icon(Icons.monitor_weight_outlined, color: AppColors.indigo, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Todavía no tienes mediciones', style: ts(16, weight: kSemi)),
                const SizedBox(height: 2),
                Text('Tu entrenador registra tu peso y composición corporal en cada evaluación; aquí verás tu evolución.',
                    style: ts(14, color: AppColors.pizarra)),
              ]),
            ),
          ]),
        )),
      ]);
    }

    return SliverPage(slivers: [
      const Box(_Header(), gapAfter: 28),
      const Box(_MetricSelector(), gapAfter: 24),
      const Box(
        TwoCol(
          leftFlex: 155,
          rightFlex: 100,
          breakpoint: 900,
          left: _ChartPanel(),
          right: _InbodyPanel(),
        ),
        gapAfter: 32,
      ),
      Box(_HistoryHeader(tableMode: tableMode), gapAfter: 0),
      // REGLA 4: historial virtualizado.
      SliverList.builder(
        itemCount: history.length,
        itemBuilder: (context, i) => _HistoryRow(
          row: history[i],
          latest: i == 0,
          last: i == history.length - 1,
          tableMode: tableMode,
        ),
      ),
    ]);
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final last = context.select<ProgresoController, String>(
      (c) => c.history.isEmpty ? '-' : c.history.first.date,
    );
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      BackLink(onTap: () => context.go('/')),
      const SizedBox(height: 4),
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        const Expanded(
          child: PageTitle(
            title: 'Mi progreso',
            subtitle: 'Historial y comparativa de tus evaluaciones',
          ),
        ),
        if (MediaQuery.sizeOf(context).width >= 640)
          Panel(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              const Eyebrow('Última medición'),
              const SizedBox(height: 4),
              Text(last, style: ts(15, weight: kSemi)),
            ]),
          ),
      ]),
    ]);
  }
}

class _MetricSelector extends StatelessWidget {
  const _MetricSelector();

  @override
  Widget build(BuildContext context) {
    final metrics = context.select<ProgresoController, List<BodyMetric>>((c) => c.metrics);
    final selected = context.select<ProgresoController, int>((c) => c.selectedMetric);
    // REGLA 4: conjunto acotado (4 métricas).
    return ResponsiveGrid(desktopCols: 4, children: [
      for (var i = 0; i < metrics.length; i++)
        SelectableCard(
          selected: selected == i,
          semanticLabel: metrics[i].label,
          onTap: () => context.read<ProgresoController>().selectMetric(i),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(metrics[i].label,
                style: ts(14, weight: kSemi, color: selected == i ? AppColors.onIndigoMuted : AppColors.pizarra)),
            const SizedBox(height: 8),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(metrics[i].valueLabel,
                  style: display(40, color: selected == i ? Colors.white : AppColors.ink)),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text(metrics[i].unit,
                    style: ts(14, weight: kSemi, color: selected == i ? AppColors.onIndigoMuted : AppColors.pizarra)),
              ),
            ]),
            const SizedBox(height: 8),
            Text('${metrics[i].changeSinceStart} desde el inicio',
                style: ts(13, weight: kSemi, color: selected == i ? AppColors.ambar : AppColors.success)),
          ]),
        ),
    ]);
  }
}

class _ChartPanel extends StatelessWidget {
  const _ChartPanel();

  @override
  Widget build(BuildContext context) {
    final metric = context.select<ProgresoController, BodyMetric?>((c) => c.currentMetric);
    if (metric == null) return const SizedBox.shrink();
    return Panel(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Eyebrow('Evolución'),
                const SizedBox(height: 6),
                Text(metric.label.toUpperCase(), style: display(28)),
              ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text.rich(TextSpan(children: [
                TextSpan(text: '${metric.valueLabel} ', style: display(32)),
                TextSpan(text: metric.unit, style: ts(14, color: AppColors.pizarra)),
              ])),
              Text(metric.changeSinceStart, style: ts(14, weight: kSemi, color: AppColors.success)),
            ]),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.niebla, borderRadius: BorderRadius.circular(14)),
          child: Column(children: [
            SizedBox(
              height: 220,
              width: double.infinity,
              child: Semantics(
                label: 'Gráfica de ${metric.label}: de ${metric.history.isEmpty ? '-' : metric.history.first} '
                    'a ${metric.valueLabel} ${metric.unit}',
                child: RepaintBoundary(child: CustomPaint(painter: _LinePainter(metric.history))),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (final label in metric.historyLabels)
                    Text(label, style: ts(12, weight: kSemi, color: AppColors.pizarra)),
                ],
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter(this.values);
  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = AppColors.line
      ..strokeWidth = 1;
    for (final f in const [0.25, 0.55, 0.85]) {
      final y = size.height * f;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    if (values.length < 2) return;

    final minV = values.reduce(math.min);
    final maxV = values.reduce(math.max);
    final range = (maxV - minV) == 0 ? 1.0 : (maxV - minV);
    const pad = 12.0;
    final step = (size.width - pad * 2) / (values.length - 1);

    final pts = <Offset>[
      for (var i = 0; i < values.length; i++)
        Offset(pad + i * step, size.height * 0.85 - ((values[i] - minV) / range) * size.height * 0.65),
    ];

    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.cobalto
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    for (var i = 0; i < pts.length; i++) {
      final last = i == pts.length - 1;
      canvas.drawCircle(pts[i], last ? 7 : 5, Paint()..color = last ? AppColors.ambar : AppColors.card);
      canvas.drawCircle(
        pts[i],
        last ? 7 : 5,
        Paint()
          ..color = last ? AppColors.ink : AppColors.cobalto
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LinePainter old) => old.values != values;
}

class _InbodyPanel extends StatelessWidget {
  const _InbodyPanel();

  @override
  Widget build(BuildContext context) {
    final inbody = context.select<ProgresoController, InbodySummary>((c) => c.inbody);
    return Panel(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Eyebrow('Composición actual'),
        const SizedBox(height: 6),
        Text('RESUMEN', style: display(28)),
        const SizedBox(height: 20),
        for (final item in inbody.items)
          Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Column(children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(item.label, style: ts(15, weight: kSemi)),
                      Text(item.hint, style: ts(13, color: AppColors.pizarra)),
                    ]),
                  ),
                  Text(item.value, style: ts(15, weight: kSemi)),
                ],
              ),
              const SizedBox(height: 10),
              MiniBar(value: item.ratio),
            ]),
          ),
        Container(
          padding: const EdgeInsets.only(top: 18),
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.line))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Eyebrow('Indicadores adicionales'),
            const SizedBox(height: 14),
            ResponsiveGrid(desktopCols: 2, spacing: 12, children: [
              for (final extra in inbody.extras)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.niebla, borderRadius: BorderRadius.circular(12)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(extra.label, style: ts(13, color: AppColors.pizarra)),
                    const SizedBox(height: 2),
                    Text(extra.value, style: ts(16, weight: kSemi)),
                  ]),
                ),
            ]),
          ]),
        ),
      ]),
    );
  }
}

const _heads = ['Fecha', 'Peso', 'Grasa corporal', 'Masa muscular', 'Grasa visceral'];

class _HistoryHeader extends StatelessWidget {
  const _HistoryHeader({required this.tableMode});
  final bool tableMode;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(kRadiusCard)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('HISTORIAL DE MEDICIONES', style: display(28)),
            Text('Comparación de tus últimas evaluaciones', style: ts(14, color: AppColors.pizarra)),
          ]),
        ),
        if (tableMode)
          Container(
            color: AppColors.niebla,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(children: [
              for (final h in _heads) Expanded(child: Eyebrow(h)),
            ]),
          ),
      ]),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.row, required this.latest, required this.last, required this.tableMode});
  final Measurement row;
  final bool latest;
  final bool last;
  final bool tableMode;

  @override
  Widget build(BuildContext context) {
    final values = [row.date, row.weight, row.bodyFat, row.muscle, row.visceral];
    final decoration = BoxDecoration(
      color: latest ? AppColors.indigoSoft : AppColors.card,
      border: const Border(
        left: BorderSide(color: AppColors.line),
        right: BorderSide(color: AppColors.line),
        bottom: BorderSide(color: AppColors.line),
      ),
    );

    final Widget content;
    if (tableMode) {
      content = Container(
        decoration: decoration,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(children: [
          for (var i = 0; i < values.length; i++)
            Expanded(
              child: Text(values[i], style: ts(15, weight: i == 0 || latest ? kSemi : kRegular)),
            ),
        ]),
      );
    } else {
      // Móvil: cada medición como tarjeta compacta, sin scroll horizontal.
      content = Container(
      decoration: decoration,
      padding: const EdgeInsets.all(18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(row.date, style: ts(16, weight: kSemi)),
          if (latest) ...[const SizedBox(width: 8), const Pill('Más reciente')],
        ]),
        const SizedBox(height: 12),
        Wrap(spacing: 20, runSpacing: 10, children: [
          for (var i = 1; i < values.length; i++)
            Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(_heads[i], style: ts(12, color: AppColors.pizarra)),
              Text(values[i], style: ts(15, weight: kSemi)),
            ]),
        ]),
      ]),
    );
    }
    // Esquinas redondeadas solo en la última fila (el borde no admite radio con lados distintos).
    return last
        ? ClipRRect(borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)), child: content)
        : content;
  }
}
