import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/fechas.dart';
import '../../../core/skeleton.dart';
import '../../../core/theme.dart';
import '../../../core/widgets.dart';
import '../../admin/models/reglamento.dart';
import '../controllers/reglamento_controller.dart';
import '../../../core/app_shell.dart';

/// RF-093: reglamento del gimnasio, solo lectura, disponible en cualquier momento.
class ReglamentoView extends StatefulWidget {
  const ReglamentoView({super.key});

  @override
  State<ReglamentoView> createState() => _ReglamentoViewState();
}

class _ReglamentoViewState extends State<ReglamentoView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ReglamentoController>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ReglamentoController>();
    final lista = c.reglamentos;

    return SliverPage(slivers: [
      const Box(GimnasioSecciones(actual: '/reglamento')),
      const Box(
        PageTitle(eyebrow: 'Tu gimnasio', title: 'Reglamento', subtitle: 'Las normas que todos cumplimos.'),
        gapAfter: 16,
      ),
      if (c.error != null)
        Box(ErrorPanel(message: c.error!, onRetry: () => c.load()))
      else if (c.loading)
        Box(SkeletonScope(
          child: Column(children: [
            for (var i = 0; i < 2; i++)
              const Padding(padding: EdgeInsets.only(bottom: 12), child: Panel(child: SkeletonRow())),
          ]),
        ))
      else if (lista.isEmpty)
        Box(Panel(child: Text('El reglamento aún no está publicado.', style: ts(15, color: AppColors.pizarra))))
      else
        SliverList.builder(
          itemCount: lista.length,
          itemBuilder: (context, i) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ReglamentoCard(lista[i]),
          ),
        ),
    ]);
  }
}

class _ReglamentoCard extends StatelessWidget {
  const _ReglamentoCard(this.r);
  final Reglamento r;

  @override
  Widget build(BuildContext context) {
    final actualizado = r.fechaActualizacion ?? r.fechaCreacion;
    return Panel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(r.titulo, style: ts(18, weight: kSemi)),
        const SizedBox(height: 4),
        Text('Actualizado ${fechaCorta(actualizado)}', style: ts(13, color: AppColors.pizarra)),
        const SizedBox(height: 12),
        Text(r.contenido, style: ts(15)),
      ]),
    );
  }
}
