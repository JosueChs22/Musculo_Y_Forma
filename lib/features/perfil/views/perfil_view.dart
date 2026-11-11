import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/skeleton.dart';
import '../../../core/theme.dart';
import '../../../core/widgets.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/perfil_controller.dart';
import '../models/user_profile.dart';

/// Perfil: placeholder hasta tener el diseño completo de la pantalla.
class PerfilView extends StatelessWidget {
  const PerfilView({super.key});

  @override
  Widget build(BuildContext context) {
    final loading = context.select<PerfilController, bool>((c) => c.loading);
    final error = context.select<PerfilController, String?>((c) => c.error);
    final p = context.select<PerfilController, UserProfile>((c) => c.profile);

    return SliverPage(slivers: [
      const Box(PageTitle(eyebrow: 'Tu cuenta', title: 'Perfil'), gapAfter: 24),
      if (error != null)
        Box(ErrorPanel(message: error, onRetry: () => context.read<PerfilController>().load()))
      else if (loading)
        const Box(SkeletonScope(child: SkeletonBox(height: 112, radius: 18)))
      else
        Box(
          Panel(
            child: Row(children: [
              Avatar(p.initials, size: 64),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p.name.toUpperCase(), style: display(30)),
                  Text(p.goal, style: ts(15, color: AppColors.pizarra)),
                  const SizedBox(height: 4),
                  Text('Coach: ${p.coachName}', style: ts(14, weight: kSemi, color: AppColors.indigo)),
                ]),
              ),
            ]),
          ),
          gapAfter: 16,
        ),
      // Cerrar sesión: al limpiar la sesión, el router redirige solo a /login.
      Box(
        OutlinedButton.icon(
          onPressed: () => context.read<AuthController>().cerrarSesion(),
          icon: const Icon(Icons.logout),
          label: Text('Cerrar sesión', style: ts(15, weight: kSemi)),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.indigo,
            minimumSize: const Size.fromHeight(48),
            side: const BorderSide(color: AppColors.line),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        gapAfter: 16,
      ),
      Box(Text('Próximamente: ajustes de cuenta y notificaciones.', style: ts(14, color: AppColors.pizarra))),
    ]);
  }
}
