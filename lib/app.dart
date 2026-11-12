import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/theme.dart';
import 'screens/anuncios_screen.dart';
import 'screens/coach_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/progress_screen.dart';
import 'screens/routines_screen.dart';
import 'screens/shell.dart';

Page<void> _page(Widget child) => NoTransitionPage<void>(child: child);

final _router = GoRouter(
  routes: [
    ShellRoute(
      builder: (context, state, child) =>
          AppShell(location: state.uri.path, child: child),
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (c, s) => _page(const HomeScreen()),
        ),
        GoRoute(
          path: '/rutinas',
          pageBuilder: (c, s) => _page(const RoutinesScreen()),
        ),
        GoRoute(
          path: '/progreso',
          pageBuilder: (c, s) => _page(const ProgressScreen()),
        ),
        GoRoute(
          path: '/perfil',
          pageBuilder: (c, s) => _page(const ProfileScreen()),
        ),
        GoRoute(
          path: '/coach',
          pageBuilder: (c, s) => _page(const CoachScreen()),
        ),

        // SPRINT 3 - GESTIÓN DE ANUNCIOS
        GoRoute(
          path: '/anuncios',
          pageBuilder: (c, s) => _page(const AnunciosScreen()),
        ),
      ],
    ),
  ],
);

class PulsoApp extends StatelessWidget {
  const PulsoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'PULSO',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      routerConfig: _router,
    );
  }
}
