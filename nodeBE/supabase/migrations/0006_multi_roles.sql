-- Più ruoli professionali per utente (guida, accompagnatore, tour operator),
-- con un'unica approvazione dell'admin. Chi non ne ha è un turista.
-- `role` resta il ruolo principale (guida, poi tour operator, poi
-- accompagnatore), usato dalle policy esistenti.
-- Da eseguire una sola volta nello SQL editor del progetto Supabase già in uso.

alter table public.profiles add column if not exists roles text[] not null default '{}';
alter table public.profiles drop constraint if exists profiles_roles_check;
alter table public.profiles add constraint profiles_roles_check
  check (roles <@ array['guida', 'accompagnatore', 'tourOperator']);

update public.profiles set roles = array[role]
  where role <> 'turista' and roles = '{}';

create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  meta jsonb := new.raw_user_meta_data;
  wanted text[] := case when jsonb_typeof(meta -> 'roles') = 'array'
    then array(select jsonb_array_elements_text(meta -> 'roles'))
    else array[meta ->> 'role'] end;
  new_roles text[] := array(
    select distinct r from unnest(wanted) r
    where r in ('guida', 'accompagnatore', 'tourOperator') order by r);
  new_role text := case
    when 'guida' = any(new_roles) then 'guida'
    when 'tourOperator' = any(new_roles) then 'tourOperator'
    when 'accompagnatore' = any(new_roles) then 'accompagnatore'
    else 'turista' end;
begin
  insert into public.profiles (id, email, name, role, roles, provider, approval_status)
  values (
    new.id,
    coalesce(new.email, ''),
    coalesce(meta ->> 'name', meta ->> 'full_name', ''),
    new_role,
    new_roles,
    coalesce(new.raw_app_meta_data ->> 'provider', 'email'),
    case when new_role = 'turista' then 'approvato' else 'in_attesa' end
  );
  return new;
end $$;

-- Elenco pubblico dei professionisti approvati, con tutti i loro ruoli.
drop view if exists public.public_profiles;
create view public.public_profiles as
  select id, name, role, roles, verified, languages, bio, city
  from public.profiles
  where role <> 'turista' and approval_status = 'approvato';
grant select on public.public_profiles to anon, authenticated;
