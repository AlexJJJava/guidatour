-- Area di gestione dell'admin: sospensione dei professionisti, eliminazione
-- dei tour, numeri della piattaforma.
-- Da eseguire una sola volta nello SQL editor del progetto Supabase già in uso.

-- Sospeso: come rifiutato, l'utente torna turista e sparisce dagli elenchi.
alter table public.profiles drop constraint if exists profiles_approval_status_check;
alter table public.profiles add constraint profiles_approval_status_check
  check (approval_status in ('in_attesa', 'approvato', 'rifiutato', 'sospeso'));

create or replace function public.set_approval_status(p_user uuid, p_status text)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_admin(auth.uid()) then
    raise exception 'Riservato agli amministratori' using errcode = '42501';
  end if;
  if p_status not in ('approvato', 'rifiutato', 'sospeso') then
    raise exception 'Stato non valido' using errcode = '22P02';
  end if;
  update profiles set approval_status = p_status
   where id = p_user and role <> 'turista';
  if not found then
    raise exception 'Profilo non trovato' using errcode = 'P0002';
  end if;
  insert into notifications (user_id, message)
  values (p_user, case p_status
    when 'approvato' then 'Il tuo account è stato approvato: ora puoi pubblicare i tuoi tour.'
    when 'sospeso' then 'Il tuo account professionale è stato sospeso: i tuoi tour non sono più visibili.'
    else 'La tua registrazione non è stata approvata.' end);
end $$;

-- I tour si vedono solo se chi li organizza è un professionista approvato;
-- l'organizzatore e l'admin li vedono sempre.
drop policy if exists tours_select_all on public.tours;
drop policy if exists tours_select_visible on public.tours;
create policy tours_select_visible on public.tours
  for select to anon, authenticated
  using (public.is_professional(guide_id)
         or guide_id = auth.uid()
         or public.is_admin(auth.uid()));

drop policy if exists tours_delete_admin on public.tours;
create policy tours_delete_admin on public.tours
  for delete to authenticated using (public.is_admin(auth.uid()));

-- Numeri che l'admin non legge riga per riga (le richieste contengono dati
-- personali dei turisti): solo i totali.
create or replace function public.admin_stats() returns json
language plpgsql stable security definer set search_path = public as $$
begin
  if not public.is_admin(auth.uid()) then
    raise exception 'Riservato agli amministratori' using errcode = '42501';
  end if;
  return json_build_object(
    'requests', (select count(*) from booking_requests),
    'requestsConfirmed', (select count(*) from booking_requests where status = 'confermata'),
    'visits', (select coalesce(sum(visits), 0) from tours),
    'scans', (select coalesce(sum(scans), 0) from tours),
    'assignments', (select count(*) from assignments));
end $$;

revoke execute on function public.admin_stats() from public, anon;
grant execute on function public.admin_stats() to authenticated;
