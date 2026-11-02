import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../core/widgets.dart';
import '../state/app_state.dart';

const _tabs = <(String, String, IconData)>[
  ('Inicio', '/', Icons.home_outlined),
  ('Rutinas', '/rutinas', Icons.fitness_center),
  ('Progreso', '/progreso', Icons.bar_chart),
  ('Perfil', '/perfil', Icons.person_outline),
];

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final wide = MediaQuery.sizeOf(context).width >= 1000;
    final coach = location.startsWith('/coach');

    Widget body;
    if (s.loading) {
      body = const Center(child: CircularProgressIndicator(color: AppColors.accent));
    } else if (s.error != null) {
      body = Center(child: Text('Error: ${s.error}', style: ts(14, color: w(.6))));
    } else {
      body = child;
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: SizedBox.expand(
              child: wide
                  ? Row(children: [
                      _Sidebar(location: location, coach: coach),
                      Expanded(child: body),
                    ])
                  : body,
            ),
          ),
        ),
      ),
      bottomNavigationBar: (!wide && !coach) ? _BottomBar(location: location) : null,
      floatingActionButton: (!wide && coach)
          ? FloatingActionButton.extended(
              onPressed: () => context.go('/'),
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              label: Text('Vista usuario', style: ts(14, weight: kBlack, color: Colors.black)),
            )
          : null,
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.location, required this.coach});
  final String location;
  final bool coach;

  @override
  Widget build(BuildContext context) {
    final streak = context.watch<AppState>().profile.streakDays;
    return Container(
      width: 240,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(border: Border(right: BorderSide(color: w(.08)))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(color: Color.fromRGBO(255, 90, 54, .25), blurRadius: 30, offset: Offset(0, 8)),
                ],
              ),
              child: const Icon(Icons.fitness_center, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Text('PULSO', style: ts(20, weight: kBlack, spacing: -.4)),
          ]),
          const SizedBox(height: 56),
          for (final (label, path, icon) in _tabs)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _SideItem(
                label: label,
                icon: icon,
                selected: !coach && location == path,
                onTap: () => context.go(path),
              ),
            ),
          const Spacer(),
          Panel(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('RACHA ACTUAL', style: ts(11, weight: kBold, color: w(.35), spacing: 1.8)),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Icon(Icons.local_fire_department_outlined, color: AppColors.accent, size: 28),
                    const SizedBox(width: 8),
                    Text('$streak', style: ts(30, weight: kBlack)),
                    const SizedBox(width: 6),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('días', style: ts(14, color: w(.45))),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => context.go(coach ? '/' : '/coach'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: w(.1)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                coach ? 'Ver como usuario' : 'Ir al panel de coach',
                style: ts(12, weight: kBold, color: w(.5)),
              ),
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
    final fg = selected ? Colors.black : w(.45);
    return Material(
      color: selected ? Colors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(children: [
            Icon(icon, size: 20, color: fg),
            const SizedBox(width: 12),
            Text(label, style: ts(14, weight: kSemi, color: fg)),
          ]),
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
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color.fromRGBO(27, 28, 33, .95),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: w(.1)),
          boxShadow: [BoxShadow(color: blk(.4), blurRadius: 30, offset: const Offset(0, 10))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (final (label, path, icon) in _tabs)
              GestureDetector(
                onTap: () => context.go(path),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 70,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: location == path ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(icon, size: 20, color: location == path ? Colors.black : w(.4)),
                    const SizedBox(height: 4),
                    Text(label, style: ts(10, weight: kSemi, color: location == path ? Colors.black : w(.4))),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
