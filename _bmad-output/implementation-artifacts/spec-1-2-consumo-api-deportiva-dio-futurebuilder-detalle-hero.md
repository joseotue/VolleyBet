---
title: 'Consumo de API Deportiva con dio, FutureBuilder y Detalle con Hero'
type: 'feature'
created: '2026-10-20'
status: 'done'
baseline_commit: '98a9f28b75f4ea01d7b97327102b83db4bc1225e'
route: 'dispatch'
review_loop_iteration: 0
context:
  - '{project-root}/docs/HISTORIAS_DE_USUARIO.md'
  - '{project-root}/apis/apiKeySports.txt'
  - '{project-root}/apis/openapi.yaml'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** VolleyBet no cuenta con la cartelera de partidos de voleibol ni con el consumo de API deportiva externa exigido por la pauta docente UDD (Requisitos 2, 3 y 4). Además, las dos APIs disponibles (API-Sports y Sportradar Volleyball v2) cuentan con cuotas y restricciones estrictas de peticiones (100 req/día en API-Sports y límites de QPS/trial en Sportradar), demandando una arquitectura resiliente multi-proveedor con failover y respaldo local para asegurar alta disponibilidad tanto en desarrollo como en la evaluación docente.

**Approach:** Construir un servicio deportivo unificado `SportsApiService` con `dio` implementando una estrategia de proveedor dual con failover dinámico:
1. **Fuente Primaria:** API-Sports (`https://v1.volleyball.api-sports.io`) con header `x-apisports-key`.
2. **Fuente Secundaria (Failover):** Sportradar Volleyball v2 (`https://api.sportradar.com/volleyball/trial/v2` según `openapi.yaml`) con query parameter `api_key`.
3. **Respaldo Offline:** Conmutación automática a `assets/mock_matches.json` si ambas APIs fallan o agotan cuotas.
Caché en memoria con TTL de 15 minutos para minimizar peticiones; vista `MatchesScreen` con `FutureBuilder<List<MatchModel>>` gestionando los 3 estados (espera, error con reintento y datos); widgets modulares `MatchCard` y `OddsButton` en `lib/widgets/`; y navegación tipada por constructor a `MatchDetailScreen(match: match)` con transición `Hero` en los escudos y cuotas de equipo.

## Boundaries & Constraints

**Always:**
- Utilizar `dio` para las peticiones HTTP a ambas APIs deportivas (Requisito 2).
- Gestionar explícitamente los 3 estados en `FutureBuilder`: `waiting` (spinner anime naranja), `error` (mensaje con botón de reintento) y `data` (lista de `MatchCard`).
- Implementar failover dinámico: intentar API-Sports -> si falla o agota cuota, intentar Sportradar -> si falla, cargar `assets/mock_matches.json`.
- Proteger las cuotas limitadas usando caché en memoria con TTL (15 minutos) antes de cualquier llamada de red.
- Cargar las claves de API desde `.env` (`API_SPORTS_KEY` y `SPORTRADAR_API_KEY`) mediante `flutter_dotenv`.
- Navegar a `MatchDetailScreen` pasando obligatoriamente `MatchModel` por constructor (`Navigator.push`) (Requisito 3).
- Implementar animación `Hero` en los escudos con tag `team-logo-${match.id}-${isHome ? 'home' : 'away'}` (Requisito 4).
- Modelar cuotas colectivas de equipo (`homeOdds`, `awayOdds`), sin estadísticas de jugadores individuales.
- Extraer widgets modulares en `lib/widgets/` (`match_card.dart`, `odds_button.dart`) (Requisito 8).
- Respetar el tema Anime M3: fondo `#1B1F29`, tarjetas `#262B38`, acento naranja `#FF6A1A`.

**Never:**
- No realizar polling continuo que agote las cuotas de las APIs.
- No depender exclusivamente de conexión a internet para pruebas o evaluación docente.
- No modelar estadísticas individuales por atleta.
- No usar dinero real ni pasarelas externas (economía 100% de puntos virtuales).

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Carga exitosa primaria | API-Sports disponible y cuota activa | `FutureBuilder` renderiza lista de `MatchCard` provista por API-Sports | N/A |
| Cuota agotada en API-Sports | Payload API-Sports con error de cuota/plan | Conmuta a Sportradar Volleyball v2 de forma transparente | Si Sportradar responde, renderiza partidos de Sportradar |
| Ambas APIs inaccesibles o sin red | Error de red o 403/429 en ambas | Carga respaldo local `assets/mock_matches.json` | Muestra datos locales y badge/aviso "Modo Datos Locales" |
| Pull-to-refresh | Deslizar hacia abajo en `MatchesScreen` | `RefreshIndicator` fuerza recarga y revalida proveedores | Si falla, preserva datos previos y avisa con SnackBar |
| Selección de partido | Tap en `MatchCard` | Abre `MatchDetailScreen(match: match)` con transición `Hero` | N/A |
| Ausencia de cuota en API | Partido sin campo de odds | Genera cuotas colectivas por defecto (ej. 1.80 vs 2.00) | Fallback determinista |

</frozen-after-approval>

## Code Map

- `pubspec.yaml` -- Dependencia `dio: ^5.7.0` y asset `assets/mock_matches.json`.
- `.env` & `.env.example` -- Variables `API_SPORTS_KEY` y `SPORTRADAR_API_KEY`.
- `assets/mock_matches.json` -- Respaldo local de 54 partidos reales de voleibol.
- `lib/models/match_model.dart` -- Modelo `MatchModel` con deserialización para API-Sports y Sportradar.
- `lib/services/sports_api_service.dart` -- Servicio unificado `SportsApiService` con `Dio`, caché TTL, failover (API-Sports -> Sportradar) y fallback a mock.
- `lib/widgets/odds_button.dart` -- Widget reutilizable de cuota con microinteracción táctil.
- `lib/widgets/match_card.dart` -- Tarjeta modular con escudos, nombres, estado, cuotas y `Hero`.
- `lib/screens/matches/matches_screen.dart` -- Cartelera con `FutureBuilder` (3 estados) y `RefreshIndicator`.
- `lib/screens/matches/match_detail_screen.dart` -- Vista de detalle con `required MatchModel match` y `Hero`.
- `lib/screens/home/home_screen.dart` -- Acceso y navegación hacia `MatchesScreen`.
- `test/widget_test.dart` -- Pruebas automatizadas para modelo, servicio failover, estados y pantallas.

## Tasks & Acceptance

**Execution:**
- [x] `pubspec.yaml` -- Agregar dependencia `dio` y declarar asset `assets/mock_matches.json`.
- [x] `.env` & `.env.example` -- Asegurar claves `API_SPORTS_KEY` y `SPORTRADAR_API_KEY`.
- [x] `lib/models/match_model.dart` -- Crear entidad `MatchModel` con atributos (`id`, `tournament`, `homeTeam`, `awayTeam`, `homeLogo`, `awayLogo`, `homeOdds`, `awayOdds`, `matchDate`, `status`, `scores`, `sourceProvider`) y factory `fromJson`.
- [x] `lib/services/sports_api_service.dart` -- Implementar `SportsApiService` con `Dio`, caché en memoria (15 min), failover dual (API-Sports -> Sportradar) y conmutación a `assets/mock_matches.json`.
- [x] `lib/widgets/odds_button.dart` -- Crear botón de cuotas de equipo con estilo Anime M3.
- [x] `lib/widgets/match_card.dart` -- Crear tarjeta de partido con animación `Hero` y cuotas.
- [x] `lib/screens/matches/matches_screen.dart` -- Implementar vista con `FutureBuilder` (3 estados) y `RefreshIndicator`.
- [x] `lib/screens/matches/match_detail_screen.dart` -- Implementar detalle con paso por constructor y `Hero`.
- [x] `lib/screens/home/home_screen.dart` -- Integrar acceso directo a `MatchesScreen`.
- [x] `test/widget_test.dart` -- Escribir pruebas automatizadas para HU-02 (modelo, failover, estados y navegación).

**Acceptance Criteria:**
- Given `MatchesScreen` cargando datos, when la conexión está pendiente, then se muestra un spinner centrado anime (`waiting`).
- Given `MatchesScreen` con fallo crítico sin datos en ningún proveedor, then se muestra mensaje amigable con botón de reintento (`hasError`).
- Given datos obtenidos de API primaria, secundaria o mock, then se renderiza lista de `MatchCard` con escudos, equipos y cuotas (`hasData`).
- Given una tarjeta `MatchCard`, when se presiona, then navega a `MatchDetailScreen` pasando `MatchModel` por constructor.
- Given el escudo del equipo en tarjeta y detalle, when se navega, then la animación `Hero` transiciona con suavidad.
- Given solicitudes sucesivas dentro del TTL (15 min), then `SportsApiService` sirve desde caché protegiendo las cuotas de ambas APIs.
- Given fallo o cuota agotada en API-Sports, then `SportsApiService` ejecuta failover a Sportradar y, en su defecto, al mock local sin colapsar.

### Review Findings

- [x] [Review][Patch] Cachear mock local con TTL corto para evitar latencias de 10s en modo offline y agregar header Accept: application/json en Sportradar [lib/services/sports_api_service.dart:134-144]
- [x] [Review][Patch] Deserialización atómica y simétrica de cuotas para mantener consistencia de margen [lib/models/match_model.dart:193-198]
- [x] [Review][Patch] Evitar condición de carrera en recargas y añadir indicador de progreso lineal durante refresco con datos previos [lib/screens/matches/matches_screen.dart:35-58, 349-376]
- [x] [Review][Patch] Hacer _buildWaitingState desplazable para habilitar pull-to-refresh en estado de carga [lib/screens/matches/matches_screen.dart:88-105]
- [x] [Review][Patch] Deshabilitar selección de cuotas en partidos finalizados o cancelados y permitir deselección (toggle off) en detalle [lib/screens/matches/match_detail_screen.dart:416-442, lib/widgets/match_card.dart:298-324]
- [x] [Review][Patch] Preservar selección inicial de equipo al navegar desde MatchCard al detalle [lib/widgets/match_card.dart:300-323, lib/screens/matches/match_detail_screen.dart:10-25]
- [x] [Review][Patch] Evitar colisión de selección de cuota si los equipos comparten nombre utilizando índice de equipo [lib/screens/matches/match_detail_screen.dart:422, 435]
- [x] [Review][Patch] Envolver Hero en Material transparente para evitar subrayado amarillo en texto de iniciales durante transición [lib/widgets/match_card.dart:37, lib/screens/matches/match_detail_screen.dart:46]
- [x] [Review][Patch] Pulido visual en detalle: maxLines en nombres de equipo, mapeo en español de estados de Sportradar y fecha formateada [lib/screens/matches/match_detail_screen.dart:275-283, 504, lib/models/match_model.dart:97-109]
- [x] [Review][Patch] Restaurar lib/generated_plugin_registrant.dart en .gitignore [.gitignore:40]
- [x] [Review][Patch] Completar suite de tests en test/widget_test.dart: aserción de estado vacío, contrato de autenticación en MockDioAdapter, preservación en error de pull-to-refresh y mock para navegación en HomeScreen [test/widget_test.dart:326-346, 589-621, 816-818, 974-1027]

#### Rejected
- `false` — Sportradar schedule summaries endpoint no requiere extensión `.json` según `apis/openapi.yaml` línea 141.
- `false` — Sportradar v2 schedule summaries no provee logos de equipos ni cuotas de apuestas en su esquema según `apis/openapi.yaml`.
- `false` — La cadena de failover registra advertencias de upstream y solo propaga el error del último respaldo por diseño.
- `low` — Selector de fecha en cartelera descartado por estar fuera del alcance de la HU-02 (limitada a la fecha actual y FutureBuilder).

## Implementation Notes

- Se agregó `dio: ^5.7.0` a `pubspec.yaml` y se registró el asset local `assets/mock_matches.json`.
- Se creó `MatchModel` con deserialización para API-Sports y Sportradar, tags `Hero` normalizados y cuotas colectivas de equipo deterministas.
- Se implementó `SportsApiService` con arquitectura de proveedor dual y failover jerárquico: caché indexado por fecha (TTL 15 min), fuente primaria API-Sports, fuente secundaria Sportradar Volleyball v2, y respaldo offline local.
- Se crearon los widgets modulares `MatchCard` (con `Hero` y navegación al detalle por constructor) y `OddsButton` (con microinteracciones táctiles).
- Se implementó `MatchesScreen` con `FutureBuilder` gestionando explícitamente los 3 estados (`waiting`, `hasError`, `hasData`), soporte de pull-to-refresh y feedback reactivo.
- Se implementó `MatchDetailScreen` recibiendo `MatchModel` por constructor con cabecera `Hero`, parciales por set con scroll horizontal anti-overflow y tarjeta de pronóstico.
- Se integró el acceso a la cartelera desde `HomeScreen`.
- Suite automatizada ampliada a 33 pruebas unitarias y de widgets en `test/widget_test.dart` (33/33 aprobadas).
- `flutter analyze`: 0 advertencias, 0 errores.
- `flutter build web --release`: compilación limpia para producción.

## Spec Change Log

## Review Triage Log

- **medium** (patch) — `lib/services/sports_api_service.dart`: El caché en memoria no estaba indexado por fecha y bloqueaba la app en mock local al fallar. Corregido con mapa `Map<String, _CacheEntry>` por fecha y sin TTL largo para el mock de respaldo.
- **medium** (patch) — `lib/services/sports_api_service.dart`: Acceso a `dotenv.env` sin verificar `dotenv.isInitialized` lanzaba `NotInitializedError`. Corregido añadiendo guarda `dotenv.isInitialized`.
- **medium** (patch) — `lib/services/sports_api_service.dart`: Respuestas válidas con 0 partidos programados se trataban como error. Corregido distinguiendo `null` (fallo) de lista vacía legítima.
- **medium** (patch) — `lib/screens/matches/matches_screen.dart`: `_lastLoadedMatches` se mutaba dentro del método `build`. Corregido actualizando el estado de forma reactiva fuera del ciclo de renderizado.
- **medium** (patch) — `lib/screens/matches/matches_screen.dart`: Vistas de error y lista vacía no eran desplazables, impidiendo el gesto de pull-to-refresh. Corregido envolviendo en `SingleChildScrollView(physics: AlwaysScrollableScrollPhysics())`.
- **medium** (patch) — `lib/screens/matches/match_detail_screen.dart`: Desbordamiento RenderFlex horizontal potencial en la fila de parciales por set en pantallas estrechas (< 440px). Corregido envolviendo en `SingleChildScrollView(scrollDirection: Axis.horizontal)`.
- **low** (patch) — `lib/widgets/match_card.dart`: Inconsistencia en visualización horaria (UTC vs local). Corregido utilizando `match.matchDate.toLocal()`.
- **low** (patch) — `lib/models/match_model.dart`: Estados de Sportradar `'started'` y `'ended'` y parciales no mapeados. Corregido añadiendo soporte explícito en el modelo.
- **low** (patch) — `.gitignore`: Restaurada la exclusión de `lib/generated_plugin_registrant.dart`.
- **medium** (patch) — `test/widget_test.dart`: Faltaba ejercitar en tests la pulsación de reintento en error y el gesto de pull-to-refresh. Corregido añadiendo pruebas de interacción widget dedicadas (33/33 pasando).
- **low** (patch) — `spec-1-2-...md`: Claves de API registradas en texto plano en notas. Corregido referenciando variables de entorno sin exponer valores en documentación.

## Design Notes

- **Failover jerárquico:**
  1. Si hay caché en memoria válido (< 15 min para la fecha solicitada), se retorna de inmediato (0 llamadas de red).
  2. Si no hay caché, se consulta API-Sports (`https://v1.volleyball.api-sports.io/games?date=YYYY-MM-DD`).
  3. Si API-Sports devuelve error de cuota o fallo HTTP, se consulta Sportradar (`https://api.sportradar.com/volleyball/trial/v2/en/schedules/...`).
  4. Si Sportradar devuelve error o no hay conexión, se sirve `assets/mock_matches.json`.
- **Claves de entorno:**
  - `API_SPORTS_KEY` y `SPORTRADAR_API_KEY` leídas desde `.env` mediante `flutter_dotenv`.

## Verification

**Commands:**
- `flutter test` -- expected: Todas las pruebas pasan (0 errores).
- `flutter analyze` -- expected: 0 warnings o errores.
- `flutter build web --release` -- expected: Compilación limpia para Flutter Web.

**Manual checks (if no CLI):**
- Abrir cartelera, verificar estados de carga/datos, tocar partido para ver `Hero` y detalle por constructor.