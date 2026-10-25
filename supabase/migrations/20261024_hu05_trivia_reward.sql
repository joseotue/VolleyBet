-- HU-05: recompensa acumulada de trivia.
-- Cada acierto entrega 200 puntos hasta un máximo histórico de 1.000.
-- El usuario puede repetir la trivia después de alcanzar el límite, pero
-- las rondas posteriores ya no aumentan el saldo.

alter table public.profiles
  add column if not exists trivia_points_earned integer not null default 0,
  add column if not exists trivia_points_capacity integer not null default 1000;

alter table public.profiles
  alter column trivia_points_capacity set default 1000;

-- Mantiene la capacidad configurada en 1.000 para los perfiles existentes.
update public.profiles
   set trivia_points_capacity = 1000
 where trivia_points_capacity <> 1000;

create or replace function public.claim_trivia_reward(
  p_correct_answers integer
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_profile public.profiles%rowtype;
  v_calculated_points integer;
  v_remaining_capacity integer;
  v_points_awarded integer;
  v_badges text[];
begin
  if v_user_id is null then
    raise exception 'Debes iniciar sesión para completar la trivia';
  end if;

  if p_correct_answers is null
     or p_correct_answers < 0
     or p_correct_answers > 5 then
    raise exception 'La cantidad de aciertos debe estar entre 0 y 5';
  end if;

  select *
    into v_profile
    from public.profiles
   where id = v_user_id
   for update;

  if not found then
    raise exception 'No se encontró el perfil del usuario';
  end if;

  v_calculated_points := p_correct_answers * 200;
  v_remaining_capacity := greatest(
    v_profile.trivia_points_capacity - v_profile.trivia_points_earned,
    0
  );
  v_points_awarded := least(v_calculated_points, v_remaining_capacity);
  v_badges := coalesce(v_profile.badges, array[]::text[]);

  if p_correct_answers = 5
     and not ('Experto Junior en Voleibol' = any(v_badges)) then
    v_badges := array_append(v_badges, 'Experto Junior en Voleibol');
  end if;

  update public.profiles
     set points_balance = points_balance + v_points_awarded,
         trivia_points_earned = trivia_points_earned + v_points_awarded,
         badges = v_badges,
         updated_at = now()
   where id = v_user_id
   returning * into v_profile;

  return jsonb_build_object(
    'correct_answers', p_correct_answers,
    'calculated_points', v_calculated_points,
    'points_awarded', v_points_awarded,
    'points_balance', v_profile.points_balance,
    'trivia_points_earned', v_profile.trivia_points_earned,
    'trivia_points_capacity', v_profile.trivia_points_capacity,
    'capacity_reached',
      v_profile.trivia_points_earned >= v_profile.trivia_points_capacity,
    'badges', v_profile.badges
  );
end;
$$;

revoke all on function public.claim_trivia_reward(integer) from public;
grant execute on function public.claim_trivia_reward(integer) to authenticated;
