import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/skeleton.dart';
import '../../../core/theme.dart';
import '../../../core/widgets.dart';
import '../controllers/horarios_controller.dart';
import '../models/horario_del_dia.dart';

/// RF-095: horarios de clases del gimnasio (solo lectura), por día y empezando por hoy.
class HorariosView extends StatefulWidget {
  const HorariosView({super.key});

  @override
  State<HorariosView> createState() => _HorariosViewState();
}

class _HorariosViewState extends State<HorariosView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<HorariosController>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.select<HorariosController, bool>((c) => c.loading);
    final error = context.select<HorariosController, String?>((c) => c.error);
    final dias = context.select<HorariosController, List<HorarioDelDia>>((c) => c.dias);
    final hoy = context.select<HorariosController, int>((c) => c.hoy);

    return SliverPage(slivers: [
      Box(
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => context.go('/perfil'),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(44, 44),
              foregroundColor: AppColors.cobalto,
            ),
            icon: const Icon(Icons.arrow_back, size: 18),
            label: Text('Volver al perfil', style: ts(14, weight: kSemi, color: AppColors.cobalto)),
          ),
        ),
        gapAfter: 8,
      ),
      const Box(
        PageTitle(eyebrow: 'Tu gimnasio', title: 'Horarios de clases', subtitle: 'Clases grupales de la semana.'),
        gapAfter: 16,
      ),
      if (error != null)
        Box(ErrorPanel(message: error, onRetry: () => context.read<HorariosController>().load()))
      else if (loading)
        Box(SkeletonScope(
          child: Column(children: [
            for (var i = 0; i < 3; i++)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Panel(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    SkeletonBox(width: 120, height: 20),
                    SizedBox(height: 12),
                    SkeletonRow(leading: false),
                    SkeletonRow(leading: false),
                  ]),
                ),
              ),
          ]),
        ))
      else if (dias.isEmpty)
        Box(Panel(child: Text('Aún no hay clases programadas.', style: ts(15, color: AppColors.pizarra))))
      else
        SliverList.builder(
          itemCount: dias.length,
          itemBuilder: (context, i) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _DiaCard(dias[i], esHoy: dias[i].dia == hoy),
          ),
        ),
    ]);
  }
}

class _DiaCard extends StatelessWidget {
  const _DiaCard(this.dia, {required this.esHoy});
  final HorarioDelDia dia;
  final bool esHoy;

  @override
  Widget build(BuildContext context) {
    return Panel(
      color: esHoy ? AppColors.indigoSoft : AppColors.card,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(dia.nombre, style: ts(18, weight: kSemi, color: AppColors.indigo))),
          if (esHoy) const Pill('Hoy'),
        ]),
        const SizedBox(height: 8),
        // REGLA 4: pocas clases por día (lista acotada); la lista de días sí es virtual
        for (final s in dia.sesiones) _SesionFila(s),
      ]),
    );
  }
}

class _SesionFila extends StatelessWidget {
  const _SesionFila(this.s);
  final SesionClase s;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
            width: 120,
            child: Text(s.rangoHora, style: ts(14, weight: kSemi, color: AppColors.cobalto)),
          ),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.nombre, style: ts(15, weight: kSemi)),
              if (s.descripcion != null && s.descripcion!.isNotEmpty)
                Text(s.descripcion!, style: ts(13, color: AppColors.pizarra)),
            ]),
          ),
        ]),
      );
}
