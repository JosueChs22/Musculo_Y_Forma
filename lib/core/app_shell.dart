import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../features/perfil/controllers/perfil_controller.dart';
import 'brand.dart';
import 'skeleton.dart';
import 'theme.dart';
import 'widgets.dart';

const _tabs = <(String, String, IconData)>[
  ('Inicio', '/', Icons.home_outlined),
  ('Rutinas', '/rutinas', Icons.fitness_center),
  ('Progreso', '/progreso', Icons.bar_chart),
  ('Perfil', '/perfil', Icons.person_outline),
];

/// Estructura de navegación: barra lateral en pantallas anchas y barra
/// inferior en móvil. Cada vista maneja su propia carga con skeletons.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 1000;
    final coach = location.startsWith('/coach');

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1240),
            child: SizedBox.expand(
              child: wide
                  ? Row(children: [
                      _Sidebar(location: location, coach: coach),
                      Expanded(child: child),
                    ])
                  : Column(children: [
                      const _MobileHeader(),
                      Expanded(child: child),
                    ]),
            ),
          ),
        ),
      ),
      bottomNavigationBar: (!wide && !coach) ? _BottomBar(location: location) : null,
      floatingActionButton: (!wide && coach)
          ? FloatingActionButton.extended(
              onPressed: () => context.go('/'),
              backgroundColor: AppColors.ambar,
              foregroundColor: AppColors.ink,
              label: Text('Vista usuario', style: ts(15, weight: kSemi)),
            )
          : null,
    );
  }
}

class _MobileHeader extends StatelessWidget {
  const _MobileHeader();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        decoration: const BoxDecoration(
          color: AppColors.card,
          border: Border(bottom: BorderSide(color: AppColors.line)),
        ),
        child: const Row(children: [
          Expanded(child: BrandLockup()),
          _StreakChip(),
        ]),
      );
}

/// Racha de días: solo se reconstruye cuando cambia la racha (REGLA 3).
class _StreakChip extends StatelessWidget {
  const _StreakChip();

  @override
  Widget build(BuildContext context) {
    final loading = context.select<PerfilController, bool>((c) => c.loading);
    final streak = context.select<PerfilController, int>((c) => c.profile.streakDays);
    if (loading) {
      return const SkeletonScope(child: SkeletonBox(width: 80, height: 30, radius: 99));
    }
    return Pill('$streak días');
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.location, required this.coach});
  final String location;
  final bool coach;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 252,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(right: BorderSide(color: AppColors.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BrandLockup(),
          const SizedBox(height: 44),
          for (final (label, path, icon) in _tabs)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _SideItem(
                label: label,
                icon: icon,
                selected: !coach && location == path,
                onTap: () => context.go(path),
              ),
            ),
          const Spacer(),
          const _StreakPanel(),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: SecondaryButton(
              label: coach ? 'Ver como usuario' : 'Panel de coach',
              onPressed: () => context.go(coach ? '/' : '/coach'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: SecondaryButton(
              label: 'Panel Secretaria',
              icon: Icons.admin_panel_settings_outlined,
              onPressed: () => context.go('/secretaria'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakPanel extends StatelessWidget {
  const _StreakPanel();

  @override
  Widget build(BuildContext context) {
    final loading = context.select<PerfilController, bool>((c) => c.loading);
    final streak = context.select<PerfilController, int>((c) => c.profile.streakDays);
    return Panel(
      color: AppColors.niebla,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Eyebrow('Racha actual'),
          const SizedBox(height: 10),
          if (loading)
            const SkeletonScope(child: SkeletonBox(width: 110, height: 36))
          else
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Icon(Icons.local_fire_department, color: AppColors.ambar, size: 30),
                const SizedBox(width: 6),
                Text('$streak', style: display(40)),
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Text('días', style: ts(15, color: AppColors.pizarra)),
                ),
              ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SideItem extends StatelessWidget {
  const _SideItem({required this.label, required this.icon, required this.selected, required this.onTap});
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : AppColors.pizarra;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? AppColors.indigo : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(children: [
              Icon(icon, size: 22, color: fg),
              const SizedBox(width: 12),
              Text(label, style: ts(16, weight: kSemi, color: fg)),
            ]),
          ),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.location});
  final String location;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
          child: Row(
            children: [
              for (final (label, path, icon) in _tabs)
                Expanded(
                  child: Semantics(
                    selected: location == path,
                    button: true,
                    label: label,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => context.go(path),
                      child: SizedBox(
                        height: 58,
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              color: location == path ? AppColors.indigoSoft : Colors.transparent,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Icon(icon,
                                size: 22, color: location == path ? AppColors.indigo : AppColors.pizarra),
                          ),
                          const SizedBox(height: 4),
                          ExcludeSemantics(
                            child: Text(
                              label,
                              style: ts(12,
                                  weight: location == path ? kSemi : kRegular,
                                  color: location == path ? AppColors.indigo : AppColors.pizarra),
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
