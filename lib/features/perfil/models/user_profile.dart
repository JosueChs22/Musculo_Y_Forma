/// Perfil del socio que usa la app.
class UserProfile {
  const UserProfile({
    required this.name,
    required this.coachName,
    required this.goal,
    required this.streakDays,
    required this.currentWorkout,
    required this.weekLabel,
    required this.lastMeasurementLabel,
  });

  final String name;
  final String coachName;
  final String goal;
  final int streakDays;
  final String currentWorkout;
  final String weekLabel;
  final String lastMeasurementLabel;

  static const empty = UserProfile(
    name: '',
    coachName: '',
    goal: '',
    streakDays: 0,
    currentWorkout: '',
    weekLabel: '',
    lastMeasurementLabel: '',
  );

  String get firstName => name.split(' ').first;
  String get initials => _initials(name);
  String get coachInitials => _initials(coachName);

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        name: json['name'] as String,
        coachName: json['coachName'] as String,
        goal: json['goal'] as String,
        streakDays: (json['streakDays'] as num).toInt(),
        currentWorkout: json['currentWorkout'] as String,
        weekLabel: json['weekLabel'] as String,
        lastMeasurementLabel: json['lastMeasurementLabel'] as String,
      );
}

String _initials(String fullName) => fullName
    .split(' ')
    .where((p) => p.isNotEmpty)
    .take(2)
    .map((p) => p[0])
    .join()
    .toUpperCase();
