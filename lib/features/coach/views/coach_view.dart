import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/skeleton.dart';
import '../../../core/theme.dart';
import '../../../core/widgets.dart';
import '../../progreso/models/body_metric.dart';
import '../../rutinas/models/exercise.dart';
import '../controllers/coach_controller.dart';
import '../models/client.dart';

class CoachView extends StatelessWidget {
  const CoachView({super.key});

  @override
  Widget build(BuildContext context) {
    final loading = context.select<CoachController, bool>((c) => c.loading);
    final error = context.select<CoachController, String?>((c) => c.error);

    if (error != null) {
      return SliverPage(slivers: [
        const Box(_Header(), gapAfter: 24),
        Box(ErrorPanel(message: error, onRetry: () => context.read<CoachController>().load())),
      ]);
    }

    if (loading) {
      return const SliverPage(slivers: [
        Box(SkeletonScope(child: SkeletonTitle()), gapAfter: 28),
        Box(
          SkeletonScope(
            child: TwoCol(
              leftWidth: 300,
              breakpoint: 900,
              left: SkeletonBox(height: 320, radius: 18),
              right: Column(children: [
                SkeletonBox(height: 120, radius: 18),
                SizedBox(height: 20),
                SkeletonBox(height: 360, radius: 18),
              ]),
            ),
          ),
        ),
      ]);
    }

    return const SliverPage(slivers: [
      Box(_Header(), gapAfter: 28),
      Box(
        TwoCol(
          leftWidth: 300,
          breakpoint: 900,
          left: _ClientList(),
          right: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _ClientSummary(),
            SizedBox(height: 20),
            _RoutineBuilder(),
          ]),
        ),
      ),
    ]);
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 640;
    return Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
      const Expanded(child: PageTitle(eyebrow: 'Panel del coach', title: 'Asignar rutina')),
      if (wide) SecondaryButton(label: 'Ver como usuario', onPressed: () => context.go('/')),
    ]);
  }
}

class _ClientList extends StatelessWidget {
  const _ClientList();

  @override
  Widget build(BuildContext context) {
    final clients = context.select<CoachController, List<Client>>((c) => c.clients);
    final selected = context.select<CoachController, int>((c) => c.selectedClient);
    final wide = MediaQuery.sizeOf(context).width >= 1000;

    return Panel(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Eyebrow('Usuarios'),
            Text('${clients.length} activos', style: ts(16, weight: kSemi)),
          ]),
        ),
        // REGLA 4: lista virtualizada con altura acotada.
        SizedBox(
          height: wide ? 440 : 260,
          child: ListView.builder(
            itemCount: clients.length,
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _ClientTile(
                client: clients[i],
                selected: selected == i,
                onTap: () => context.read<CoachController>().selectClient(i),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _ClientTile extends StatelessWidget {
  const _ClientTile({required this.client, required this.selected, required this.onTap});
  final Client client;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? AppColors.indigo : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(children: [
              Avatar(
                client.initials,
                size: 40,
                bg: selected ? AppColors.ambar : AppColors.indigoSoft,
                fg: selected ? AppColors.ink : AppColors.indigo,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(client.name,
                      overflow: TextOverflow.ellipsis,
                      style: ts(15, weight: kSemi, color: selected ? Colors.white : AppColors.ink)),
                  Text(client.goal,
                      overflow: TextOverflow.ellipsis,
                      style: ts(13, color: selected ? AppColors.onIndigoMuted : AppColors.pizarra)),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _ClientSummary extends StatelessWidget {
  const _ClientSummary();

  @override
  Widget build(BuildContext context) {
    final client = context.select<CoachController, Client?>((c) => c.client);
    final metrics = context.select<CoachController, List<BodyMetric>>((c) => c.clientMetrics);
    final metricsLoading = context.select<CoachController, bool>((c) => c.metricsLoading);
    if (client == null) return const SizedBox.shrink();

    return Panel(
      padding: const EdgeInsets.all(24),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            const Eyebrow('Rutina para'),
            const SizedBox(height: 6),
            Text(client.name.toUpperCase(), style: display(32)),
            Text(client.goal, style: ts(15, color: AppColors.pizarra)),
          ]),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: AppColors.niebla, borderRadius: BorderRadius.circular(14)),
            child: metricsLoading
                ? const SkeletonScope(child: SkeletonBox(width: 220, height: 38))
                : Row(mainAxisSize: MainAxisSize.min, children: [
                    for (var i = 0; i < metrics.length; i++) ...[
                      if (i > 0) const SizedBox(width: 20),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Eyebrow(metrics[i].label),
                        Text(metrics[i].displayValue, style: ts(16, weight: kSemi)),
                      ]),
                    ],
                  ]),
          ),
        ],
      ),
    );
  }
}

class _RoutineBuilder extends StatelessWidget {
  const _RoutineBuilder();

  Future<void> _save(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await context.read<CoachController>().save();
    if (!ok) {
      messenger.showSnackBar(
        const SnackBar(content: Text('No se pudo asignar la rutina. Inténtalo de nuevo.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final assigned = context.select<CoachController, List<Exercise>>((c) => c.assigned);
    final status = context.select<CoachController, AssignStatus>((c) => c.status);
    final saved = status == AssignStatus.saved;

    return Panel(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Eyebrow('Constructor'),
            Text(CoachController.routineTitle.toUpperCase(), style: display(28)),
          ]),
          Pill('${assigned.length} ejercicios', tone: PillTone.cobalto),
        ]),
        const SizedBox(height: 20),
        // REGLA 4: conjunto acotado (una rutina tiene pocos ejercicios).
        for (var i = 0; i < assigned.length; i++)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
            decoration: BoxDecoration(
              color: AppColors.niebla,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(10)),
                child: Text('${i + 1}'.padLeft(2, '0'), style: display(18, color: AppColors.indigo)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(assigned[i].name, overflow: TextOverflow.ellipsis, style: ts(15, weight: kSemi)),
                  Text(assigned[i].summary, style: ts(13, color: AppColors.pizarra)),
                ]),
              ),
              IconButton(
                tooltip: 'Quitar ${assigned[i].name}',
                icon: const Icon(Icons.close, size: 20, color: AppColors.pizarra),
                onPressed: () => context.read<CoachController>().removeExerciseAt(i),
              ),
            ]),
          ),
        const SizedBox(height: 12),
        const _ExerciseSearch(),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.only(top: 18),
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.line))),
          child: Wrap(
            spacing: 16,
            runSpacing: 12,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(saved ? Icons.check_circle : Icons.info_outline,
                    size: 18, color: saved ? AppColors.success : AppColors.pizarra),
                const SizedBox(width: 6),
                Text(
                  saved ? 'Rutina asignada correctamente' : 'Los cambios aún no se han guardado',
                  style: ts(14, weight: kSemi, color: saved ? AppColors.success : AppColors.pizarra),
                ),
              ]),
              PrimaryButton(
                label: 'Guardar y asignar rutina',
                onPressed: saved || assigned.isEmpty ? null : () => _save(context),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

/// Búsqueda de ejercicios con debounce (REGLA 9) y resultados virtualizados (REGLA 4).
const _rowExtent = 64.0;

class _ExerciseSearch extends StatefulWidget {
  const _ExerciseSearch();

  @override
  State<_ExerciseSearch> createState() => _ExerciseSearchState();
}

class _ExerciseSearchState extends State<_ExerciseSearch> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final available = context.select<CoachController, List<Exercise>>((c) => c.available);
    final searching = context.select<CoachController, bool>((c) => c.searching);
    final query = context.select<CoachController, String>((c) => c.query);
    final tooShort = query.isNotEmpty && query.length < CoachController.minQueryLength;

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('Agregar ejercicio', style: ts(14, weight: kSemi)),
      const SizedBox(height: 8),
      ValueListenableBuilder<TextEditingValue>(
        valueListenable: _text,
        builder: (context, value, _) => TextField(
          controller: _text,
          onChanged: (v) => context.read<CoachController>().onQueryChanged(v),
          textInputAction: TextInputAction.search,
          style: ts(15),
          decoration: InputDecoration(
            hintText: 'Buscar en el catálogo (mín. 2 letras)',
            prefixIcon: const Icon(Icons.search, color: AppColors.pizarra),
            suffixIcon: value.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Limpiar búsqueda',
                    icon: const Icon(Icons.close, color: AppColors.pizarra),
                    onPressed: () {
                      _text.clear();
                      context.read<CoachController>().onQueryChanged('');
                    },
                  ),
          ),
        ),
      ),
      const SizedBox(height: 10),
      if (tooShort)
        Text('Escribe al menos ${CoachController.minQueryLength} letras para buscar.',
            style: ts(13, color: AppColors.pizarra))
      else if (searching)
        const SkeletonScope(child: Column(children: [SkeletonRow(leading: false), SkeletonRow(leading: false)]))
      else if (available.isEmpty)
        Text('No hay ejercicios que coincidan.', style: ts(13, color: AppColors.pizarra))
      else
        SizedBox(
          height: available.length > 4 ? 4 * _rowExtent : available.length * _rowExtent,
          child: ListView.builder(
            itemCount: available.length,
            itemExtent: _rowExtent,
            itemBuilder: (context, i) {
              final ex = available[i];
              // ListTile necesita su propio Material para pintar el efecto al tocar.
              return Material(
                type: MaterialType.transparency,
                child: ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                title: Text(ex.name, overflow: TextOverflow.ellipsis, style: ts(15, weight: kSemi)),
                subtitle: Text(ex.summary, overflow: TextOverflow.ellipsis, style: ts(13, color: AppColors.pizarra)),
                trailing: const Icon(Icons.add_circle_outline, color: AppColors.cobalto),
                onTap: () => context.read<CoachController>().addExercise(ex),
                ),
              );
            },
          ),
        ),
    ]);
  }
}
