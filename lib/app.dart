import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/app_shell.dart';
import 'core/theme.dart';
import 'features/admin/views/usuarios_view.dart';
import 'features/auth/controllers/auth_controller.dart';
import 'features/auth/models/usuario.dart';
import 'features/auth/views/login_view.dart';
import 'features/auth/views/recuperar_view.dart';
import 'features/coach/views/coach_view.dart';
import 'features/inicio/views/inicio_view.dart';
import 'features/perfil/views/perfil_view.dart';
import 'features/progreso/views/progreso_view.dart';
import 'features/rutinas/views/rutinas_view.dart';
import 'features/secretaria/views/secretaria_view.dart';

Page<void> _page(Widget child) => NoTransitionPage<void>(child: child);

/// Rutas restringidas por rol. Es protección de pantalla (UX); la seguridad
/// real la hace la API validando el token en cada petición.
const _rolesPorRuta = <String, Set<RolUsuario>>{
  '/secretaria': {RolUsuario.secretaria, RolUsuario.administrador},
  '/coach': {RolUsuario.entrenador, RolUsuario.administrador},
  '/admin': {RolUsuario.administrador},
};

GoRouter buildRouter(AuthController auth) => GoRouter(
      // Cada vez que cambia la sesión (login/logout) se vuelve a evaluar redirect.
      refreshListenable: auth,
      redirect: (context, state) {
        final ruta = state.matchedLocation;
        // Sin sesión solo se puede estar en el login o recuperando la contraseña
        final publica = ruta == '/login' || ruta == '/recuperar';
        if (!auth.autenticado) return publica ? null : '/login';
        if (publica) return '/';
        final permitidos = _rolesPorRuta[ruta];
        if (permitidos != null && !permitidos.contains(auth.usuario!.rol)) return '/';
        return null;
      },
      routes: [
        GoRoute(path: '/login', pageBuilder: (c, s) => _page(const LoginView())),
        GoRoute(path: '/recuperar', pageBuilder: (c, s) => _page(const RecuperarView())),
        ShellRoute(
          builder: (context, state, child) => AppShell(location: state.uri.path, child: child),
          routes: [
            GoRoute(path: '/', pageBuilder: (c, s) => _page(const InicioView())),
            GoRoute(path: '/rutinas', pageBuilder: (c, s) => _page(const RutinasView())),
            GoRoute(path: '/progreso', pageBuilder: (c, s) => _page(const ProgresoView())),
            GoRoute(path: '/perfil', pageBuilder: (c, s) => _page(const PerfilView())),
            GoRoute(path: '/coach', pageBuilder: (c, s) => _page(const CoachView())),
            GoRoute(path: '/secretaria', pageBuilder: (c, s) => _page(const SecretariaView())),
            GoRoute(path: '/admin', pageBuilder: (c, s) => _page(const UsuariosView())),
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
  late final GoRouter _router = buildRouter(context.read<AuthController>());

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
