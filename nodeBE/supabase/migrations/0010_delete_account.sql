-- Cancellazione dell'account su richiesta dell'utente (privacy, diritto
-- all'oblio). Da eseguire una sola volta nello SQL editor del progetto
-- Supabase già in uso.
--
-- L'utente chiama la funzione dall'app (rpc 'delete_my_account'); la foto
-- profilo l'app la cancella prima con le API di Storage (le tabelle di
-- storage non si svuotano da SQL).
--
-- Cosa sparisce:
--  - le richieste di prenotazione inviate dall'utente (nome, email, telefono);
--  - i consensi WhatsApp collegati al suo account;
--  - l'utente di Supabase Auth, e a cascata profilo, tour pubblicati (con le
--    richieste ricevute), preferiti, carrello, avvisi e proposte tra colleghi.
-- Gli account admin non si cancellano da qui: altrimenti si potrebbe restare
-- senza nessun admin. Si tolgono dalla dashboard Supabase.

create or replace function public.delete_my_account()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  me uuid := auth.uid();
begin
  if me is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  if exists (select 1 from public.profiles where id = me and is_admin) then
    raise exception 'admin_account' using errcode = '42501';
  end if;

  delete from public.booking_requests where user_id = me;
  delete from public.whatsapp_consents where user_id = me;
  delete from auth.users where id = me;
end;
$$;

revoke all on function public.delete_my_account() from public, anon;
grant execute on function public.delete_my_account() to authenticated;
