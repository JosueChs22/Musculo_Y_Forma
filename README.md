# PULSO · Prototipo Flutter

Prototipo de la app de rutinas para gimnasio (diseño de Figma Make), con datos de ejemplo.
Stack objetivo: **Flutter + API + MongoDB** (la API y la base de datos aún no están conectadas).

## Cómo correrlo

```bash
cd pulso_app
flutter create . --project-name pulso_app   # genera android/ios/web (no se incluyen en el zip)
flutter pub get
flutter run -d chrome                        # o un emulador / dispositivo
```

## Pantallas
- **Inicio** (`/`): rutina asignada, coach, última evaluación, rutina semanal.
- **Rutinas** (`/rutinas`): lista de rutinas + detalle de ejercicios.
- **Progreso** (`/progreso`): métricas, gráfica de evolución, resumen InBody, historial.
- **Panel coach** (`/coach`): elegir cliente, armar y asignar rutina.
- **Perfil** (`/perfil`): placeholder (no estaba en el diseño).

Responsivo: barra lateral en pantallas anchas (≥1000 px), barra inferior en móvil.

## Arquitectura

```
lib/
  core/          tema y widgets compartidos
  models/        Exercise, Routine, BodyMetric, Client... (fromJson/toJson listos)
  repositories/  GymRepository (interfaz) + MockGymRepository (datos de ejemplo)
  state/         AppState (Provider)
  screens/       una pantalla por archivo + shell de navegación
  widgets/       diálogos reutilizables
```

## Conectar la API con MongoDB después
1. Crear `ApiGymRepository implements GymRepository` (con `http` o `dio`).
2. En `main.dart`, cambiar `MockGymRepository()` por `ApiGymRepository()`.
3. Las pantallas no cambian. Los modelos ya leen `_id` como `String`
   (serializa el ObjectId como string en la API).
4. Pendiente en el mock: resumen InBody (`progress_screen.dart`), guardado de
   `assignRoutine` y autenticación/roles usuario-coach.
