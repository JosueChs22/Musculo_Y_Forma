import 'package:flutter/material.dart';

import '../../../../core/brand.dart';
import '../../../../core/theme.dart';
import '../../../../core/widgets.dart';

Future<void> showWorkoutDialog(BuildContext context, String title) {
  return showDialog<void>(
    context: context,
    barrierColor: const Color(0x991B1C4D),
    builder: (ctx) => Dialog(
      backgroundColor: AppColors.card,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 448),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const GmyfEmblem(size: 72),
              const SizedBox(height: 20),
              const Eyebrow('Lista para comenzar'),
              const SizedBox(height: 8),
              Text(title.toUpperCase(), textAlign: TextAlign.center, style: display(34)),
              const SizedBox(height: 12),
              Text(
                'Rutina preparada por tu coach según tu evaluación y objetivo. Registra cada serie al completarla.',
                textAlign: TextAlign.center,
                style: ts(15, color: AppColors.pizarra, height: 1.5),
              ),
              const SizedBox(height: 28),
              PrimaryButton(
                label: 'Comenzar entrenamiento',
                expand: true,
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
