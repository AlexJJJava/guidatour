-- Aggiunge la città al profilo (guide/operator/accompagnatore): usata come
-- valore precompilato in fase di creazione tour, non un vincolo rigido.
-- Da eseguire una sola volta nello SQL editor del progetto Supabase già in uso.

alter table public.profiles add column if not exists city text not null default 'Roma';

drop view if exists public.public_profiles;
create view public.public_profiles as
  select id, name, role, verified, languages, bio, city
  from public.profiles
  where role <> 'turista';
grant select on public.public_profiles to anon, authenticated;
