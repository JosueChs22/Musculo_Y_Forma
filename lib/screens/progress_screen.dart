import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../core/widgets.dart';
import '../models/body_metric.dart';
import '../state/app_state.dart';

// TODO(API): estos datos del resumen InBody vendrán de la API.
const _inbody = <(String, String, String, double)>[
  ('IMC', '24.7', 'Rango saludable', .68),
  ('Agua corporal', '44.1 L', '56.3% del peso', .74),
  ('Metabolismo basal', '1,724 kcal', 'Gasto en reposo', .81),
  ('Masa libre de grasa', '61.3 kg', '78.2% del peso', .78),
];
const _extras = <(String, String)>[
  ('Proteínas', '12.8 kg'),
  ('Minerales', '4.1 kg'),
  ('Relación cintura-cadera', '0.87'),
  ('Puntuación InBody', '78 / 100'),
];
const _months = ['Dic', 'Ene', 'Feb', 'Mar', 'Abr', 'May'];

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  int _metric = 0;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    if (s.metrics.isEmpty) return const SizedBox.shrink();
    final m = s.metrics[_metric];

    return PageBody(children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              BackLink(onTap: () => context.go('/')),
              const SizedBox(height: 8),
              Text('Mi progreso corporal', style: ts(28, weight: kBlack, spacing: -.6)),
              const SizedBox(height: 4),
              Text('Historial y comparativa de evaluaciones InBody', style: ts(14, color: w(.4))),
            ]),
          ),
          if (MediaQuery.sizeOf(context).width >= 640)
            Panel(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('ÚLTIMA MEDICIÓN', style: ts(10, weight: kBold, color: w(.35), spacing: 1.2)),
                const SizedBox(height: 4),
                Text(s.history.isEmpty ? '-' : s.history.first.date, style: ts(14, weight: kBold)),
              ]),
            ),
        ],
      ),
      const SizedBox(height: 32),
      ResponsiveGrid(desktopCols: 4, children: [
        for (var i = 0; i < s.metrics.length; i++)
          SelectableCard(
            selected: _metric == i,
            onTap: () => setState(() => _metric = i),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.metrics[i].label,
                  style: ts(12, weight: kSemi, color: _metric == i ? w(.7) : w(.4))),
              const SizedBox(height: 12),
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(s.metrics[i].valueLabel, style: ts(30, weight: kBlack, spacing: -.6)),
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Text(s.metrics[i].unit,
                      style: ts(12, weight: kSemi, color: _metric == i ? w(.7) : w(.35))),
                ),
              ]),
              const SizedBox(height: 12),
              Text('${s.metrics[i].changeSinceStart} desde el inicio',
                  style: ts(12, weight: kBold, color: _metric == i ? Colors.white : AppColors.green)),
            ]),
          ),
      ]),
      const SizedBox(height: 24),
      TwoCol(
        leftFlex: 155,
        rightFlex: 100,
        breakpoint: 900,
        left: _ChartPanel(metric: m),
        right: const _InbodyPanel(),
      ),
      const SizedBox(height: 24),
      _HistoryTable(),
    ]);
  }
}

class _ChartPanel extends StatelessWidget {
  const _ChartPanel({required this.metric});
  final BodyMetric metric;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: w(.08)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Flexible(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Eyebrow('Evolución'),
              const SizedBox(height: 8),
              Text(metric.label, style: ts(20, weight: kBlack)),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text.rich(TextSpan(children: [
              TextSpan(text: '${metric.valueLabel} ', style: ts(24, weight: kBlack)),
              TextSpan(text: metric.unit, style: ts(12, color: w(.4))),
            ])),
            const SizedBox(height: 4),
            Text(metric.changeSinceStart,
                style: ts(12, weight: kBold, color: AppColors.green)),
          ]),
        ]),
        const SizedBox(height: 28),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: blk(.2), borderRadius: BorderRadius.circular(12)),
          child: Column(children: [
            SizedBox(
              height: 240,
              width: double.infinity,
              child: CustomPaint(painter: _LinePainter(metric.history)),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [for (final mo in _months) Text(mo, style: ts(10, weight: kSemi, color: w(.3)))],
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
      ..color = w(.08)
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
        ..color = AppColors.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    for (final p in pts) {
      canvas.drawCircle(p, 5, Paint()..color = AppColors.card);
      canvas.drawCircle(
        p,
        5,
        Paint()
          ..color = AppColors.accent
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
    return Panel(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Eyebrow('Composición actual'),
        const SizedBox(height: 8),
        Text('Resumen InBody', style: ts(20, weight: kBlack)),
        const SizedBox(height: 24),
        for (final (label, value, hint, pct) in _inbody)
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(children: [
              Row(crossAxisAlignment: CrossAxisAlignment.end, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(label, style: ts(14, weight: kBold)),
                  const SizedBox(height: 4),
                  Text(hint, style: ts(12, color: w(.35))),
                ]),
                Text(value, style: ts(14, weight: kBlack)),
              ]),
              const SizedBox(height: 12),
              MiniBar(
                value: pct,
                track: w(.08),
                gradient: const LinearGradient(colors: [AppColors.accent, Color(0xFFFF9A5A)]),
              ),
            ]),
          ),
        Container(
          padding: const EdgeInsets.only(top: 20),
          decoration: BoxDecoration(border: Border(top: BorderSide(color: w(.08)))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('INDICADORES ADICIONALES', style: ts(11, weight: kBold, color: w(.35), spacing: 1.4)),
            const SizedBox(height: 16),
            ResponsiveGrid(desktopCols: 2, spacing: 12, children: [
              for (final (label, value) in _extras)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: blk(.2), borderRadius: BorderRadius.circular(12)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(label, style: ts(10, color: w(.35))),
                    const SizedBox(height: 4),
                    Text(value, style: ts(14, weight: kBold)),
                  ]),
                ),
            ]),
          ]),
        ),
      ]),
    );
  }
}

class _HistoryTable extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final rows = context.watch<AppState>().history;
    const heads = ['Fecha', 'Peso', 'Grasa corporal', 'Masa muscular', 'Grasa visceral'];

    Widget cell(String text, {bool head = false, bool bold = false, Color? color}) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            child: Text(
              head ? text.toUpperCase() : text,
              style: head
                  ? ts(10, weight: kBold, color: w(.3), spacing: 1.2)
                  : ts(14, weight: bold ? kBold : FontWeight.w500, color: color ?? w(.55)),
            ),
          ),
        );

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: w(.08)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: w(.08)))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Historial de mediciones', style: ts(18, weight: kBlack)),
            const SizedBox(height: 4),
            Text('Comparación de tus últimas evaluaciones', style: ts(12, color: w(.35))),
          ]),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: 750,
            child: Column(children: [
              Row(children: [for (final h in heads) cell(h, head: true)]),
              for (var i = 0; i < rows.length; i++)
                Container(
                  decoration: BoxDecoration(
                    color: i == 0 ? const Color.fromRGBO(255, 90, 54, .05) : null,
                    border: Border(top: BorderSide(color: w(.08))),
                  ),
                  child: Row(children: [
                    cell(rows[i].date, bold: true, color: i == 0 ? Colors.white : w(.55)),
                    cell(rows[i].weight, color: i == 0 ? Colors.white : null),
                    cell(rows[i].bodyFat, color: i == 0 ? Colors.white : null),
                    cell(rows[i].muscle, color: i == 0 ? Colors.white : null),
                    cell(rows[i].visceral, color: i == 0 ? Colors.white : null),
                  ]),
                ),
            ]),
          ),
        ),
      ]),
    );
  }
}
