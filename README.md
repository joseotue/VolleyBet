# 🏐 VolleyBet — MVP & Evaluación UDD

> Aplicación móvil y web de pronósticos deportivos virtuales y gamificados de voleibol con estética Anime Material 3, arquitectura limpia en 3 capas, backend serverless en Supabase y gestión de estado con Provider.

Proyecto desarrollado para la asignatura **IIP323W (Programación Móvil con Flutter)** — **Universidad del Desarrollo (UDD)**.  
**Profesor:** Cristóbal Maturana

---

## 👥 Equipo y Distribución de Trabajo

| Integrante | Rol en el Proyecto | Historias de Usuario Implementadas |
|---|---|---|
| **Lucas Riquelme** | **Persona 1:** Lead Backend, Base de Datos & Setup | **HU-01:** Setup, Tema M3, Supabase Auth & AuthGate<br>**HU-03:** Formulario con Validación & Tabla Supabase RLS (CRUD) |
| **Otue Rojas** | **Persona 2:** Lead UI, API Externa & Navegación | **HU-02:** Consumo API deportiva (`dio`), `FutureBuilder` & `Hero`<br>**HU-05 (Parte A):** Animaciones Implícitas & Widgets modulares |
| **Jesús** | **Persona 3:** Estado Global, Simulación & Gamificación | **HU-04:** Manejo de estado con `Provider` & Motor de Simulación<br>**HU-05 (Parte B):** Modo Aprender (Trivia), Ranking & Build Web |

---

## 📌 Cumplimiento de la Pauta Docente (9 Requisitos Obligatorios)

| # | Requisito Exigido | Implementación en VolleyBet | Evidencia en Código |
|---|---|---|---|
| **1** | **Login con Supabase** | `AuthGate` reactivo, registro, login y botones de demo | `lib/screens/auth/` |
| **2** | **API Deportiva con `FutureBuilder`** | 3 estados (`waiting`, `error` con reintento, `data`) | `lib/screens/matches/matches_screen.dart` |
| **3** | **Navegación por Constructor** | Paso directo de `MatchModel` sin variables globales | `lib/screens/matches/match_detail_screen.dart` |
| **4** | **Animaciones (Hero + Implícita)** | `Hero` en escudos; `AnimatedScale` y `AnimatedContainer` | `lib/widgets/animated_odds_button.dart` y `Hero` |
| **5** | **Tabla Supabase RLS (CRUD)** | `bets` con políticas RLS (`Create`, `Read`, `Update`, `Delete`) | `lib/services/supabase_service.dart` |
| **6** | **Formulario con Validación** | `Form`, `GlobalKey<FormState>()` y validador de saldo | `lib/widgets/bet_form.dart` |
| **7** | **Estado Global con `Provider`** | `MultiProvider`, `ChangeNotifier`, `context.watch` | `lib/providers/betting_provider.dart` |
| **8** | **Widgets Propios Separados** | 8 componentes modulares independientes | `lib/widgets/` |
| **9** | **Commits en GitHub y Web** | Commits equilibrados de los 3 integrantes y build web | `flutter build web` en `build/web` |

---

## 🚀 Cómo Hacerlo Funcionar (Puesta en Marcha)

Sigue estos sencillos pasos para configurar y correr la aplicación en tu máquina:

### 1. Prerrequisitos
* **Flutter SDK:** versión `>= 3.19.0` ([Guía oficial de instalación](https://docs.flutter.dev/get-started/install)).
* **Dart SDK:** incluido con Flutter.
* **Google Chrome** (forma más rápida y recomendada para probar) o emulador/dispositivo Android.

---

### 2. Configurar Variables de Entorno (`.env`)

En la raíz del proyecto, crea un archivo llamado exactamente `.env` (puedes tomar como base `.env.example`). Debe contener las credenciales de Supabase y de las APIs deportivas:

```dotenv
# Supabase Project Credentials
SUPABASE_URL=https://urlsupzctpjdmtofbvwj.supabase.co
SUPABASE_REST_URL=https://urlsupzctpjdmtofbvwj.supabase.co/rest/v1/
SUPABASE_PUBLISHABLE_KEY=sb_publishable_0NJxQ-SUnRKBniPntN_2oQ_4p4USQeO
SUPABASE_ANON_KEY=sb_publishable_0NJxQ-SUnRKBniPntN_2oQ_4p4USQeO

# Sports APIs (Cartelera en Vivo)
API_SPORTS_KEY=b7541a26cfa1e67b768433112b9a617f
SPORTRADAR_API_KEY=OIHZGdzBLs7GPFGElNMe78TP6LNPJSoEayjDYDi4
```

> [!NOTE]
> **Resiliencia de Cartelera:** La app implementa failover en 3 capas:
> 1. Intenta consultar **API-Sports**.
> 2. Si falla o se agota la cuota, conmuta automáticamente a **Sportradar**.
> 3. Si ambas fallan o no hay conexión a internet, utiliza el respaldo local (`assets/mock_matches.json`), garantizando que la aplicación nunca se quede en blanco.

---

### 3. Descargar Paquetes y Verificar el Proyecto

Abre una terminal en la carpeta del proyecto y ejecuta:

```bash
# 1. Descargar dependencias de Flutter
flutter pub get

# 2. Análisis estático de código (debe reportar 0 issues)
flutter analyze

# 3. Correr la suite de pruebas unitarias y de widgets (71/71 tests pasan)
flutter test
```

---

### 4. Ejecutar la Aplicación

```bash
# Opción A: Ejecutar en Google Chrome (Recomendado para evaluación rápida)
flutter run -d chrome

# Opción B: Ejecutar en entorno nativo de escritorio Linux
flutter run -d linux

# Opción C: Ejecutar en dispositivo móvil o emulador conectado
flutter run
```

---

## 🔑 Cuentas de Acceso Rápido (Evaluación Docente)

Para no perder tiempo escribiendo credenciales manualmente en la pantalla de inicio de sesión (`LoginScreen`), existen **botones de acceso directo de 1 toque** para cada integrante del equipo con un saldo inicial precargado de **1,000 puntos**:

| Botón de Acceso | Correo Electrónico | Contraseña | Saldo Inicial |
|---|---|---|:---:|
| **Lucas** | `lucas@volleybet.udd` | `volleybet123` | 1,000 pts |
| **Otue** | `otue@volleybet.udd` | `volleybet123` | 1,000 pts |
| **Jesús** | `jesus@volleybet.udd` | `volleybet123` | 1,000 pts |

*También es posible crear usuarios nuevos mediante la pestaña "Registrarse" con confirmación directa.*

---

## 🕹️ Guía de Demostración y Flujo de la App

Para evaluar todas las funcionalidades en menos de 5 minutos:

1. **Inicio de Sesión (HU-01):**
   * Presiona el botón rápido **"Lucas"** en el Login para entrar a la pantalla principal.
2. **Explorar Cartelera & Transición Hero (HU-02):**
   * Toca **"EXPLORAR CARTELERA"** para ver los partidos de voleibol en vivo y programados.
   * Haz tap sobre cualquier partido: observa la animación fluida **Hero** en los escudos al pasar al detalle.
3. **Formulario de Apuesta y Validación (HU-03):**
   * En el detalle, selecciona un equipo y prueba ingresar un monto inválido (0 o superior al saldo) para verificar los mensajes de error.
   * Ingresa un monto válido y confirma la apuesta: el saldo se descontará reactivamente.
4. **Historial, CRUD y Liquidación (HU-03 & HU-04):**
   * Ve a **"MIS APUESTAS"**: verás la apuesta creada en estado *Pendiente*.
   * Puedes **editar el monto** o **cancelar la apuesta** con reembolso automático de puntos.
   * Presiona **"Simular Partido"** (o liquidar con resultados reales) para resolver el encuentro y ver cómo se abonan las ganancias en caso de victoria.
5. **Modo Aprender, Ranking e Insignias (HU-05):**
   * Entra a **"MODO APRENDER"**, responde la trivia de voleibol y gana puntos adicionales y la insignia *"Experto Junior"*.
   * Abre el icono de **Ranking** en la barra superior para ver la tabla de clasificación ordenada en tiempo real.
   * En la vista de perfil podrás revisar las 3 insignias del sistema: *Experto Junior*, *Francotirador* y *Líder de Tabla*.

---

## 🏛️ Estructura y Arquitectura del Proyecto

El código está estructurado en una arquitectura modular limpia en capas dentro de `lib/`:

```text
lib/
├── main.dart                      # Punto de entrada, MultiProvider y carga de tema
├── theme/
│   └── app_theme.dart             # Tema Anime Material 3 (#1B1F29, #262B38, #FF6A1A)
├── models/                        # Capa 1: Entidades de datos y serialización JSON
│   ├── bet_model.dart             # Modelo de apuestas y estados (PENDING, WON, LOST, CANCELLED)
│   ├── match_model.dart           # Modelo de partidos de voleibol y cuotas colectivas
│   ├── trivia_reward_result.dart  # Resultado de recompensas de trivia
│   └── user_profile.dart          # Perfil de usuario, saldo e insignias
├── services/                      # Capa 2: Servicios de API y persistencia en Supabase
│   ├── betting_repository.dart    # Interfaz del repositorio de apuestas
│   ├── simulation_service.dart    # Motor de simulación acelerada de marcadores de sets
│   ├── sports_api_service.dart    # Consumo con Dio de API-Sports, Sportradar y mock offline
│   └── supabase_service.dart      # Autenticación, RLS, base de datos y RPC en Supabase
├── screens/                       # Capa 3: Pantallas de la aplicación
│   ├── auth/                      # AuthGate (StreamBuilder) y LoginScreen
│   ├── home/                      # HomeScreen con navegación y saldo global
│   ├── matches/                   # MatchesScreen (FutureBuilder 3 estados) y MatchDetailScreen (Hero)
│   ├── bets/                      # BetHistoryScreen con gestión CRUD de apuestas
│   ├── learn/                     # TriviaScreen (cuestionario interactivo de voleibol)
│   ├── ranking/                   # RankingScreen (tabla de líderes en tiempo real)
│   └── profile/                   # ProfileScreen (saldo e insignias desbloqueadas)
├── widgets/                       # Componentes modulares independientes reutilizables
│   ├── animated_odds_button.dart  # Botón de cuota con AnimatedScale y AnimatedContainer
│   ├── badge_tile.dart            # Tarjeta de insignia con microinteracción
│   ├── bet_card.dart              # Tarjeta de historial de apuesta
│   ├── bet_form.dart              # Formulario con validación estricta y FormState
│   ├── match_card.dart            # Tarjeta de partido con tag Hero
│   ├── odds_button.dart           # Botón base de cuota
│   ├── points_badge.dart          # Insignia de saldo reactiva con context.watch
│   ├── ranking_row.dart           # Fila de posición en el ranking
│   └── simulation_control_dialog.dart # Modal para disparo de simulación y liquidación
└── providers/                     # Gestión de estado reactivo global
    └── betting_provider.dart      # ChangeNotifier para saldo, apuestas, racha e insignias
```

---

## 📚 Documentación de Respaldo

* 📋 **Historias de Usuario y Rúbrica UDD:** [`docs/HISTORIAS_DE_USUARIO.md`](docs/HISTORIAS_DE_USUARIO.md)
* 🔒 **Configuración y Tablas de Supabase:** [`docs/SUPABASE_CONFIG.md`](docs/SUPABASE_CONFIG.md)
* 📐 **Especificación Funcional BMad:** [`_bmad-output/specs/spec-volleybet/SPEC.md`](_bmad-output/specs/spec-volleybet/SPEC.md)
* 🏁 **Retrospectiva del Sprint:** [`_bmad-output/implementation-artifacts/epic-1-retro-2026-10-25.md`](_bmad-output/implementation-artifacts/epic-1-retro-2026-10-25.md)
