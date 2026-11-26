import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme.dart';
import '../../../../core/widgets.dart';

/// Se muestra en lugar de las mediciones cuando el usuario no autorizó sus datos de salud.
class SinConsentimientoSalud extends StatelessWidget {
  const SinConsentimientoSalud({super.key});

  @override
  Widget build(BuildContext context) => Panel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.health_and_safety_outlined,
                color: AppColors.indigo, size: 32),
            const SizedBox(width: 16),
            Expanded(
                child: Text('Tus mediciones están desactivadas',
                    style: ts(16, weight: kSemi))),
          ]),
          const SizedBox(height: 8),
          Text(
            'Tu peso, grasa corporal y demás mediciones son datos de salud. Solo los registramos y '
            'mostramos si nos das tu autorización expresa. Puedes darla (o retirarla) cuando quieras '
            'desde Perfil › Privacidad y datos.',
            style: ts(14, color: AppColors.pizarra, height: 1.45),
          ),
          const SizedBox(height: 14),
          SecondaryButton(
            label: 'Ir a Privacidad y datos',
            icon: Icons.privacy_tip_outlined,
            onPressed: () => context.go('/perfil'),
          ),
        ]),
      );
}
