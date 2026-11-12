import 'dart:async';

import '../../../core/base_controller.dart';
import '../models/body_metric.dart';
import '../models/inbody_summary.dart';
import '../services/progreso_service.dart';

class ProgresoController extends BaseController {
  ProgresoController(this._service);

  final ProgresoService _service;

  List<BodyMetric> _metrics = const [];
  List<BodyMetric> get metrics => _metrics;

  List<Measurement> _history = const [];
  List<Measurement> get history => _history;

  InbodySummary _inbody = InbodySummary.empty;
  InbodySummary get inbody => _inbody;

  int _selectedMetric = 0;
  int get selectedMetric => _selectedMetric;

  BodyMetric? get currentMetric => _metrics.isEmpty ? null : _metrics[_selectedMetric];

  @override
  Future<void> fetch() async {
    // REGLA 10: peticiones independientes en paralelo.
    final (metrics, history, inbody) = await (
      _service.getBodyMetrics(),
      _service.getMeasurementHistory(),
      _service.getInbodySummary(),
    ).wait;
    _metrics = metrics;
    _history = history;
    _inbody = inbody;
    if (_selectedMetric >= _metrics.length) _selectedMetric = 0;
  }

  void selectMetric(int index) {
    if (index == _selectedMetric || index < 0 || index >= _metrics.length) return;
    _selectedMetric = index;
    notify();
  }
}
