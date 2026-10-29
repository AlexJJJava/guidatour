-- Approvazione delle registrazioni professionali da parte di un admin.
-- Guide, accompagnatori e tour operator nascono "in_attesa": finché un admin
-- non li approva non compaiono nell'elenco pubblico e non possono usare le
-- funzioni da professionista. I turisti sono approvati subito.
-- Gli utenti già registrati restano approvati (default della colonna).
-- Da eseguire una sola volta nello SQL editor del progetto Supabase già in uso.

alter table public.profiles add column if not exists approval_status text
  not null default 'approvato'
  check (approval_status in ('in_attesa', 'approvato', 'rifiutato'));

create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  meta_role text := new.raw_user_meta_data ->> 'role';
  new_role text := case when meta_role in ('turista', 'guida', 'accompagnatore', 'tourOperator')
    then meta_role else 'turista' end;
begin
  insert into public.profiles (id, email, name, role, provider, approval_status)
  values (
    new.id,
    coalesce(new.email, ''),
    coalesce(new.raw_user_meta_data ->> 'name', new.raw_user_meta_data ->> 'full_name', ''),
    new_role,
    coalesce(new.raw_app_meta_data ->> 'provider', 'email'),
    case when new_role = 'turista' then 'approvato' else 'in_attesa' end
  );
  return new;
end $$;

-- Professionista = ruolo non turista E approvato: vale per le policy dei tour
-- e delle cessioni.
create or replace function public.is_professional(uid uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from profiles
                 where id = uid and role <> 'turista' and approval_status = 'approvato')
$$;

-- Gli admin vedono tutti i profili (per la pagina delle approvazioni).
drop policy if exists profiles_select_admin on public.profiles;
create policy profiles_select_admin on public.profiles
  for select to authenticated using (public.is_admin(auth.uid()));

-- Solo professionisti approvati nell'elenco pubblico.
drop view if exists public.public_profiles;
create view public.public_profiles as
  select id, name, role, verified, languages, bio, city
  from public.profiles
  where role <> 'turista' and approval_status = 'approvato';
grant select on public.public_profiles to anon, authenticated;

-- Approva o rifiuta una registrazione: solo admin, solo profili professionali.
create or replace function public.set_approval_status(p_user uuid, p_status text)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_admin(auth.uid()) then
    raise exception 'Riservato agli amministratori' using errcode = '42501';
  end if;
  if p_status not in ('approvato', 'rifiutato') then
    raise exception 'Stato non valido' using errcode = '22P02';
  end if;
  update profiles set approval_status = p_status
   where id = p_user and role <> 'turista';
  if not found then
    raise exception 'Profilo non trovato' using errcode = 'P0002';
  end if;
  insert into notifications (user_id, message)
  values (p_user, case when p_status = 'approvato'
    then 'Il tuo account è stato approvato: ora puoi pubblicare i tuoi tour.'
    else 'La tua registrazione non è stata approvata.' end);
end $$;

revoke execute on function public.set_approval_status(uuid, text) from public, anon;
grant execute on function public.set_approval_status(uuid, text) to authenticated;

-- Per nominare il primo admin (sostituire l'email):
-- update public.profiles set is_admin = true where email = 'tua@email.it';
