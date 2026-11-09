/// Socio asignado a un coach.
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
