import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../core/widgets.dart';
import '../state/app_state.dart';
import '../widgets/workout_dialog.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _gradients = [
    [Color(0xFFFF5A36), Color(0xFFFF8A3D)],
    [Color(0xFF8B5CF6), Color(0xFFC084FC)],
    [Color(0xFF24B47E), Color(0xFF54D6A1)],
  ];
  static const _metricIcons = [
    Icons.bar_chart,
    Icons.local_fire_department_outlined,
    Icons.fitness_center,
  ];

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final p = s.profile;
    final wide = MediaQuery.sizeOf(context).width >= 640;
    final heroCount = s.routines.isEmpty ? 0 : s.routines.first.exercises.length;

    return PageBody(children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tu plan personalizado', style: ts(14, color: w(.4))),
              const SizedBox(height: 4),
              Text('Hola, ${p.firstName}', style: ts(30, weight: kBlack, spacing: -.6)),
            ],
          ),
          const _BellButton(),
        ],
      ),
      const SizedBox(height: 32),
      _Hero(
        week: p.weekLabel,
        title: p.currentWorkout,
        meta: '$heroCount ejercicios',
        onStart: () => showWorkoutDialog(context, p.currentWorkout),
      ),
      const SizedBox(height: 36),
      Panel(
        padding: const EdgeInsets.all(20),
        child: Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Row(mainAxisSize: MainAxisSize.min, children: [
              Avatar(p.coachInitials),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tu coach', style: ts(12, color: w(.4))),
                  const SizedBox(height: 2),
                  Text(p.coachName, style: ts(16, weight: kBold)),
                ],
              ),
            ]),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: w(.05), borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Objetivo actual', style: ts(12, color: w(.4))),
                  const SizedBox(height: 2),
                  Text(p.goal, style: ts(14, weight: kSemi)),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 36),
      SectionHeader(
        eyebrow: p.lastMeasurementLabel,
        title: 'Mi evaluación',
        trailing: wide
            ? TextButton(
                onPressed: () => context.go('/progreso'),
                child: Text('Ver historial', style: ts(14, weight: kSemi, color: w(.45))),
              )
            : null,
      ),
      const SizedBox(height: 20),
      ResponsiveGrid(children: [
        for (var i = 0; i < s.metrics.length && i < 3; i++)
          Panel(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.metrics[i].displayValue, style: ts(24, weight: kBlack, spacing: -.4)),
                    const SizedBox(height: 4),
                    Text(s.metrics[i].label, style: ts(12, color: w(.4))),
                    const SizedBox(height: 12),
                    Text('${s.metrics[i].changeVsPrevious} desde la anterior',
                        style: ts(12, weight: kBold, color: AppColors.green)),
                  ],
                ),
                Icon(_metricIcons[i], size: 20, color: AppColors.accentLight),
              ],
            ),
          ),
      ]),
      const SizedBox(height: 40),
      SectionHeader(
        eyebrow: 'Plan creado por tu coach',
        title: 'Mi rutina semanal',
        trailing: wide
            ? TextButton(
                onPressed: () => context.go('/rutinas'),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('Ver plan completo', style: ts(14, weight: kSemi, color: w(.45))),
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 16, color: w(.45)),
                ]),
              )
            : null,
      ),
      const SizedBox(height: 20),
      ResponsiveGrid(children: [
        for (var i = 0; i < s.routines.length; i++)
          _WorkoutCard(
            number: (i + 1).toString().padLeft(2, '0'),
            title: s.routines[i].title,
            meta: '${s.routines[i].exercises.length} ejercicios',
            colors: _gradients[i % _gradients.length],
            onTap: () => showWorkoutDialog(context, s.routines[i].title),
          ),
      ]),
    ]);
  }
}

class _BellButton extends StatelessWidget {
  const _BellButton();

  @override
  Widget build(BuildContext context) => Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: w(.04),
          border: Border.all(color: w(.1)),
        ),
        child: Stack(alignment: Alignment.center, children: [
          Icon(Icons.notifications_none, color: w(.7)),
          Positioned(
            top: 10,
            right: 11,
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.bg, width: 2),
              ),
            ),
          ),
        ]),
      );
}

class _Hero extends StatelessWidget {
  const _Hero({required this.week, required this.title, required this.meta, required this.onStart});
  final String week;
  final String title;
  final String meta;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final big = MediaQuery.sizeOf(context).width >= 600;
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: Container(
        width: double.infinity,
        color: AppColors.cream,
        child: Stack(children: [
          Positioned(
            right: -64,
            top: -96,
            child: Container(
              width: 288,
              height: 288,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color.fromRGBO(255, 90, 54, .15), width: 45),
              ),
            ),
          ),
          Positioned(
            right: 56,
            bottom: 0,
            child: Container(
              width: 90,
              height: 170,
              decoration: const BoxDecoration(
                color: Color.fromRGBO(255, 90, 54, .10),
                borderRadius: BorderRadius.vertical(top: Radius.circular(90)),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(big ? 36 : 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(99)),
                    child: Text('RUTINA ASIGNADA · ${week.toUpperCase()}',
                        style: ts(11, weight: kXBold, spacing: 1.4)),
                  ),
                  const SizedBox(height: 20),
                  Text(title,
                      style: ts(big ? 46 : 32, weight: kBlack, color: AppColors.ink, height: 1.05, spacing: -1.4)),
                  const SizedBox(height: 20),
                  Text(meta, style: ts(14, weight: kSemi, color: blk(.55))),
                  const SizedBox(height: 28),
                  GestureDetector(
                    onTap: onStart,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(20, 10, 10, 10),
                      decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(99)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text('Empezar rutina', style: ts(14, weight: kBold)),
                        const SizedBox(width: 12),
                        Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: const Icon(Icons.play_arrow, size: 18, color: Colors.black),
                        ),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _WorkoutCard extends StatelessWidget {
  const _WorkoutCard({
    required this.number,
    required this.title,
    required this.meta,
    required this.colors,
    required this.onTap,
  });
  final String number;
  final String title;
  final String meta;
  final List<Color> colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: w(.08)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            height: 112,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
            ),
            child: Stack(children: [
              Positioned(
                right: 12,
                bottom: -22,
                child: Text(number, style: ts(112, weight: kBlack, color: blk(.10), height: 1)),
              ),
              Positioned(
                left: 16,
                top: 16,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: blk(.2), shape: BoxShape.circle),
                  child: const Icon(Icons.fitness_center, size: 20, color: Colors.white),
                ),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: ts(18, weight: kBold)),
              const SizedBox(height: 4),
              Text(meta, style: ts(12, color: w(.4))),
            ]),
          ),
        ]),
      ),
    );
  }
}
