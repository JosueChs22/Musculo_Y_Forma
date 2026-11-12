import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/skeleton.dart';
import '../../../core/theme.dart';
import '../../../core/widgets.dart';
import '../../perfil/controllers/perfil_controller.dart';
import '../../perfil/models/user_profile.dart';
import '../../planes/models/plan.dart';
import '../../progreso/controllers/progreso_controller.dart';
import '../../progreso/models/body_metric.dart';
import '../../rutinas/controllers/rutinas_controller.dart';
import '../../rutinas/models/routine.dart';
import '../../rutinas/views/widgets/workout_dialog.dart';

/// Inicio: compone datos de Perfil, Rutinas y Progreso del usuario con sesión.
/// Cada sección escucha solo su controlador y muestra su propio skeleton.
class InicioView extends StatelessWidget {
  const InicioView({super.key});

  @override
  Widget build(BuildContext context) {
    return const SliverPage(slivers: [
      Box(_Greeting(), gapAfter: 28),
      Box(_TodayHero(), gapAfter: 24),
      Box(_CoachCard(), gapAfter: 40),
      Box(_EvaluationSection(), gapAfter: 40),
      Box(_WeekSection()),
    ]);
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting();

  @override
  Widget build(BuildContext context) {
    final loading = context.select<PerfilController, bool>((c) => c.loading);
    final firstName = context.select<PerfilController, String>((c) => c.profile.firstName);
    if (loading || firstName.isEmpty) return const SkeletonScope(child: SkeletonTitle());
    return PageTitle(eyebrow: 'Tu plan personalizado', title: 'Hola, $firstName');
  }
}

class _TodayHero extends StatelessWidget {
  const _TodayHero();

  @override
  Widget build(BuildContext context) {
    final rutinasLoading = context.select<RutinasController, bool>((c) => c.loading);
    final error = context.select<RutinasController, String?>((c) => c.error);
    final routine = context.select<RutinasController, Routine?>((c) => c.deHoy);

    if (error != null) {
      return ErrorPanel(message: error, onRetry: () => context.read<RutinasController>().load());
    }
    if (rutinasLoading) {
      return const SkeletonScope(child: SkeletonBox(height: 260, radius: 24));
    }
    if (routine == null) {
      return const _Vacio(
        icono: Icons.event_note_outlined,
        titulo: 'Todavía no tienes una rutina asignada',
        texto: 'Cuando tu entrenador te asigne un plan, aparecerá aquí.',
      );
    }

    final big = MediaQuery.sizeOf(context).width >= 600;
    final progress = routine.progress;
    final title = routine.title;
    final esDeHoy = routine.diaSemana == DateTime.now().weekday;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(big ? 36 : 24),
      decoration: BoxDecoration(
        color: AppColors.indigo,
        borderRadius: BorderRadius.circular(28),
        boxShadow: kShadowFloating,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Eyebrow(
            esDeHoy ? 'Rutina de hoy · ${diasSemana[routine.diaSemana! - 1]}' : 'Tu próxima rutina',
            color: AppColors.onIndigoMuted,
          ),
          const SizedBox(height: 12),
          Text(title.toUpperCase(), style: display(big ? 56 : 40, color: Colors.white, height: .95)),
          const SizedBox(height: 12),
          Text('${routine.exercises.length} ${routine.exercises.length == 1 ? 'ejercicio' : 'ejercicios'} · ${routine.focus}',
              style: ts(15, color: AppColors.onIndigoMuted)),
          const SizedBox(height: 20),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: MiniBar(
              value: progress / 100,
              track: const Color(0x38FFFFFF),
              fill: AppColors.ambar,
            ),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: progress > 0 ? 'Continuar rutina · $progress%' : 'Empezar rutina',
            icon: Icons.play_arrow_rounded,
            onPressed: () => showWorkoutDialog(context, title),
          ),
        ],
      ),
    );
  }
}

class _CoachCard extends StatelessWidget {
  const _CoachCard();

  @override
  Widget build(BuildContext context) {
    final loading = context.select<PerfilController, bool>((c) => c.loading);
    final profile = context.select<PerfilController, UserProfile>((c) => c.profile);
    if (loading) return const SkeletonScope(child: SkeletonBox(height: 88, radius: 18));
    return Panel(
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
            Avatar(profile.coachName == null ? '?' : profile.coachInitials),
            const SizedBox(width: 14),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Tu coach', style: ts(13, color: AppColors.pizarra)),
              Text(profile.coachName ?? 'Sin coach asignado', style: ts(17, weight: kSemi)),
            ]),
          ]),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: AppColors.niebla, borderRadius: BorderRadius.circular(14)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text('Objetivo actual', style: ts(13, color: AppColors.pizarra)),
              Text(profile.goal ?? 'Sin definir', style: ts(15, weight: kSemi)),
            ]),
          ),
        ],
      ),
    );
  }
}

class _EvaluationSection extends StatelessWidget {
  const _EvaluationSection();

  static const _icons = [Icons.monitor_weight_outlined, Icons.water_drop_outlined, Icons.fitness_center];

  @override
  Widget build(BuildContext context) {
    final label = context.select<PerfilController, String>((c) => c.profile.lastMeasurementLabel ?? '');
    final loading = context.select<ProgresoController, bool>((c) => c.loading);
    final error = context.select<ProgresoController, String?>((c) => c.error);
    final metrics = context.select<ProgresoController, List<BodyMetric>>((c) => c.metrics);
    final wide = MediaQuery.sizeOf(context).width >= 640;

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SectionHeader(
        eyebrow: label.isEmpty ? 'Evaluación' : label,
        title: 'Mi evaluación',
        trailing: wide
            ? TextButton(
                onPressed: () => context.go('/progreso'),
                child: Text('Ver historial', style: ts(15, weight: kSemi, color: AppColors.cobalto)),
              )
            : null,
      ),
      const SizedBox(height: 18),
      if (error != null)
        ErrorPanel(message: error, onRetry: () => context.read<ProgresoController>().load())
      else if (loading)
        const SkeletonScope(
          child: ResponsiveGrid(children: [SkeletonCard(height: 130), SkeletonCard(height: 130), SkeletonCard(height: 130)]),
        )
      else if (metrics.isEmpty)
        const _Vacio(
          icono: Icons.monitor_weight_outlined,
          titulo: 'Todavía no tienes mediciones',
          texto: 'Tu entrenador registra tu peso y composición corporal en cada evaluación.',
        )
      else
        // REGLA 4: conjunto acotado (3 métricas destacadas).
        ResponsiveGrid(children: [
          for (var i = 0; i < metrics.length && i < 3; i++)
            Panel(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(metrics[i].displayValue, style: display(34)),
                      Text(metrics[i].label, style: ts(14, color: AppColors.pizarra)),
                      const SizedBox(height: 10),
                      Text('${metrics[i].changeVsPrevious} desde la anterior',
                          style: ts(13, weight: kSemi, color: AppColors.success)),
                    ]),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: AppColors.indigoSoft, borderRadius: BorderRadius.circular(12)),
                    child: Icon(_icons[i], size: 22, color: AppColors.indigo),
                  ),
                ],
              ),
            ),
        ]),
    ]);
  }
}

class _WeekSection extends StatelessWidget {
  const _WeekSection();

  static const _bands = [AppColors.indigo, AppColors.cobalto, AppColors.ambar];

  @override
  Widget build(BuildContext context) {
    final loading = context.select<RutinasController, bool>((c) => c.loading);
    final routines = context.select<RutinasController, List<Routine>>((c) => c.routines);
    final wide = MediaQuery.sizeOf(context).width >= 640;

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SectionHeader(
        eyebrow: 'Plan creado por tu coach',
        title: 'Mi rutina semanal',
        trailing: wide
            ? TextButton(
                onPressed: () => context.go('/rutinas'),
                child: Text('Ver plan completo', style: ts(15, weight: kSemi, color: AppColors.cobalto)),
              )
            : null,
      ),
      const SizedBox(height: 18),
      if (loading)
        const SkeletonScope(child: ResponsiveGrid(children: [SkeletonCard(), SkeletonCard(), SkeletonCard()]))
      else if (routines.isEmpty)
        const _Vacio(
          icono: Icons.calendar_month_outlined,
          titulo: 'Sin rutinas esta semana',
          texto: 'Tu plan semanal aparecerá aquí cuando tu entrenador lo asigne.',
        )
      else
        // REGLA 4: conjunto acotado (máximo 7 días por semana).
        ResponsiveGrid(children: [
          for (var i = 0; i < routines.length; i++)
            _WorkoutCard(
              number: (i + 1).toString().padLeft(2, '0'),
              routine: routines[i],
              band: _bands[i % _bands.length],
              onTap: () => showWorkoutDialog(context, routines[i].title),
            ),
        ]),
    ]);
  }
}

class _WorkoutCard extends StatelessWidget {
  const _WorkoutCard({required this.number, required this.routine, required this.band, required this.onTap});
  final String number;
  final Routine routine;
  final Color band;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final onBand = band == AppColors.ambar ? AppColors.ink : Colors.white;
    return Pressable(
      onTap: onTap,
      radius: kRadiusCard,
      semanticLabel: routine.title,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(kRadiusCard),
          boxShadow: kShadowCard,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(kRadiusCard),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              height: 96,
              width: double.infinity,
              color: band,
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(Icons.fitness_center, color: onBand, size: 24),
                  Text(number, style: display(64, color: onBand.withAlpha(90))),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(routine.title.toUpperCase(), style: display(26)),
                const SizedBox(height: 4),
                Text('${routine.exercises.length} ${routine.exercises.length == 1 ? 'ejercicio' : 'ejercicios'} · ${routine.focus}',
                    style: ts(14, color: AppColors.pizarra)),
                const SizedBox(height: 14),
                MiniBar(value: routine.progress / 100),
                const SizedBox(height: 6),
                Text(routine.progressLabel, style: ts(13, weight: kSemi, color: AppColors.pizarra)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Mensaje para cuando todavía no hay datos.
class _Vacio extends StatelessWidget {
  const _Vacio({required this.icono, required this.titulo, required this.texto});
  final IconData icono;
  final String titulo;
  final String texto;

  @override
  Widget build(BuildContext context) => Panel(
        child: Row(children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: AppColors.indigoSoft, borderRadius: BorderRadius.circular(14)),
            child: Icon(icono, color: AppColors.indigo),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(titulo, style: ts(16, weight: kSemi)),
              const SizedBox(height: 2),
              Text(texto, style: ts(14, color: AppColors.pizarra)),
            ]),
          ),
        ]),
      );
}
