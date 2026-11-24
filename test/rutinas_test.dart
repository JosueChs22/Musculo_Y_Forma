import 'package:flutter_test/flutter_test.dart';
import 'package:pulso_app/features/planes/models/plan.dart' show CategoriaPlan;
import 'package:pulso_app/features/rutinas/controllers/rutinas_controller.dart';
import 'package:pulso_app/features/rutinas/models/exercise.dart';
import 'package:pulso_app/features/rutinas/models/routine.dart';
import 'package:pulso_app/features/rutinas/services/rutinas_service.dart';

Routine _r(String id, CategoriaPlan c) =>
    Routine(id: id, title: id, focus: c.etiqueta, progress: 0, exercises: const [], categoria: c);

class _Falso implements RutinasService {
  final cursores = <String?>[];
  bool fallarHistorial = false;

  @override
  Future<List<Routine>> getRoutines() async => [
        _r('e1', CategoriaPlan.entrenamiento),
        _r('c1', CategoriaPlan.calentamiento),
        _r('e2', CategoriaPlan.entrenamiento),
      ];

  @override
  Future<PaginaRutinas> getHistorial({String? cursor, int limite = 20}) async {
    cursores.add(cursor);
    if (fallarHistorial) throw Exception('404');
    if (cursor == null) return PaginaRutinas([_r('h1', CategoriaPlan.entrenamiento)], 'p2');
    return PaginaRutinas([_r('h2', CategoriaPlan.estiramiento)], null);
  }
}

void main() {
  group('Modelos', () {
    test('Routine.fromJson tolera campos faltantes', () {
      final r = Routine.fromJson({'id': 'p1', 'nombre': 'Plan', 'categoria': 'calentamiento'});
      expect(r.categoria, CategoriaPlan.calentamiento);
      expect(r.exercises, isEmpty);
      expect(r.diaSemana, isNull);
      expect(r.coachName, isNull);
      expect(r.activa, isTrue);
      expect(r.totalEjercicios, 0);
    });

    test('Routine.fromJson del historial', () {
      final r = Routine.fromJson({
        'id': 'p2',
        'nombre': 'Viejo',
        'categoria': 'estiramiento',
        'diaSemana': 1,
        'estado': 'Inhabilitado',
        'totalEjercicios': 5,
        'ejercicios': [],
        'coach': {'id': 'c', 'nombre': 'Ana', 'usuario': 'ana'},
      });
      expect(r.activa, isFalse);
      expect(r.totalEjercicios, 5);
      expect(r.coachName, 'Ana');
      expect(r.focus, 'Estiramiento · Lunes');
    });

    test('Exercise.fromJson con y sin opcionales', () {
      final min = Exercise.fromJson({'idEjercicio': 'x', 'nombre': 'Plancha'});
      expect(min.sets, 0);
      expect(min.pesoSugerido, isNull);
      expect(min.gifUrl, isNull);
      expect(min.coachNote, '');
      final full = Exercise.fromJson({
        'idEjercicio': 'y',
        'nombre': 'Press',
        'series': 4,
        'repeticiones': 10,
        'descanso': 60,
        'pesoSugerido': 40,
        'nota': 'Lento',
        'grupoMuscular': 'Pecho',
        'herramienta': 'Barra',
        'instrucciones': 'Baja controlado',
        'gif': 'g.gif',
        'imagen': null,
      });
      expect(full.reps, '10 repeticiones');
      expect(full.pesoLabel, '40 kg sugeridos');
      expect(full.grupoMuscular, 'Pecho');
      expect(full.herramienta, 'Barra');
      expect(full.instrucciones, 'Baja controlado');
      expect(full.imageUrl, isNull);
    });
  });

  group('RutinasController', () {
    test('agrupa por categoría y filtra por pestaña', () async {
      final c = RutinasController(_Falso());
      await c.load();
      expect(c.porCategoria(CategoriaPlan.entrenamiento).map((r) => r.id), ['e1', 'e2']);
      expect(c.porCategoria(CategoriaPlan.estiramiento), isEmpty);
      c.select(1);
      expect(c.selected!.id, 'e2');
      c.setTab(RutinasTab.calentamiento);
      expect(c.selected!.id, 'c1');
      c.setTab(RutinasTab.estiramiento);
      expect(c.selected, isNull);
    });

    test('historial pagina con cursor y no repite al terminar', () async {
      final s = _Falso();
      final c = RutinasController(s);
      await c.load();
      await c.cargarHistorial();
      expect(c.historial.map((r) => r.id), ['h1']);
      expect(c.hayMasHistorial, isTrue);
      await c.cargarMasHistorial();
      expect(c.historial.map((r) => r.id), ['h1', 'h2']);
      expect(c.hayMasHistorial, isFalse);
      await c.cargarMasHistorial();
      expect(s.cursores, [null, 'p2']);
    });

    test('error del historial no rompe las rutinas', () async {
      final s = _Falso()..fallarHistorial = true;
      final c = RutinasController(s);
      await c.load();
      await c.cargarHistorial();
      expect(c.historialError, isNotNull);
      expect(c.error, isNull);
      expect(c.routines, hasLength(3));
    });
  });
}
