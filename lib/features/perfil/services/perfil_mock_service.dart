import '../models/user_profile.dart';
import 'perfil_service.dart';

class PerfilMockService implements PerfilService {
  const PerfilMockService({this.latency = const Duration(milliseconds: 250)});
  final Duration latency;

  @override
  Future<UserProfile> getProfile() => Future.delayed(
        latency,
        () => UserProfile(
          name: 'Alex Rivera',
          coachName: 'Carlos Méndez',
          goal: 'Reducir grasa y ganar fuerza',
          lastMeasurement: DateTime(2026, 5, 18),
        ),
      );
}
