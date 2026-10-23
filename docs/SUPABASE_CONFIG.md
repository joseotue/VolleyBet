# Configuración y Credenciales de Supabase — VolleyBet

Este documento contiene los datos de conexión y credenciales de Supabase para el proyecto **VolleyBet**.

---

## 1. Credenciales del Proyecto

| Parámetro | Valor | Descripción / Uso |
|---|---|---|
| **Project Base URL** | `https://urlsupzctpjdmtofbvwj.supabase.co` | URL base del proyecto para inicializar el cliente en Flutter (`Supabase.initialize`). |
| **REST API URL** | `https://urlsupzctpjdmtofbvwj.supabase.co/rest/v1/` | Endpoint directo para llamadas REST / PostgREST. |
| **Publishable / Anon Key** | `sb_publishable_0NJxQ-SUnRKBniPntN_2oQ_4p4USQeO` | Clave pública para el cliente Flutter (móvil y web). Segura para usar en frontend protegida por RLS. |
| **Secret / Service Role Key** | `[CONFIGURADA_EN_SUPABASE_DASHBOARD]` | Clave secreta con privilegios de administrador. **NUNCA incluir en la app cliente Flutter ni en Git**. |

---

## 2. Notas Importantes de Integración

### A. URL Base en Flutter
En Flutter con `supabase_flutter`, debes usar la **URL base** (sin `/rest/v1/`):
```dart
await Supabase.initialize(
  url: 'https://urlsupzctpjdmtofbvwj.supabase.co',
  anonKey: 'sb_publishable_0NJxQ-SUnRKBniPntN_2oQ_4p4USQeO',
);
```

### B. Seguridad de las Claves
- La **Publishable Key** es la que viaja en la aplicación móvil/web y está protegida mediante las políticas **Row Level Security (RLS)** en Postgres.
- La **Secret Key** omite todas las políticas RLS. Solo se debe usar en scripts administrativos o funciones serverless protegidas en backend, nunca en código que se compile hacia el usuario final.

---

## 3. Tabla `bets` con RLS (HU-03 / HU-04)

Ejecutar una vez el script [`supabase/migrations/20261023_hu03_hu04_bets_rls.sql`](../supabase/migrations/20261023_hu03_hu04_bets_rls.sql) en **Supabase Dashboard → SQL Editor → New query → Run**. Es idempotente.

Qué crea:
- Tabla `public.bets` (más columnas `home_team`, `away_team`, `settled_at`) con RLS: cada usuario solo ve, crea, edita y borra sus propias apuestas (`auth.uid() = user_id`). Editar y borrar solo se permite mientras la apuesta está `PENDING`.
- Trigger `bets_apply_balance` que mueve `profiles.points_balance` en la misma transacción: descuenta al apostar, ajusta la diferencia al editar, reembolsa al cancelar y abona `monto * cuota` al liquidar como `WON`. Rechaza apuestas que superen el saldo.

Requisito previo: la tabla `public.profiles` del esquema de HU-01 debe existir con una fila por usuario.
