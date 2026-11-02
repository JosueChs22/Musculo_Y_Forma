class Client {
  const Client({required this.id, required this.name, required this.goal});

  final String id;
  final String name;
  final String goal;

  String get initials => name
      .split(' ')
      .where((p) => p.isNotEmpty)
      .take(2)
      .map((p) => p[0])
      .join()
      .toUpperCase();

  factory Client.fromJson(Map<String, dynamic> json) => Client(
        id: json['_id'] as String,
        name: json['name'] as String,
        goal: json['goal'] as String,
      );
}

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

  String get coachInitials => coachName
      .split(' ')
      .where((p) => p.isNotEmpty)
      .take(2)
      .map((p) => p[0])
      .join()
      .toUpperCase();
}
