import 'package:flutter/material.dart';

import '../../../../core/imagen_red.dart';
import '../../../../core/theme.dart';
import '../../../../core/widgets.dart';
import '../../models/exercise.dart';

/// RF-085 / RF-087 / RF-089: detalle de un ejercicio de la rutina.
/// Diálogo en pantallas anchas y bottom sheet en el teléfono.
Future<void> showEjercicioDetalle(BuildContext context, Exercise e) {
  final wide = MediaQuery.sizeOf(context).width >= 640;
  if (wide) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.card,
        insetPadding: const EdgeInsets.all(24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 720),
          child: _Detalle(e, onClose: () => Navigator.of(ctx).pop()),
        ),
      ),
    );
  }
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * 0.9),
      child: _Detalle(e, onClose: () => Navigator.of(ctx).pop()),
    ),
  );
}

class _Detalle extends StatelessWidget {
  const _Detalle(this.e, {required this.onClose});
  final Exercise e;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    // WCAG 2.3.3: con "reducir movimiento" se muestra la imagen fija, no el GIF.
    final quieto = MediaQuery.disableAnimationsOf(context);
    final media = quieto ? (e.imageUrl ?? e.gifUrl) : (e.gifUrl ?? e.imageUrl);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          const Expanded(child: Eyebrow('Detalle del ejercicio')),
          IconButton(
            tooltip: 'Cerrar',
            onPressed: onClose,
            icon: const Icon(Icons.close, color: AppColors.pizarra),
          ),
        ]),
        Text(e.name.toUpperCase(), style: display(28)),
        if (e.grupoMuscular != null || e.herramienta != null) ...[
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            if (e.grupoMuscular != null) Pill(e.grupoMuscular!, tone: PillTone.cobalto),
            if (e.herramienta != null) Pill(e.herramienta!),
          ]),
        ],
        if (media != null) ...[
          const SizedBox(height: 16),
          Center(
            child: Semantics(
              image: true,
              label: 'Demostración del ejercicio ${e.name}',
              child: ImagenRed(media, size: 260, radius: 16),
            ),
          ),
        ],
        const SizedBox(height: 16),
        Wrap(spacing: 8, runSpacing: 8, children: [
          InfoChip(e.setsLabel),
          InfoChip(e.reps),
          InfoChip(e.restLabel),
          if (e.pesoLabel != null) InfoChip(e.pesoLabel!),
        ]),
        if (e.coachNote.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Nota del coach', style: ts(15, weight: kSemi)),
          const SizedBox(height: 4),
          Text(e.coachNote, style: ts(14, color: AppColors.pizarra)),
        ],
        if (e.instrucciones != null) ...[
          const SizedBox(height: 16),
          Text('Instrucciones', style: ts(15, weight: kSemi)),
          const SizedBox(height: 4),
          Text(e.instrucciones!, style: ts(14, color: AppColors.pizarra).copyWith(height: 1.5)),
        ],
      ]),
    );
  }
}
