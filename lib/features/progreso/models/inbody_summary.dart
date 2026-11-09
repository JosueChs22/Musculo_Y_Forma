/// Resumen de composición corporal (InBody).
class InbodySummary {
  const InbodySummary({required this.items, required this.extras});

  final List<InbodyItem> items;
  final List<InbodyExtra> extras;

  static const empty = InbodySummary(items: [], extras: []);

  factory InbodySummary.fromJson(Map<String, dynamic> json) => InbodySummary(
        items: (json['items'] as List)
            .map((e) => InbodyItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        extras: (json['extras'] as List)
            .map((e) => InbodyExtra.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class InbodyItem {
  const InbodyItem({required this.label, required this.value, required this.hint, required this.ratio});

  final String label;
  final String value;
  final String hint;

  /// Proporción de 0 a 1 para la barra.
  final double ratio;

  factory InbodyItem.fromJson(Map<String, dynamic> json) => InbodyItem(
        label: json['label'] as String,
        value: json['value'] as String,
        hint: json['hint'] as String,
        ratio: (json['ratio'] as num).toDouble(),
      );
}

class InbodyExtra {
  const InbodyExtra({required this.label, required this.value});

  final String label;
  final String value;

  factory InbodyExtra.fromJson(Map<String, dynamic> json) => InbodyExtra(
        label: json['label'] as String,
        value: json['value'] as String,
      );
}
