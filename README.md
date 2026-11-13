# Músculo y Forma (GMYF) · App Flutter

App de rutinas para gimnasio en Flutter (web, Android, iOS y escritorio).
Consume la API de producción en Render, que vive en su propio repo privado **`GYM-API`**
(Node.js + Express + MongoDB Atlas):

`https://musculo-y-forma.onrender.com/api`

## Cómo correrla

```bash
flutter pub get
flutter run -d chrome          # o un emulador / dispositivo / escritorio
```

Por defecto usa la API de producción. Para probar contra una API local (ver README de `GYM-API`):

```bash
flutter run -d chrome --dart-define=API_BASE=http://localhost:3000/api
```

## Pantallas y roles

- **Todos**: Inicio, Rutinas (las asignadas al usuario), Progreso (sus mediciones) y Perfil.
- **Entrenador**: además, el panel de coach (`/coach`): catálogo de ejercicios con imagen y GIF, armar planes y asignarlos a un cliente buscándolo por nombre.
- **Secretaria**: además, el panel de clases (`/secretaria`).
- **Administrador**: todo, más la gestión de usuarios (`/admin`).

La sesión se guarda de forma segura y se restaura al abrir la app. Los permisos por rol están en `lib/core/permisos.dart`.

## Arquitectura (Modelo · Servicio · Controlador · Vista)

```
lib/
  core/        tema, widgets, skeletons, cliente HTTP (api_http), sesión, permisos, shell de navegación
  features/    auth, inicio, rutinas, progreso, perfil, ejercicios, planes, secretaria, admin
  app.dart     rutas (go_router) con guardia por rol
  main.dart    inyección de servicios y controladores (Provider)
```

Reglas del proyecto: ver `CLAUDE.md`.
