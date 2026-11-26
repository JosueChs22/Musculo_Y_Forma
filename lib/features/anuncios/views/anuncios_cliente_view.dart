import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/fechas.dart';
import '../../../core/skeleton.dart';
import '../../../core/theme.dart';
import '../../../core/widgets.dart';
import '../../secretaria/models/anuncio.dart';
import '../../secretaria/utils/imagen_anuncio.dart';
import '../controllers/anuncios_cliente_controller.dart';
import '../../../core/app_shell.dart';

/// RF-092: anuncios activos del gimnasio (título, contenido, fecha de publicación e imagen).
class AnunciosClienteView extends StatefulWidget {
  const AnunciosClienteView({super.key});

  @override
  State<AnunciosClienteView> createState() => _AnunciosClienteViewState();
}

class _AnunciosClienteViewState extends State<AnunciosClienteView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AnunciosClienteController>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<AnunciosClienteController>();
    final lista = c.anuncios;

    return SliverPage(slivers: [
      const Box(GimnasioSecciones(actual: '/anuncios')),
      const Box(
        PageTitle(eyebrow: 'Tu gimnasio', title: 'Anuncios', subtitle: 'Novedades y promociones vigentes.'),
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
        Box(Panel(child: Text('No hay anuncios activos por ahora.', style: ts(15, color: AppColors.pizarra))))
      else ...[
        SliverList.builder(
          itemCount: lista.length,
          itemBuilder: (context, i) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _AnuncioCard(lista[i]),
          ),
        ),
        if (c.errorMas != null)
          Box(Text(c.errorMas!, style: ts(14, color: AppColors.danger)), gapAfter: 8),
        if (c.hayMas)
          Box(
            Align(
              alignment: Alignment.center,
              child: SecondaryButton(
                label: c.cargandoMas ? 'Cargando…' : 'Cargar más',
                icon: Icons.expand_more,
                onPressed: c.cargandoMas ? null : () => c.cargarMas(),
              ),
            ),
          ),
      ],
    ]);
  }
}

class _AnuncioCard extends StatelessWidget {
  const _AnuncioCard(this.a);
  final Anuncio a;

  @override
  Widget build(BuildContext context) {
    final imagen = a.imagen;
    return Panel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (a.clasificacion != null) ...[
          Text(a.clasificacion!, style: ts(13, weight: kSemi, color: AppColors.cobalto)),
          const SizedBox(height: 4),
        ],
        Text(a.titulo, style: ts(18, weight: kSemi)),
        const SizedBox(height: 4),
        Text('Publicado ${fechaCorta(a.fechaPublicacion)}', style: ts(13, color: AppColors.pizarra)),
        if (imagen != null && imagen.isNotEmpty) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: ColoredBox(
              color: AppColors.niebla,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: Image.memory(
                  bytesDeDataUrl(imagen),
                  width: double.infinity,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stack) =>
                      Text('No se pudo mostrar la imagen.', style: ts(14, color: AppColors.danger)),
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Text(a.contenido, style: ts(15)),
      ]),
    );
  }
}
