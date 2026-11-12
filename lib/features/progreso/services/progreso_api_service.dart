import '../../../core/api_http.dart';
import '../../../core/fechas.dart';
import '../models/body_metric.dart';
import '../models/inbody_summary.dart';
import 'progreso_service.dart';

/// Medición tal como la devuelve GET /mi/mediciones.
class _Medicion {
  _Medicion(Map<String, dynamic> j)
      : fecha = DateTime.parse(j['fecha'] as String),
        objetivo = j['objetivo'] as String?,
        peso = (j['peso'] as num?)?.toDouble(),
        grasa = (j['grasaCorporal'] as num?)?.toDouble(),
        visceral = (j['grasaVisceral'] as num?)?.toDouble(),
        musculo = (j['masaMuscular'] as num?)?.toDouble(),
        imc = (j['imc'] as num?)?.toDouble(),
        edad = (j['edad'] as num?)?.toInt(),
        estatura = (j['estatura'] as num?)?.toDouble(),
        actividad = j['nivelActividad'] as String?,
        frecuencia = (j['frecuenciaSemanal'] as num?)?.toInt();

  final DateTime fecha;
  final String? objetivo;
  final double? peso, grasa, visceral, musculo, imc, estatura;
  final int? edad, frecuencia;
  final String? actividad;
}

/// Progreso del usuario con sesión, calculado a partir de sus mediciones (siempre las del token).
class ProgresoApiService implements ProgresoService {
  ProgresoApiService({ApiHttp? http}) : _http = http ?? ApiHttp();

  final ApiHttp _http;

  // Puntos que se ven en la gráfica
  static const _puntos = 6;

  // REGLA 8: las tres consultas del controlador comparten una sola petición en curso.
  Future<List<_Medicion>>? _enCurso;

  /// De la más reciente a la más vieja.
  Future<List<_Medicion>> _mediciones() => _enCurso ??= _http
      .get('/mi/mediciones', query: {'limite': '50'})
      .then((json) => [for (final m in json['data'] as List) _Medicion(m as Map<String, dynamic>)])
      .whenComplete(() => _enCurso = null);

  @override
  Future<List<BodyMetric>> getBodyMetrics() async {
    final cronologico = (await _mediciones()).reversed.toList();
    return [
      _metrica(cronologico, 'Peso corporal', 'kg', 1, (m) => m.peso),
      _metrica(cronologico, 'Grasa corporal', '%', 1, (m) => m.grasa),
      _metrica(cronologico, 'Masa muscular', 'kg', 1, (m) => m.musculo),
      _metrica(cronologico, 'Grasa visceral', 'nivel', 0, (m) => m.visceral),
    ].whereType<BodyMetric>().toList();
  }

  /// null si ninguna medición trae ese dato.
  BodyMetric? _metrica(
    List<_Medicion> cronologico,
    String label,
    String unit,
    int decimals,
    double? Function(_Medicion) valor,
  ) {
    final conDato = [for (final m in cronologico) if (valor(m) != null) m];
    if (conDato.isEmpty) return null;
    final valores = [for (final m in conDato) valor(m)!];
    final recientes = conDato.length > _puntos ? conDato.sublist(conDato.length - _puntos) : conDato;

    return BodyMetric(
      label: label,
      unit: unit,
      value: valores.last,
      decimals: decimals,
      changeSinceStart: _cambio(valores.last - valores.first, unit, decimals),
      changeVsPrevious: valores.length < 2 ? 'Sin cambio' : _cambio(valores.last - valores[valores.length - 2], unit, decimals),
      history: [for (final m in recientes) valor(m)!],
      historyLabels: [for (final m in recientes) mesCorto(m.fecha)],
    );
  }

  @override
  Future<List<Measurement>> getMeasurementHistory({int limit = 20, String? cursor}) async => [
        for (final m in await _mediciones())
          Measurement(
            date: fechaCorta(m.fecha),
            weight: _texto(m.peso, ' kg', 1),
            bodyFat: _texto(m.grasa, '%', 1),
            muscle: _texto(m.musculo, ' kg', 1),
            visceral: _texto(m.visceral, '', 0),
          ),
      ];

  @override
  Future<InbodySummary> getInbodySummary() async {
    final lista = await _mediciones();
    if (lista.isEmpty) return InbodySummary.empty;
    final m = lista.first;

    return InbodySummary(
      items: [
        if (m.imc != null) InbodyItem(label: 'IMC', value: m.imc!.toStringAsFixed(1), hint: _categoriaImc(m.imc!), ratio: m.imc! / 40),
        if (m.grasa != null)
          InbodyItem(label: 'Grasa corporal', value: '${m.grasa!.toStringAsFixed(1)}%', hint: 'Del peso total', ratio: m.grasa! / 50),
        if (m.musculo != null && m.peso != null)
          InbodyItem(
            label: 'Masa muscular',
            value: '${m.musculo!.toStringAsFixed(1)} kg',
            hint: '${(m.musculo! / m.peso! * 100).toStringAsFixed(1)}% del peso',
            ratio: m.musculo! / m.peso!,
          ),
        if (m.visceral != null)
          InbodyItem(
            label: 'Grasa visceral',
            value: 'Nivel ${m.visceral!.toStringAsFixed(0)}',
            hint: m.visceral! <= 9 ? 'Rango saludable' : 'Por encima de lo recomendado',
            ratio: m.visceral! / 20,
          ),
      ],
      extras: [
        if (m.estatura != null) InbodyExtra(label: 'Estatura', value: '${m.estatura!.toStringAsFixed(0)} cm'),
        if (m.edad != null) InbodyExtra(label: 'Edad', value: '${m.edad} años'),
        if (m.frecuencia != null) InbodyExtra(label: 'Entrenamientos por semana', value: '${m.frecuencia}'),
        if (m.actividad != null) InbodyExtra(label: 'Nivel de actividad', value: m.actividad!),
        if (m.objetivo != null) InbodyExtra(label: 'Objetivo', value: m.objetivo!),
      ],
    );
  }

  static String _texto(double? v, String unidad, int decimales) =>
      v == null ? '—' : '${v.toStringAsFixed(decimales)}$unidad';

  static String _cambio(double d, String unit, int decimals) {
    final abs = d.abs().toStringAsFixed(decimals);
    final signo = d > 0 ? '+' : (d < 0 ? '-' : '');
    final sufijo = switch (unit) {
      '%' => '%',
      'nivel' => (d.abs() == 1 ? ' nivel' : ' niveles'),
      _ => ' $unit',
    };
    return '$signo$abs$sufijo';
  }

  static String _categoriaImc(double imc) => imc < 18.5
      ? 'Bajo peso'
      : imc < 25
          ? 'Rango saludable'
          : imc < 30
              ? 'Sobrepeso'
              : 'Obesidad';
}
