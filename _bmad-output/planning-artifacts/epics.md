---
status: ready
project: VolleyBet
sources:
  - _bmad-output/specs/spec-volleybet/SPEC.md
  - _bmad-output/specs/spec-volleybet/stack.md
  - _bmad-output/specs/spec-volleybet/stories.yaml
  - VolleyBet Pantallas y diseño/VolleyBet Pantallas.dc.html
---

# VolleyBet - Plan de Desarrollo del MVP

## Overview

Este documento desglosa formalmente las capacidades y requisitos técnicos de VolleyBet en una épica central con 5 historias de usuario ejecutables e independientes. Cada historia está diseñada para cumplir simultáneamente con los objetivos de negocio del MVP de 2 semanas y con la totalidad de los 9 requisitos obligatorios de la pauta docente de Flutter (Unidad 2 - UDD).

## Inventario de Requisitos

### Capacidades Funcionales (SPEC-volleybet)
- **CAP-1 (Modo Aprender):** Minijuego interactivo de trivia finita estructurado en capítulos (reglas básicas, puntos/sets, rotaciones). Entrega bolsa inicial de 1,000 puntos y la insignia permanente "Experto Junior en Voleibol" una única vez.
- **CAP-2 (Cartelera y Cuotas de Equipos):** Cartelera de partidos programados y activos de voleibol con cuotas a nivel de equipo para ganador de partido y marcador en sets.
- **CAP-3 (Pronosticos Deportivos):** Colocación de pronósticos con saldo virtual y liquidación automática tras finalizar los partidos.
- **CAP-4 (Motor de Simulacion Acelerada):** Entorno de simulación de partidos acelerados para validar resolución de apuestas, cambios de balance y actualización de estadísticas sin depender de partidos reales en vivo.
- **CAP-5 (Ranking y Gamificacion):** Tabla de clasificación global/semanal sincronizada con Supabase entre los usuarios (incluyendo los 3 perfiles del equipo) y seguimiento de 3 insignias ("Experto Junior", "Francotirador", "Líder de Tabla").

### Requisitos Tecnicos y Arquitectura (Pauta IIP323W Flutter UDD)
- **R1:** Login con Supabase Auth y control de sesión con `AuthGate`.
- **R2:** Consumo de datos de API deportiva externa usando `dio` y renderizado con `FutureBuilder` (manejando estados waiting, error, data).
- **R3:** Navegacion al detalle de partido pasando el objeto modelo por constructor (`Navigator.push`).
- **R4:** Animaciones visuales: `Hero` en escudo/logo del equipo y animacion implícita (`AnimatedScale` / `AnimatedContainer`) en cuotas y confirmación.
- **R5:** Tabla `bets` en Supabase con Row Level Security (RLS: `auth.uid() = user_id`) soportando CRUD completo (Crear apuesta, Ver historial, Editar monto pendiente, Cancelar apuesta).
- **R6:** Formulario con validación (`Form`, `GlobalKey<FormState>`, `TextFormField`, `validator`).
- **R7:** Manejo de estado compartido mediante `Provider` (`ChangeNotifier`, `MultiProvider`, `context.watch<T>()` / `Consumer`).
- **R8:** Widgets modulares propios extraídos en archivos individuales dentro de `lib/widgets/`.
- **R9:** Repositorio Git con historial balanceado de los 3 estudiantes y compatibilidad con compilación Flutter Web para Vercel.

---

## Epic 1: VolleyBet MVP Core & Evaluacion UDD

**Objetivo de la Epica:** Construir e integrar el cliente Flutter y backend Supabase de VolleyBet para entregar una aplicación funcional, testeable y desplegable que satisfaga todas las capacidades del MVP y el 100% de la pauta de evaluación en el plazo estricto de 2 semanas.

---

### Story 1.1: Setup inicial de Flutter, Tema Anime M3, Supabase Auth y AuthGate

**Como** estudiante o evaluador de VolleyBet,  
**Quiero** iniciar sesión de forma segura o autenticarme con uno de los perfiles del equipo,  
**Para** acceder a la aplicación protegida con la estética anime oficial del proyecto.

**Criterios de Aceptacion:**
- **Given** el proyecto Flutter configurado en Android Studio con soporte Web y Móvil y estructura en 3 capas (`models/`, `services/`, `screens/`, `widgets/`, `providers/`),
- **When** se inicia la app y no existe sesión activa,
- **Then** el `AuthGate` redirige a la pantalla de Login/Registro estilizada con tema Material 3 (fondo `#1B1F29`, acentos naranja `#FF6A1A`, tipografía deportiva).
- **And** al autenticarse exitosamente con Supabase Auth, se desbloquea el acceso a las pantallas principales de la app.
- **And** se provee selector rápido o credenciales de los 3 perfiles sembrados de los desarrolladores (Lucas, Otue y Jesús) para pruebas inmediatas.

---

### Story 1.2: Consumo de API Deportiva con dio, FutureBuilder y Detalle con Hero

**Como** fanático del voleibol,  
**Quiero** ver la cartelera de partidos programados y consultar el detalle de un encuentro con su cuota,  
**Para** analizar qué equipos se enfrentan y preparar mis pronósticos.

**Criterios de Aceptacion:**
- **Given** el servicio `SportsApiService` implementado con la librería `dio`,
- **When** el usuario ingresa a la cartelera de partidos (`MatchesScreen`),
- **Then** la vista utiliza `FutureBuilder<List<MatchModel>>` gestionando explícitamente los 3 estados: indicador de carga en `ConnectionState.waiting`, mensaje amigable en caso de error, y renderizado de tarjetas `MatchCard` modulares cuando hay datos.
- **And** al seleccionar un partido, la navegación se realiza por constructor hacia `MatchDetailScreen` pasando la instancia de `MatchModel`.
- **And** el escudo o logo del equipo transiciona fluidamente entre la tarjeta y la pantalla de detalle mediante el widget `Hero`.

---

### Story 1.3: Formulario con Validacion y Tabla en Supabase con RLS (CRUD)

**Como** usuario autenticado,  
**Quiero** colocar pronósticos deportivos ingresando montos válidos y administrar mis apuestas,  
**Para** gestionar mi historial de apuestas de forma segura y personalizada.

**Criterios de Aceptacion:**
- **Given** la tabla `bets` creada en Supabase con políticas Row Level Security (`auth.uid() = user_id`),
- **When** el usuario abre el diálogo o formulario de apuesta (`BetForm`),
- **Then** el formulario implementa `Form` con `GlobalKey<FormState>()` y validadores que impiden montos vacíos, menores a 1 punto o superiores al saldo disponible.
- **And** al enviar un monto válido, la apuesta se inserta en Supabase (`Create`).
- **And** la vista de historial lista únicamente las apuestas del usuario actual (`Read`).
- **And** el usuario puede modificar el monto de una apuesta pendiente (`Update`) o cancelarla antes de que el partido comience (`Delete`), cumpliendo el CRUD completo bajo RLS.

---

### Story 1.4: Manejo de Estado con Provider y Motor de Simulacion Acelerada

**Como** usuario o evaluador,  
**Quiero** simular la resolución inmediata de partidos y que mi saldo se actualice al instante,  
**Para** verificar el ciclo de apuestas y cobros de puntos sin depender de partidos reales en vivo.

**Criterios de Aceptacion:**
- **Given** la aplicación configurada con `MultiProvider` y `ChangeNotifier` (`BettingProvider` / `UserSessionProvider`),
- **When** el usuario confirma una apuesta o acciona el botón de "Simular Partido",
- **Then** el saldo se descuenta inmediatamente al apostar y se actualiza reactivamente en la interfaz mediante `notifyListeners()` y `context.watch<T>()` / `Consumer`.
- **And** el motor de simulación asigna un marcador final al encuentro y ejecuta la liquidación de apuestas: las apuestas ganadoras abonan `monto * cuota` en Supabase y memoria, y las perdedoras marcan el estado `LOST`.
- **And** se evalúa la racha de aciertos consecutivos para la entrega de la insignia "Francotirador" (3 aciertos seguidos).

---

### Story 1.5: Modo Aprender, Ranking, Animaciones Implicitas y Verificacion Web

**Como** usuario nuevo y competitivo,  
**Quiero** completar la trivia educativa para ganar mi saldo inicial, ver mi posición en el ranking frente a mis compañeros y disfrutar de interacciones fluidas,  
**Para** dominar las reglas del voleibol y liderar la tabla de pronósticos.

**Criterios de Aceptacion:**
- **Given** el módulo de trivia del Modo Aprender con preguntas sobre reglas, puntuación y rotaciones,
- **When** el usuario completa la trivia por primera vez,
- **Then** se otorgan 1,000 puntos y se desbloquea la insignia permanente "Experto Junior en Voleibol", persistiendo el logro en Supabase e impidiendo repetición fraudulenta.
- **And** la pantalla de `RankingScreen` muestra la tabla en tiempo real ordenada por puntaje entre los perfiles de los usuarios y desarrolladores (Lucas, Otue y Jesús), actualizando el estatus de la insignia "Líder de Tabla".
- **And** las selecciones de cuotas y botones de acción cuentan con microinteracciones mediante `AnimatedScale` o `AnimatedContainer`.
- **And** el proyecto compila limpiamente para Flutter Web (`flutter build web`) listo para despliegue en Vercel, y el repositorio registra historial de commits balanceado de Lucas, Otue y Jesús.
