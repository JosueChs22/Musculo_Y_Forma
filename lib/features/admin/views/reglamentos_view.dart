import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/skeleton.dart';
import '../../../core/theme.dart';
import '../../../core/widgets.dart';
import '../controllers/reglamentos_controller.dart';
import '../models/reglamento.dart';
import 'widgets/reglamento_detalle_dialog.dart';
import 'widgets/reglamento_form_dialog.dart';

/// Panel del Administrador: reglamento del gimnasio. Lista (RF-102), publicar
/// (RF-097), editar (RF-098) e inhabilitar (RF-101).
class ReglamentosView extends StatefulWidget {
  const ReglamentosView({super.key});

  @override
  State<ReglamentosView> createState() => _ReglamentosViewState();
}

class _ReglamentosViewState extends State<ReglamentosView> {
  @override
  void initState() {
    super.initState();
    // Se recarga cada vez que se abre la pantalla.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ReglamentosController>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ReglamentosController>();
    final lista = c.reglamentos;

    return SliverPage(slivers: [
      Box(
        Align(alignment: Alignment.centerLeft, child: BackLink(onTap: () => context.go('/admin'))),
        gapAfter: 8,
      ),
      const Box(
        PageTitle(
          eyebrow: 'Panel del administrador',
          title: 'Reglamento',
          subtitle: 'Normas del gimnasio que consultan los clientes en la app.',
        ),
        gapAfter: 16,
      ),
      Box(
        Align(
          alignment: Alignment.centerLeft,
          child: PrimaryButton(
            label: 'Nuevo reglamento',
            icon: Icons.add,
            onPressed: () => _nuevoReglamento(context),
          ),
        ),
        gapAfter: 16,
      ),
      if (c.error != null)
        Box(ErrorPanel(message: c.error!, onRetry: () => c.load()))
      else if (c.loading)
        Box(SkeletonScope(
          child: Column(children: [
            for (var i = 0; i < 3; i++)
              const Padding(padding: EdgeInsets.only(bottom: 12), child: Panel(child: SkeletonRow())),
          ]),
        ))
      else if (lista.isEmpty)
        Box(Panel(
          child: Text('Aún no hay reglamentos publicados.', style: ts(15, color: AppColors.pizarra)),
        ))
      else
        SliverList.builder(
          itemCount: lista.length,
          itemBuilder: (context, i) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ReglamentoTile(lista[i]),
          ),
        ),
    ]);
  }
}

/// RF-097: abre el formulario para publicar un reglamento.
void _nuevoReglamento(BuildContext context) {
  final c = context.read<ReglamentosController>();
  c.limpiarErrorGuardar();
  showDialog<void>(
    context: context,
    barrierDismissible: false, // no se cierra por accidente a mitad de un formulario
    builder: (_) => ReglamentoFormDialog(controller: c),
  );
}

/// RF-098: abre el mismo formulario con los datos del reglamento.
void _editarReglamento(BuildContext context, Reglamento r) {
  final c = context.read<ReglamentosController>();
  c.limpiarErrorGuardar();
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => ReglamentoFormDialog(controller: c, reglamento: r),
  );
}

/// RF-101: pide confirmación y luego inhabilita. Avisa con un mensaje al terminar.
Future<void> _inhabilitarReglamento(BuildContext context, Reglamento r) async {
  final c = context.read<ReglamentosController>();
  final messenger = ScaffoldMessenger.of(context);

  final confirmar = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.card,
      title: Text('¿INHABILITAR REGLAMENTO?', style: display(26)),
      content: Text(
        '"${r.titulo}" dejará de ser visible para los clientes. Su información se '
        'conserva y no se elimina nada.',
        style: ts(15),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text('Cancelar', style: ts(15, weight: kSemi, color: AppColors.cobalto)),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text('Inhabilitar', style: ts(15, weight: kSemi, color: AppColors.danger)),
        ),
      ],
    ),
  );
  if (confirmar != true) return;

  final ok = await c.inhabilitarReglamento(r.id);
  messenger.showSnackBar(SnackBar(
    content: Text(ok
        ? 'Reglamento inhabilitado correctamente'
        : (c.errorAccion ?? 'No se pudo inhabilitar el reglamento.')),
  ));
}

/// Vuelve a publicar un reglamento inhabilitado, con confirmación y mensaje al terminar.
Future<void> _habilitarReglamento(BuildContext context, Reglamento r) async {
  final c = context.read<ReglamentosController>();
  final messenger = ScaffoldMessenger.of(context);

  final confirmar = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.card,
      title: Text('¿HABILITAR REGLAMENTO?', style: display(26)),
      content: Text('"${r.titulo}" volverá a ser visible para los clientes.', style: ts(15)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text('Cancelar', style: ts(15, weight: kSemi, color: AppColors.cobalto)),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text('Habilitar', style: ts(15, weight: kSemi, color: AppColors.success)),
        ),
      ],
    ),
  );
  if (confirmar != true) return;

  final ok = await c.habilitarReglamento(r.id);
  messenger.showSnackBar(SnackBar(
    content: Text(ok
        ? 'Reglamento habilitado correctamente'
        : (c.errorAccion ?? 'No se pudo habilitar el reglamento.')),
  ));
}

class _ReglamentoTile extends StatelessWidget {
  const _ReglamentoTile(this.r);
  final Reglamento r;

  @override
  Widget build(BuildContext context) => SelectableCard(
        selected: false,
        semanticLabel: '${r.titulo}, ${r.estado.valor}',
        onTap: () => _mostrarDetalle(context, r),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.gavel_outlined, size: 28, color: AppColors.cobalto),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r.titulo, maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(16, weight: kSemi)),
              const SizedBox(height: 4),
              // Vista previa: el contenido completo está en el detalle
              Text(r.contenido, maxLines: 3, overflow: TextOverflow.ellipsis, style: ts(14, color: AppColors.pizarra)),
            ]),
          ),
          const SizedBox(width: 12),
          Text(r.estado.valor,
              style: ts(13, weight: kSemi, color: r.estaActivo ? AppColors.success : AppColors.danger)),
        ]),
      );
}

/// Detalle completo del reglamento. Editar e inhabilitar se abren con el contexto
/// de la pantalla (no el del diálogo, que ya se cerró).
void _mostrarDetalle(BuildContext context, Reglamento r) {
  showDialog<void>(
    context: context,
    builder: (_) => ReglamentoDetalleDialog(
      reglamento: r,
      onEditar: () => _editarReglamento(context, r),
      onInhabilitar: () => _inhabilitarReglamento(context, r),
      onHabilitar: () => _habilitarReglamento(context, r),
    ),
  );
}
