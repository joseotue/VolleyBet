# Epic 1 Context: VolleyBet MVP Core & Evaluacion UDD

<!-- Compiled from planning artifacts. Edit freely. Regenerate with compile-epic-context if planning docs change. -->

## Goal

Construir e integrar el cliente Flutter y backend Supabase de VolleyBet para entregar una aplicación funcional, testeable y desplegable que satisfaga todas las capacidades del MVP de pronósticos de voleibol y el 100% de la pauta de evaluación académica (9 requisitos obligatorios de Flutter) en el plazo estricto de 2 semanas.

## Stories

- Story 1.1: Setup inicial de Flutter, Tema Anime M3, Supabase Auth y AuthGate
- Story 1.2: Consumo de API Deportiva con dio, FutureBuilder y Detalle con Hero
- Story 1.3: Formulario con Validacion y Tabla en Supabase con RLS (CRUD)
- Story 1.4: Manejo de Estado con Provider y Motor de Simulacion Acelerada
- Story 1.5: Modo Aprender, Ranking, Animaciones Implicitas y Verificacion

## Requirements & Constraints

- Autenticación obligatoria con Supabase Auth gestionada a través de un `AuthGate` para proteger el acceso a las pantallas principales y permitir login rápido con perfiles sembrados del equipo.
- Consumo de partidos/fixtures de voleibol usando `dio` con renderizado reactivo mediante `FutureBuilder` (manejando estados waiting, error y data).
- Navegación al detalle de partido (`MatchDetailScreen`) pasando el modelo `MatchModel` directamente por constructor con `Navigator.push`.
- Animaciones obligatorias: transición `Hero` entre la tarjeta y la pantalla de detalle para el escudo/logo del equipo, y animaciones implícitas (`AnimatedScale`/`AnimatedContainer`) en cuotas y confirmaciones.
- Gestión de pronósticos mediante la tabla `bets` en Supabase protegida con Row Level Security (`auth.uid() = user_id`) con soporte completo de operaciones CRUD (crear apuesta, listar historial propio, editar monto pendiente, cancelar apuesta pendiente).
- Formularios validados utilizando `Form`, `GlobalKey<FormState>()` y `TextFormField` con validadores que prevengan montos negativos o superiores al saldo disponible.
- Manejo de estado global reactivo mediante `Provider` (`ChangeNotifier`, `MultiProvider`, `context.watch<T>()` / `Consumer`) para balance de puntos, apuestas activas y simulación.
- Modularización de componentes en archivos individuales dentro de `lib/widgets/`.
- Soporte de compilación y ejecución en Flutter Web y Móvil (Android/iOS).
- Economía 100% de puntos virtuales sin dinero real ni pasarelas de pago. Cuotas y apuestas modeladas a nivel de equipo colectivo (sin estadísticas individuales de jugadores).

## Technical Decisions

- Arquitectura limpia en 3 capas:
  - `services/`: `sports_api_service.dart` (`dio`), `supabase_service.dart` (`supabase_flutter`).
  - `models/`: `match_model.dart`, `bet_model.dart`, `user_profile_model.dart` con deserialización tipada `fromJson`.
  - `screens/`, `widgets/`, `providers/`: capa de presentación y estado reactivo.
- Paleta de diseño Anime Material 3: fondo oscuro `#1B1F29`, acentos naranja vibrante `#FF6A1A`, tarjetas `#262B36`, tipografía deportiva.
- Motor de simulación acelerada de partidos locales para permitir pruebas de resolución de apuestas y balances sin depender de eventos deportivos en vivo.
- Configuración de Supabase cargada desde variables de entorno (`.env` con `flutter_dotenv`).

## UX & Interaction Patterns

- Flujo de autenticación: Si no hay sesión activa, `AuthGate` redirige a `LoginScreen`. Si hay sesión, accede a `MatchesScreen`.
- Selección de partidos y cuotas con feedback visual instantáneo (cambio de escala/color al presionar).
- Diálogo modal o vista de confirmación de apuesta con validación en tiempo real antes de enviar.
- Navegación principal fluida entre Cartelera de Partidos, Historial de Apuestas, Modo Aprender y Ranking.

## Cross-Story Dependencies

- Story 1.1 sienta la base del proyecto Flutter, estructura de carpetas, cliente Supabase y `AuthGate`, bloqueando el resto de las historias hasta estar completada.
- Story 1.2 provee los modelos y datos de partidos que Story 1.3 y 1.4 necesitan para colocar pronósticos y ejecutar la simulación.
- Story 1.3 implementa la persistencia de apuestas en Supabase (RLS CRUD) que alimenta el `BettingProvider` de Story 1.4.
- Story 1.4 suministra el motor de simulación y actualización de saldo que Story 1.5 utiliza para el ranking y desbloqueo de insignias.
