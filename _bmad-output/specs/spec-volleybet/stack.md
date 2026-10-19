# Arquitectura y Stack Tecnológico — VolleyBet (MVP 2 Semanas)
## Basado en la Pauta Oficial IIP323W · Unidad 2 Flutter (UDD)

## 1. Filosofía de Arquitectura y Alineación Docente

El proyecto se estructura para cumplir al 100% la pauta de evaluación y los **9 requisitos mínimos obligatorios** dictados por el profesor Cristóbal Maturana en la Unidad 2 de Flutter:
- **Estructura en 3 Capas Oficial:**
  1. **Datos / Servicios (`services/`):** Consumo de API externa de deportes con `dio` y persistencia con `supabase_flutter`.
  2. **Modelos (`models/`):** Mapeo de datos JSON tipados en clases Dart con constructores y `factory Model.fromJson`.
  3. **Presentación & Estado (`screens/`, `widgets/`, `providers/`):** Vistas limpias que extraen componentes reutilizables y consumen estado global mediante `Provider` (`ChangeNotifier`).

---

## 2. Los 9 Requisitos Mínimos del Profesor y su Implementación en VolleyBet

| # | Requisito Exigido por el Profesor | Cómo se Cumple en VolleyBet |
|---|---|---|
| **1** | **Login con Supabase** (`AuthGate`, registrarse, entrar, salir) | Pantalla de Login/Registro con Supabase Auth que protege la app con sesión activa para los 3 integrantes del grupo. |
| **2** | **Datos de API Deportiva con `FutureBuilder`** | Consumo de fixtures/partidos reales (o endpoint deportivo) usando `dio` y renderizado mediante `FutureBuilder` manejando los 3 estados (cargando, error y datos). |
| **3** | **Navegación al Detalle por Constructor** | Al tocar una tarjeta de partido en la lista, se abre `MatchDetailScreen` pasando el objeto `Match` directamente por constructor con `Navigator.push`. |
| **4** | **Animaciones (Hero + Animación Implícita)** | - **`Hero`:** Escudo o logo del equipo transiciona fluidamente desde la tarjeta al encabezado del detalle.<br>- **Animación Implícita:** `AnimatedScale` o `AnimatedContainer` al presionar una cuota de apuesta y al revelar el resultado. |
| **5** | **Tabla en Supabase con RLS (CRUD Completo)** | Tabla `bets` (pronósticos) protegida con Row Level Security (`auth.uid() = user_id`) donde el usuario puede **Crear** (apostar), **Ver** (historial), **Editar** (modificar monto antes del cierre) y **Borrar** (cancelar apuesta pendiente). |
| **6** | **Formulario con Validación (`Form` + `TextFormField`)** | `Form` con `GlobalKey<FormState>()` y validadores (`validator`) para ingresar monto de apuesta (número positivo, sin exceder saldo disponible) y registro de usuario. |
| **7** | **Estado Compartido con `Provider`** | `ChangeNotifier` (`UserSessionProvider` / `BettingProvider`) compartido con `MultiProvider` y escuchado con `context.watch<T>()` / `Consumer` para actualizar saldo y ranking en vivo. |
| **8** | **Widgets Propios en Archivos Separados** | Componentes modulares reutilizables extraídos en `lib/widgets/` (`MatchCardWidget`, `OddsButtonWidget`, `BadgeTileWidget`, `CustomButton`). |
| **9** | **GitHub con Commits de los 3 Integrantes** | Repositorio git con ramas e historial de commits balanceado y verificable de los 3 estudiantes. |

---

## 3. Esquema Relacional de Supabase con RLS

```sql
-- Habilitar RLS
alter table public.profiles enable row level security;
alter table public.bets enable row level security;

-- 1. Tabla de Perfiles
create table public.profiles (
  id uuid references auth.users on delete cascade primary key,
  username text not null,
  points_balance integer default 1000 not null,
  badges text[] default array[]::text[],
  updated_at timestamp with time zone default now()
);

-- Políticas RLS para Profiles
create policy "Ver perfiles públicos" on public.profiles for select using (true);
create policy "Editar propio perfil" on public.profiles for update using (auth.uid() = id);

-- 2. Tabla de Pronósticos / Apuestas (CRUD Completo por Usuario)
create table public.bets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade default auth.uid() not null,
  match_id text not null,
  selected_team text not null,
  odds numeric(4,2) not null,
  points_staked integer not null check (points_staked > 0),
  status text default 'PENDING' not null, -- 'PENDING' | 'WON' | 'LOST' | 'CANCELLED'
  points_won integer default 0,
  created_at timestamp with time zone default now()
);

-- Políticas RLS CRUD para Bets
create policy "Ver propias apuestas" on public.bets for select using (auth.uid() = user_id);
create policy "Crear apuesta propia" on public.bets for insert with check (auth.uid() = user_id);
create policy "Editar apuesta pendiente propia" on public.bets for update using (auth.uid() = user_id);
create policy "Eliminar apuesta pendiente propia" on public.bets for delete using (auth.uid() = user_id);
```

---

## 4. Estructura de Archivos Recomendada (3 Capas)

```
lib/
├── models/
│   ├── match_model.dart        # Modelo con factory MatchModel.fromJson
│   ├── bet_model.dart          # Modelo de apuesta y RLS
│   └── user_profile_model.dart # Perfil y saldo
├── services/
│   ├── sports_api_service.dart # Consumo con dio y Future<List<MatchModel>>
│   └── supabase_service.dart   # Auth, queries CRUD y RLS
├── providers/
│   ├── auth_provider.dart      # ChangeNotifier de sesión
│   └── betting_provider.dart   # ChangeNotifier de saldo, apuestas y simulación
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart   # Formulario con validación
│   │   └── auth_gate.dart      # Control de sesión obligatorio
│   ├── matches/
│   │   ├── matches_screen.dart # FutureBuilder con GridView/ListView
│   │   └── match_detail_screen.dart # Detalle con Hero y datos por constructor
│   ├── learn/
│   │   └── trivia_screen.dart  # Modo Aprender (Trivia)
│   ├── profile/
│   │   └── profile_screen.dart # Insignias y balance
│   └── ranking/
│       └── ranking_screen.dart # Tabla de posiciones
├── widgets/
│   ├── match_card.dart         # Widget modular con Hero
│   ├── odds_button.dart        # Botón de cuota con AnimatedScale
│   └── empty_state_widget.dart # Manejo de estados vacíos
└── main.dart                   # MultiProvider y ThemeData M3
```

---

## 5. Criterios de Evaluación y Preparación para la Interrogación Individual

1. **Defensa del Código:** Todos los integrantes deben dominar:
   - Ciclo de vida del `StatefulWidget` (`initState`, `build`, `dispose`).
   - Diferencia entre `StatelessWidget` y `StatefulWidget`.
   - Cómo viaja el dato desde `dio` -> `fromJson` -> `FutureBuilder` -> `Widget`.
   - Cómo `Provider` notifica a la UI usando `notifyListeners()` y `context.watch<T>()`.
   - Cómo protege Supabase la tabla con `auth.uid() = user_id` mediante RLS.
2. **Resiliencia en Vivo:** La app no debe caerse en la presentación grupal: manejo riguroso de errores (`try-catch`), estados de carga (`CircularProgressIndicator`) y estados vacíos.
