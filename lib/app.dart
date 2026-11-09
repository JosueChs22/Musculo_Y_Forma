import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/app_shell.dart';
import 'core/theme.dart';
import 'features/coach/views/coach_view.dart';
import 'features/inicio/views/inicio_view.dart';
import 'features/perfil/views/perfil_view.dart';
import 'features/progreso/views/progreso_view.dart';
import 'features/rutinas/views/rutinas_view.dart';
import 'features/secretaria/views/secretaria_view.dart';

Page<void> _page(Widget child) => NoTransitionPage<void>(child: child);

GoRouter buildRouter() => GoRouter(
      routes: [
        ShellRoute(
          builder: (context, state, child) => AppShell(location: state.uri.path, child: child),
          routes: [
            GoRoute(path: '/', pageBuilder: (c, s) => _page(const InicioView())),
            GoRoute(path: '/rutinas', pageBuilder: (c, s) => _page(const RutinasView())),
            GoRoute(path: '/progreso', pageBuilder: (c, s) => _page(const ProgresoView())),
            GoRoute(path: '/perfil', pageBuilder: (c, s) => _page(const PerfilView())),
            GoRoute(path: '/coach', pageBuilder: (c, s) => _page(const CoachView())),
            GoRoute(path: '/secretaria', pageBuilder: (c, s) => _page(const SecretariaView())),
          ],
        ),
      ],
    );

class GmyfApp extends StatefulWidget {
  const GmyfApp({super.key});

  @override
  State<GmyfApp> createState() => _GmyfAppState();
}

class _GmyfAppState extends State<GmyfApp> {
  // El router se crea una sola vez (no en cada build, REGLA 3).
  late final GoRouter _router = buildRouter();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Músculo y Forma',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      routerConfig: _router,
    );
  }
}
