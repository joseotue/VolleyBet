# VolleyBet (Forged Idea)

## Decisiones Firmes (Locks)
- **Núcleo de juego:** Pronósticos deportivos basados en **equipos** (no atletas individuales) usando cuotas reales de mercado (Odds/Bets) provistas por APIs.
- **Economía:** 100% puntos virtuales con bolsa inicial de bienvenida. Cero dinero real.
- **Onboarding ("Modo Aprender"):** Minijuego de trivia educativo finito por capítulos (reglas, sets, rotaciones). Otorga puntos iniciales sin riesgo y la insignia "Experto Junior en Voleibol".
- **Competiciones y Cobertura:** Clubes (ligas top mundiales para continuidad semanal) + Selecciones (VNL, Mundiales, JJ.OO. con mayor multiplicador de puntos); ramas masculina y femenina.
- **Retención en periodos inactivos:** Minijuego de Trivia histórica para selecciones cuando no haya torneos en vivo.
- **Entorno de Prueba / Simulación:** Capacidad de jugar sobre datos históricos para probar la app, resolver apuestas y acumular historial sin depender de partidos en vivo.
- **Meta-juego y Gamificación:** Competencia en Ranking semanal/global y exactamente 3 insignias:
  1. *Experto Junior en Voleibol* (completar Modo Aprender).
  2. *Francotirador* (racha de 3 pronósticos acertados).
  3. *Líder de Tabla* (top en el Ranking semanal o umbral de puntos).
- **Estética:** Lenguaje visual manga/anime (estilo Haikyu!!, tramas halftone, líneas de velocidad, colores de alto contraste) sobre Flutter/Material 3.

## Opciones Rechazadas y Motivos
- **Rechazado:** Fantasy tradicional de jugadores individuales (fichar 6 titulares + 3 reservas con estadísticas de puntos/bloqueos individuales).
  - *Motivo:* APIs de estadísticas individuales (FIVB/VolleyStation) son inaccesibles/carísimas; la complejidad abruma a novatos.
- **Rechazado:** Apuestas con dinero real.
  - *Motivo:* Incompatible con público joven/anime; requiere licencias de juego y regulación legal compleja.
- **Rechazado:** Tutorial o tour guiado tradicional estático.
  - *Motivo:* Alta tasa de abandono; reemplazado por el "Modo Aprender" jugable y recompensado.
- **Rechazado:** Foco exclusivo en torneos de selecciones o liga local menor.
  - *Motivo:* Vacíos de 10 meses sin partidos (selecciones) o calendarios muy cortos y sin APIs de calidad (liga local).
