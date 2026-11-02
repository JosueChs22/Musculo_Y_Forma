import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'repositories/mock_gym_repository.dart';
import 'state/app_state.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      // Cuando exista la API, cambia MockGymRepository() por ApiGymRepository().
      create: (_) => AppState(MockGymRepository())..load(),
      child: const PulsoApp(),
    ),
  );
}
