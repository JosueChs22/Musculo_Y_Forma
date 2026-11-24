import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/fechas.dart';
import '../../../core/skeleton.dart';
import '../../../core/theme.dart';
import '../../../core/widgets.dart';
import '../controllers/anuncios_controller.dart';
import '../models/anuncio.dart';
import 'widgets/anuncio_detalle_dialog.dart';
import 'widgets/anuncio_form_dialog.dart';

/// Panel de la Secretaria: anuncios. Lista (RF-032), publicar (RF-017),
/// editar (RF-022) e inhabilitar (RF-027).
class AnunciosView extends StatefulWidget {
  const AnunciosView({super.key});

  @override
  State<AnunciosView> createState() => _AnunciosViewState();
}

class _AnunciosViewState extends State<AnunciosView> {
  @override
  void initState() {
    super.initState();
    // Se recarga cada vez que se abre la pantalla (la API necesita el token de la sesión).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AnunciosController>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<AnunciosController>();
    final lista = c.anuncios;

    return SliverPage(slivers: [
      Box(
        Align(alignment: Alignment.centerLeft, child: BackLink(onTap: () => context.go('/secretaria'))),
        gapAfter: 8,
      ),
      const Box(
        PageTitle(
          eyebrow: 'Panel de secretaria',
          title: 'Anuncios',
          subtitle: 'Avisos y promociones que ven los clientes en la app.',
        ),
        gapAfter: 16,
      ),
      Box(
        Align(
          alignment: Alignment.centerLeft,
          child: PrimaryButton(
            label: 'Nuevo anuncio',
            icon: Icons.add,
            onPressed: () => _nuevoAnuncio(context),
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
          child: Text('Aún no hay anuncios publicados.', style: ts(15, color: AppColors.pizarra)),
        ))
      else ...[
        // REGLA 4: la lista puede crecer, se arma con SliverList.builder
        SliverRejilla(
          itemCount: lista.length,
          itemBuilder: (context, i) => _AnuncioTile(lista[i]),
        ),
        // REGLA 12: la API entrega los anuncios por páginas
        if (c.hayMas)
          Box(
            Align(
              alignment: Alignment.center,
              child: SecondaryButton(
                label: c.cargandoMas ? 'Cargando…' : 'Cargar más',
                icon: Icons.expand_more,
                onPressed: c.cargandoMas ? null : () => _cargarMas(context),
              ),
            ),
          ),
      ],
    ]);
  }
}

Future<void> _cargarMas(BuildContext context) async {
  final c = context.read<AnunciosController>();
  final messenger = ScaffoldMessenger.of(context);
  await c.cargarMas();
  if (c.errorAccion != null) {
    messenger.showSnackBar(SnackBar(content: Text(c.errorAccion!)));
  }
}

/// RF-017: abre el formulario para publicar un anuncio.
void _nuevoAnuncio(BuildContext context) {
  final c = context.read<AnunciosController>();
  c.limpiarErrorGuardar();
  showDialog<void>(
    context: context,
    barrierDismissible: false, // no se cierra por accidente a mitad de un formulario
    builder: (_) => AnuncioFormDialog(controller: c),
  );
}

/// RF-022: abre el mismo formulario con los datos del anuncio.
void _editarAnuncio(BuildContext context, Anuncio a) {
  final c = context.read<AnunciosController>();
  c.limpiarErrorGuardar();
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => AnuncioFormDialog(controller: c, anuncio: a),
  );
}

/// RF-027: pide confirmación y luego inhabilita. Avisa con un mensaje al terminar.
Future<void> _inhabilitarAnuncio(BuildContext context, Anuncio a) async {
  final c = context.read<AnunciosController>();
  final messenger = ScaffoldMessenger.of(context);

  final confirmar = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.card,
      title: Text('¿INHABILITAR ANUNCIO?', style: display(26)),
      content: Text(
        '"${a.titulo}" dejará de mostrarse a los clientes. Su información se '
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

  final ok = await c.inhabilitarAnuncio(a.id);
  messenger.showSnackBar(SnackBar(
    content: Text(ok
        ? 'Anuncio inhabilitado correctamente'
        : (c.errorAccion ?? 'No se pudo inhabilitar el anuncio.')),
  ));
}

/// Vuelve a publicar un anuncio inhabilitado, con confirmación y mensaje al terminar.
Future<void> _habilitarAnuncio(BuildContext context, Anuncio a) async {
  final c = context.read<AnunciosController>();
  final messenger = ScaffoldMessenger.of(context);

  final confirmar = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.card,
      title: Text('¿HABILITAR ANUNCIO?', style: display(26)),
      content: Text('"${a.titulo}" volverá a mostrarse a los clientes.', style: ts(15)),
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

  final ok = await c.habilitarAnuncio(a.id);
  messenger.showSnackBar(SnackBar(
    content: Text(ok
        ? 'Anuncio habilitado correctamente'
        : (c.errorAccion ?? 'No se pudo habilitar el anuncio.')),
  ));
}

class _AnuncioTile extends StatelessWidget {
  const _AnuncioTile(this.a);
  final Anuncio a;

  @override
  Widget build(BuildContext context) => SelectableCard(
        selected: false,
        semanticLabel: '${a.titulo}, ${a.etiquetaEstado}',
        onTap: () => _mostrarDetalle(context, a),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(a.tieneImagen ? Icons.image_outlined : Icons.campaign_outlined, size: 28, color: AppColors.cobalto),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(a.titulo, maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(16, weight: kSemi)),
              const SizedBox(height: 4),
              // RF-032 #3 y #4: fecha de publicación y vigencia
              Text('Publicado ${fechaCorta(a.fechaPublicacion)} · Vigencia ${a.textoVigencia}',
                  maxLines: 2, overflow: TextOverflow.ellipsis, style: ts(14, color: AppColors.pizarra)),
              if (a.clasificacion != null) ...[
                const SizedBox(height: 4),
                Text(a.clasificacion!, style: ts(13, weight: kSemi, color: AppColors.cobalto)),
              ],
            ]),
          ),
          const SizedBox(width: 12),
          // RF-032 #5: estado del anuncio
          Text(a.etiquetaEstado,
              textAlign: TextAlign.end,
              style: ts(13,
                  weight: kSemi,
                  color: a.enVigencia ? AppColors.success : (a.estaActivo ? AppColors.pizarra : AppColors.danger))),
        ]),
      );
}

/// Detalle completo del anuncio (RF-032 #6). Editar e inhabilitar se abren con el
/// contexto de la pantalla (no el del diálogo, que ya se cerró).
void _mostrarDetalle(BuildContext context, Anuncio a) {
  final c = context.read<AnunciosController>();
  showDialog<void>(
    context: context,
    builder: (_) => AnuncioDetalleDialog(
      anuncio: a,
      cargar: () => c.obtenerAnuncio(a.id),
      onEditar: (completo) => _editarAnuncio(context, completo),
      onInhabilitar: () => _inhabilitarAnuncio(context, a),
      onHabilitar: () => _habilitarAnuncio(context, a),
    ),
  );
}
