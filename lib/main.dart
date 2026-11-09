import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'features/coach/controllers/coach_controller.dart';
import 'features/coach/services/coach_mock_service.dart';
import 'features/coach/services/coach_service.dart';
import 'features/perfil/controllers/perfil_controller.dart';
import 'features/perfil/services/perfil_mock_service.dart';
import 'features/perfil/services/perfil_service.dart';
import 'features/progreso/controllers/progreso_controller.dart';
import 'features/progreso/services/progreso_mock_service.dart';
import 'features/progreso/services/progreso_service.dart';
import 'features/rutinas/controllers/rutinas_controller.dart';
import 'features/rutinas/services/rutinas_mock_service.dart';
import 'features/rutinas/services/rutinas_service.dart';
import 'features/secretaria/controllers/clases_controller.dart';
import 'features/secretaria/services/clases_mock_service.dart';
import 'features/secretaria/services/clases_service.dart';

/// Servicios de la app. Cuando exista la API, se cambian los Mock por los
/// servicios reales aquí y nada más cambia (REGLA 0).
class AppServices {
  const AppServices({
    this.perfil = const PerfilMockService(),
    this.rutinas = const RutinasMockService(),
    this.progreso = const ProgresoMockService(),
    this.coach = const CoachMockService(),
  });

  final PerfilService perfil;
  final RutinasService rutinas;
  final ProgresoService progreso;
  final CoachService coach;

  // ignore: prefer_const_constructors
  ClasesService get clases => ClasesMockService();
}

void main() => runApp(const AppRoot());

/// Inyecta un controlador por funcionalidad. Todos cargan en paralelo
/// al iniciar (REGLA 10) y cada vista muestra su skeleton mientras tanto.
class AppRoot extends StatelessWidget {
  const AppRoot({super.key, this.services = const AppServices()});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PerfilController(services.perfil)..load()),
        ChangeNotifierProvider(create: (_) => RutinasController(services.rutinas)..load()),
        ChangeNotifierProvider(create: (_) => ProgresoController(services.progreso)..load()),
        // El panel de coach se carga solo cuando se abre (lazy por defecto).
        ChangeNotifierProvider(create: (_) => CoachController(services.coach)..load()),
        // Panel de Secretaria: se carga cuando se abre la vista.
        ChangeNotifierProvider(create: (_) => ClasesController(services.clases)..load()),
      ],
      child: const GmyfApp(),
    );
  }
}
