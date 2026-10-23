-- =============================================================================
-- VolleyBet — HU-03 (Tabla bets con RLS / CRUD) y HU-04 (Liquidación de apuestas)
-- Ejecutar completo en: Supabase Dashboard > SQL Editor > New query > Run.
-- Es idempotente: se puede volver a ejecutar sin romper datos existentes.
-- =============================================================================

-- 1. Tabla de pronósticos / apuestas -------------------------------------------
create table if not exists public.bets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade default auth.uid() not null,
  match_id text not null,
  selected_team text not null,
  odds numeric(4,2) not null,
  points_staked integer not null check (points_staked > 0),
  status text default 'PENDING' not null,
  points_won integer default 0,
  created_at timestamp with time zone default now()
);

-- Columnas añadidas para mostrar el enfrentamiento en el historial y ordenar la racha
alter table public.bets add column if not exists home_team text;
alter table public.bets add column if not exists away_team text;
alter table public.bets add column if not exists settled_at timestamp with time zone;

do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'bets_status_check') then
    alter table public.bets
      add constraint bets_status_check
      check (status in ('PENDING', 'WON', 'LOST', 'CANCELLED'));
  end if;
  if not exists (select 1 from pg_constraint where conname = 'profiles_points_balance_non_negative') then
    alter table public.profiles
      add constraint profiles_points_balance_non_negative
      check (points_balance >= 0);
  end if;
end $$;

create index if not exists bets_user_id_idx on public.bets (user_id);
create index if not exists bets_match_id_idx on public.bets (match_id);

-- 2. Row Level Security (Requisito 5) ------------------------------------------
alter table public.bets enable row level security;

drop policy if exists "Ver propias apuestas" on public.bets;
drop policy if exists "Crear apuesta propia" on public.bets;
drop policy if exists "Editar apuesta pendiente propia" on public.bets;
drop policy if exists "Eliminar apuesta pendiente propia" on public.bets;

create policy "Ver propias apuestas" on public.bets
  for select using (auth.uid() = user_id);

create policy "Crear apuesta propia" on public.bets
  for insert with check (auth.uid() = user_id);

-- Solo se editan apuestas PENDING; el nuevo estado puede ser WON/LOST (liquidación HU-04).
create policy "Editar apuesta pendiente propia" on public.bets
  for update using (auth.uid() = user_id and status = 'PENDING')
  with check (auth.uid() = user_id);

create policy "Eliminar apuesta pendiente propia" on public.bets
  for delete using (auth.uid() = user_id and status = 'PENDING');

-- 3. Saldo coherente: trigger que mueve puntos en la misma transacción ----------
-- El cliente nunca escribe points_balance para apostar: el trigger descuenta,
-- ajusta diferencias, reembolsa cancelaciones y abona premios (monto * cuota).
create or replace function public.bets_apply_balance()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := coalesce(new.user_id, old.user_id);
  v_balance integer;
  v_delta integer;
begin
  select points_balance into v_balance
  from public.profiles
  where id = v_user
  for update;

  if v_balance is null then
    -- Borrado en cascada de un usuario: el perfil ya no existe y no hay saldo que mover.
    if tg_op = 'DELETE' then
      return old;
    end if;
    raise exception 'Perfil no encontrado para el usuario %', v_user;
  end if;

  if tg_op = 'INSERT' then
    if new.status <> 'PENDING' then
      raise exception 'Una apuesta nueva debe crearse en estado PENDING';
    end if;
    if new.points_staked > v_balance then
      raise exception 'Saldo insuficiente (disponibles: % pts)', v_balance;
    end if;
    new.points_won := 0;
    new.settled_at := null;
    update public.profiles
      set points_balance = points_balance - new.points_staked, updated_at = now()
      where id = v_user;
    return new;
  end if;

  if tg_op = 'UPDATE' then
    if old.status <> 'PENDING' then
      raise exception 'Solo se pueden modificar apuestas en estado PENDING';
    end if;
    if new.user_id <> old.user_id
       or new.match_id <> old.match_id
       or new.selected_team <> old.selected_team
       or new.odds <> old.odds then
      raise exception 'Solo se puede modificar el monto o liquidar la apuesta';
    end if;

    if new.status = 'PENDING' then
      v_delta := new.points_staked - old.points_staked;
      if v_delta > v_balance then
        raise exception 'Saldo insuficiente (disponibles: % pts)', v_balance;
      end if;
      new.points_won := 0;
      update public.profiles
        set points_balance = points_balance - v_delta, updated_at = now()
        where id = v_user;
      return new;
    end if;

    if new.points_staked <> old.points_staked then
      raise exception 'No se puede cambiar el monto al liquidar una apuesta';
    end if;
    new.settled_at := now();

    if new.status = 'WON' then
      new.points_won := round(old.points_staked * old.odds);
      update public.profiles
        set points_balance = points_balance + new.points_won, updated_at = now()
        where id = v_user;
    elsif new.status = 'CANCELLED' then
      new.points_won := 0;
      update public.profiles
        set points_balance = points_balance + old.points_staked, updated_at = now()
        where id = v_user;
    else
      new.points_won := 0; -- LOST
    end if;
    return new;
  end if;

  -- DELETE: cancelar apuesta pendiente devuelve el monto íntegro
  if old.status = 'PENDING' then
    update public.profiles
      set points_balance = points_balance + old.points_staked, updated_at = now()
      where id = v_user;
  end if;
  return old;
end;
$$;

drop trigger if exists bets_apply_balance on public.bets;
create trigger bets_apply_balance
  before insert or update or delete on public.bets
  for each row execute function public.bets_apply_balance();
