import '../models/body_metric.dart';
import '../models/inbody_summary.dart';
import 'progreso_service.dart';

const _months = ['Dic', 'Ene', 'Feb', 'Mar', 'Abr', 'May'];

class ProgresoMockService implements ProgresoService {
  const ProgresoMockService({this.latency = const Duration(milliseconds: 250)});
  final Duration latency;

  Future<T> _fake<T>(T value) => Future.delayed(latency, () => value);

  @override
  Future<List<BodyMetric>> getBodyMetrics() => _fake(const [
        BodyMetric(
          label: 'Peso corporal',
          unit: 'kg',
          value: 78.4,
          decimals: 1,
          changeSinceStart: '-3.2 kg',
          changeVsPrevious: '-1.2 kg',
          history: [81.6, 80.9, 80.2, 79.5, 78.9, 78.4],
          historyLabels: _months,
        ),
        BodyMetric(
          label: 'Grasa corporal',
          unit: '%',
          value: 21.8,
          decimals: 1,
          changeSinceStart: '-2.6%',
          changeVsPrevious: '-0.8%',
          history: [24.4, 23.9, 23.2, 22.8, 22.1, 21.8],
          historyLabels: _months,
        ),
        BodyMetric(
          label: 'Masa muscular',
          unit: 'kg',
          value: 34.2,
          decimals: 1,
          changeSinceStart: '+1.4 kg',
          changeVsPrevious: '+0.5 kg',
          history: [32.8, 33.0, 33.3, 33.6, 33.9, 34.2],
          historyLabels: _months,
        ),
        BodyMetric(
          label: 'Grasa visceral',
          unit: 'nivel',
          value: 8,
          decimals: 0,
          changeSinceStart: '-2 niveles',
          changeVsPrevious: '0 niveles',
          history: [10, 10, 9, 9, 8, 8],
          historyLabels: _months,
        ),
      ]);

  @override
  Future<List<Measurement>> getMeasurementHistory({int limit = 20, String? cursor}) => _fake(const [
        Measurement(date: '18 may 2025', weight: '78.4 kg', bodyFat: '21.8%', muscle: '34.2 kg', visceral: '8'),
        Measurement(date: '20 abr 2025', weight: '78.9 kg', bodyFat: '22.1%', muscle: '33.9 kg', visceral: '8'),
        Measurement(date: '16 mar 2025', weight: '79.5 kg', bodyFat: '22.8%', muscle: '33.6 kg', visceral: '9'),
        Measurement(date: '15 feb 2025', weight: '80.2 kg', bodyFat: '23.2%', muscle: '33.3 kg', visceral: '9'),
      ]);

  @override
  Future<InbodySummary> getInbodySummary() => _fake(const InbodySummary(
        items: [
          InbodyItem(label: 'IMC', value: '24.7', hint: 'Rango saludable', ratio: .68),
          InbodyItem(label: 'Agua corporal', value: '44.1 L', hint: '56.3% del peso', ratio: .74),
          InbodyItem(label: 'Metabolismo basal', value: '1,724 kcal', hint: 'Gasto en reposo', ratio: .81),
          InbodyItem(label: 'Masa libre de grasa', value: '61.3 kg', hint: '78.2% del peso', ratio: .78),
        ],
        extras: [
          InbodyExtra(label: 'Proteínas', value: '12.8 kg'),
          InbodyExtra(label: 'Minerales', value: '4.1 kg'),
          InbodyExtra(label: 'Relación cintura-cadera', value: '0.87'),
          InbodyExtra(label: 'Puntuación InBody', value: '78 / 100'),
        ],
      ));
}
