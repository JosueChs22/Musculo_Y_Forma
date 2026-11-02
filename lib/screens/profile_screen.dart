import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../core/widgets.dart';
import '../state/app_state.dart';

/// Pantalla placeholder: el diseño de Figma no incluye la vista de Perfil todavía.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppState>().profile;
    return PageBody(children: [
      Text('Perfil', style: ts(30, weight: kBlack, spacing: -.6)),
      const SizedBox(height: 24),
      Panel(
        child: Row(children: [
          Avatar(p.name.split(' ').map((e) => e[0]).take(2).join(), size: 64),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.name, style: ts(20, weight: kBlack)),
              const SizedBox(height: 4),
              Text(p.goal, style: ts(14, color: w(.45))),
              const SizedBox(height: 4),
              Text('Coach: ${p.coachName}', style: ts(12, color: w(.35))),
            ]),
          ),
        ]),
      ),
      const SizedBox(height: 16),
      Text('Próximamente: ajustes de cuenta y notificaciones.', style: ts(13, color: w(.35))),
    ]);
  }
}
