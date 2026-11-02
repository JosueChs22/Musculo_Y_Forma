import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../core/widgets.dart';
import '../models/routine.dart';
import '../state/app_state.dart';
import '../widgets/workout_dialog.dart';

class RoutinesScreen extends StatefulWidget {
  const RoutinesScreen({super.key});

  @override
  State<RoutinesScreen> createState() => _RoutinesScreenState();
}

class _RoutinesScreenState extends State<RoutinesScreen> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    if (s.routines.isEmpty) return const SizedBox.shrink();
    final routine = s.routines[_selected];
    final wide = MediaQuery.sizeOf(context).width >= 640;

    return PageBody(children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BackLink(onTap: () => context.go('/')),
              const SizedBox(height: 8),
              Text('Mis rutinas', style: ts(30, weight: kBlack, spacing: -.6)),
              const SizedBox(height: 4),
              Text('Plan asignado por ${s.profile.coachName}', style: ts(14, color: w(.4))),
            ],
          ),
          if (wide) AccentPill('${s.routines.length} rutinas asignadas'),
        ],
      ),
      const SizedBox(height: 32),
      TwoCol(
        leftWidth: 320,
        breakpoint: 900,
        left: Column(children: [
          for (var i = 0; i < s.routines.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _RoutineTile(
                routine: s.routines[i],
                selected: _selected == i,
                onTap: () => setState(() => _selected = i),
              ),
            ),
        ]),
        right: _Detail(routine: routine),
      ),
    ]);
  }
}

class _RoutineTile extends StatelessWidget {
  const _RoutineTile({required this.routine, required this.selected, required this.onTap});
  final Routine routine;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final soft = selected ? w(.7) : w(.35);
    return SelectableCard(
      selected: selected,
      onTap: onTap,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: selected ? blk(.15) : w(.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.fitness_center, size: 20),
          ),
          Text('${routine.exercises.length} ejercicios', style: ts(12, weight: kXBold, color: soft)),
        ]),
        const SizedBox(height: 20),
        Text(routine.title, style: ts(18, weight: kBlack)),
        const SizedBox(height: 4),
        Text(routine.focus, style: ts(12, color: selected ? w(.7) : w(.4))),
        const SizedBox(height: 20),
        MiniBar(
          value: routine.progress / 100,
          track: selected ? blk(.15) : w(.08),
          fill: selected ? Colors.white : AppColors.accent,
        ),
        const SizedBox(height: 8),
        Text(routine.progressLabel, style: ts(11, weight: kSemi, color: soft)),
      ]),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.routine});
  final Routine routine;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: w(.08)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: w(.08)))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Eyebrow('Detalle de rutina'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Text(routine.title, style: ts(28, weight: kBlack, spacing: -.5)),
                  const SizedBox(height: 4),
                  Text(routine.focus, style: ts(14, color: w(.4))),
                ]),
                WhiteButton(
                  label: 'Comenzar rutina',
                  onPressed: () => showWorkoutDialog(context, routine.title),
                ),
              ],
            ),
          ]),
        ),
        for (var i = 0; i < routine.exercises.length; i++)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: i == 0 ? null : Border(top: BorderSide(color: w(.08))),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: w(.08), borderRadius: BorderRadius.circular(12)),
                child: Text('${i + 1}'.padLeft(2, '0'), style: ts(12, weight: kBlack, color: w(.45))),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(routine.exercises[i].name, style: ts(16, weight: kBold)),
                  const SizedBox(height: 12),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    InfoChip(routine.exercises[i].setsLabel),
                    InfoChip(routine.exercises[i].reps),
                    InfoChip(routine.exercises[i].restLabel),
                  ]),
                  const SizedBox(height: 12),
                  Text.rich(
                    TextSpan(children: [
                      TextSpan(text: 'Nota del coach: ', style: ts(12, weight: kBold, color: w(.55))),
                      TextSpan(text: routine.exercises[i].coachNote, style: ts(12, color: w(.35))),
                    ]),
                    style: const TextStyle(height: 1.6),
                  ),
                ]),
              ),
            ]),
          ),
      ]),
    );
  }
}
