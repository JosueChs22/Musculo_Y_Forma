import '../models/user_profile.dart';
import 'perfil_service.dart';

class PerfilMockService implements PerfilService {
  const PerfilMockService({this.latency = const Duration(milliseconds: 250)});
  final Duration latency;

  @override
  Future<UserProfile> getProfile() => Future.delayed(
        latency,
        () => const UserProfile(
          name: 'Alex Rivera',
          coachName: 'Carlos Méndez',
          goal: 'Reducir grasa y ganar fuerza',
          streakDays: 12,
          currentWorkout: 'Empuje: pecho y tríceps',
          weekLabel: 'Semana 3',
          lastMeasurementLabel: 'Última medición · 18 mayo',
        ),
      );
}
