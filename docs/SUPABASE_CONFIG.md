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
