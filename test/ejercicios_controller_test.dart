import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pulso_app/core/api_exception.dart';
import 'package:pulso_app/features/ejercicios/controllers/ejercicios_controller.dart';
import 'package:pulso_app/features/ejercicios/models/ejercicio.dart';
import 'package:pulso_app/features/ejercicios/services/ejercicios_service.dart';

Ejercicio _ej(
  String id, {
  bool activo = true,
  String? grupo,
  String tipo = 'entrenamiento',
}) =>
    Ejercicio(
      id: id,
      nombre: 'Ejercicio $id',
      grupoMuscular: grupo,
      tipo: tipo,
      activo: activo,
    );

/// Servicio en memoria.
/// No utiliza HTTP ni MongoDB.
class _ServicioFalso implements EjerciciosService {
  final consultas = <({
    String? texto,
    String? grupo,
    String? tipo,
    bool soloActivos,
    String? cursor,
  })>[];

  bool fallarEstado = false;
  bool fallarCrear = true;

  DatosEjercicio? ultimoCreado;
  DatosEjercicio? ultimoActualizado;
  String? ultimoIdActualizado;

  /// Permite pausar la siguiente consulta.
  Completer<void>? pausa;

  @override
  Future<PaginaEjercicios> listar({
    String? texto,
    String? grupo,
    String? tipo,
    bool soloActivos = true,
    String? cursor,
  }) async {
    consultas.add((
      texto: texto,
      grupo: grupo,
      tipo: tipo,
      soloActivos: soloActivos,
      cursor: cursor,
    ));

    final espera = pausa;
    pausa = null;

    if (espera != null) {
      await espera.future;
    }

    if (cursor != null) {
      return PaginaEjercicios(
        [_ej('3', tipo: tipo ?? 'entrenamiento')],
        null,
      );
    }

    return PaginaEjercicios(
      [
        _ej(
          '1',
          grupo: grupo,
          tipo: tipo ?? 'entrenamiento',
        ),
        _ej(
          '2',
          tipo: tipo ?? 'entrenamiento',
        ),
      ],
      'pag2',
    );
  }

  @override
  Future<Ejercicio> crear(DatosEjercicio d) async {
    ultimoCreado = d;

    if (fallarCrear) {
      throw const ApiException('Nombre repetido');
    }

    return Ejercicio(
      id: 'nuevo',
      nombre: d.nombre,
      grupoMuscular: d.grupoMuscular,
      tipo: d.tipo ?? 'entrenamiento',
      activo: true,
    );
  }

  @override
  Future<Ejercicio> actualizar(
    String id,
    DatosEjercicio d,
  ) async {
    ultimoActualizado = d;
    ultimoIdActualizado = id;

    return Ejercicio(
      id: id,
      nombre: d.nombre,
      grupoMuscular: d.grupoMuscular,
      tipo: d.tipo ?? 'entrenamiento',
      activo: true,
    );
  }

  @override
  Future<Ejercicio> inhabilitar(String id) async => fallarEstado
      ? throw const ApiException('Sin conexión')
      : _ej(id, activo: false);

  @override
  Future<Ejercicio> reactivar(String id) async => _ej(id);
}

void main() {
  late _ServicioFalso servicio;
  late EjerciciosController c;

  setUp(() async {
    servicio = _ServicioFalso();
    c = EjerciciosController(servicio);
    await c.load();
  });

  tearDown(() => c.dispose());

  // ===================================================
  // PRUEBAS EXISTENTES
  // ===================================================

  test('carga la primera página y luego la siguiente', () async {
    expect(c.items.map((e) => e.id), ['1', '2']);
    expect(c.hayMas, isTrue);
    expect(servicio.consultas.single.soloActivos, isTrue);

    await c.cargarMas();

    expect(c.items.map((e) => e.id), ['1', '2', '3']);
    expect(c.hayMas, isFalse);
    expect(servicio.consultas.last.cursor, 'pag2');
  });

  test('buscar espera 300 ms y no consulta con menos de 2 letras', () async {
    c.buscar('s');

    await Future<void>.delayed(
      const Duration(milliseconds: 350),
    );

    expect(c.textoMuyCorto, isTrue);
    expect(servicio.consultas, hasLength(1));

    c.buscar('se');
    c.buscar('sen');

    await Future<void>.delayed(
      const Duration(milliseconds: 350),
    );

    expect(servicio.consultas, hasLength(2));
    expect(servicio.consultas.last.texto, 'sen');
    expect(c.escrito, 'sen');
  });

  test(
    'si el filtro cambia durante una carga, gana el último filtro',
    () async {
      final pausa = servicio.pausa = Completer<void>();

      c.mostrarInhabilitados(true);
      c.filtrarGrupo('Pecho');

      pausa.complete();
      await c.load();

      expect(servicio.consultas.last.grupo, 'Pecho');
      expect(servicio.consultas.last.soloActivos, isFalse);
      expect(c.items.first.grupoMuscular, 'Pecho');
      expect(c.loading, isFalse);
    },
  );

  test(
    'inhabilitar quita el ejercicio de la lista de activos',
    () async {
      final ok = await c.cambiarEstado(
        c.items.first,
        activo: false,
      );

      expect(ok, isTrue);
      expect(c.items.map((e) => e.id), ['2']);
    },
  );

  test(
    'inhabilitar revierte el cambio si el servidor falla',
    () async {
      servicio.fallarEstado = true;

      final ok = await c.cambiarEstado(
        c.items.first,
        activo: false,
      );

      expect(ok, isFalse);
      expect(c.items.map((e) => e.id), ['1', '2']);
      expect(c.items.first.activo, isTrue);
      expect(c.tomarAviso(), 'Sin conexión');
      expect(c.tomarAviso(), isNull);
    },
  );

  test(
    'guardar deja el mensaje de la API si falla y actualiza en sitio si va bien',
    () async {
      const datos = DatosEjercicio(
        nombre: 'Nuevo nombre',
      );

      expect(await c.guardar(datos), isFalse);
      expect(c.errorGuardar, 'Nombre repetido');

      expect(
        await c.guardar(datos, id: '2'),
        isTrue,
      );

      expect(c.errorGuardar, isNull);
      expect(
        c.items.map((e) => e.nombre),
        ['Ejercicio 1', 'Nuevo nombre'],
      );
    },
  );

  // ===================================================
  // SPRINT 3: EJERCICIOS DE ESTIRAMIENTO
  // ===================================================

  test(
    'RF-066: filtrar estiramientos consulta el tipo correcto',
    () async {
      c.filtrarTipo('estiramiento');
      await c.load();

      expect(c.tipoFiltro, 'estiramiento');
      expect(c.hayFiltros, isTrue);

      expect(
        servicio.consultas.last.tipo,
        'estiramiento',
      );

      expect(
        c.items.every(
          (e) => e.tipo == 'estiramiento',
        ),
        isTrue,
      );
    },
  );

  test(
    'RF-077: paginar estiramientos conserva el filtro',
    () async {
      c.filtrarTipo('estiramiento');
      await c.load();

      expect(c.hayMas, isTrue);

      await c.cargarMas();

      expect(
        servicio.consultas.last.tipo,
        'estiramiento',
      );

      expect(
        servicio.consultas.last.cursor,
        'pag2',
      );

      expect(
        c.items.map((e) => e.id),
        ['1', '2', '3'],
      );

      expect(
        c.items.every(
          (e) => e.tipo == 'estiramiento',
        ),
        isTrue,
      );
    },
  );

  test(
    'RF-045: crear estiramiento envía el tipo al servicio',
    () async {
      servicio.fallarCrear = false;

      const datos = DatosEjercicio(
        nombre: 'Estiramiento de cuádriceps',
        tipo: 'estiramiento',
      );

      final ok = await c.guardar(datos);

      expect(ok, isTrue);
      expect(servicio.ultimoCreado, isNotNull);

      expect(
        servicio.ultimoCreado!.nombre,
        'Estiramiento de cuádriceps',
      );

      expect(
        servicio.ultimoCreado!.tipo,
        'estiramiento',
      );
    },
  );

  test(
    'RF-052: actualizar estiramiento conserva su tipo',
    () async {
      c.filtrarTipo('estiramiento');
      await c.load();

      const datos = DatosEjercicio(
        nombre: 'Estiramiento actualizado',
        tipo: 'estiramiento',
      );

      final ok = await c.guardar(
        datos,
        id: '1',
      );

      expect(ok, isTrue);

      expect(
        servicio.ultimoIdActualizado,
        '1',
      );

      expect(
        servicio.ultimoActualizado?.tipo,
        'estiramiento',
      );

      expect(
        c.items.first.nombre,
        'Estiramiento actualizado',
      );

      expect(
        c.items.first.tipo,
        'estiramiento',
      );
    },
  );

  test(
    'RF-059: inhabilitar un estiramiento lo oculta de los activos',
    () async {
      c.filtrarTipo('estiramiento');
      await c.load();

      final ejercicio = c.items.first;

      expect(
        ejercicio.tipo,
        'estiramiento',
      );

      final ok = await c.cambiarEstado(
        ejercicio,
        activo: false,
      );

      expect(ok, isTrue);

      expect(
        c.items.any(
          (e) => e.id == ejercicio.id,
        ),
        isFalse,
      );
    },
  );
}
