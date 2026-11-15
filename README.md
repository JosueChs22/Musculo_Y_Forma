# Músculo y Forma (GMYF) · App Flutter

Aplicación Flutter conectada a la API Node.js + MongoDB del proyecto hermano
[`GYM-API`](../GYM-API/README.md). Por defecto usa la API desplegada en Render.

## Cómo correrla

Desde esta carpeta:

```bash
flutter pub get
flutter run -d chrome
```

Para usar una copia local de [`GYM-API`](../GYM-API/README.md), inicia el backend
desde la carpeta hermana `GYM-API` (no desde `Musculo_Y_Forma\api`, que no
incluye las rutas de citas):

```bash
# Terminal 1
cd ..\GYM-API
npm run dev

# Terminal 2, desde Musculo_Y_Forma
flutter run -d chrome --dart-define=API_BASE=http://localhost:3000/api
```

En un emulador Android, usa la dirección del host accesible desde el emulador en
lugar de `localhost` (por ejemplo, `http://10.0.2.2:3000/api`).

La URL se puede cambiar con `--dart-define=API_BASE=...`; no se guardan secretos
ni credenciales de MongoDB en la aplicación.

## Pantallas
- **Inicio** (`/`): rutina asignada, coach, última evaluación, rutina semanal.
- **Rutinas** (`/rutinas`): lista de rutinas + detalle de ejercicios.
- **Progreso** (`/progreso`): métricas, gráfica de evolución, resumen InBody, historial.
- **Panel coach** (`/coach`): elegir cliente, armar y asignar rutina.
- **Panel Secretaría** (`/secretaria`): horarios, clientes, agendamiento,
  consulta diaria de citas por entrenador con búsqueda por carné o nombre del
  cliente, modificación de entrenador/fecha/hora y cambio independiente entre
  los estados Agendada y Cancelada.
- **Perfil** (`/perfil`): placeholder (no estaba en el diseño).

Responsivo: barra lateral en pantallas anchas (≥1000 px), barra inferior en móvil.

## Funcionalidades conectadas

La aplicación consume inicio de sesión/restauración de sesión, perfil, rutinas,
mediciones, ejercicios, planes, clases, clientes, citas y administración de usuarios.
Las peticiones protegidas envían el token JWT guardado en almacenamiento seguro.

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
