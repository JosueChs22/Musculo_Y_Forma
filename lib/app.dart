import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/theme.dart';

// Rutas de la app. Por ahora solo hay una pantalla vacía de arranque;
// el login (RF-033) y el panel de administrador se agregan aquí.
final _router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const _InicioVacio()),
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

/// Pantalla temporal mientras se construye el login.
class _InicioVacio extends StatelessWidget {
  const _InicioVacio();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('PULSO', style: ts(30, weight: kBlack, spacing: -.6)),
      ),
    );
  }
}
