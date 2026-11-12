import 'dart:async';

import 'package:flutter/foundation.dart';

/// REGLA 9: ejecuta la acción solo cuando pasan [delay] sin nuevas llamadas.
class Debouncer {
  Debouncer({this.delay = const Duration(milliseconds: 300)});

  final Duration delay;
  Timer? _timer;

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void cancel() => _timer?.cancel();

  void dispose() => cancel();
}
