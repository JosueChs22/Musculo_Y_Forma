import 'package:flutter_test/flutter_test.dart';
import 'package:pulso_app/core/api_exception.dart';
import 'package:pulso_app/features/ejercicios/models/ejercicio.dart';
import 'package:pulso_app/features/planes/controllers/buscador_clientes_controller.dart';
import 'package:pulso_app/features/planes/controllers/plan_editor_controller.dart';
import 'package:pulso_app/features/planes/controllers/planes_controller.dart';
import 'package:pulso_app/features/planes/models/plan.dart';
import 'package:pulso_app/features/planes/services/planes_service.dart';

const _juan = UsuarioResumen(id: 'u1', nombre: 'Juan Pérez', usuario: 'juan.perez');
const _maria = UsuarioResumen(id: 'u2', nombre: 'María López', usuario: 'maria.lopez');

Plan _plan(String id, {bool activo = true, UsuarioResumen? usuario, CategoriaPlan cat = CategoriaPlan.entrenamiento}) =>
    Plan(id: id, nombre: 'Plan $id', categoria: cat, activo: activo, usuario: usuario, totalEjercicios: 2);

Ejercicio _ej(String id) => Ejercicio(id: id, nombre: 'Ejercicio $id', grupoMuscular: 'Pecho', activo: true);

/// Servicio en memoria que anota lo que se le pide.
class _ServicioFalso implements PlanesService {
  final consultas = <({String? texto, CategoriaPlan? categoria, bool soloActivos, String? cursor})>[];
  final busquedasClientes = <String?>[];
  final llamadas = <String>[];
  bool fallar = false;
  Plan detalle = Plan(
    id: 'p9',
    nombre: 'Plan existente',
    categoria: CategoriaPlan.calentamiento,
    activo: true,
    usuario: _juan,
    totalEjercicios: 1,
    ejercicios: const [PlanEjercicio(idEjercicio: 'e1', nombre: 'Ejercicio e1')],
  );

  @override
  Future<PaginaPlanes> listar({CategoriaPlan? categoria, String? texto, bool soloActivos = true, String? cursor}) async {
    consultas.add((texto: texto, categoria: categoria, soloActivos: soloActivos, cursor: cursor));
    if (cursor != null) return PaginaPlanes([_plan('3')], null);
    return PaginaPlanes([_plan('1', cat: categoria ?? CategoriaPlan.entrenamiento), _plan('2')], 'pag2');
  }

  @override
  Future<Plan> obtener(String id) async => fallar ? throw const ApiException('Sin conexión') : detalle;

  @override
  Future<Plan> crear(DatosPlan datos, {String? idUsuario}) async {
    llamadas.add('crear:${datos.nombre}:${datos.ejercicios.length}:${idUsuario ?? '-'}');
    if (fallar) throw const ApiException('Nombre repetido');
    return _plan('nuevo');
  }

  @override
  Future<Plan> actualizar(String id, DatosPlan datos) async {
    llamadas.add('actualizar:$id');
    return _plan(id);
  }

  @override
  Future<UsuarioResumen?> asignar(String id, String? idUsuario) async {
    llamadas.add('asignar:$id:${idUsuario ?? '-'}');
    if (fallar) throw const ApiException('Sin conexión');
    return idUsuario == null ? null : (idUsuario == 'u1' ? _juan : _maria);
  }

  @override
  Future<void> inhabilitar(String id) async {
    if (fallar) throw const ApiException('Sin conexión');
  }

  @override
  Future<void> reactivar(String id) async {}

  @override
  Future<PaginaClientes> buscarClientes({String? texto, String? cursor}) async {
    busquedasClientes.add(texto);
    return const PaginaClientes([_juan, _maria], null);
  }
}

void main() {
  group('PlanesController', () {
    late _ServicioFalso servicio;
    late PlanesController c;

    setUp(() async {
      servicio = _ServicioFalso();
      c = PlanesController(servicio);
      await c.load();
    });

    tearDown(() => c.dispose());

    test('carga la primera página y luego la siguiente', () async {
      expect(c.items.map((p) => p.id), ['1', '2']);
      expect(c.hayMas, isTrue);
      expect(servicio.consultas.single.soloActivos, isTrue);

      await c.cargarMas();
      expect(c.items.map((p) => p.id), ['1', '2', '3']);
      expect(c.hayMas, isFalse);
      expect(servicio.consultas.last.cursor, 'pag2');
    });

    test('buscar espera 300 ms y no consulta con menos de 2 letras', () async {
      c.buscar('p');
      await Future<void>.delayed(const Duration(milliseconds: 350));
      expect(c.textoMuyCorto, isTrue);
      expect(servicio.consultas, hasLength(1)); // solo la carga inicial

      c.buscar('pe');
      c.buscar('pec');
      await Future<void>.delayed(const Duration(milliseconds: 350));
      expect(servicio.consultas, hasLength(2)); // una sola consulta para "pec"
      expect(servicio.consultas.last.texto, 'pec');
    });

    test('filtrar por categoría vuelve a consultar con esa categoría', () async {
      c.filtrarCategoria(CategoriaPlan.calentamiento);
      await c.load();
      expect(servicio.consultas.last.categoria, CategoriaPlan.calentamiento);
      expect(c.hayFiltros, isTrue);
    });

    test('asignar actualiza el plan y deja el usuario asignado', () async {
      final ok = await c.asignar(c.items.first, _maria);
      expect(ok, isTrue);
      expect(c.items.first.usuario?.id, 'u2');
      expect(servicio.llamadas, ['asignar:1:u2']);
    });

    test('asignar revierte si el servidor falla', () async {
      servicio.fallar = true;
      final ok = await c.asignar(c.items.first, _maria);
      expect(ok, isFalse);
      expect(c.items.first.usuario, isNull);
      expect(c.tomarAviso(), 'Sin conexión');
      expect(c.tomarAviso(), isNull);
    });

    test('inhabilitar saca el plan de la lista y revierte si falla', () async {
      expect(await c.cambiarEstado(c.items.first, activo: false), isTrue);
      expect(c.items.map((p) => p.id), ['2']);

      servicio.fallar = true;
      expect(await c.cambiarEstado(c.items.first, activo: false), isFalse);
      expect(c.items.map((p) => p.id), ['2']); // vuelve a estar
      expect(c.items.first.activo, isTrue);
    });
  });

  group('PlanEditorController', () {
    late _ServicioFalso servicio;

    setUp(() => servicio = _ServicioFalso());

    test('un plan nuevo agrega, ordena y quita ejercicios sin repetirlos', () {
      final c = PlanEditorController(servicio);
      expect(c.agregar(_ej('a')), isTrue);
      expect(c.agregar(_ej('b')), isTrue);
      expect(c.agregar(_ej('a')), isFalse); // ya estaba
      expect(c.ejercicios.map((e) => e.idEjercicio), ['a', 'b']);

      c.mover('b', -1);
      expect(c.ejercicios.map((e) => e.idEjercicio), ['b', 'a']);
      c.mover('b', -1); // ya es el primero: no pasa nada
      expect(c.ejercicios.first.idEjercicio, 'b');

      c.quitar('b');
      expect(c.ejercicios.map((e) => e.idEjercicio), ['a']);
      c.dispose();
    });

    test('no guarda sin nombre o sin ejercicios', () async {
      final c = PlanEditorController(servicio);
      expect(await c.guardar(), isFalse);
      expect(c.errorGuardar, 'Ponle un nombre al plan.');

      c.cambiarNombre('Mi plan');
      expect(await c.guardar(), isFalse);
      expect(c.errorGuardar, 'Agrega al menos un ejercicio.');
      expect(servicio.llamadas, isEmpty);
      c.dispose();
    });

    test('crea el plan ya asignado al cliente elegido', () async {
      final c = PlanEditorController(servicio)
        ..cambiarNombre('Mi plan')
        ..agregar(_ej('a'))
        ..cambiarCliente(_juan);
      expect(await c.guardar(), isTrue);
      expect(servicio.llamadas, ['crear:Mi plan:1:u1']);
      c.dispose();
    });

    test('guardar deja el mensaje de la API si falla', () async {
      servicio.fallar = true;
      final c = PlanEditorController(servicio)
        ..cambiarNombre('Mi plan')
        ..agregar(_ej('a'));
      expect(await c.guardar(), isFalse);
      expect(c.errorGuardar, 'Nombre repetido');
      expect(c.guardando, isFalse);
      c.dispose();
    });

    test('al editar carga el plan y solo reasigna si cambió el cliente', () async {
      final c = PlanEditorController(servicio, id: 'p9');
      await c.cargar();
      expect(c.nombre, 'Plan existente');
      expect(c.categoria, CategoriaPlan.calentamiento);
      expect(c.cliente?.id, 'u1');

      expect(await c.guardar(), isTrue);
      expect(servicio.llamadas, ['actualizar:p9']); // mismo cliente: no vuelve a asignar

      c.cambiarCliente(_maria);
      expect(await c.guardar(), isTrue);
      expect(servicio.llamadas, ['actualizar:p9', 'actualizar:p9', 'asignar:p9:u2']);
      c.dispose();
    });

    test('un ejercicio inhabilitado impide guardar hasta quitarlo', () async {
      servicio.detalle = Plan(
        id: 'p9',
        nombre: 'Plan viejo',
        categoria: CategoriaPlan.entrenamiento,
        activo: true,
        totalEjercicios: 1,
        ejercicios: const [PlanEjercicio(idEjercicio: 'e1', nombre: 'Banca', activo: false), PlanEjercicio(idEjercicio: 'e2', nombre: 'Remo')],
      );
      final c = PlanEditorController(servicio, id: 'p9');
      await c.cargar();
      expect(await c.guardar(), isFalse);
      expect(c.errorGuardar, contains('Banca'));

      c.quitar('e1');
      expect(await c.guardar(), isTrue);
      c.dispose();
    });

    test('un plan inhabilitado no se puede editar', () async {
      servicio.detalle = _plan('p9', activo: false);
      final c = PlanEditorController(servicio, id: 'p9');
      await c.cargar();
      expect(c.editable, isFalse);
      expect(await c.guardar(), isFalse);
      expect(servicio.llamadas, isEmpty);
      c.dispose();
    });

    test('si falla la carga, deja el error', () async {
      servicio.fallar = true;
      final c = PlanEditorController(servicio, id: 'p9');
      await c.cargar();
      expect(c.errorCarga, 'Sin conexión');
      c.dispose();
    });
  });

  test('BuscadorClientesController espera 300 ms y exige 2 letras', () async {
    final servicio = _ServicioFalso();
    final c = BuscadorClientesController(servicio);
    await c.cargar();
    expect(servicio.busquedasClientes, ['']);

    c.buscar('j');
    await Future<void>.delayed(const Duration(milliseconds: 350));
    expect(c.textoMuyCorto, isTrue);
    expect(servicio.busquedasClientes, hasLength(1));

    c.buscar('ju');
    c.buscar('jua');
    await Future<void>.delayed(const Duration(milliseconds: 350));
    expect(servicio.busquedasClientes, ['', 'jua']);
    expect(c.items.map((u) => u.id), ['u1', 'u2']);
    c.dispose();
  });

  test('Plan: el JSON de la API se convierte y el cuerpo sale en snake_case', () {
    final plan = Plan.fromJson({
      'id': 'p1',
      'nombre': 'Pecho',
      'categoria': 'estiramiento',
      'observaciones': null,
      'diaSemana': 3,
      'estado': 'Activo',
      'usuario': {'id': 'u1', 'nombre': 'Juan Pérez', 'usuario': 'juan.perez'},
      'totalEjercicios': 1,
      'ejercicios': [
        {
          'idEjercicio': 'e1', 'nombre': 'Banca', 'imagen': 'https://x/y.jpg', 'grupoMuscular': 'Pecho', 'activo': true,
          'series': 4, 'repeticiones': 8, 'descanso': 90, 'pesoSugerido': 42.5, 'nota': null,
        },
      ],
    });
    expect(plan.categoria, CategoriaPlan.estiramiento);
    expect(plan.dia, 'Miércoles');
    expect(plan.usuario?.iniciales, 'JP');
    expect(plan.ejercicios.single.resumen, '4 series · 8 reps · 90 s de descanso');

    final cuerpo = DatosPlan(nombre: ' Pecho ', categoria: plan.categoria, diaSemana: 3, ejercicios: plan.ejercicios).toJson();
    expect(cuerpo['nombre'], 'Pecho');
    expect(cuerpo['categoria'], 'estiramiento');
    expect(cuerpo['dia_semana'], 3);
    expect((cuerpo['ejercicios'] as List).single, {
      'id_ejercicio': 'e1', 'series': 4, 'repeticiones': 8, 'descanso': 90, 'peso_sugerido': 42.5, 'nota': null,
    });
  });
}
