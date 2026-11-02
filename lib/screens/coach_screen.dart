import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../core/widgets.dart';
import '../state/app_state.dart';

class CoachScreen extends StatefulWidget {
  const CoachScreen({super.key});

  @override
  State<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends State<CoachScreen> {
  int _client = 0;
  bool _saved = false;
  late List<String> _assigned;

  @override
  void initState() {
    super.initState();
    final catalog = context.read<AppState>().catalog;
    _assigned = catalog.take(3).map((e) => e.name).toList();
  }

  Future<void> _save() async {
    final s = context.read<AppState>();
    await s.assignRoutine(
      clientId: s.clients[_client].id,
      routineTitle: 'Pecho y tríceps',
      exercises: _assigned,
    );
    if (!mounted) return;
    setState(() => _saved = true);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    if (s.clients.isEmpty) return const SizedBox.shrink();
    final client = s.clients[_client];
    final wide = MediaQuery.sizeOf(context).width >= 640;
    String summaryOf(String name) =>
        s.catalog.firstWhere((e) => e.name == name, orElse: () => s.catalog.first).summary;
    final available = s.catalog.where((e) => !_assigned.contains(e.name)).toList();

    return PageBody(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Panel del coach', style: ts(14, weight: kSemi, color: AppColors.accentLight)),
          const SizedBox(height: 4),
          Text('Asignar rutina', style: ts(30, weight: kBlack, spacing: -.6)),
        ]),
        if (wide)
          OutlinedButton(
            onPressed: () => context.go('/'),
            style: OutlinedButton.styleFrom(
              backgroundColor: w(.04),
              side: BorderSide(color: w(.1)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: const StadiumBorder(),
            ),
            child: Text('Ver como usuario', style: ts(14, weight: kSemi, color: w(.6))),
          ),
      ]),
      const SizedBox(height: 32),
      TwoCol(
        leftWidth: 300,
        breakpoint: 900,
        left: Panel(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('USUARIOS', style: ts(11, weight: kBold, color: w(.35), spacing: 1.8)),
                  const SizedBox(height: 4),
                  Text('${s.clients.length} activos', style: ts(14, weight: kSemi)),
                ]),
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: w(.08), shape: BoxShape.circle),
                  child: Text('+', style: ts(18)),
                ),
              ]),
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < s.clients.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () => setState(() {
                    _client = i;
                    _saved = false;
                  }),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _client == i ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(children: [
                      Avatar(
                        s.clients[i].initials,
                        size: 40,
                        bg: _client == i ? AppColors.accent : w(.08),
                        fg: _client == i ? Colors.white : w(.6),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(s.clients[i].name,
                              overflow: TextOverflow.ellipsis,
                              style: ts(14, weight: kBold, color: _client == i ? Colors.black : Colors.white)),
                          const SizedBox(height: 2),
                          Text(s.clients[i].goal,
                              overflow: TextOverflow.ellipsis,
                              style: ts(12, color: _client == i ? blk(.5) : w(.35))),
                        ]),
                      ),
                    ]),
                  ),
                ),
              ),
          ]),
        ),
        right: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Panel(
            padding: const EdgeInsets.all(24),
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  const Eyebrow('Rutina para'),
                  const SizedBox(height: 8),
                  Text(client.name, style: ts(24, weight: kBlack)),
                  const SizedBox(height: 4),
                  Text(client.goal, style: ts(14, color: w(.45))),
                ]),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(color: blk(.2), borderRadius: BorderRadius.circular(12)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    for (var i = 0; i < 3 && i < s.metrics.length; i++) ...[
                      if (i > 0) const SizedBox(width: 20),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(['PESO', 'GRASA', 'MÚSCULO'][i],
                            style: ts(10, color: w(.35), spacing: 1)),
                        const SizedBox(height: 4),
                        Text(s.metrics[i].displayValue, style: ts(14, weight: kBold)),
                      ]),
                    ],
                  ]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: w(.08)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('CONSTRUCTOR', style: ts(11, weight: kBold, color: w(.35), spacing: 1.8)),
                  const SizedBox(height: 4),
                  Text('Pecho y tríceps', style: ts(20, weight: kBlack)),
                ]),
                AccentPill('${_assigned.length} ejercicios'),
              ]),
              const SizedBox(height: 24),
              for (var i = 0; i < _assigned.length; i++)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: w(.035),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: w(.08)),
                  ),
                  child: Row(children: [
                    Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: w(.08), borderRadius: BorderRadius.circular(8)),
                      child: Text('${i + 1}'.padLeft(2, '0'), style: ts(12, weight: kBlack, color: w(.45))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(_assigned[i], overflow: TextOverflow.ellipsis, style: ts(14, weight: kBold)),
                        const SizedBox(height: 2),
                        Text(summaryOf(_assigned[i]), style: ts(12, color: w(.35))),
                      ]),
                    ),
                    IconButton(
                      tooltip: 'Quitar ${_assigned[i]}',
                      icon: Icon(Icons.close, size: 18, color: w(.3)),
                      onPressed: () => setState(() {
                        _assigned.removeAt(i);
                        _saved = false;
                      }),
                    ),
                  ]),
                ),
              const SizedBox(height: 8),
              Text('Agregar ejercicio', style: ts(12, weight: kSemi, color: w(.4))),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final ex in available)
                  GestureDetector(
                    onTap: () => setState(() {
                      _assigned.add(ex.name);
                      _saved = false;
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: w(.15)),
                      ),
                      child: Text('+ ${ex.name}', style: ts(12, weight: kSemi, color: w(.55))),
                    ),
                  ),
              ]),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.only(top: 20),
                decoration: BoxDecoration(border: Border(top: BorderSide(color: w(.08)))),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      _saved ? 'Rutina asignada correctamente' : 'Los cambios aún no se han guardado',
                      style: ts(12, weight: kSemi, color: _saved ? AppColors.green : w(.3)),
                    ),
                    WhiteButton(
                      label: 'Guardar y asignar rutina',
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      onPressed: _save,
                    ),
                  ],
                ),
              ),
            ]),
          ),
        ]),
      ),
    ]);
  }
}
