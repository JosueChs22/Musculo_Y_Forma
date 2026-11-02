class BodyMetric {
  const BodyMetric({
    required this.label,
    required this.unit,
    required this.value,
    required this.decimals,
    required this.changeSinceStart,
    required this.changeVsPrevious,
    required this.history,
  });

  final String label;
  final String unit;
  final double value;
  final int decimals;
  final String changeSinceStart;
  final String changeVsPrevious;
  final List<double> history;

  String get valueLabel => value.toStringAsFixed(decimals);
  String get displayValue => unit == '%' ? '$valueLabel%' : '$valueLabel $unit';

  factory BodyMetric.fromJson(Map<String, dynamic> json) => BodyMetric(
        label: json['label'] as String,
        unit: json['unit'] as String,
        value: (json['value'] as num).toDouble(),
        decimals: (json['decimals'] as num?)?.toInt() ?? 1,
        changeSinceStart: json['changeSinceStart'] as String,
        changeVsPrevious: json['changeVsPrevious'] as String,
        history: (json['history'] as List).map((e) => (e as num).toDouble()).toList(),
      );
}

class Measurement {
  const Measurement({
    required this.date,
    required this.weight,
    required this.bodyFat,
    required this.muscle,
    required this.visceral,
  });

  final String date;
  final String weight;
  final String bodyFat;
  final String muscle;
  final String visceral;

  factory Measurement.fromJson(Map<String, dynamic> json) => Measurement(
        date: json['date'] as String,
        weight: json['weight'] as String,
        bodyFat: json['bodyFat'] as String,
        muscle: json['muscle'] as String,
        visceral: json['visceral'] as String,
      );
}
