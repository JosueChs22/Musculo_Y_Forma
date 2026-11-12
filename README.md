# Músculo y Forma (GMYF) · App Flutter

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

## Arquitectura (Modelo · Servicio · Controlador · Vista)

```
lib/
  core/        tema (Dirección B), widgets compartidos, skeletons, emblema GMYF, debouncer, BaseController, shell de navegación
  features/
    inicio/    views/
    rutinas/   models/ services/ controllers/ views/
    progreso/  models/ services/ controllers/ views/
    coach/     models/ services/ controllers/ views/
    perfil/    models/ services/ controllers/ views/
  app.dart     rutas (go_router)
  main.dart    inyección de servicios y controladores (Provider)
assets/fonts/  Barlow y Barlow Condensed (fuentes locales)
```

Reglas completas del proyecto: ver `CLAUDE.md`.

## Conectar la API con MongoDB después
1. Por cada funcionalidad, crear `*_api_service.dart` que implemente la interfaz `*_service.dart` (con `http` o `dio`, timeout de 10 s).
2. En `main.dart`, pasar los servicios reales en `AppServices(...)` en lugar de los Mock.
3. Las vistas y controladores no cambian. Los modelos ya leen `_id` como `String`.
