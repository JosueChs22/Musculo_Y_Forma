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
- **Panel coach** (`/coach`): menú de Planes, Ejercicios, Citas, Mediciones e
  Historial; gestión de planes, catálogo de ejercicios y consulta diaria de
  citas asignadas al entrenador conectado. En Citas también se puede buscar por
  carné o nombre y ver solo la cita más reciente de cada cliente coincidente.
  Mediciones registra sus datos corporales; Historial consulta todas sus
  mediciones desde la más reciente, separadas por estado. Permite habilitar o
  inhabilitar desde la lista y editar los datos agrupados sin alterar su fecha.
  La comparación usa las dos mediciones activas más recientes e indica valores,
  diferencia absoluta y variación porcentual sin interpretar los cambios. La
  diferencia es la magnitud sin signo; la variación se calcula como
  `(actual - anterior) / anterior × 100` y no se calcula si el anterior es cero
  o falta uno de los valores. Para grasa corporal, la diferencia se expresa en
  puntos porcentuales. La vista secundaria de evolución consulta todas las
  páginas del historial activo al abrirla y permite actualizarlo manualmente.
  El rango personalizado se limita a las fechas de la primera y última medición
  activa; los períodos rápidos se cuentan desde la fecha actual.
  Permite filtrar por fechas, visualizar gráficos por categoría y comparar el
  primer y último valor disponible de cada indicador en el período; con un único
  valor no se calcula el cambio.
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

## Publicar la versión web

La política de seguridad de contenido (CSP) no va en `web/index.html` porque bloquea el modo debug de `flutter run`.
Al publicar `build/web`, configúrala como **cabecera** del servidor (también permite agregar `frame-ancestors 'none'`):

```
Content-Security-Policy: default-src 'self'; script-src 'self' 'wasm-unsafe-eval' https://www.gstatic.com; style-src 'self' 'unsafe-inline'; img-src 'self' data: blob: https:; font-src 'self' data: https://fonts.gstatic.com; connect-src 'self' https: http://localhost:* http://127.0.0.1:*; worker-src 'self' blob:; object-src 'none'; base-uri 'self'; form-action 'none'; frame-ancestors 'none'
```

## Publicar en tiendas

- **Identificador de la app:** `com.musculoyforma.app` (Android, iOS, macOS y Linux).
- **Llave de subida (Android):** vive fuera del repo en `C:\Users\josue\.android-keys\gmyf-upload.jks` (alias `gmyf`), junto con una copia de `key.properties`.
- **Haz respaldo** del `.jks` y de sus contraseñas en un lugar seguro (gestor de contraseñas, USB cifrada). Si se pierde, no se podrán publicar actualizaciones de la app en Google Play.
- `android/key.properties` **no está en git** (ver `android/.gitignore`). Sin ese archivo, el build de release se firma con la llave debug, así que sirve para probar pero no para subir a Play.
- Generar el paquete para Google Play:

  ```bash
  flutter build appbundle --release
  ```

  El archivo queda en `build/app/outputs/bundle/release/app-release.aab`.
