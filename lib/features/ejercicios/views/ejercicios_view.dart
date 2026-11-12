import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/imagen_red.dart';
import '../../../core/skeleton.dart';
import '../../../core/theme.dart';
import '../../../core/widgets.dart';
import '../controllers/ejercicios_controller.dart';
import '../models/ejercicio.dart';
import 'widgets/ejercicio_form_dialog.dart';

/// Panel del Entrenador: catálogo de ejercicios (RF-062) con búsqueda (RF-073).
class EjerciciosView extends StatefulWidget {
  const EjerciciosView({super.key});

  @override
  State<EjerciciosView> createState() => _EjerciciosViewState();
}

class _EjerciciosViewState extends State<EjerciciosView> {
  // El controlador sobrevive a la pantalla: al volver, el campo muestra la búsqueda vigente.
  late final _busqueda = TextEditingController(text: context.read<EjerciciosController>().escrito);

  @override
  void initState() {
    super.initState();
    // Se recarga cada vez que se abre la pantalla (necesita el token de la sesión).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<EjerciciosController>().load();
    });
  }

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<EjerciciosController>();
    final items = c.items;

    return SliverPage(slivers: [
      Box(
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => context.go('/coach'),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(44, 44),
              foregroundColor: AppColors.cobalto,
            ),
            icon: const Icon(Icons.arrow_back, size: 18),
            label: Text('Volver a los planes', style: ts(14, weight: kSemi, color: AppColors.cobalto)),
          ),
        ),
        gapAfter: 8,
      ),
      const Box(
        PageTitle(
          eyebrow: 'Panel del entrenador',
          title: 'Ejercicios',
          subtitle: 'Catálogo con imagen y animación de cada ejercicio.',
        ),
        gapAfter: 16,
      ),
      Box(
        Align(
          alignment: Alignment.centerLeft,
          child: PrimaryButton(
            label: 'Nuevo ejercicio',
            icon: Icons.add,
            onPressed: () => _abrirFormulario(context),
          ),
        ),
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
              hintText: 'Buscar por nombre (mín. ${EjerciciosController.minimoBusqueda} letras)',
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
          Text('Escribe al menos ${EjerciciosController.minimoBusqueda} letras para buscar.',
              style: ts(13, color: AppColors.pizarra)),
          gapAfter: 12,
        ),
      Box(
        Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
          _Chip('Todos', c.grupoFiltro == null, () => c.filtrarGrupo(null)),
          for (final g in gruposMusculares) _Chip(g, c.grupoFiltro == g, () => c.filtrarGrupo(g)),
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
            for (var i = 0; i < 6; i++)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Panel(child: SkeletonRow()),
              ),
          ]),
        ))
      else if (items.isEmpty)
        Box(Panel(
          child: Text(
            c.hayFiltros
                ? 'No hay ejercicios que coincidan con la búsqueda.'
                : 'Todavía no hay ejercicios en el catálogo. Crea el primero con "Nuevo ejercicio".',
            style: ts(15, color: AppColors.pizarra),
          ),
        ))
      else ...[
        // REGLA 4: lista virtualizada
        SliverList.builder(
          itemCount: items.length,
          itemBuilder: (context, i) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _EjercicioTile(items[i]),
          ),
        ),
        if (c.cargandoMas)
          const Box(SkeletonScope(child: Panel(child: SkeletonRow())))
        else if (c.hayMas)
          Box(Center(
            child: SecondaryButton(label: 'Cargar más', onPressed: () => _cargarMas(context)),
          )),
      ],
    ]);
  }
}

void _mostrarAviso(BuildContext context) {
  final aviso = context.read<EjerciciosController>().tomarAviso();
  if (aviso != null) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(aviso)));
}

Future<void> _cargarMas(BuildContext context) async {
  await context.read<EjerciciosController>().cargarMas();
  if (context.mounted) _mostrarAviso(context);
}

void _abrirFormulario(BuildContext context, [Ejercicio? ejercicio]) {
  final c = context.read<EjerciciosController>();
  c.limpiarErrorGuardar();
  showDialog<void>(
    context: context,
    barrierDismissible: false, // no se cierra por accidente a mitad de un formulario
    builder: (_) => EjercicioFormDialog(controller: c, ejercicio: ejercicio),
  );
}

/// RF-055: pide confirmación antes de inhabilitar. Reactivar no la necesita.
Future<void> _cambiarEstado(BuildContext context, Ejercicio e, {required bool activo}) async {
  if (!activo) {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text('INHABILITAR EJERCICIO', style: display(26)),
        content: Text(
          '"${e.nombre}" dejará de estar disponible para armar planes. Los planes que ya lo tienen lo conservan. Puedes reactivarlo cuando quieras.',
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
    if (confirmar != true || !context.mounted) return;
  }

  final messenger = ScaffoldMessenger.of(context);
  final c = context.read<EjerciciosController>();
  final ok = await c.cambiarEstado(e, activo: activo);
  messenger.showSnackBar(SnackBar(
    content: Text(ok ? 'Ejercicio ${activo ? 'reactivado' : 'inhabilitado'}' : c.tomarAviso() ?? ''),
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

class _EjercicioTile extends StatelessWidget {
  const _EjercicioTile(this.e);
  final Ejercicio e;

  @override
  Widget build(BuildContext context) => SelectableCard(
        selected: false,
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        semanticLabel: '${e.nombre}, ${e.grupoMuscular ?? ''}, ${e.estado}',
        onTap: () => _mostrarDetalle(context, e),
        child: Row(children: [
          ImagenRed(e.imagenUrl, size: 64),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(e.nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ts(16, weight: kSemi, color: e.activo ? AppColors.ink : AppColors.pizarra)),
              const SizedBox(height: 2),
              Text(
                e.resumen.isEmpty ? 'Sin datos' : e.resumen,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ts(14, color: AppColors.pizarra),
              ),
            ]),
          ),
          if (!e.activo) ...[
            const SizedBox(width: 12),
            Text('Inhabilitado', style: ts(13, weight: kSemi, color: AppColors.danger)),
          ],
          PopupMenuButton<String>(
            tooltip: 'Opciones de ${e.nombre}',
            icon: const Icon(Icons.more_vert, color: AppColors.pizarra),
            onSelected: (accion) => switch (accion) {
              'editar' => _abrirFormulario(context, e),
              'inhabilitar' => _cambiarEstado(context, e, activo: false),
              _ => _cambiarEstado(context, e, activo: true),
            },
            itemBuilder: (_) => [
              if (e.activo) ...[
                _opcion('editar', Icons.edit_outlined, 'Editar', AppColors.ink),
                _opcion('inhabilitar', Icons.block, 'Inhabilitar', AppColors.danger),
              ] else
                _opcion('reactivar', Icons.check_circle_outline, 'Reactivar', AppColors.success),
            ],
          ),
        ]),
      );
}

PopupMenuItem<String> _opcion(String valor, IconData icono, String texto, Color color) => PopupMenuItem(
      value: valor,
      child: Row(children: [
        Icon(icono, size: 18, color: color),
        const SizedBox(width: 10),
        Text(texto, style: ts(14, color: color)),
      ]),
    );

/// RF-062: todos los datos del ejercicio, con su animación.
void _mostrarDetalle(BuildContext context, Ejercicio e) {
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.card,
      title: Text(e.nombre.toUpperCase(), style: display(26)),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (e.gifUrl != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Center(child: ImagenRed(e.gifUrl, size: 240, radius: 16)),
              ),
            _Dato('Grupo muscular', e.grupoMuscular),
            _Dato('Herramienta o equipo', e.herramienta),
            _Dato('Estado', e.estado),
            if (e.tiempoRecomendado != null) _Dato('Tiempo recomendado', '${e.tiempoRecomendado} min'),
            _Dato('Instrucciones', e.instrucciones),
            if (e.recomendaciones != null) _Dato('Recomendaciones', e.recomendaciones),
            if (e.observaciones != null) _Dato('Observaciones', e.observaciones),
          ]),
        ),
      ),
      actions: [
        if (e.activo)
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _abrirFormulario(context, e);
            },
            child: Text('Editar', style: ts(15, weight: kSemi, color: AppColors.cobalto)),
          ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text('Cerrar', style: ts(15, weight: kSemi, color: AppColors.cobalto)),
        ),
      ],
    ),
  );
}

class _Dato extends StatelessWidget {
  const _Dato(this.label, this.valor);
  final String label;
  final String? valor;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Eyebrow(label),
          const SizedBox(height: 2),
          Text(valor ?? 'Sin especificar', style: ts(16, color: valor == null ? AppColors.pizarra : AppColors.ink)),
        ]),
      );
}
