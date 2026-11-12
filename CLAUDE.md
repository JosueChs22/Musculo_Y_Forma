# Músculo y Forma (GMYF) · Reglas del proyecto

App para gimnasio: **Flutter** (móvil y web) + **API** propia + **MongoDB** (base `gimnasio`, script en `database/gimnasio_init.js`).
Estas reglas son obligatorias en todo código nuevo o modificado. Si una regla no se puede cumplir, se deja anotado el motivo en el PR o en un comentario `// REGLA: ...`.

Cada regla indica dónde aplica: **[App]** Flutter · **[API]** backend · **[BD]** MongoDB · **[Web]** build web de Flutter / sitio.

---

## 0. Arquitectura: Modelo · Servicio · Controlador · Vista

Todo el código se organiza en cuatro capas, tanto en la app como en la API. Cada capa solo habla con la de abajo: **Vista → Controlador → Servicio → (API / BD)**. Los **Modelos** los usan todas las capas.

| Capa | Responsabilidad | NO debe |
|---|---|---|
| **Modelo** | Clases de datos: campos, `fromJson`/`toJson`, validaciones simples y valores derivados (`initials`, `firstName`). Inmutables (`final`, `copyWith`). | Hacer llamadas HTTP, acceder a la BD o conocer widgets. |
| **Servicio** | Acceso a datos y lógica de negocio: llamadas a la API (app) o a MongoDB (API), caché, timeouts, paginación, reglas del negocio. Se define con una interfaz (`abstract class`) para poder cambiar la implementación real por un mock. | Conocer widgets, `BuildContext`, `req`/`res` ni detalles de la pantalla. |
| **Controlador** | Estado y acciones de una pantalla o funcionalidad: llama a los servicios, maneja carga, error y actualización optimista, y expone el estado a la vista. | Construir widgets, ni hacer HTTP o consultas a la BD directamente (eso es del servicio). |
| **Vista** | Solo presentación: pinta el estado del controlador (incluidos los skeletons) y le pasa los eventos del usuario. | Tener lógica de negocio, llamar servicios o hacer HTTP. |

**En la app (Flutter)**, por funcionalidad:

```
lib/
  core/                      tema, widgets compartidos (skeletons, botones), utilidades
  features/
    rutinas/
      models/                routine.dart, exercise.dart
      services/              rutinas_service.dart (interfaz) + rutinas_api_service.dart + rutinas_mock_service.dart
      controllers/           rutinas_controller.dart (ChangeNotifier)
      views/                 rutinas_view.dart + widgets/ propios de la pantalla
    progreso/ · coach/ · inicio/ · perfil/ · auth/   (misma estructura)
  app.dart · main.dart       rutas e inyección de dependencias (Provider)
```

- Un controlador por funcionalidad (no un estado global único). Las vistas leen solo lo que usan con `context.select` / `Selector` (regla 3).
- Los servicios se inyectan en los controladores por constructor desde `main.dart`; cambiar de mock a API real es cambiar una línea ahí.

**En la API (backend)**, por recurso:

```
src/
  models/          esquemas y validación (usuario, rutina, medicion...)
  services/        lógica de negocio y consultas a MongoDB (con projection, índices, caché)
  controllers/     reciben req, validan entrada, llaman al servicio y arman la respuesta
  views/           serializadores / DTO de respuesta: definen exactamente qué campos salen (nunca `contrasena`)
  routes/          rutas HTTP + middlewares (auth, roles, rate limit) que apuntan a los controladores
  config/          conexión a BD (pool), Redis, variables de entorno
```

- Los controladores no tocan la BD; los servicios no tocan `req`/`res`; las vistas (DTO) son la única forma de devolver datos al cliente.

## 1. Experiencia de carga

1. **Skeleton de carga** [App] — Toda pantalla o sección que espera datos muestra un *skeleton* con la forma del contenido final (tarjetas, filas, textos grises animados). No se usan spinners (`CircularProgressIndicator`) a pantalla completa; solo se permiten dentro de botones mientras se envía una acción.
2. **Actualización optimista** [App] — Acciones del usuario (marcar ejercicio, asignar rutina, agendar cita, etc.) actualizan la interfaz de inmediato y se confirman con el servidor en segundo plano. Si el servidor falla, se revierte el cambio y se avisa con un mensaje claro.
3. **Evitar re-renders innecesarios** [App] — Usar constructores `const`, `Selector`/`context.select` de Provider en lugar de escuchar todo el estado, separar widgets grandes en widgets pequeños, y `RepaintBoundary` donde haya animaciones. No llamar a la API ni crear objetos pesados dentro de `build()`.
4. **Virtualizar listas largas** [App] — Cualquier lista que pueda crecer (clientes, ejercicios, historial de mediciones, citas, anuncios) usa `ListView.builder` / `SliverList` / `GridView.builder`. Prohibido `Column(children: lista.map(...))` para listas de datos.

## 2. Imágenes y fuentes

5. **Imágenes en WebP o AVIF** [App][API][Web] — Solo cuando haya imágenes (ejercicios, máquinas, anuncios). Los assets se guardan en WebP (AVIF opcional en web). Las imágenes que suban los usuarios se convierten a WebP en el servidor y se guardan en varios tamaños (miniatura y completa).
6. **Lazy loading de imágenes** [App][Web] — Las imágenes fuera de pantalla no se descargan hasta que se van a mostrar (`ListView.builder` + `Image.network` con `cacheWidth`/`cacheHeight`, o `cached_network_image`). Siempre con un placeholder del tamaño final para que el layout no salte.
7. **Fuentes alojadas y pocos grosores** [App][Web] — Las fuentes se incluyen como archivos dentro del proyecto (`assets/fonts/`, declaradas en `pubspec.yaml`); no se descargan en tiempo de ejecución de Google Fonts. Máximo **2 familias** y **3 grosores** en total (por ejemplo, 400, 600 y 800).

## 3. Llamadas a la API (desde la app)

8. **Sin llamadas duplicadas** [App] — *Se aplica cuando la API exista.* Una misma petición en curso no se repite: los servicios guardan la petición pendiente (`Future` compartido) y una caché en memoria de corta duración. Los botones que disparan peticiones se deshabilitan mientras se procesan.
9. **Debounce en búsqueda y autocompletado** [App] — Todo campo que busca mientras se escribe espera **300 ms** sin teclear antes de llamar a la API, cancela la búsqueda anterior y no busca con menos de 2 caracteres.
10. **Peticiones independientes en paralelo** [App][API] — Si dos o más datos no dependen entre sí, se piden al mismo tiempo (`Future.wait` en Dart, `Promise.all` o equivalente en la API). Nunca en cadena con `await` uno tras otro.
11. **Timeout a las APIs externas** [App][API] — Toda llamada HTTP tiene timeout: **10 s** de la app a nuestra API y **5 s** de la API a servicios externos (correo, pagos, etc.), con un reintento como máximo y un mensaje de error comprensible.

## 4. API (backend)

12. **Paginar resultados** [API] — Todo endpoint que devuelve listas es paginado (`?limite=20&cursor=...`, máximo 100 por página). Se prefiere paginación por cursor (`_id` o fecha) sobre `skip`. La respuesta incluye el siguiente cursor.
13. **Cola de trabajos para tareas lentas** [API] — Envío de correos (recuperación de contraseña, avisos), procesamiento de imágenes, reportes y notificaciones se mandan a una cola de trabajos (por ejemplo BullMQ sobre Redis). El endpoint responde de inmediato.
14. **Compresión Brotli / Gzip** [API][Web] — Las respuestas de la API y los archivos del build web se sirven comprimidos con Brotli y, si el cliente no lo soporta, con Gzip.
15. **Caché con Redis** [API] — Los datos más consultados y que cambian poco (catálogo de ejercicios, máquinas, clases y horarios, anuncios activos, roles) se cachean en Redis con un TTL definido, y la caché se invalida cuando se modifican. **Nunca** se cachean en Redis datos personales o de salud sin cifrar.
16. **Pool de conexiones** [API][BD] — Una sola instancia del cliente de MongoDB para toda la API, con pool configurado (`maxPoolSize`, `minPoolSize`, `maxIdleTimeMS`). Prohibido abrir y cerrar una conexión por petición.
17. **Estáticos con caché en el navegador** [API][Web] — Archivos con hash en el nombre (JS, CSS, fuentes, imágenes del build) con `Cache-Control: public, max-age=31536000, immutable`. El `index.html` y las respuestas de la API con `no-cache`.

## 5. Base de datos (MongoDB)

18. **Corregir consultas N+1** [API][BD] — No consultar dentro de un ciclo. Para traer datos relacionados (el coach de cada cliente, los ejercicios de una rutina) se usa `$in` con todos los IDs de una vez o `$lookup` en un *aggregation pipeline*.
19. **Índices para las consultas más comunes** [BD] — Cada consulta frecuente nueva debe tener un índice que la cubra; se agrega al script `database/gimnasio_init.js` y se revisa con `explain()` (que use `IXSCAN`, no `COLLSCAN`).
20. **Pedir solo los campos necesarios** [API][BD] — Toda consulta lleva *projection*. Nunca se devuelven campos sensibles como `contrasena` o `historial_cambios`, ni datos que la pantalla no usa.

## 6. Web y dependencias

21. **Renderizar en el servidor o en el build** [Web] — Las páginas públicas (sitio del gym, landing) se generan en el build o en el servidor para que carguen rápido y sean indexables. La app Flutter web se compila en modo release (`flutter build web --release`).
22. **Scripts de terceros después de la página** [Web] — Analítica, chats, mapas y similares se cargan con `defer`/`async` o después del evento `load`, nunca bloqueando el render inicial.
23. **Quitar dependencias sin usar** [App][API] — Antes de cada entrega se revisan `pubspec.yaml` y `package.json`, y se elimina lo que no se use. Antes de agregar una dependencia nueva hay que justificarla.

## 7. Seguridad y datos personales (ISO/IEC 27001 / 27701)

- La app nunca se conecta directo a MongoDB: todo pasa por la API. Las credenciales viven en `.env` del servidor (fuera de git).
- Contraseñas y códigos de recuperación se guardan con hash (argon2id o bcrypt).
- Autenticación con tokens de corta duración + refresh token; los tokens en la app se guardan en almacenamiento seguro (`flutter_secure_storage`).
- Control de acceso por rol (Administrador, Secretaria, Entrenador, Cliente) validado en la API, no solo en la app.
- Validar y sanear toda entrada; limitar intentos de login (rate limiting); HTTPS obligatorio.
- Los datos de salud (`mediciones`) son sensibles: acceso mínimo necesario y registro de quién los consulta o modifica.

---

## Estado de cumplimiento (actualizado 2026-11-08)

**Resuelto en la migración a `features/` + Dirección B:**
- Regla 0: app reorganizada en `lib/features/{inicio,rutinas,progreso,coach,perfil}/{models,services,controllers,views}`, un controlador por funcionalidad (`BaseController` en `core/`). Servicios con interfaz + implementación mock, inyectados en `main.dart` (`AppServices`).
- Regla 1: skeletons en todas las vistas (`core/skeleton.dart`); sin spinners de pantalla completa.
- Regla 2: asignación de rutina del coach con actualización optimista y reversión si falla.
- Regla 3: vistas con `context.select` por dato; router creado una sola vez.
- Regla 4: listas que crecen con `SliverList.builder` / `ListView.builder` (ejercicios, historial, clientes, resultados de búsqueda). Conjuntos acotados marcados con comentario `REGLA 4`.
- Regla 7: fuentes locales en `assets/fonts/` (Barlow Condensed 800, Barlow 400 y 600). Se quitó `google_fonts`.
- Regla 8: `BaseController.load()` reutiliza la carga en curso.
- Regla 9: búsqueda de ejercicios en el panel del coach con debounce de 300 ms y mínimo 2 letras.
- Regla 10: cargas con `Future.wait` / `(…).wait` y controladores que cargan en paralelo.
- Regla 12: las interfaces de servicio ya reciben `limit` / `cursor`.
- Identidad visual: Dirección B · Índigo Atlético (`core/theme.dart`, emblema GMYF en `core/brand.dart`).

**Pendiente:**
- Verificar en una máquina con Flutter: `flutter pub get`, `flutter analyze` y `flutter test` (la migración se escribió sin poder compilar en el entorno de Claude).
- Reglas 5, 6, 8 (en red), 11 a 20: se aplican al construir la API y los servicios reales (`*_api_service.dart`).
- Pantalla de Perfil sigue siendo placeholder.
