// Barrido de layout: abre cada ruta con cada rol en varios tamaños de pantalla y
// falla si algún widget se desborda (RenderFlex overflowed, etc.). Los servicios
// son falsos en memoria para que las pantallas muestren datos reales, no errores.
//
// Capturas de los paneles (coach, secretaria, admin):
//   CAPTURAS=1 flutter test test/layout_test.dart --update-goldens --plain-name capturas
// Se escriben en ../build/capturas/paneles/ (fuera de test/, no se versionan).
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pulso_app/core/permisos.dart';
import 'package:pulso_app/features/admin/models/reglamento.dart';
import 'package:pulso_app/features/admin/services/reglamentos_service.dart';
import 'package:pulso_app/features/admin/services/usuarios_service.dart';
import 'package:pulso_app/features/auth/models/usuario.dart';
import 'package:pulso_app/features/auth/services/auth_service.dart';
import 'package:pulso_app/features/ejercicios/models/ejercicio.dart';
import 'package:pulso_app/features/ejercicios/services/ejercicios_service.dart';
import 'package:pulso_app/features/horarios/services/horarios_service.dart';
import 'package:pulso_app/features/mediciones/models/datos_medicion.dart';
import 'package:pulso_app/features/mediciones/models/medicion_cliente.dart';
import 'package:pulso_app/features/mediciones/services/mediciones_service.dart';
import 'package:pulso_app/features/perfil/services/perfil_mock_service.dart';
import 'package:pulso_app/features/planes/models/plan.dart';
import 'package:pulso_app/features/planes/services/planes_service.dart';
import 'package:pulso_app/features/progreso/services/progreso_mock_service.dart';
import 'package:pulso_app/features/rutinas/services/rutinas_mock_service.dart';
import 'package:pulso_app/features/secretaria/models/anuncio.dart';
import 'package:pulso_app/features/secretaria/models/cita.dart';
import 'package:pulso_app/features/secretaria/models/clase.dart';
import 'package:pulso_app/features/secretaria/models/cliente.dart' as sec;
import 'package:pulso_app/features/secretaria/services/anuncios_service.dart';
import 'package:pulso_app/features/secretaria/services/citas_service.dart';
import 'package:pulso_app/features/secretaria/services/clases_mock_service.dart';
import 'package:pulso_app/features/secretaria/services/clases_service.dart';
import 'package:pulso_app/features/secretaria/services/clientes_service.dart';
import 'package:pulso_app/main.dart';

// ---------------------------------------------------------------------------
// Datos falsos
// ---------------------------------------------------------------------------

final _hoy = DateTime.now();

Usuario _usuario(String id, RolUsuario rol, String nombre, String apellido, {EstadoUsuario estado = EstadoUsuario.activo}) =>
    Usuario(
      id: id,
      rol: rol,
      nombre: nombre,
      primerApellido: apellido,
      segundoApellido: 'Solano',
      correo: '${nombre.toLowerCase()}.${apellido.toLowerCase()}@musculoyforma.com',
      telefono: '88887777',
      usuario: '${nombre.toLowerCase()}.${apellido.toLowerCase()}',
      estado: estado,
      fechaIngreso: DateTime(2025, 3, 14),
      ultimoLogin: DateTime(2026, 11, 20, 8, 30),
    );

const _nombres = [
  ('María Fernanda', 'Rodríguez'),
  ('Juan Carlos', 'Pérez'),
  ('Ana', 'Jiménez'),
  ('Luis Diego', 'Vargas'),
  ('Sofía', 'Castro'),
  ('Andrés', 'Mora'),
  ('Valeria', 'Quesada'),
  ('José Pablo', 'Hernández'),
];

class _Sesion implements AuthService {
  _Sesion(this.rol);
  final RolUsuario? rol;
  @override
  Future<Usuario?> restaurarSesion() async => rol == null ? null : _usuario('u0', rol!, 'Alex', 'Rivera');
  @override
  Future<Usuario> iniciarSesion({required String usuario, required String contrasena}) => throw UnimplementedError();
  @override
  Future<void> cambiarContrasena({required String actual, required String nueva}) async {}
  @override
  Future<void> solicitarRecuperacion(String correo) async {}
  @override
  Future<void> restablecerContrasena({required String correo, required String codigo, required String nueva}) async {}
  @override
  Future<void> cerrarSesion() async {}
}

const _grupos = ['Pecho', 'Espalda', 'Piernas', 'Hombros', 'Brazos', 'Core'];

Ejercicio _ejercicio(int i) => Ejercicio(
      id: 'e$i',
      nombre: ['Press de banca inclinado con mancuernas', 'Sentadilla', 'Remo con barra', 'Plancha abdominal', 'Curl de bíceps', 'Peso muerto rumano'][i % 6],
      grupoMuscular: _grupos[i % _grupos.length],
      herramienta: i.isEven ? 'Mancuernas' : 'Barra olímpica',
      tiempoRecomendado: 45,
      instrucciones: 'Mantén la espalda recta, baja de forma controlada y sube con fuerza sin bloquear las articulaciones.',
      observaciones: 'Evitar si hay molestias en el hombro.',
      recomendaciones: 'Calentar antes con series ligeras.',
      activo: i != 3,
    );

class _Ejercicios implements EjerciciosService {
  @override
  Future<PaginaEjercicios> listar({String? texto, String? grupo, bool soloActivos = true, String? cursor}) async =>
      PaginaEjercicios([for (var i = 0; i < 12; i++) _ejercicio(i)], null);
  @override
  Future<Ejercicio> crear(DatosEjercicio datos) async => _ejercicio(0);
  @override
  Future<Ejercicio> actualizar(String id, DatosEjercicio datos) async => _ejercicio(0);
  @override
  Future<Ejercicio> inhabilitar(String id) async => _ejercicio(3);
  @override
  Future<Ejercicio> reactivar(String id) async => _ejercicio(0);
}

final _clientesPlan = [
  for (var i = 0; i < _nombres.length; i++)
    UsuarioResumen(id: 'c$i', nombre: '${_nombres[i].$1} ${_nombres[i].$2}', usuario: _nombres[i].$1.toLowerCase().replaceAll(' ', '.')),
];

Plan _plan(int i) => Plan(
      id: 'p$i',
      nombre: ['Fuerza tren superior — semana 1', 'Cardio HIIT', 'Movilidad', 'Hipertrofia piernas y glúteos'][i % 4],
      categoria: CategoriaPlan.values[i % CategoriaPlan.values.length],
      observaciones: 'Trabajar con técnica antes que con peso.',
      diaSemana: i % 7 + 1,
      activo: i != 5,
      usuario: i.isEven ? _clientesPlan[i % _clientesPlan.length] : null,
      totalEjercicios: 4 + i,
      ejercicios: [
        for (var j = 0; j < 4; j++)
          PlanEjercicio(idEjercicio: 'e$j', nombre: _ejercicio(j).nombre, grupoMuscular: _ejercicio(j).grupoMuscular, pesoSugerido: 20, nota: 'Controlar la bajada'),
      ],
    );

class _Planes implements PlanesService {
  @override
  Future<PaginaPlanes> listar({CategoriaPlan? categoria, String? texto, bool soloActivos = true, bool? asignado, String? cursor}) async =>
      PaginaPlanes([for (var i = 0; i < 9; i++) _plan(i)], null);
  @override
  Future<Plan> obtener(String id) async => _plan(0);
  @override
  Future<Plan> crear(DatosPlan datos, {String? idUsuario}) async => _plan(0);
  @override
  Future<Plan> actualizar(String id, DatosPlan datos) async => _plan(0);
  @override
  Future<UsuarioResumen?> asignar(String id, String? idUsuario) async => _clientesPlan.first;
  @override
  Future<void> inhabilitar(String id) async {}
  @override
  Future<void> reactivar(String id) async {}
  @override
  Future<PaginaClientes> buscarClientes({String? texto, String? cursor}) async => PaginaClientes(_clientesPlan, null);
}

sec.Cliente _cliente(int i) => sec.Cliente(
      id: 'c$i',
      nombre: _nombres[i % _nombres.length].$1,
      primerApellido: _nombres[i % _nombres.length].$2,
      segundoApellido: 'Solano',
      correo: 'cliente$i@correo.com',
      cedula: '1-0${i}23-0456',
      telefono: '8888777$i',
      carne: 'GMYF-00$i',
      estado: i == 2 ? sec.EstadoCliente.values.last : sec.EstadoCliente.values.first,
      fechaIngreso: DateTime(2026, 1, 1 + i),
    );

class _Clientes implements ClientesService {
  @override
  Future<sec.PaginaClientes> listarClientes({String? estado, String? busqueda, String? cursor}) async =>
      sec.PaginaClientes([for (var i = 0; i < 10; i++) _cliente(i)], null);
  @override
  Future<sec.Cliente> crearCliente(
          {required String nombre,
          required String primerApellido,
          required String segundoApellido,
          required String correo,
          required String cedula,
          required String telefono,
          required String carne,
          required DateTime fechaIngreso}) async =>
      _cliente(0);
  @override
  Future<sec.Cliente> actualizarCliente(String id,
          {required String nombre,
          required String primerApellido,
          required String segundoApellido,
          required String correo,
          required String cedula,
          required String telefono,
          required String carne,
          required DateTime fechaIngreso}) async =>
      _cliente(0);
  @override
  Future<sec.Cliente> cambiarEstadoCliente(String id, sec.EstadoCliente estado) async => _cliente(0);
}

CitaConsulta _cita(int i) => CitaConsulta(
      id: 'ci$i',
      idCliente: 'c$i',
      clienteNombreCompleto: '${_nombres[i % _nombres.length].$1} ${_nombres[i % _nombres.length].$2} Solano',
      carne: 'GMYF-00$i',
      idCoach: 'u0',
      entrenadorNombreCompleto: 'Alex Rivera Solano',
      fechaHora: DateTime(_hoy.year, _hoy.month, _hoy.day, 7 + i),
      estado: ['Agendada', 'Completada', 'Cancelada'][i % 3],
    );

class _Citas implements CitasService {
  @override
  Future<ClienteCita> buscarClientePorCarne(String carne) async => const ClienteCita(
      id: 'c0', nombreCompleto: 'María Fernanda Rodríguez Solano', carne: 'GMYF-000', cedula: '1-0123-0456', correo: 'maria@correo.com', estado: 'Activo');
  @override
  Future<List<EntrenadorCita>> listarEntrenadoresActivos() async =>
      const [EntrenadorCita(id: 'u0', nombreCompleto: 'Alex Rivera Solano'), EntrenadorCita(id: 'u9', nombreCompleto: 'Carlos Méndez')];
  @override
  Future<List<CitaConsulta>> listarCitasPorFecha({required String inicio, required String fin}) async => [for (var i = 0; i < 6; i++) _cita(i)];
  @override
  Future<List<CitaConsulta>> listarCitasEntrenadorPorFecha({required String inicio, required String fin}) async =>
      [for (var i = 0; i < 6; i++) _cita(i)];
  @override
  Future<List<CitaConsulta>> buscarUltimasCitasEntrenador(String termino) async => [for (var i = 0; i < 3; i++) _cita(i)];
  @override
  Future<List<DateTime>> listarCitasAgendadasClienteEnRango(
          {required String idCliente, required String inicio, required String fin, String? excluirCitaId}) async =>
      const [];
  @override
  Future<CitaAgendada> crearCita({required String idCliente, required String idCoach, required String fechaHora}) async =>
      CitaAgendada(id: 'n', idCliente: idCliente, idCoach: idCoach, fechaHora: _hoy, estado: 'Agendada');
  @override
  Future<CitaAgendada> actualizarCita({required String idCita, required String idCoach, required String fechaHora}) async =>
      CitaAgendada(id: idCita, idCliente: 'c0', idCoach: idCoach, fechaHora: _hoy, estado: 'Agendada');
  @override
  Future<CitaAgendada> cambiarEstadoCita({required String idCita, required String estado}) async =>
      CitaAgendada(id: idCita, idCliente: 'c0', idCoach: 'u0', fechaHora: _hoy, estado: estado);
}

MedicionCliente _medicion(int i) => MedicionCliente(
      id: 'm$i',
      fecha: DateTime(2026, 1 + i, 10),
      estado: 'Activo',
      pesoCorporal: 82 - i * 1.5,
      estatura: 175,
      objetivo: 'Bajar grasa y ganar fuerza',
      grasaCorporal: 24 - i.toDouble(),
      grasaVisceral: 9,
      masaMuscular: 34 + i * .5,
      imc: 26.1,
      edad: 31,
      medidas: {
        'cintura': 90 - i,
        'brazo': {'izq': 31 + i * .3, 'der': 31.5 + i * .3},
      },
      nivelActividadFisica: 'Moderado',
      frecuenciaSemanal: 4,
      observaciones: 'Buena evolución.',
    );

class _Mediciones implements MedicionesService {
  @override
  Future<void> crearMedicion(DatosMedicion medicion) async {}
  @override
  Future<PaginaMediciones> listarHistorial(String idUsuario, {required String estado, String? cursor}) async =>
      PaginaMediciones([for (var i = 0; i < 6; i++) _medicion(i)], null);
  @override
  Future<MedicionCliente> actualizarMedicion(String id, DatosMedicion medicion) async => _medicion(0);
  @override
  Future<void> cambiarEstadoMedicion(String id, String estado) async {}
}

class _Horarios implements HorariosService {
  final _clases = ClasesMockService(latency: Duration.zero);
  @override
  Future<List<Clase>> getClases() => _clases.getClases();
}

Anuncio _anuncio(int i) => Anuncio(
      id: 'a$i',
      titulo: ['Nuevo horario de fin de año para todas las sedes', 'Promoción de diciembre', 'Mantenimiento de máquinas'][i % 3],
      contenido: 'El gimnasio tendrá horario especial durante las festividades. Revisa los detalles en recepción y en nuestras redes.',
      clasificacion: ['Aviso', 'Promoción', 'Evento'][i % 3],
      estado: i == 4 ? EstadoAnuncio.values.last : EstadoAnuncio.values.first,
      fechaPublicacion: DateTime(2026, 11, 1 + i),
      fechaFin: DateTime(2026, 12, 31),
      fechaCreacion: DateTime(2026, 10, 30),
    );

class _Anuncios implements AnunciosService {
  @override
  Future<PaginaAnuncios> getAnuncios({String? cursor}) async => PaginaAnuncios([for (var i = 0; i < 6; i++) _anuncio(i)], null);
  @override
  Future<PaginaAnuncios> getAnunciosVigentes({String? cursor}) async => PaginaAnuncios([for (var i = 0; i < 4; i++) _anuncio(i)], null);
  @override
  Future<Anuncio> getAnuncio(String id) async => _anuncio(0);
  @override
  Future<Anuncio> crearAnuncio(
          {required String titulo,
          required String contenido,
          required String clasificacion,
          required DateTime fechaPublicacion,
          DateTime? fechaFin,
          String? imagen}) async =>
      _anuncio(0);
  @override
  Future<Anuncio> actualizarAnuncio(
          {required String id,
          required String titulo,
          required String contenido,
          required String clasificacion,
          required DateTime fechaPublicacion,
          DateTime? fechaFin,
          String? imagen,
          bool cambiarImagen = false}) async =>
      _anuncio(0);
  @override
  Future<Anuncio> inhabilitarAnuncio(String id) async => _anuncio(4);
  @override
  Future<Anuncio> habilitarAnuncio(String id) async => _anuncio(0);
}

Reglamento _reglamento(int i) => Reglamento(
      id: 'r$i',
      titulo: ['Uso de las máquinas y del equipo de pesas libre', 'Vestimenta', 'Horarios y acceso'][i % 3],
      contenido: 'Limpiar el equipo después de usarlo. Devolver las pesas a su lugar. Respetar los turnos en horas pico.',
      estado: i == 3 ? EstadoReglamento.values.last : EstadoReglamento.values.first,
      fechaCreacion: DateTime(2026, 2, 1 + i),
      fechaActualizacion: DateTime(2026, 10, 1),
    );

class _Reglamentos implements ReglamentosService {
  @override
  Future<List<Reglamento>> getReglamentos() async => [for (var i = 0; i < 5; i++) _reglamento(i)];
  @override
  Future<List<Reglamento>> getReglamentosVigentes() async => [for (var i = 0; i < 3; i++) _reglamento(i)];
  @override
  Future<Reglamento> crearReglamento({required String titulo, required String contenido}) async => _reglamento(0);
  @override
  Future<Reglamento> actualizarReglamento({required String id, required String titulo, required String contenido}) async =>
      _reglamento(0);
  @override
  Future<Reglamento> inhabilitarReglamento(String id) async => _reglamento(3);
  @override
  Future<Reglamento> habilitarReglamento(String id) async => _reglamento(0);
}

class _Usuarios implements UsuariosService {
  @override
  Future<List<Usuario>> getUsuarios() async => [
        for (var i = 0; i < _nombres.length; i++)
          _usuario('u${i + 1}', RolUsuario.values[i % 4], _nombres[i].$1, _nombres[i].$2,
              estado: i == 5 ? EstadoUsuario.values.last : EstadoUsuario.values.first),
      ];
  @override
  Future<Usuario> crearUsuario(
          {required String nombre,
          required String primerApellido,
          String? segundoApellido,
          required String correo,
          required String telefono,
          required RolUsuario rol,
          required String usuario,
          required String contrasena}) async =>
      _usuario('n', rol, nombre, primerApellido);
  @override
  Future<Usuario> actualizarUsuario(
          {required String id,
          required String nombre,
          required String primerApellido,
          String? segundoApellido,
          required String correo,
          required String telefono,
          required RolUsuario rol,
          required String usuario,
          String? contrasena}) async =>
      _usuario(id, rol, nombre, primerApellido);
  @override
  Future<Usuario> inhabilitarUsuario(String id) async => _usuario(id, RolUsuario.cliente, 'Ana', 'Jiménez');
  @override
  Future<Usuario> habilitarUsuario(String id) async => _usuario(id, RolUsuario.cliente, 'Ana', 'Jiménez');
}

/// Todos los servicios en memoria (sin red).
class _Servicios extends AppServices {
  _Servicios(RolUsuario? rol)
      : super(
          auth: _Sesion(rol),
          perfil: const PerfilMockService(),
          rutinas: const RutinasMockService(),
          progreso: const ProgresoMockService(),
          clientes: _Clientes(),
          citas: _Citas(),
          mediciones: _Mediciones(),
        );

  @override
  ClasesService get clases => ClasesMockService(latency: Duration.zero);
  @override
  HorariosService get horarios => _Horarios();
  @override
  AnunciosService get anuncios => _Anuncios();
  @override
  UsuariosService get usuarios => _Usuarios();
  @override
  ReglamentosService get reglamentos => _Reglamentos();
  @override
  EjerciciosService get ejercicios => _Ejercicios();
  @override
  PlanesService get planes => _Planes();
}

// ---------------------------------------------------------------------------
// Utilidades
// ---------------------------------------------------------------------------

Future<void> _loadFonts() async {
  final barlow = FontLoader('Barlow')
    ..addFont(rootBundle.load('assets/fonts/Barlow-Regular.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Barlow-SemiBold.ttf'));
  final condensed = FontLoader('BarlowCondensed')..addFont(rootBundle.load('assets/fonts/BarlowCondensed-ExtraBold.ttf'));
  await Future.wait([barlow.load(), condensed.load()]);
}

const _sizes = [Size(844, 390), Size(1280, 400), Size(390, 600), Size(390, 844), Size(820, 600), Size(1024, 500), Size(1280, 600), Size(1440, 900)];

const _rutas = [
  '/',
  '/rutinas',
  '/progreso',
  '/horarios',
  '/anuncios',
  '/reglamento',
  '/perfil',
  '/entrenar/r1',
  '/coach',
  '/coach/ejercicios',
  '/coach/citas',
  '/coach/mediciones',
  '/coach/mediciones/historial',
  '/coach/plan/nuevo',
  '/coach/plan/p0',
  '/secretaria',
  '/secretaria/anuncios',
  '/admin',
  '/admin/reglamentos',
];

/// Avanza el tiempo sin pumpAndSettle (los skeletons animan sin fin).
Future<void> _esperar(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 150));
  }
}

Future<void> _abrirApp(WidgetTester tester, Size size, RolUsuario? rol, {bool sinRed = false}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  // sinRed: servicios reales sin servidor (en pruebas HTTP responde 400) → estados de error
  await tester.pumpWidget(AppRoot(services: sinRed ? AppServices(auth: _Sesion(rol)) : _Servicios(rol)));
  await _esperar(tester);
}

Future<void> _ir(WidgetTester tester, String ruta) async {
  GoRouter.of(tester.element(find.byType(Navigator).first)).go(ruta);
  await _esperar(tester);
}

/// Anota cualquier excepción pendiente (los desbordes llegan aquí).
void _revisar(WidgetTester tester, List<String> errores, String donde) {
  final e = tester.takeException();
  if (e != null) {
    final texto = e.toString().split('\n').take(3).join(' ');
    // Aviso de pintura (no de layout): se informa pero no hace fallar el barrido
    if (texto.contains('ListTile background color')) {
      debugPrint('AVISO $donde → $texto');
    } else {
      errores.add('$donde → $texto');
    }
  }
}

/// Cierra diálogos y pantallas apiladas encima de la ruta (en todos los navegadores).
Future<void> _cerrarDialogos(WidgetTester tester) async {
  for (final nav in tester.stateList<NavigatorState>(find.byType(Navigator))) {
    nav.popUntil((r) => r.settings is Page);
  }
  await _esperar(tester);
}

/// Toca el primer widget que coincida, si existe; devuelve si lo encontró.
Future<bool> _tocar(WidgetTester tester, Finder f) async {
  if (f.evaluate().isEmpty) {
    // Puede estar fuera de pantalla en una lista perezosa: se desplaza el scroll principal
    final principal = find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down);
    final candidatos = principal.evaluate().toList()
      ..sort((a, b) => (b.size!.height * b.size!.width).compareTo(a.size!.height * a.size!.width));
    if (candidatos.isEmpty) return false;
    final scroll = find.byElementPredicate((e) => identical(e, candidatos.first));
    for (var i = 0; i < 20 && f.evaluate().isEmpty; i++) {
      await tester.drag(scroll, const Offset(0, -250), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 50));
    }
    if (f.evaluate().isEmpty) return false;
  }
  await tester.ensureVisible(f.first);
  await tester.pump();
  await tester.tap(f.first, warnIfMissed: false);
  await _esperar(tester);
  return true;
}

/// Recorridos a probar en cada ruta: textos a tocar en orden (diálogos, formularios, subpantallas).
const _recorridos = <String, List<List<String>>>{
  '/perfil': [
    ['Cambiar contraseña'],
  ],
  '/coach': [
    ['Nuevo plan'],
  ],
  '/coach/ejercicios': [
    ['Nuevo ejercicio'],
    ['Press de banca inclinado con mancuernas'],
  ],
  '/coach/plan/nuevo': [
    ['Agregar ejercicios'],
    ['Asignar a un usuario'],
  ],
  '/coach/plan/p0': [
    ['Cambiar usuario'],
  ],
  '/coach/mediciones/historial': [
    ['Buscar cliente por nombre|Cambiar cliente', 'María Fernanda Rodríguez'],
    ['Buscar cliente por nombre|Cambiar cliente', 'María Fernanda Rodríguez', 'Comparar mediciones'],
    ['Buscar cliente por nombre|Cambiar cliente', 'María Fernanda Rodríguez', 'Ver evolución histórica'],
  ],
  '/secretaria': [
    ['Nueva clase'],
  ],
  '/secretaria/anuncios': [
    ['Nuevo anuncio'],
    ['Nuevo horario de fin de año para todas las sedes'],
  ],
  '/admin': [
    ['Nuevo usuario'],
    ['María Fernanda'],
  ],
  '/admin/reglamentos': [
    ['Nuevo reglamento'],
    ['Vestimenta'],
  ],
  '/entrenar/r1': [
    ['Completar serie'],
  ],
  '/rutinas': [
    ['Press de banca'],
  ],
};

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await _loadFonts();
  });

  // teclado: además se simula el teclado en pantalla abierto (viewInsets de 340 px)
  final casos = [for (final s in _sizes) (s, false), (const Size(390, 844), true), (const Size(1280, 720), true)];
  for (final rol in RolUsuario.values) {
    for (final (size, teclado) in casos) {
      testWidgets('Sin desbordes · ${rol.valor} · ${size.width.toInt()}x${size.height.toInt()}${teclado ? ' · teclado' : ''}', (tester) async {
        final errores = <String>[];
        final faltantes = <String>[];
        if (teclado) {
          tester.view.viewInsets = const FakeViewPadding(bottom: 340);
          addTearDown(tester.view.resetViewInsets);
        }
        await _abrirApp(tester, size, rol);
        _revisar(tester, errores, 'arranque');
        for (final ruta in _rutas) {
          if (!puedeEntrar(rol, ruta)) continue;
          await _ir(tester, ruta);
          _revisar(tester, errores, ruta);
          for (final pasos in _recorridos[ruta] ?? const <List<String>>[]) {
            for (final paso in pasos) {
              final ok = await _tocar(tester, find.textContaining(RegExp(paso)));
              _revisar(tester, errores, '$ruta · $paso');
              if (!ok) {
                faltantes.add('$ruta · $paso');
                break;
              }
            }
            await _cerrarDialogos(tester);
            await _ir(tester, ruta);
            _revisar(tester, errores, '$ruta · al cerrar');
          }
        }
        if (faltantes.isNotEmpty) debugPrint('Recorridos sin botón (${rol.valor} $size): $faltantes');
        expect(errores, isEmpty, reason: errores.join('\n'));
      });
    }
  }

  // Sin sesión: login y recuperación, también con teclado abierto.
  for (final size in [..._sizes, const Size(844, 390)]) {
    for (final teclado in [false, true]) {
      testWidgets('Sin desbordes · sin sesión · ${size.width.toInt()}x${size.height.toInt()}${teclado ? ' · teclado' : ''}', (tester) async {
        final errores = <String>[];
        if (teclado) {
          tester.view.viewInsets = const FakeViewPadding(bottom: 300);
          addTearDown(tester.view.resetViewInsets);
        }
        await _abrirApp(tester, size, null);
        _revisar(tester, errores, '/login');
        await _ir(tester, '/recuperar');
        _revisar(tester, errores, '/recuperar');
        expect(errores, isEmpty, reason: errores.join(' | '));
      });
    }
  }

  // Estados de error: la API falla en todas las pantallas.
  for (final rol in RolUsuario.values) {
    for (final size in const [Size(390, 600), Size(1024, 500), Size(1440, 900)]) {
      testWidgets('Sin desbordes con errores de API · ${rol.valor} · ${size.width.toInt()}x${size.height.toInt()}', (tester) async {
        final errores = <String>[];
        await _abrirApp(tester, size, rol, sinRed: true);
        _revisar(tester, errores, 'arranque');
        for (final ruta in _rutas) {
          if (!puedeEntrar(rol, ruta)) continue;
          await _ir(tester, ruta);
          _revisar(tester, errores, ruta);
        }
        expect(errores, isEmpty, reason: errores.join(' | '));
      });
    }
  }

  // Capturas de los paneles para revisión visual. Solo con --update-goldens.
  group('capturas', () {
    final paneles = <(RolUsuario, String, String)>[
      (RolUsuario.entrenador, '/coach', 'coach_planes'),
      (RolUsuario.entrenador, '/coach/ejercicios', 'coach_ejercicios'),
      (RolUsuario.entrenador, '/coach/citas', 'coach_citas'),
      (RolUsuario.entrenador, '/coach/mediciones', 'coach_mediciones'),
      (RolUsuario.entrenador, '/coach/mediciones/historial', 'coach_historial'),
      (RolUsuario.entrenador, '/coach/plan/nuevo', 'coach_plan_nuevo'),
      (RolUsuario.entrenador, '/coach/plan/p0', 'coach_plan_editar'),
      (RolUsuario.secretaria, '/secretaria', 'secretaria'),
      (RolUsuario.secretaria, '/secretaria/anuncios', 'secretaria_anuncios'),
      (RolUsuario.administrador, '/admin', 'admin_usuarios'),
      (RolUsuario.administrador, '/admin/reglamentos', 'admin_reglamentos'),
    ];
    for (final (rol, ruta, nombre) in paneles) {
      for (final size in const [Size(390, 844), Size(1440, 900)]) {
        final archivo = '${nombre}_${size.width.toInt()}x${size.height.toInt()}';
        testWidgets(archivo, (tester) async {
          await _abrirApp(tester, size, rol);
          await _ir(tester, ruta);
          await expectLater(find.byType(MaterialApp).first, matchesGoldenFile('../build/capturas/paneles/$archivo.png'));
        });
      }
    }
  }, skip: !autoUpdateGoldenFiles || Platform.environment['CAPTURAS'] == null);
}
