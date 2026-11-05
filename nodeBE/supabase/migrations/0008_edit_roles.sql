-- Ruoli modificabili dal profilo. Togliere un ruolo vale subito; aggiungerne
-- uno richiede l'approvazione dell'admin: chi è già professionista tiene i
-- ruoli approvati e i nuovi restano in pending_roles; per gli altri la
-- richiesta riparte come in registrazione (un'unica approvazione).
-- Da eseguire una sola volta nello SQL editor del progetto Supabase già in uso.

alter table public.profiles add column if not exists pending_roles text[] not null default '{}';
alter table public.profiles drop constraint if exists profiles_pending_roles_check;
alter table public.profiles add constraint profiles_pending_roles_check
  check (pending_roles <@ array['guida', 'accompagnatore', 'tourOperator']);

create or replace function public.primary_role(p_roles text[]) returns text
language sql immutable as $$
  select case
    when 'guida' = any(p_roles) then 'guida'
    when 'tourOperator' = any(p_roles) then 'tourOperator'
    when 'accompagnatore' = any(p_roles) then 'accompagnatore'
    else 'turista' end
$$;

create or replace function public.request_roles(p_roles text[]) returns void
language plpgsql security definer set search_path = public as $$
declare
  me profiles%rowtype;
  wanted text[] := array(
    select distinct r from unnest(coalesce(p_roles, '{}')) r
    where r in ('guida', 'accompagnatore', 'tourOperator') order by r);
  kept text[];
  added text[];
begin
  select * into me from profiles where id = auth.uid();
  if not found then
    raise exception 'Profilo non trovato' using errcode = 'P0002';
  end if;
  if me.approval_status = 'sospeso' then
    raise exception 'Account sospeso: i ruoli non si possono cambiare' using errcode = '42501';
  end if;
  if me.approval_status = 'approvato' and me.roles <> '{}' then
    kept := array(select r from unnest(me.roles) r where r = any(wanted) order by r);
    added := array(select r from unnest(wanted) r where not r = any(me.roles) order by r);
    if kept <> '{}' then
      update profiles set roles = kept, pending_roles = added,
        role = public.primary_role(kept) where id = me.id;
      return;
    end if;
    -- Tolti tutti i ruoli approvati: si riparte come un turista.
    wanted := added;
  end if;
  update profiles set
    roles = wanted,
    pending_roles = '{}',
    role = public.primary_role(wanted),
    approval_status = case when wanted = '{}' then 'approvato' else 'in_attesa' end
  where id = me.id;
end $$;

revoke execute on function public.request_roles(text[]) from public, anon;
grant execute on function public.request_roles(text[]) to authenticated;

-- Approvazione: se l'utente è già approvato e ha ruoli in attesa, si decide
-- solo su quelli (approvati si aggiungono, rifiutati si scartano).
create or replace function public.set_approval_status(p_user uuid, p_status text)
returns void language plpgsql security definer set search_path = public as $$
declare
  target profiles%rowtype;
  extra boolean;
begin
  if not public.is_admin(auth.uid()) then
    raise exception 'Riservato agli amministratori' using errcode = '42501';
  end if;
  if p_status not in ('approvato', 'rifiutato', 'sospeso') then
    raise exception 'Stato non valido' using errcode = '22P02';
  end if;
  select * into target from profiles where id = p_user and role <> 'turista';
  if not found then
    raise exception 'Profilo non trovato' using errcode = 'P0002';
  end if;
  extra := target.approval_status = 'approvato' and target.pending_roles <> '{}'
           and p_status <> 'sospeso';
  if extra and p_status = 'approvato' then
    update profiles set
      roles = array(select distinct r from unnest(roles || pending_roles) r order by r),
      role = public.primary_role(roles || pending_roles),
      pending_roles = '{}'
    where id = p_user;
  elsif extra then
    update profiles set pending_roles = '{}' where id = p_user;
  else
    update profiles set approval_status = p_status,
      pending_roles = case when p_status = 'approvato'
        then '{}' else pending_roles end
    where id = p_user;
  end if;
  insert into notifications (user_id, message)
  values (p_user, case
    when extra and p_status = 'approvato' then 'I nuovi ruoli che hai chiesto sono stati approvati.'
    when extra then 'I nuovi ruoli che hai chiesto non sono stati approvati.'
    when p_status = 'approvato' then 'Il tuo account è stato approvato: ora puoi pubblicare i tuoi tour.'
    when p_status = 'sospeso' then 'Il tuo account professionale è stato sospeso: i tuoi tour non sono più visibili.'
    else 'La tua registrazione non è stata approvata.' end);
end $$;
