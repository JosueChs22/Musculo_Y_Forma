import 'package:flutter/material.dart';

import '../../../../core/theme.dart';
import '../../legal_textos.dart';

/// Nota visible en los textos legales mientras no los apruebe un abogado.
class AvisoBorrador extends StatelessWidget {
  const AvisoBorrador({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
        container: true,
        label: kAvisoBorrador,
        excludeSemantics: true,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.ambarSoft,
            borderRadius: BorderRadius.circular(kRadiusControl),
            border: Border.all(color: AppColors.ambar),
          ),
          child: Row(children: [
            const Icon(Icons.gavel_outlined, size: 18, color: AppColors.indigo),
            const SizedBox(width: 10),
            Expanded(
                child: Text(kAvisoBorrador,
                    style: ts(14, weight: kSemi, color: AppColors.indigo))),
          ]),
        ),
      );
}
