import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/app_shell.dart';
import 'core/brand.dart';
import 'core/permisos.dart';
import 'core/theme.dart';
import 'features/admin/views/usuarios_view.dart';
import 'features/auth/controllers/auth_controller.dart';
import 'features/auth/views/login_view.dart';
import 'features/auth/views/recuperar_view.dart';
import 'features/ejercicios/views/ejercicios_view.dart';
import 'features/inicio/views/inicio_view.dart';
import 'features/perfil/views/perfil_view.dart';
import 'features/planes/views/plan_editor_view.dart';
import 'features/planes/views/planes_view.dart';
import 'features/progreso/views/progreso_view.dart';
import 'features/rutinas/views/rutinas_view.dart';
import 'features/secretaria/views/secretaria_view.dart';

/// Cambio de pantalla: la nueva aparece con un fundido y sube unos píxeles; la
/// anterior se va más rápido. Sin movimiento si el sistema pide reducirlo.
Page<void> _page(GoRouterState s, Widget child) => CustomTransitionPage<void>(
      key: s.pageKey,
      child: child,
      transitionDuration: kMedium,
      reverseTransitionDuration: kFast,
      transitionsBuilder: (context, animation, saliendo, child) {
        if (MediaQuery.disableAnimationsOf(context)) return child;
        final curva = CurvedAnimation(parent: animation, curve: kCurve);
        return FadeTransition(
          // La pantalla anterior se desvanece primero y la nueva entra después: nunca se ven encimadas
          opacity: Tween(begin: 1.0, end: 0.0)
              .animate(CurvedAnimation(parent: saliendo, curve: const Interval(0, .35))),
          child: FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: const Interval(.35, 1, curve: kCurve)),
          child: SlideTransition(
            position: Tween(begin: const Offset(0, .015), end: Offset.zero).animate(curva),
            child: child,
          ),
          ),
        );
      },
    );

/// Desplazamiento con rebote en todas las plataformas, como en iOS.
class _Desplazamiento extends MaterialScrollBehavior {
  const _Desplazamiento();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
}

/// [inicial]: ruta con la que se abrió la app (por ejemplo al recargar en el navegador).
GoRouter buildRouter(AuthController auth, {String inicial = '/'}) => GoRouter(
      initialLocation: inicial,
      // La ruta inicial se toma al arrancar: la pantalla de "abriendo sesión" ya cambió la URL
      overridePlatformDefaultLocation: true,
      // Cada vez que cambia la sesión (login/logout) se vuelve a evaluar redirect.
      refreshListenable: auth,
      redirect: (context, state) {
        final ruta = state.matchedLocation;
        // Sin sesión solo se puede estar en el login o recuperando la contraseña
        final publica = ruta == '/login' || ruta == '/recuperar';
        if (!auth.autenticado) return publica ? null : '/login';
        if (publica) return '/';
        // Paneles por rol (core/permisos.dart); un rol sin permiso vuelve al inicio
        return puedeEntrar(auth.usuario!.rol, ruta) ? null : '/';
      },
      routes: [
        GoRoute(path: '/login', pageBuilder: (c, s) => _page(s, const LoginView())),
        GoRoute(path: '/recuperar', pageBuilder: (c, s) => _page(s, const RecuperarView())),
        ShellRoute(
          builder: (context, state, child) => AppShell(location: state.uri.path, child: child),
          routes: [
            GoRoute(path: '/', pageBuilder: (c, s) => _page(s, const InicioView())),
            GoRoute(path: '/rutinas', pageBuilder: (c, s) => _page(s, const RutinasView())),
            GoRoute(path: '/progreso', pageBuilder: (c, s) => _page(s, const ProgresoView())),
            GoRoute(path: '/perfil', pageBuilder: (c, s) => _page(s, const PerfilView())),
            GoRoute(path: '/coach', pageBuilder: (c, s) => _page(s, const PlanesView())),
            GoRoute(path: '/coach/ejercicios', pageBuilder: (c, s) => _page(s, const EjerciciosView())),
            GoRoute(path: '/coach/plan/nuevo', pageBuilder: (c, s) => _page(s, const PlanEditorView())),
            GoRoute(
              path: '/coach/plan/:id',
              pageBuilder: (c, s) => _page(s, PlanEditorView(key: ValueKey(s.pathParameters['id']), id: s.pathParameters['id'])),
            ),
            GoRoute(path: '/secretaria', pageBuilder: (c, s) => _page(s, const SecretariaView())),
            GoRoute(path: '/admin', pageBuilder: (c, s) => _page(s, const UsuariosView())),
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
  // El router se crea una sola vez (no en cada build, REGLA 3), y solo después de
  // restaurar la sesión: así toma la URL actual y una recarga no pasa por el login.
  GoRouter? _router;

  // Ruta con la que se abrió la app (URL del navegador o enlace profundo en móvil),
  // leída antes de que la pantalla de carga la cambie.
  final String _rutaInicial = WidgetsBinding.instance.platformDispatcher.defaultRouteName;

  @override
  void dispose() {
    _router?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final restaurando = context.select<AuthController, bool>((c) => c.loading);
    if (restaurando) {
      return MaterialApp(
        title: 'Músculo y Forma',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        // La ruta real la toma el router después; aquí solo se muestra la carga
        initialRoute: '/',
        home: const _Restaurando(),
      );
    }
    final router = _router ??= buildRouter(context.read<AuthController>(), inicial: _rutaInicial);
    return MaterialApp.router(
      title: 'Músculo y Forma',
      scrollBehavior: const _Desplazamiento(),
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      routerConfig: router,
    );
  }
}

/// Mientras se comprueba la sesión guardada (REGLA 1: sin spinner a pantalla completa).
class _Restaurando extends StatelessWidget {
  const _Restaurando();

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const BrandLockup(),
            const SizedBox(height: 16),
            Text('Abriendo tu sesión…', style: ts(15, color: AppColors.pizarra)),
          ]),
        ),
      );
}
