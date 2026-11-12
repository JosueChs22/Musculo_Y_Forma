import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'features/admin/controllers/usuarios_controller.dart';
import 'features/admin/services/usuarios_api_service.dart';
import 'features/admin/services/usuarios_service.dart';
import 'features/auth/controllers/auth_controller.dart';
import 'features/auth/services/auth_api_service.dart';
import 'features/auth/services/auth_service.dart';
import 'features/ejercicios/controllers/ejercicios_controller.dart';
import 'features/ejercicios/services/ejercicios_api_service.dart';
import 'features/ejercicios/services/ejercicios_service.dart';
import 'features/perfil/controllers/perfil_controller.dart';
import 'features/perfil/services/perfil_api_service.dart';
import 'features/perfil/services/perfil_service.dart';
import 'features/planes/controllers/planes_controller.dart';
import 'features/planes/services/planes_api_service.dart';
import 'features/planes/services/planes_service.dart';
import 'features/progreso/controllers/progreso_controller.dart';
import 'features/progreso/services/progreso_api_service.dart';
import 'features/progreso/services/progreso_service.dart';
import 'features/rutinas/controllers/rutinas_controller.dart';
import 'features/rutinas/services/rutinas_api_service.dart';
import 'features/rutinas/services/rutinas_service.dart';
import 'features/secretaria/controllers/clases_controller.dart';
import 'features/secretaria/services/clases_api_service.dart';
import 'features/secretaria/services/clases_service.dart';

/// Servicios de la app (REGLA 0). Todos hablan con la API; en pruebas se pueden
/// pasar implementaciones mock por el constructor.
class AppServices {
  const AppServices({PerfilService? perfil, RutinasService? rutinas, ProgresoService? progreso})
      : _perfil = perfil,
        _rutinas = rutinas,
        _progreso = progreso;

  final PerfilService? _perfil;
  final RutinasService? _rutinas;
  final ProgresoService? _progreso;

  PerfilService get perfil => _perfil ?? PerfilApiService();

  RutinasService get rutinas => _rutinas ?? RutinasApiService();

  ProgresoService get progreso => _progreso ?? ProgresoApiService();

  ClasesService get clases => ClasesApiService();

  AuthService get auth => AuthApiService();

  UsuariosService get usuarios => UsuariosApiService();

  EjerciciosService get ejercicios => EjerciciosApiService();

  PlanesService get planes => PlanesApiService();
}

void main() => runApp(const AppRoot());

/// Inyecta un controlador por funcionalidad. Los datos propios del usuario (perfil,
/// rutinas, progreso) se cargan en paralelo (REGLA 10) cada vez que cambia la sesión
/// y se borran al cerrarla; cada vista muestra su skeleton mientras tanto.
class AppRoot extends StatelessWidget {
  const AppRoot({super.key, this.services = const AppServices()});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Sesión del usuario (login). El router la usa para proteger las rutas.
        ChangeNotifierProvider(create: (_) => AuthController(services.auth)..load()),
        // Panel del Administrador: la vista llama a load() al abrirse (necesita token).
        ChangeNotifierProvider(create: (_) => UsuariosController(services.usuarios)),
        // Datos del usuario con sesión: se recargan al cambiar de usuario y se borran al salir
        ChangeNotifierProxyProvider<AuthController, PerfilController>(
          create: (_) => PerfilController(services.perfil),
          update: (_, auth, c) => c!..usarUsuario(auth.usuario?.id),
        ),
        ChangeNotifierProxyProvider<AuthController, RutinasController>(
          create: (_) => RutinasController(services.rutinas),
          update: (_, auth, c) => c!..usarUsuario(auth.usuario?.id),
        ),
        ChangeNotifierProxyProvider<AuthController, ProgresoController>(
          create: (_) => ProgresoController(services.progreso),
          update: (_, auth, c) => c!..usarUsuario(auth.usuario?.id),
        ),
        // Panel del Entrenador: catálogo de ejercicios y planes. Las vistas llaman a load() al abrirse (necesitan el token).
        Provider<EjerciciosService>(create: (_) => services.ejercicios),
        Provider<PlanesService>(create: (_) => services.planes),
        ChangeNotifierProvider(create: (c) => EjerciciosController(c.read<EjerciciosService>())),
        ChangeNotifierProvider(create: (c) => PlanesController(c.read<PlanesService>())),
        // Panel de Secretaria: se carga cuando se abre la vista.
        ChangeNotifierProvider(create: (_) => ClasesController(services.clases)),
      ],
      child: const GmyfApp(),
    );
  }
}
