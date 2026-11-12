import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pulso_app/core/api_exception.dart';
import 'package:pulso_app/features/ejercicios/controllers/ejercicios_controller.dart';
import 'package:pulso_app/features/ejercicios/models/ejercicio.dart';
import 'package:pulso_app/features/ejercicios/services/ejercicios_service.dart';

Ejercicio _ej(String id, {bool activo = true, String? grupo}) =>
    Ejercicio(id: id, nombre: 'Ejercicio $id', grupoMuscular: grupo, activo: activo);

/// Servicio en memoria que anota lo que se le pide.
class _ServicioFalso implements EjerciciosService {
  final consultas = <({String? texto, String? grupo, bool soloActivos, String? cursor})>[];
  bool fallarEstado = false;

  /// Si se asigna, la siguiente consulta espera a que se complete.
  Completer<void>? pausa;

  @override
  Future<PaginaEjercicios> listar({
    String? texto,
    String? grupo,
    bool soloActivos = true,
    String? cursor,
  }) async {
    consultas.add((texto: texto, grupo: grupo, soloActivos: soloActivos, cursor: cursor));
    final espera = pausa;
    pausa = null;
    if (espera != null) await espera.future;
    if (cursor != null) return PaginaEjercicios([_ej('3')], null);
    return PaginaEjercicios([_ej('1', grupo: grupo), _ej('2')], 'pag2');
  }

  @override
  Future<Ejercicio> crear(DatosEjercicio d) async => throw const ApiException('Nombre repetido');

  @override
  Future<Ejercicio> actualizar(String id, DatosEjercicio d) async => Ejercicio(id: id, nombre: d.nombre, activo: true);

  @override
  Future<Ejercicio> inhabilitar(String id) async =>
      fallarEstado ? throw const ApiException('Sin conexión') : _ej(id, activo: false);

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
    await Future<void>.delayed(const Duration(milliseconds: 350));
    expect(c.textoMuyCorto, isTrue);
    expect(servicio.consultas, hasLength(1)); // solo la carga inicial

    c.buscar('se');
    c.buscar('sen');
    await Future<void>.delayed(const Duration(milliseconds: 350));
    expect(servicio.consultas, hasLength(2)); // una sola consulta para "sen"
    expect(servicio.consultas.last.texto, 'sen');
    expect(c.escrito, 'sen');
  });

  test('si el filtro cambia durante una carga, gana el último filtro', () async {
    final pausa = servicio.pausa = Completer<void>();
    c.mostrarInhabilitados(true); // consulta que queda esperando
    c.filtrarGrupo('Pecho'); // cambia antes de que responda
    pausa.complete();
    await c.load();

    expect(servicio.consultas.last.grupo, 'Pecho');
    expect(servicio.consultas.last.soloActivos, isFalse);
    expect(c.items.first.grupoMuscular, 'Pecho');
    expect(c.loading, isFalse);
  });

  test('inhabilitar quita el ejercicio de la lista de activos', () async {
    final ok = await c.cambiarEstado(c.items.first, activo: false);
    expect(ok, isTrue);
    expect(c.items.map((e) => e.id), ['2']);
  });

  test('inhabilitar revierte el cambio si el servidor falla', () async {
    servicio.fallarEstado = true;
    final ok = await c.cambiarEstado(c.items.first, activo: false);
    expect(ok, isFalse);
    expect(c.items.map((e) => e.id), ['1', '2']);
    expect(c.items.first.activo, isTrue);
    expect(c.tomarAviso(), 'Sin conexión');
    expect(c.tomarAviso(), isNull);
  });

  test('guardar deja el mensaje de la API si falla y actualiza en sitio si va bien', () async {
    const datos = DatosEjercicio(nombre: 'Nuevo nombre');

    expect(await c.guardar(datos), isFalse);
    expect(c.errorGuardar, 'Nombre repetido');

    expect(await c.guardar(datos, id: '2'), isTrue);
    expect(c.errorGuardar, isNull);
    expect(c.items.map((e) => e.nombre), ['Ejercicio 1', 'Nuevo nombre']);
  });
}
