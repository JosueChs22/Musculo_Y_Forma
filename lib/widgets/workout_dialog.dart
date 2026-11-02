import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../core/widgets.dart';

Future<void> showWorkoutDialog(BuildContext context, String title) {
  return showDialog<void>(
    context: context,
    barrierColor: blk(.7),
    builder: (ctx) => Dialog(
      backgroundColor: AppColors.sheet,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(32),
        side: BorderSide(color: w(.1)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 448),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.fitness_center, size: 32, color: Colors.white),
              ),
              const SizedBox(height: 24),
              const Eyebrow('Lista para comenzar'),
              const SizedBox(height: 8),
              Text(title, textAlign: TextAlign.center, style: ts(24, weight: kBlack)),
              const SizedBox(height: 12),
              Text(
                'Rutina preparada por tu coach según tu evaluación y objetivo. Registra cada serie al completarla.',
                textAlign: TextAlign.center,
                style: ts(14, color: w(.45), height: 1.6),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: WhiteButton(
                  label: 'Comenzar entrenamiento',
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
