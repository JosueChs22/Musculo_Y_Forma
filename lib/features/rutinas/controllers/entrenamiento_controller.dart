import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/exercise.dart';
import '../models/routine.dart';

/// Sesión de entrenamiento en curso: un ejercicio a la vez, series marcadas a
/// mano y un descanso con cuenta regresiva entre series. Vive solo mientras la
/// pantalla está abierta (la API todavía no guarda el avance de las sesiones).
class EntrenamientoController extends ChangeNotifier {
  EntrenamientoController(this.rutina, {DateTime Function()? reloj})
      : _reloj = reloj ?? DateTime.now,
        _hechas = List.filled(rutina.exercises.length, 0) {
    _inicio = _reloj();
  }

  final Routine rutina;
  final DateTime Function() _reloj;
  final List<int> _hechas; // series completadas por ejercicio
  late final DateTime _inicio;
  DateTime? _fin;

  int _indice = 0;
  int _descanso = 0; // segundos restantes; 0 = sin descanso
  Timer? _timer;

  List<Exercise> get ejercicios => rutina.exercises;
  bool get vacia => ejercicios.isEmpty;
  int get indice => _indice;
  Exercise get actual => ejercicios[_indice];
  int get hechasActual => _hechas[_indice];
  int seriesHechas(int i) => _hechas[i];
  bool get ejercicioCompleto => hechasActual >= actual.sets;
  bool get esUltimo => _indice == ejercicios.length - 1;
  bool get terminado => _fin != null;
  int get descanso => _descanso;
  bool get descansando => _descanso > 0;

  int get seriesTotales => ejercicios.fold(0, (a, e) => a + e.sets);
  int get seriesCompletadas {
    var n = 0;
    for (var i = 0; i < ejercicios.length; i++) {
      n += _hechas[i].clamp(0, ejercicios[i].sets);
    }
    return n;
  }

  double get progreso => seriesTotales == 0 ? 0 : seriesCompletadas / seriesTotales;
  int get ejerciciosCompletos => [for (var i = 0; i < ejercicios.length; i++) if (_hechas[i] >= ejercicios[i].sets) i].length;
  Duration get duracion => (_fin ?? _reloj()).difference(_inicio);

  /// Marca la serie actual como hecha. Si quedan series, arranca el descanso;
  /// si fue la última del ejercicio, pasa al siguiente tras el descanso.
  void completarSerie() {
    if (terminado || ejercicioCompleto) return;
    _hechas[_indice]++;
    final quedanSeries = !ejercicioCompleto;
    final quedanEjercicios = !esUltimo;
    if (quedanSeries || quedanEjercicios) {
      _iniciarDescanso(actual.restSeconds, avanzarAlFinal: !quedanSeries);
    }
    notifyListeners();
  }

  /// Deshace la última serie marcada del ejercicio actual (por si fue un toque de más).
  void deshacerSerie() {
    if (terminado || hechasActual == 0) return;
    _hechas[_indice]--;
    _cancelarDescanso();
    notifyListeners();
  }

  bool _avanzarAlFinal = false;

  void _iniciarDescanso(int segundos, {required bool avanzarAlFinal}) {
    _cancelarDescanso();
    _avanzarAlFinal = avanzarAlFinal;
    if (segundos <= 0) {
      if (avanzarAlFinal) _irA(_indice + 1);
      return;
    }
    _descanso = segundos;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _descanso--;
      if (_descanso <= 0) {
        _finDescanso();
      } else {
        notifyListeners();
      }
    });
  }

  void _finDescanso() {
    _cancelarDescanso();
    if (_avanzarAlFinal) _irA(_indice + 1);
    notifyListeners();
  }

  void _cancelarDescanso() {
    _timer?.cancel();
    _timer = null;
    _descanso = 0;
  }

  void sumarDescanso([int segundos = 15]) {
    if (!descansando) return;
    _descanso += segundos;
    notifyListeners();
  }

  void saltarDescanso() {
    if (!descansando) return;
    _finDescanso();
  }

  void _irA(int i) {
    if (i < 0 || i >= ejercicios.length) return;
    _indice = i;
  }

  void siguiente() {
    _cancelarDescanso();
    _irA(_indice + 1);
    notifyListeners();
  }

  void anterior() {
    _cancelarDescanso();
    _irA(_indice - 1);
    notifyListeners();
  }

  void irA(int i) {
    _cancelarDescanso();
    _irA(i);
    notifyListeners();
  }

  void terminar() {
    _cancelarDescanso();
    _fin = _reloj();
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
