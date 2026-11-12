import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/skeleton.dart';
import '../../../core/theme.dart';
import '../../../core/widgets.dart';
import '../controllers/planes_controller.dart';
import '../models/plan.dart';
import 'widgets/cliente_picker_dialog.dart';

/// Panel del Entrenador: sus planes de entrenamiento. Desde aquí crea planes,
/// los edita, los asigna a un usuario (buscándolo por nombre) y entra al catálogo de ejercicios.
class PlanesView extends StatefulWidget {
  const PlanesView({super.key});

  @override
  State<PlanesView> createState() => _PlanesViewState();
}

class _PlanesViewState extends State<PlanesView> {
  // El controlador sobrevive a la pantalla: al volver, el campo muestra la búsqueda vigente.
  late final _busqueda = TextEditingController(text: context.read<PlanesController>().escrito);

  @override
  void initState() {
    super.initState();
    // Se recarga cada vez que se abre la pantalla (necesita el token de la sesión).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<PlanesController>().load();
    });
  }

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<PlanesController>();
    final items = c.items;

    return SliverPage(slivers: [
      const Box(
        PageTitle(
          eyebrow: 'Panel del entrenador',
          title: 'Planes',
          subtitle: 'Arma planes con los ejercicios del catálogo y asígnalos a tus usuarios.',
        ),
        gapAfter: 16,
      ),
      Box(
        Wrap(spacing: 12, runSpacing: 12, children: [
          PrimaryButton(label: 'Nuevo plan', icon: Icons.add, onPressed: () => context.go('/coach/plan/nuevo')),
          SecondaryButton(
            label: 'Catálogo de ejercicios',
            icon: Icons.fitness_center,
            onPressed: () => context.go('/coach/ejercicios'),
          ),
        ]),
        gapAfter: 16,
      ),
      Box(
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _busqueda,
          builder: (context, value, _) => TextField(
            controller: _busqueda,
            onChanged: c.buscar,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Buscar plan por nombre (mín. ${PlanesController.minimoBusqueda} letras)',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: value.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Limpiar búsqueda',
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _busqueda.clear();
                        c.buscar('');
                      },
                    ),
            ),
          ),
        ),
        gapAfter: c.textoMuyCorto ? 6 : 12,
      ),
      if (c.textoMuyCorto)
        Box(
          Text('Escribe al menos ${PlanesController.minimoBusqueda} letras para buscar.',
              style: ts(13, color: AppColors.pizarra)),
          gapAfter: 12,
        ),
      Box(
        Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
          _Chip('Todos', c.categoriaFiltro == null, () => c.filtrarCategoria(null)),
          for (final cat in CategoriaPlan.values)
            _Chip(cat.etiqueta, c.categoriaFiltro == cat, () => c.filtrarCategoria(cat)),
          _Chip('Ver inhabilitados', c.verInhabilitados, () => c.mostrarInhabilitados(!c.verInhabilitados),
              marca: true),
        ]),
        gapAfter: 16,
      ),
      if (c.error != null)
        Box(ErrorPanel(message: c.error!, onRetry: () => c.load()))
      else if (c.loading)
        Box(SkeletonScope(
          child: Column(children: [
            for (var i = 0; i < 4; i++)
              const Padding(padding: EdgeInsets.only(bottom: 12), child: Panel(child: SkeletonRow())),
          ]),
        ))
      else if (items.isEmpty)
        Box(Panel(
          child: Text(
            c.hayFiltros
                ? 'No hay planes que coincidan con la búsqueda.'
                : 'Todavía no tienes planes. Crea el primero con "Nuevo plan".',
            style: ts(15, color: AppColors.pizarra),
          ),
        ))
      else ...[
        // REGLA 4: lista virtualizada
        SliverList.builder(
          itemCount: items.length,
          itemBuilder: (context, i) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _PlanTile(items[i]),
          ),
        ),
        if (c.cargandoMas)
          const Box(SkeletonScope(child: Panel(child: SkeletonRow())))
        else if (c.hayMas)
          Box(Center(child: SecondaryButton(label: 'Cargar más', onPressed: () => _cargarMas(context)))),
      ],
    ]);
  }
}

void _avisar(BuildContext context, String? mensaje) {
  if (mensaje != null) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
}

Future<void> _cargarMas(BuildContext context) async {
  final c = context.read<PlanesController>();
  await c.cargarMas();
  if (context.mounted) _avisar(context, c.tomarAviso());
}

Future<void> _asignar(BuildContext context, Plan plan) async {
  final elegido = await ClientePickerDialog.mostrar(context, actual: plan.usuario);
  if (elegido == null || !context.mounted) return;
  final messenger = ScaffoldMessenger.of(context);
  final c = context.read<PlanesController>();
  final ok = await c.asignar(plan, elegido.cliente);
  messenger.showSnackBar(SnackBar(
    content: Text(ok
        ? (elegido.cliente == null ? 'Plan sin asignar' : 'Plan asignado a ${elegido.cliente!.nombre}')
        : c.tomarAviso() ?? ''),
  ));
}

/// Pide confirmación antes de inhabilitar. Reactivar no la necesita.
Future<void> _cambiarEstado(BuildContext context, Plan plan, {required bool activo}) async {
  if (!activo) {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text('INHABILITAR PLAN', style: display(26)),
        content: Text('"${plan.nombre}" dejará de poder editarse y asignarse. Puedes reactivarlo cuando quieras.',
            style: ts(15)),
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
    if (confirmar != true || !context.mounted) return;
  }

  final messenger = ScaffoldMessenger.of(context);
  final c = context.read<PlanesController>();
  final ok = await c.cambiarEstado(plan, activo: activo);
  messenger.showSnackBar(SnackBar(
    content: Text(ok ? 'Plan ${activo ? 'reactivado' : 'inhabilitado'}' : c.tomarAviso() ?? ''),
  ));
}

class _Chip extends StatelessWidget {
  const _Chip(this.label, this.selected, this.onTap, {this.marca = false});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// true para un interruptor (muestra el check); false para una opción de un grupo.
  final bool marca;

  @override
  Widget build(BuildContext context) => FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        showCheckmark: marca,
        checkmarkColor: Colors.white,
        backgroundColor: AppColors.card,
        selectedColor: AppColors.indigo,
        side: BorderSide.none,
        shape: const StadiumBorder(),
        labelStyle: ts(14, weight: kSemi, color: selected ? Colors.white : AppColors.ink),
      );
}

class _PlanTile extends StatelessWidget {
  const _PlanTile(this.plan);
  final Plan plan;

  @override
  Widget build(BuildContext context) {
    final detalle = [
      '${plan.totalEjercicios} ${plan.totalEjercicios == 1 ? 'ejercicio' : 'ejercicios'}',
      if (plan.dia != null) plan.dia!,
    ].join(' · ');

    return SelectableCard(
      selected: false,
      padding: const EdgeInsets.fromLTRB(20, 14, 8, 14),
      semanticLabel: '${plan.nombre}, ${plan.categoria.etiqueta}, ${plan.activo ? 'activo' : 'inhabilitado'}',
      onTap: plan.activo ? () => context.go('/coach/plan/${plan.id}') : () => _cambiarEstado(context, plan, activo: true),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Wrap(spacing: 10, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
              Text(plan.nombre,
                  style: ts(16, weight: kSemi, color: plan.activo ? AppColors.ink : AppColors.pizarra)),
              InfoChip(plan.categoria.etiqueta),
              if (!plan.activo) Text('Inhabilitado', style: ts(13, weight: kSemi, color: AppColors.danger)),
            ]),
            const SizedBox(height: 4),
            Text(detalle, style: ts(14, color: AppColors.pizarra)),
            const SizedBox(height: 4),
            Row(children: [
              Icon(plan.usuario == null ? Icons.person_off_outlined : Icons.person_outline,
                  size: 16, color: plan.usuario == null ? AppColors.pizarra : AppColors.cobalto),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  plan.usuario == null ? 'Sin asignar' : 'Asignado a ${plan.usuario!.nombre}',
                  overflow: TextOverflow.ellipsis,
                  style: ts(14, weight: kSemi, color: plan.usuario == null ? AppColors.pizarra : AppColors.cobalto),
                ),
              ),
            ]),
          ]),
        ),
        PopupMenuButton<String>(
          tooltip: 'Opciones de ${plan.nombre}',
          icon: const Icon(Icons.more_vert, color: AppColors.pizarra),
          onSelected: (accion) => switch (accion) {
            'editar' => context.go('/coach/plan/${plan.id}'),
            'asignar' => _asignar(context, plan),
            'inhabilitar' => _cambiarEstado(context, plan, activo: false),
            _ => _cambiarEstado(context, plan, activo: true),
          },
          itemBuilder: (_) => [
            if (plan.activo) ...[
              _opcion('editar', Icons.edit_outlined, 'Editar', AppColors.ink),
              _opcion('asignar', Icons.person_add_alt_1_outlined, plan.usuario == null ? 'Asignar a un usuario' : 'Cambiar usuario',
                  AppColors.ink),
              _opcion('inhabilitar', Icons.block, 'Inhabilitar', AppColors.danger),
            ] else
              _opcion('reactivar', Icons.check_circle_outline, 'Reactivar', AppColors.success),
          ],
        ),
      ]),
    );
  }
}

PopupMenuItem<String> _opcion(String valor, IconData icono, String texto, Color color) => PopupMenuItem(
      value: valor,
      child: Row(children: [
        Icon(icono, size: 18, color: color),
        const SizedBox(width: 10),
        Text(texto, style: ts(14, color: color)),
      ]),
    );
