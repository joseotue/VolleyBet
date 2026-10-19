---
title: 'Setup inicial de Flutter, Tema Anime M3, Supabase Auth y AuthGate'
type: 'feature'
created: '2026-10-18'
status: 'done'
baseline_commit: 'bc4e044e27310ac7a1b54776c6b3b50799603c06'
route: 'dispatch'
review_loop_iteration: 0
context:
  - '{project-root}/docs/SUPABASE_CONFIG.md'
  - '{project-root}/docs/HISTORIAS_DE_USUARIO.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** El proyecto VolleyBet no cuenta con la estructura base de Flutter ni con el sistema de autenticación y tematización obligatorio para comenzar el desarrollo del MVP y satisfacer la pauta docente UDD.

**Approach:** Inicializar el proyecto Flutter con soporte móvil y web en una arquitectura limpia en 3 capas, configurar el tema visual Anime Material 3 (`#1B1F29` / `#FF6A1A`), conectar el cliente `supabase_flutter` con variables de entorno, e implementar un `AuthGate` reactivo junto a una pantalla de login con soporte para credenciales estándar y selector de acceso rápido para los 3 perfiles del equipo (Lucas, Otue y Jesús).

## Boundaries & Constraints

**Always:**
- Utilizar Flutter con Material 3 (`useMaterial3: true`), paleta oficial (fondo oscuro `#1B1F29`, tarjetas `#262B38`, acento naranja `#FF6A1A`).
- Organizar el código bajo la arquitectura en 3 capas dentro de `lib/`: `models/`, `services/`, `screens/`, `widgets/`, `providers/`.
- Proteger las rutas principales mediante `AuthGate` escuchando el stream de sesión de Supabase Auth (`onAuthStateChange`).
- Proveer acceso rápido a los 3 perfiles sembrados del equipo para facilitar la evaluación sin ingreso manual tedioso de credenciales.
- Cargar las credenciales de Supabase exclusivamente desde variables de entorno (`.env` mediante `flutter_dotenv`).

**Never:**
- No exponer la `Secret Key` (Service Role) en el cliente Flutter bajo ninguna circunstancia.
- No hardcodear claves o URLs de Supabase directamente en el código fuente.
- No incluir aún lógica de apuestas o partidos reales (eso corresponde a las historias 1.2 y 1.3).

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| App inicia sin sesión | No existe sesión activa en Supabase | `AuthGate` redirige inmediatamente a `LoginScreen` | N/A |
| Login con credenciales válidas | Email y contraseña correctos | Sesión creada, `AuthGate` transiciona a `HomeScreen` | N/A |
| Login con credenciales incorrectas | Email o contraseña inválidos | Muestra SnackBar de error con mensaje claro | No navega, limpia campo de contraseña |
| Acceso rápido de equipo | Presionar chip/botón de Lucas, Otue o Jesús | Autenticación automática del perfil seleccionado y transición al Home | Si falla la autenticación remota, reportar error en SnackBar |
| Cierre de sesión (Sign Out) | Clic en "Cerrar Sesión" en Home | Invocación de `supabase.auth.signOut()`, retorno inmediato a `LoginScreen` | N/A |

</frozen-after-approval>

## Code Map

- `pubspec.yaml` -- Configuración del proyecto Flutter y dependencias (`supabase_flutter`, `flutter_dotenv`, `google_fonts`).
- `lib/main.dart` -- Punto de entrada de la aplicación, inicialización de dotenv, Supabase y configuración de `MaterialApp`.
- `lib/theme/app_theme.dart` -- Definición del tema Material 3 anime (ColorScheme oscuro, tipografía y estilos de botones).
- `lib/services/supabase_service.dart` -- Singleton/wrapper para el cliente Supabase y helpers de autenticación.
- `lib/screens/auth/auth_gate.dart` -- Widget guardián basado en StreamBuilder escuchando cambios de sesión (`onAuthStateChange`).
- `lib/screens/auth/login_screen.dart` -- Pantalla de Login con formulario validado y selector rápido de los 3 perfiles del equipo.
- `lib/screens/home/home_screen.dart` -- Vista inicial protegida temporal para verificar login exitoso, usuario actual y botón de logout.

## Tasks & Acceptance

**Execution:**
- [x] `pubspec.yaml` -- Inicializar proyecto Flutter y añadir dependencias (`supabase_flutter`, `flutter_dotenv`, `google_fonts`). -- Establece la base de paquetes requeridos para el MVP.
- [x] `lib/theme/app_theme.dart` -- Implementar `AppTheme` con paleta oscura anime (`#1B1F29`, `#262B38`, `#FF6A1A`) y Material 3. -- Cumple con la dirección de arte y requerimiento estético del proyecto.
- [x] `lib/services/supabase_service.dart` -- Crear servicio de inicialización y utilidades de Supabase Auth usando variables de `.env`. -- Abstrae la conexión al backend.
- [x] `lib/screens/auth/auth_gate.dart` -- Construir `AuthGate` reactivo para controlar el flujo entre `LoginScreen` y `HomeScreen`. -- Requisito docente 1 (control de sesión).
- [x] `lib/screens/auth/login_screen.dart` -- Diseñar interfaz de Login con validación y botones de acceso rápido para los 3 perfiles (Lucas, Otue, Jesús). -- Permite autenticación estándar y pruebas inmediatas durante la demo.
- [x] `lib/screens/home/home_screen.dart` -- Crear pantalla temporal de bienvenida que muestre el email/username del usuario autenticado y botón de cerrar sesión. -- Confirma visualmente la transición y el cierre de sesión.
- [x] `lib/main.dart` -- Enlazar inicializaciones asíncronas, tema `AppTheme` y home con `AuthGate`. -- Ensambla la arquitectura en 3 capas.

**Acceptance Criteria:**
- Given la app ejecutándose sin sesión previa, when se abre la aplicación, then se visualiza la pantalla `LoginScreen` con el tema oscuro anime M3.
- Given la pantalla `LoginScreen`, when se presiona el botón de acceso rápido de uno de los 3 integrantes o se ingresan credenciales válidas, then la sesión se inicia en Supabase y el `AuthGate` transiciona fluidamente a `HomeScreen`.
- Given la pantalla `HomeScreen`, when el usuario presiona "Cerrar Sesión", then la sesión de Supabase se destruye y la aplicación retorna a `LoginScreen`.

### Review Findings

- [x] [Review][Decision] Architectural choice between consolidated LoginScreen toggle vs separate RegisterScreen file — Resolved: user selected retaining the consolidated single-screen toggle (_isLoginMode) for smoother mobile UX.
- [x] [Review][Patch] Exposure of SUPABASE_SECRET_KEY in .env.example template violates client security boundary [.env.example:6]
- [x] [Review][Patch] AuthGate session evaluation falls back to stale currentSession on sign-out and ignores stream errors [lib/screens/auth/auth_gate.dart:18-25]
- [x] [Review][Patch] Unhandled startup exception in main() crashes app if .env is missing [lib/main.dart:12-16]
- [x] [Review][Patch] SupabaseService.signUp upsert risks resetting points balance to 1000 [lib/services/supabase_service.dart:107-115]
- [x] [Review][Patch] Registration mode lacks dedicated username input field [lib/screens/auth/login_screen.dart:253-286]
- [x] [Review][Patch] Core acceptance criteria (AuthGate routing, HomeScreen sign-out, valid submission) lack automated widget test coverage [test/widget_test.dart:1588-1604]
- [x] [Review][Patch] Defensive type conversions in UserProfile.fromJson, email regex plus-addressing support, and AppTheme.darkTheme memoization [lib/models/user_profile.dart:19]

#### Rejected Appendix
- [Rejected][False] Empty providers/ and widgets/ directories: spec explicitly leaves these for subsequent stories 1.2–1.4.
- [Rejected][False] RangeError on empty TeamQuickProfile.name: teamProfiles is a static const list with predefined non-empty strings.
- [Rejected][False] Missing AndroidManifest.xml internet permission: permission is present at android/app/src/main/AndroidManifest.xml:2; was only absent from the scoped patch diff.
- [Rejected][Low] Contextual loading indicator on individual quick login cards: main submit button already displays loading feedback.
- [Rejected][Low] Displaying user badges on HomeScreen: badge visualization is scheduled for Story 1.5.
- [Rejected][Low] Visual progress indicator during sign-out: sign-out completes near-instantaneously in local client state.
- [Rejected][Low] Offline Google Fonts asset bundling: runtime font fetching is standard for early MVP phase.


## Implementation Notes

- Proyecto Flutter inicializado con soporte multiplataforma (Android, iOS, Web) y dependencias `supabase_flutter`, `flutter_dotenv`, `google_fonts`.
- Tema visual Material 3 (`useMaterial3: true`) con paleta anime oficial (`#1B1F29`, `#262B38`, `#FF6A1A`) y tipografías Teko, Barlow Condensed y Rajdhani.
- `SupabaseService` implementado como singleton seguro cargando credenciales desde `.env` (`SUPABASE_URL`, `SUPABASE_ANON_KEY`) sin exponer claves secretas.
- Perfiles de los 3 integrantes sembrados en Supabase Auth y tabla `profiles` (`lucas@volleybet.udd`, `otue@volleybet.udd`, `jesus@volleybet.udd`).
- `AuthGate` reactivo basado en `StreamBuilder` sobre `onAuthStateChange`.
- `LoginScreen` con validaciones estrictas y selector de acceso rápido con 1 toque para los 3 miembros del equipo.
- `HomeScreen` con verificación de usuario, saldo de puntos inicial (1,000 pts) y botón de cierre de sesión.
- Suite de pruebas automatizadas en `test/widget_test.dart` (14/14 aprobadas).
- Verificado con `flutter analyze` (0 advertencias/errores) y `flutter build web --release` (compilación limpia).

## Spec Change Log

## Review Triage Log

- **medium** (patch) — `android/app/src/main/AndroidManifest.xml`: Falta el permiso `android.permission.INTERNET` en la configuración principal de Android, lo que provocaría fallos de red en compilaciones release. Corregido añadiendo el permiso en el manifest.
- **medium** (patch) — `lib/screens/auth/login_screen.dart`: Regex de email restringía el TLD a 4 caracteres (`{2,4}`), rechazando correos válidos con extensiones modernas (`.online`, `.cloud`, etc.). Corregido ampliando el regex a `[a-zA-Z]{2,}$`.
- **low** (patch) — `lib/models/user_profile.dart`: Caseteo directo `as int?` en `points_balance` puede lanzar `TypeError` si Postgres devuelve tipos numéricos o double. Corregido con casteo seguro `(json['points_balance'] as num?)?.toInt() ?? 1000`.
- **low** (patch) — `lib/screens/home/home_screen.dart`: Múltiples toques rápidos en "Cerrar Sesión" pueden disparar llamadas concurrentes a `signOut()`. Corregido agregando guarda `_isSigningOut`.
- **low** (patch) — `test/widget_test.dart`: Faltaban aserciones específicas para la validación de contraseña corta (< 6 caracteres) y la interacción de toque en el acceso rápido. Corregido añadiendo 3 tests unitarios/widget adicionales (10/10 pasando).
- **false** — `pubspec.yaml`: El reporte argumentó que empaquetar `.env` en assets es inseguro; sin embargo `flutter_dotenv` requiere que el archivo resida en assets para cargarlo, y dicho archivo solo contiene variables públicas de frontend sin claves secretas.
- **false** — `lib/services/supabase_service.dart`: El reporte cuestionó credenciales fijas en perfiles de prueba de equipo; estas fueron explícitamente requeridas por el Criterio 1.5 del spec para facilitar la evaluación docente.
- **low** (defer) — `docs/SUPABASE_CONFIG.md`: Contiene clave de servicio de Supabase en archivo de documentación previo. Documentado para rotación y saneamiento en `deferred-work.md`.

## Design Notes

- Estructura de carpetas en 3 capas requerida por el profesor:
  - `lib/models/` (modelos tipados con fromJson)
  - `lib/services/` (servicios de red y persistencia)
  - `lib/screens/` (vistas completas)
  - `lib/widgets/` (componentes modulares reutilizables)
  - `lib/providers/` (gestión de estado global)
- Los perfiles sembrados de prueba permiten alternar entre Lucas (`lucas@volleybet.udd`), Otue (`otue@volleybet.udd`) y Jesús (`jesus@volleybet.udd`).
