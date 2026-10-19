---
id: SPEC-volleybet
companions:
  - stack.md
  - ../../../VolleyBet Pantallas y diseño/VolleyBet Pantallas.dc.html
sources:
  - _bmad-output/forge/volleybet/forged-idea.md
---

> **Canonical contract.** This SPEC and the files in `companions:` are the complete, preservation-validated contract for what to build, test, and validate. Source documents listed in frontmatter are for traceability — consult them only if you need narrative rationale or prose color this contract intentionally omits.

# VolleyBet (MVP 2 Semanas)

## Why

VolleyBet busca capturar la oportunidad de acercar al público seguidor del voleibol y fanáticos de la animación deportiva mediante una experiencia gamificada y accesible de pronósticos basada en equipos y un modo de aprendizaje interactivo. Resuelve la barrera de entrada que representan las reglas complejas del deporte y la frustración de la estacionalidad de torneos, bajo el mandato estricto de entregar un producto funcional, testeable y sin sobrecarga en un plazo improrrogable de 2 semanas, respaldado en una arquitectura obligatoria con Supabase y Flutter.

## Capabilities

- **CAP-1**
  - **intent:** El usuario nuevo completa un minijuego interactivo finito de trivia educativa ("Modo Aprender") estructurado en capítulos (reglas básicas, sistema de puntos/sets y rotaciones) para comprender el deporte y recibir su capital inicial de juego.
  - **success:** El flujo educativo otorga una bolsa inicial de puntos virtuales y la insignia permanente "Experto Junior en Voleibol" una única vez, registrando el progreso en Supabase y bloqueando intentos posteriores de farming repetitivo.

- **CAP-2**
  - **intent:** El usuario explora una cartelera de partidos programados y activos de clubes y selecciones (masculino y femenino), consultando cuotas (odds) de mercado calculadas a nivel de equipo para ganador de partido y marcador de sets.
  - **success:** La interfaz lista los eventos deportivos agrupados por torneo con sus equipos, horarios y cuotas actualizadas desde Supabase/local, permitiendo seleccionar opciones de pronóstico para armar un boleto de juego.

- **CAP-3**
  - **intent:** El usuario coloca pronósticos deportivos asignando puntos virtuales de su saldo y recibe el retorno correspondiente de manera automática cuando el partido concluye.
  - **success:** Al confirmar el pronóstico, el saldo se descuenta inmediatamente; al registrarse el resultado final, si el pronóstico es acertado se abona el premio (monto × cuota) y la transacción queda asentada en el historial de apuestas en Supabase.

- **CAP-4**
  - **intent:** El usuario o evaluador activa un entorno de simulación acelerada sobre partidos históricos o ficticios para verificar la resolución de apuestas, cambios de saldo e hitos de juego sin depender de partidos reales en vivo.
  - **success:** Al presionar el control de simulación, el partido seleccionado pasa al estado finalizado con un marcador generado, desencadenando la liquidación inmediata de las apuestas activas, la actualización de saldo en Supabase y el refresco de estadísticas.

- **CAP-5**
  - **intent:** El usuario compite en una tabla de clasificación (Ranking semanal/global) basada en el rendimiento de sus pronósticos contra los demás usuarios (incluyendo los 3 perfiles de desarrolladores del equipo) y visualiza el progreso y desbloqueo de tres insignias exclusivas.
  - **success:** El ranking sincronizado con Supabase ordena a los perfiles por puntaje acumulado destacando la posición actual, y la vista de perfil refleja con precisión el estado (bloqueado/desbloqueado) de las insignias "Experto Junior en Voleibol", "Francotirador" (racha de 3 aciertos consecutivos) y "Líder de Tabla" (primer lugar en ranking o umbral de puntos).

## Constraints

- **Plazo de entrega de 2 semanas:** El diseño de arquitectura, interfaz y lógica de negocio debe circunscribirse estrictamente a lo realizable y testeable dentro de 14 días calendario.
- **Herramientas y Backend Obligatorios:** Implementación obligatoria en **Flutter** y **Dart** (usando Android Studio como entorno principal), con **Supabase** como backend relacional y persistencia remota, y compatibilidad con compilación a **Flutter Web** para despliegue en Vercel.
- **Economía 100% virtual:** Queda prohibida toda transacción, carga, retiro o integración que involucre dinero real o pasarelas de pago.
- **Modelado a nivel de EQUIPO:** Todas las cuotas, pronósticos y dinámicas operan sobre equipos colectivos; queda prohibido el seguimiento o cálculo de estadísticas individuales por jugador (puntos, bloqueos o saques individuales).
- **Estética Anime/Manga:** La interfaz debe reflejar una dirección de arte deportiva inspirada en el anime (alto contraste, fondos oscuros `#1B1F29`, acentos naranja `#FF6A1A`, tipografía Barlow/Anton) implementada en Flutter con Material 3.
- **Operación Dual (Simulada + Online):** El sistema debe incluir un motor de simulación de partidos acelerados para no depender de partidos de voleibol en vivo durante demostraciones y pruebas de evaluación.

## Non-goals

- Fantasy clásico con alineación de jugadores individuales, límites salariales de atletas o puntuaciones por acciones individuales de campo.
- Apuestas con dinero real o cobro de comisiones financieras.
- Módulos de mensajería privada, chat en vivo o foros comunitarios entre usuarios.
- Cobertura de ligas locales no oficiales carentes de estructuras de datos normalizadas.
- Scraping de portales web externos no oficiales.

## Success signal

- En una sesión de evaluación de 5 minutos, un usuario (o uno de los 3 perfiles del equipo) inicia sesión, supera la trivia del Modo Aprender obteniendo 1,000 puntos virtuales y la insignia "Experto Junior", selecciona un partido en la cartelera apostando 200 puntos a cuota 1.85, dispara la simulación para resolver el partido con victoria, cobra 370 puntos virtuales en Supabase y comprueba su ascenso en la tabla de Ranking frente a los otros perfiles.

## Assumptions

- Se asume que el acceso inicial contará con un selector o inicio rápido entre los 3 perfiles de desarrolladores sembrados en Supabase (o sesión anónima) para permitir pruebas ágiles en cualquier dispositivo.
- Se asume que los fixtures iniciales cubrirán al menos 2 torneos representativos (VNL y liga de clubes top) con cuotas balanceadas.
