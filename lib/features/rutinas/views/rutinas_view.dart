import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/imagen_red.dart';
import '../../../core/skeleton.dart';
import '../../../core/theme.dart';
import '../../../core/widgets.dart';
import '../../perfil/controllers/perfil_controller.dart';
import '../controllers/rutinas_controller.dart';
import '../models/exercise.dart';
import '../models/routine.dart';
import 'widgets/ejercicio_detalle.dart';

class RutinasView extends StatelessWidget {
  const RutinasView({super.key});

  @override
  Widget build(BuildContext context) {
    final loading = context.select<RutinasController, bool>((c) => c.loading);
    final error = context.select<RutinasController, String?>((c) => c.error);
    final tab = context.select<RutinasController, RutinasTab>((c) => c.tab);
    final routine = context.select<RutinasController, Routine?>((c) => c.selected);

    if (error != null) {
      return SliverPage(slivers: [
        const Box(_Header(), gapAfter: 24),
        Box(ErrorPanel(message: error, onRetry: () => context.read<RutinasController>().load())),
      ]);
    }

    if (loading) {
      return const SliverPage(slivers: [
        Box(SkeletonScope(child: SkeletonTitle()), gapAfter: 28),
        Box(SkeletonScope(child: SkeletonBox(height: 44, radius: 22)), gapAfter: 24),
        Box(SkeletonScope(child: SkeletonBox(height: 180, radius: 18)), gapAfter: 24),
        Box(SkeletonScope(child: SkeletonBox(height: 120, radius: 18)), gapAfter: 16),
        Box(SkeletonScope(child: Column(children: [SkeletonRow(), SkeletonRow(), SkeletonRow()]))),
      ]);
    }

    if (tab == RutinasTab.historial) {
      return const SliverPage(slivers: [
        Box(_Header(), gapAfter: 20),
        Box(_Tabs(), gapAfter: 24),
        _HistorialSliver(),
      ]);
    }

    if (routine == null) {
      return SliverPage(slivers: [
        const Box(_Header(), gapAfter: 20),
        const Box(_Tabs(), gapAfter: 24),
        Box(_Vacio(tab: tab)),
      ]);
    }

    return SliverPage(slivers: [
      const Box(_Header(), gapAfter: 20),
      const Box(_Tabs(), gapAfter: 24),
      const Box(_RoutinePicker(), gapAfter: 24),
      Box(_DetailHeader(routine: routine), gapAfter: 12),
      // REGLA 4: lista virtualizada. En pantallas anchas los ejercicios van en
      // 2 o 3 columnas para ver la rutina completa sin tanto desplazamiento.
      SliverLayoutBuilder(builder: (context, caja) {
        final ancho = caja.crossAxisExtent;
        final cols = ancho >= 1100 ? 3 : (ancho >= 700 ? 2 : 1);
        final ejercicios = routine.exercises;
        final filas = (ejercicios.length / cols).ceil();
        return SliverList.builder(
          itemCount: filas,
          itemBuilder: (context, f) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              for (var k = 0; k < cols; k++) ...[
                if (k > 0) const SizedBox(width: 12),
                Expanded(
                  child: f * cols + k < ejercicios.length
                      ? _ExerciseTile(index: f * cols + k, exercise: ejercicios[f * cols + k])
                      : const SizedBox.shrink(),
                ),
              ],
            ]),
          ),
        );
      }),
    ]);
  }
}

/// RF-084 / RF-086 / RF-088 / RF-091: Entrenamiento · Calentamiento · Estiramiento · Historial.
class _Tabs extends StatelessWidget {
  const _Tabs();

  @override
  Widget build(BuildContext context) {
    final tab = context.select<RutinasController, RutinasTab>((c) => c.tab);
    return SegmentedPill<RutinasTab>(
      opciones: [for (final t in RutinasTab.values) (t, t.etiqueta)],
      seleccion: tab,
      onCambio: (t) => context.read<RutinasController>().setTab(t),
    );
  }
}

class _Vacio extends StatelessWidget {
  const _Vacio({required this.tab});
  final RutinasTab tab;

  @override
  Widget build(BuildContext context) {
    final nombre = tab.etiqueta.toLowerCase();
    return Panel(
      child: Row(children: [
        const Icon(Icons.event_note_outlined, color: AppColors.indigo, size: 32),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Todavía no tienes rutinas de $nombre', style: ts(16, weight: kSemi)),
            const SizedBox(height: 2),
            Text('Cuando tu entrenador te asigne un plan de $nombre, lo verás aquí con cada ejercicio.',
                style: ts(14, color: AppColors.pizarra)),
          ]),
        ),
      ]),
    );
  }
}

/// RF-091: planes pasados (inhabilitados) con scroll infinito.
class _HistorialSliver extends StatelessWidget {
  const _HistorialSliver();

  @override
  Widget build(BuildContext context) {
    final loading = context.select<RutinasController, bool>((c) => c.historialLoading);
    final error = context.select<RutinasController, String?>((c) => c.historialError);
    final items = context.select<RutinasController, List<Routine>>((c) => c.historial);
    final hayMas = context.select<RutinasController, bool>((c) => c.hayMasHistorial);
    final cargandoMas = context.select<RutinasController, bool>((c) => c.cargandoMas);

    if (error != null) {
      return SliverToBoxAdapter(
        child: ErrorPanel(message: error, onRetry: () => context.read<RutinasController>().cargarHistorial()),
      );
    }
    if (loading) {
      return const SliverToBoxAdapter(
        child: SkeletonScope(child: Column(children: [SkeletonRow(), SkeletonRow(), SkeletonRow(), SkeletonRow()])),
      );
    }
    if (items.isEmpty) {
      return SliverToBoxAdapter(
        child: Panel(child: Text('Aún no tienes rutinas anteriores.', style: ts(15, color: AppColors.pizarra))),
      );
    }
    final extra = (hayMas || cargandoMas) ? 1 : 0;
    return SliverList.builder(
      itemCount: items.length + extra,
      itemBuilder: (context, i) {
        // Cerca del final se pide la siguiente página (fuera del build).
        if (hayMas && i >= items.length - 3) {
          final c = context.read<RutinasController>();
          WidgetsBinding.instance.addPostFrameCallback((_) => c.cargarMasHistorial());
        }
        if (i >= items.length) {
          return const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: SkeletonScope(child: SkeletonRow()),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _HistorialTile(routine: items[i]),
        );
      },
    );
  }
}

/// La API del historial no trae ejercicios: solo nombre, categoría, coach y conteo.
class _HistorialTile extends StatelessWidget {
  const _HistorialTile({required this.routine});
  final Routine routine;

  @override
  Widget build(BuildContext context) {
    final n = routine.totalEjercicios;
    return Panel(
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: AppColors.indigoSoft, borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.history, size: 20, color: AppColors.indigo),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(routine.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(16, weight: kSemi)),
            const SizedBox(height: 2),
            Text(
              [
                routine.focus,
                '$n ${n == 1 ? 'ejercicio' : 'ejercicios'}',
                if (routine.coachName != null) 'Coach ${routine.coachName}',
              ].join(' · '),
              style: ts(14, color: AppColors.pizarra),
            ),
          ]),
        ),
        const SizedBox(width: 8),
        const Pill('Inhabilitada'),
      ]),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final coach = context.select<PerfilController, String>((c) => c.profile.coachName ?? '');
    final count = context.select<RutinasController, int>((c) => c.routines.length);
    final wide = MediaQuery.sizeOf(context).width >= 640;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 4),
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Expanded(
          child: PageTitle(
            title: 'Mis rutinas',
            subtitle: coach.isEmpty ? null : 'Plan asignado por $coach',
          ),
        ),
        if (wide && count > 0) Pill('$count rutinas asignadas', tone: PillTone.cobalto),
      ]),
    ]);
  }
}

/// Selector horizontal de rutinas (REGLA 4: ListView.builder).
class _RoutinePicker extends StatelessWidget {
  const _RoutinePicker();

  @override
  Widget build(BuildContext context) {
    final routines = context.select<RutinasController, List<Routine>>((c) => c.visibles);
    final selected = context.select<RutinasController, int>((c) => c.selectedIndex);
    return SizedBox(
      height: 190,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: routines.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, i) => SizedBox(
          width: 270,
          child: _RoutineTile(
            routine: routines[i],
            selected: selected == i,
            onTap: () => context.read<RutinasController>().select(i),
          ),
        ),
      ),
    );
  }
}

class _RoutineTile extends StatelessWidget {
  const _RoutineTile({required this.routine, required this.selected, required this.onTap});
  final Routine routine;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : AppColors.ink;
    final soft = selected ? AppColors.onIndigoMuted : AppColors.pizarra;
    return SelectableCard(
      selected: selected,
      onTap: onTap,
      semanticLabel: routine.title,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: selected ? const Color(0x26FFFFFF) : AppColors.indigoSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.fitness_center, size: 20, color: selected ? Colors.white : AppColors.indigo),
          ),
          Text('${routine.exercises.length} ${routine.exercises.length == 1 ? 'ejercicio' : 'ejercicios'}',
              style: ts(13, weight: kSemi, color: soft)),
        ]),
        const Spacer(),
        Text(routine.title.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: display(26, color: fg)),
        Text(routine.focus, style: ts(14, color: soft)),
        const SizedBox(height: 12),
        MiniBar(
          value: routine.progress / 100,
          track: selected ? const Color(0x38FFFFFF) : AppColors.track,
          fill: selected ? AppColors.ambar : AppColors.cobalto,
        ),
        const SizedBox(height: 6),
        Text(routine.progressLabel, style: ts(13, weight: kSemi, color: soft)),
      ]),
    );
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({required this.routine});
  final Routine routine;

  @override
  Widget build(BuildContext context) {
    return Panel(
      padding: const EdgeInsets.all(24),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.end,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            const Eyebrow('Detalle de rutina'),
            const SizedBox(height: 6),
            Text(routine.title.toUpperCase(), style: display(36)),
            Text(routine.focus, style: ts(15, color: AppColors.pizarra)),
            if (routine.observaciones != null && routine.observaciones!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(routine.observaciones!, style: ts(14, color: AppColors.ink)),
            ],
          ]),
          PrimaryButton(
            label: 'Comenzar rutina',
            icon: Icons.play_arrow_rounded,
            onPressed: () => context.go('/entrenar/${routine.id}'),
          ),
        ],
      ),
    );
  }
}

class _ExerciseTile extends StatelessWidget {
  const _ExerciseTile({required this.index, required this.exercise});
  final int index;
  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      semanticLabel: 'Ver detalle de ${exercise.name}',
      onTap: () => showEjercicioDetalle(context, exercise),
      child: Panel(
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: AppColors.indigoSoft, borderRadius: BorderRadius.circular(12)),
            child: Text('${index + 1}'.padLeft(2, '0'), style: display(20, color: AppColors.indigo)),
          ),
          const SizedBox(width: 12),
          if (exercise.imageUrl != null) ...[
            // Al tocar la imagen se ve la animación del ejercicio
            ImagenRed(exercise.imageUrl, size: 72),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(exercise.name, style: ts(17, weight: kSemi)),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8, children: [
                InfoChip(exercise.setsLabel),
                InfoChip(exercise.reps),
                InfoChip(exercise.restLabel),
                if (exercise.pesoLabel != null) InfoChip(exercise.pesoLabel!),
              ]),
              if (exercise.coachNote.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text.rich(
                  TextSpan(children: [
                    TextSpan(text: 'Nota del coach: ', style: ts(14, weight: kSemi)),
                    TextSpan(text: exercise.coachNote, style: ts(14, color: AppColors.pizarra)),
                  ]),
                  style: const TextStyle(height: 1.5),
                ),
              ],
            ]),
          ),
        ]),
      ),
    );
  }
}
