import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../features/auth/controllers/auth_controller.dart';
import '../features/auth/models/usuario.dart';
import '../features/perfil/controllers/perfil_controller.dart';
import 'brand.dart';
import 'permisos.dart';
import 'skeleton.dart';
import 'theme.dart';
import 'widgets.dart';

const _tabs = <(String, String, IconData, IconData)>[
  ('Inicio', '/', Icons.home_outlined, Icons.home_rounded),
  ('Rutinas', '/rutinas', Icons.fitness_center_outlined, Icons.fitness_center),
  ('Progreso', '/progreso', Icons.bar_chart_outlined, Icons.bar_chart_rounded),
  ('Perfil', '/perfil', Icons.person_outline, Icons.person_rounded),
];

const _altoCabecera = 60.0;
const _altoBarra = 64.0;
const _margenBarra = 12.0;

/// Estructura de navegación adaptativa: barra lateral en pantallas anchas; en
/// móvil, cabecera y barra de pestañas translúcidas con el contenido pasando por
/// debajo. Las pestañas comunes las ve todo usuario con sesión; los paneles de
/// trabajo, solo los roles con permiso (core/permisos.dart) y en móvil se abren
/// desde Perfil. Cada vista maneja su propia carga con skeletons.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final wide = mq.size.width >= 1000;

    if (wide) {
      return Scaffold(
        body: SafeArea(
          bottom: false,
          child: Row(children: [
            _Sidebar(location: location),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1040), child: child),
              ),
            ),
          ]),
        ),
      );
    }

    // Las vistas reciben el alto de las barras como padding (ver SliverPage)
    final barras = EdgeInsets.only(
      top: mq.padding.top + _altoCabecera,
      bottom: mq.padding.bottom + _altoBarra + _margenBarra * 2,
    );
    return Scaffold(
      body: Stack(children: [
        Positioned.fill(
          child: MediaQuery(data: mq.copyWith(padding: barras), child: child),
        ),
        const Positioned(top: 0, left: 0, right: 0, child: _MobileHeader()),
        Positioned(left: 0, right: 0, bottom: 0, child: _TabBar(location: location)),
      ]),
    );
  }
}

/// Superficie translúcida con desenfoque del contenido que tiene detrás.
class _Glass extends StatelessWidget {
  const _Glass({required this.child, this.radius = 0, this.color = AppColors.glass});
  final Widget child;
  final double radius;
  final Color color;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: ColoredBox(color: color, child: child),
          ),
        ),
      );
}

class _MobileHeader extends StatelessWidget {
  const _MobileHeader();

  @override
  Widget build(BuildContext context) {
    final arriba = MediaQuery.paddingOf(context).top;
    return _Glass(
      color: const Color(0xE6F5F6FB),
      child: Container(
        height: arriba + _altoCabecera,
        padding: EdgeInsets.fromLTRB(20, arriba, 20, 0),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.hover))),
        child: const Row(children: [
          Expanded(child: BrandLockup()),
          _StreakChip(),
        ]),
      ),
    );
  }
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
    if (streak == 0) return const SizedBox.shrink(); // aún no se registra la racha
    return Pill('$streak días');
  }
}

/// Barra de pestañas flotante: una píldora translúcida con un indicador que se
/// desliza hasta la pestaña activa.
class _TabBar extends StatelessWidget {
  const _TabBar({required this.location});
  final String location;

  @override
  Widget build(BuildContext context) {
    final abajo = MediaQuery.paddingOf(context).bottom;
    final actual = _tabs.indexWhere((t) => t.$2 == location); // -1 dentro de un panel
    final quieto = MediaQuery.disableAnimationsOf(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, abajo + _margenBarra),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: DecoratedBox(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(_altoBarra / 2), boxShadow: kShadowFloating),
            child: _Glass(
              radius: _altoBarra / 2,
              child: SizedBox(
                height: _altoBarra,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Stack(children: [
                    // Indicador deslizante
                    AnimatedAlign(
                      duration: quieto ? Duration.zero : const Duration(milliseconds: 320),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment(actual < 0 ? 0 : -1 + 2 * actual / (_tabs.length - 1), 0),
                      child: FractionallySizedBox(
                        widthFactor: 1 / _tabs.length,
                        heightFactor: 1,
                        child: AnimatedOpacity(
                          duration: kFast,
                          opacity: actual < 0 ? 0 : 1,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppColors.indigoSoft,
                              borderRadius: BorderRadius.circular(_altoBarra / 2),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Row(children: [
                      for (var i = 0; i < _tabs.length; i++)
                        Expanded(
                          child: _TabItem(
                            label: _tabs[i].$1,
                            icon: i == actual ? _tabs[i].$4 : _tabs[i].$3,
                            selected: i == actual,
                            onTap: () => context.go(_tabs[i].$2),
                          ),
                        ),
                    ]),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({required this.label, required this.icon, required this.selected, required this.onTap});
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.indigo : AppColors.pizarra;
    return Pressable(
      onTap: onTap,
      radius: _altoBarra / 2,
      pressedScale: .9,
      selected: selected,
      semanticLabel: label,
      child: ExcludeSemantics(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(height: 2),
          Text(label, style: ts(11, weight: selected ? kSemi : kRegular, color: color)),
        ]),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.location});
  final String location;

  @override
  Widget build(BuildContext context) {
    // Solo se reconstruye si cambia el rol (login/logout), REGLA 3
    final rol = context.select<AuthController, RolUsuario?>((c) => c.usuario?.rol);
    final suyos = panelesDe(rol);
    final enPanel = panelDe(location) != null;

    return Container(
      width: 264,
      decoration: const BoxDecoration(
        color: Color(0x99FFFFFF),
        border: Border(right: BorderSide(color: AppColors.line)),
      ),
      // Con desplazamiento por si la ventana es baja y el rol tiene varios paneles
      child: CustomScrollView(slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 28, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(padding: EdgeInsets.only(left: 8), child: BrandLockup()),
                const SizedBox(height: 36),
                for (final (label, path, icon, activo) in _tabs)
                  _SideItem(
                    label: label,
                    icon: !enPanel && location == path ? activo : icon,
                    selected: !enPanel && location == path,
                    onTap: () => context.go(path),
                  ),
                if (suyos.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  const Padding(padding: EdgeInsets.only(left: 14, bottom: 8), child: Eyebrow('Paneles')),
                  for (final p in suyos)
                    _SideItem(
                      label: p.titulo,
                      icon: p.icono,
                      selected: p.cubre(location),
                      onTap: () => context.go(p.ruta),
                    ),
                ],
                const Spacer(),
                const SizedBox(height: 24),
                const _StreakPanel(),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}

class _StreakPanel extends StatelessWidget {
  const _StreakPanel();

  @override
  Widget build(BuildContext context) {
    final loading = context.select<PerfilController, bool>((c) => c.loading);
    final streak = context.select<PerfilController, int>((c) => c.profile.streakDays);
    if (!loading && streak == 0) return const SizedBox.shrink(); // aún no se registra la racha
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Pressable(
        onTap: onTap,
        radius: 12,
        pressedScale: .98,
        selected: selected,
        child: AnimatedContainer(
          duration: kMedium,
          curve: kCurve,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: selected ? AppColors.indigo : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            Icon(icon, size: 21, color: fg),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, overflow: TextOverflow.ellipsis, style: ts(15, weight: kSemi, color: fg)),
            ),
          ]),
        ),
      ),
    );
  }
}
