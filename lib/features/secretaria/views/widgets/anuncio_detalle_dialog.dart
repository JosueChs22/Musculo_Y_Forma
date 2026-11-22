import 'package:flutter/material.dart';

import '../../../../core/fechas.dart';
import '../../../../core/skeleton.dart';
import '../../../../core/theme.dart';
import '../../../../core/widgets.dart';
import '../../models/anuncio.dart';
import '../../utils/imagen_anuncio.dart';

/// Detalle completo de un anuncio (RF-032 #6), con las acciones de editar (RF-022) e
/// inhabilitar (RF-027). Si el anuncio tiene imagen, se pide aquí: la lista no la trae.
/// Las acciones cierran este diálogo y llaman a [onEditar] / [onInhabilitar] / [onHabilitar],
/// que abren la pantalla de origen.
class AnuncioDetalleDialog extends StatefulWidget {
  const AnuncioDetalleDialog({
    super.key,
    required this.anuncio,
    required this.cargar,
    required this.onEditar,
    required this.onInhabilitar,
    required this.onHabilitar,
  });

  final Anuncio anuncio;

  /// Trae el anuncio completo, con su imagen.
  final Future<Anuncio> Function() cargar;
  final void Function(Anuncio anuncio) onEditar;
  final VoidCallback onInhabilitar;
  final VoidCallback onHabilitar;

  @override
  State<AnuncioDetalleDialog> createState() => _AnuncioDetalleDialogState();
}

class _AnuncioDetalleDialogState extends State<AnuncioDetalleDialog> {
  Anuncio? _completo;
  late bool _cargando = widget.anuncio.tieneImagen;
  bool _falloImagen = false;

  @override
  void initState() {
    super.initState();
    if (_cargando) _cargarImagen();
  }

  Future<void> _cargarImagen() async {
    try {
      final a = await widget.cargar();
      if (!mounted) return;
      setState(() {
        _completo = a;
        _cargando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _falloImagen = true;
      });
    }
  }

  Widget _imagen() {
    if (_cargando) {
      // Recuadro del tamaño final mientras llega la imagen (REGLAS 1 y 6)
      return const SkeletonScope(child: SkeletonBox(height: 200, radius: 12));
    }
    final dataUrl = _completo?.imagen;
    if (dataUrl == null) {
      return _falloImagen
          ? Text('No se pudo cargar la imagen.', style: ts(14, color: AppColors.danger))
          : const SizedBox.shrink();
    }
    // Se ve completa, sin recortar: se ajusta dentro del recuadro (como mucho 320 px de alto)
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: ColoredBox(
        color: AppColors.niebla,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 320),
          child: Image.memory(
            bytesDeDataUrl(dataUrl),
            width: double.infinity,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stack) =>
                Text('No se pudo mostrar la imagen.', style: ts(14, color: AppColors.danger)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.anuncio;
    final tieneImagen = a.tieneImagen;
    return AlertDialog(
      backgroundColor: AppColors.card,
      title: Text(a.titulo.toUpperCase(), style: display(26)),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (tieneImagen) ...[
              _imagen(),
              const SizedBox(height: 16),
            ],
            const Eyebrow('Estado'),
            const SizedBox(height: 2),
            Text(a.etiquetaEstado,
                style: ts(16, weight: kSemi, color: a.enVigencia ? AppColors.success : (a.estaActivo ? AppColors.pizarra : AppColors.danger))),
            if (a.clasificacion != null) ...[
              const SizedBox(height: 12),
              const Eyebrow('Clasificación'),
              const SizedBox(height: 2),
              Text(a.clasificacion!, style: ts(16)),
            ],
            const SizedBox(height: 12),
            const Eyebrow('Contenido'),
            const SizedBox(height: 2),
            SelectableText(a.contenido, style: ts(16)),
            const SizedBox(height: 12),
            const Eyebrow('Fecha de publicación'),
            const SizedBox(height: 2),
            Text(fechaCorta(a.fechaPublicacion), style: ts(16)),
            const SizedBox(height: 12),
            const Eyebrow('Vigencia'),
            const SizedBox(height: 2),
            Text(a.fechaFin == null ? 'Sin fecha de fin' : 'Hasta el ${fechaCorta(a.fechaFin!)}', style: ts(16)),
            if (a.fechaCreacion != null) ...[
              const SizedBox(height: 12),
              const Eyebrow('Creado'),
              const SizedBox(height: 2),
              Text(fechaCorta(a.fechaCreacion!), style: ts(16)),
            ],
            if (a.fechaActualizacion != null) ...[
              const SizedBox(height: 12),
              const Eyebrow('Última actualización'),
              const SizedBox(height: 2),
              Text(fechaCorta(a.fechaActualizacion!), style: ts(16)),
            ],
          ]),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cerrar', style: ts(15, weight: kSemi, color: AppColors.cobalto)),
        ),
        if (a.estaActivo)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onInhabilitar();
            },
            child: Text('Inhabilitar', style: ts(15, weight: kSemi, color: AppColors.danger)),
          )
        else
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onHabilitar();
            },
            child: Text('Habilitar', style: ts(15, weight: kSemi, color: AppColors.success)),
          ),
        PrimaryButton(
          label: 'Editar',
          icon: Icons.edit_outlined,
          // Con la imagen ya cargada el formulario la muestra; si falló, se edita igual y la imagen se conserva
          onPressed: () {
            Navigator.of(context).pop();
            widget.onEditar(_completo ?? a);
          },
        ),
      ],
    );
  }
}
