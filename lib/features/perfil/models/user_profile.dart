import '../../../core/fechas.dart';

/// Perfil del usuario con sesión: su nombre, su coach, su objetivo y su última medición.
/// Los datos de la cuenta (rol, correo, teléfono) vienen de la sesión (AuthController).
class UserProfile {
  const UserProfile({
    required this.name,
    this.coachName,
    this.goal,
    this.lastMeasurement,
    this.streakDays = 0,
  });

  final String name;

  /// null si todavía no tiene coach.
  final String? coachName;

  /// Objetivo registrado en su última medición, o null.
  final String? goal;
  final DateTime? lastMeasurement;

  /// Días seguidos entrenando. Aún no se registra en la API: queda en 0 y no se muestra.
  final int streakDays;

  static const empty = UserProfile(name: '');

  String get firstName => name.split(' ').first;
  String get initials => _initials(name);
  String get coachInitials => _initials(coachName ?? '');

  /// "Última medición · 9 nov", o null si no tiene mediciones.
  String? get lastMeasurementLabel =>
      lastMeasurement == null ? null : 'Última medición · ${diaMes(lastMeasurement!)}';

  /// Desde GET /mi/perfil.
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final u = json['usuario'] as Map<String, dynamic>;
    final coach = json['coach'] as Map<String, dynamic>?;
    return UserProfile(
      name: [u['nombre'], u['primerApellido'], u['segundoApellido']]
          .whereType<String>()
          .where((s) => s.isNotEmpty)
          .join(' '),
      coachName: coach?['nombre'] as String?,
      goal: json['objetivo'] as String?,
      lastMeasurement: json['ultimaMedicion'] == null ? null : DateTime.parse(json['ultimaMedicion'] as String),
    );
  }
}

String _initials(String fullName) => fullName
    .split(' ')
    .where((p) => p.isNotEmpty)
    .take(2)
    .map((p) => p[0])
    .join()
    .toUpperCase();
