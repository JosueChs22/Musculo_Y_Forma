const _meses = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];

/// "9 nov 2026"
String fechaCorta(DateTime d) {
  final l = d.toLocal();
  return '${l.day} ${_meses[l.month - 1]} ${l.year}';
}

/// "9 nov"
String diaMes(DateTime d) {
  final l = d.toLocal();
  return '${l.day} ${_meses[l.month - 1]}';
}

/// "Nov"
String mesCorto(DateTime d) {
  final m = _meses[d.toLocal().month - 1];
  return m[0].toUpperCase() + m.substring(1);
}
