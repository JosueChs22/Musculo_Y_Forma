import '../models/body_metric.dart';
import '../models/inbody_summary.dart';

/// Acceso a las mediciones corporales del socio.
abstract class ProgresoService {
  Future<List<BodyMetric>> getBodyMetrics();

  /// REGLA 12: el historial se pide por páginas.
  Future<List<Measurement>> getMeasurementHistory({int limit = 20, String? cursor});

  Future<InbodySummary> getInbodySummary();
}
