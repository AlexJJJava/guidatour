-- Schema GuidaTour per Supabase (Postgres).
-- Eseguire nell'SQL editor del progetto Supabase. È idempotente solo in parte:
-- pensato per un database vuoto.
--
-- La sicurezza è nelle policy RLS: il backend usa la anon key e il token
-- dell'utente, quindi ogni query vede solo ciò che le policy consentono.

-- ── Profili ──────────────────────────────────────────────────────────
-- Un profilo per ogni utente di Supabase Auth, creato dal trigger qui sotto.
-- role/verified/is_admin si cambiano solo da dashboard Supabase (service role).
create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  name text not null default '',
  email text not null default '',
  role text not null default 'turista'
    check (role in ('turista', 'guida', 'accompagnatore', 'tourOperator')),
  provider text not null default 'email',
  verified boolean not null default false,
  is_admin boolean not null default false,
  languages text[] not null default '{Italiano}',
  bio text not null default '',
  created_at timestamptz not null default now()
);

create function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  meta_role text := new.raw_user_meta_data ->> 'role';
begin
  insert into public.profiles (id, email, name, role, provider)
  values (
    new.id,
    coalesce(new.email, ''),
    coalesce(new.raw_user_meta_data ->> 'name', new.raw_user_meta_data ->> 'full_name', ''),
    case when meta_role in ('turista', 'guida', 'accompagnatore', 'tourOperator')
      then meta_role else 'turista' end,
    coalesce(new.raw_app_meta_data ->> 'provider', 'email')
  );
  return new;
end $$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

create function public.is_professional(uid uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from profiles where id = uid and role <> 'turista')
$$;

create function public.is_admin(uid uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from profiles where id = uid and is_admin)
$$;

alter table public.profiles enable row level security;

create policy profiles_select_own on public.profiles
  for select to authenticated using (id = auth.uid());
create policy profiles_update_own on public.profiles
  for update to authenticated using (id = auth.uid()) with check (id = auth.uid());

-- L'utente può modificare solo i campi descrittivi, non ruolo o verifica.
revoke insert, update, delete on public.profiles from anon, authenticated;
grant update (name, bio, languages) on public.profiles to authenticated;

-- Vista pubblica dei professionisti, senza email: la usano la scheda tour
-- e l'elenco colleghi per la cessione. Gira con i permessi del proprietario
-- (bypassa RLS) di proposito, esponendo solo queste colonne.
create view public.public_profiles as
  select id, name, role, verified, languages, bio
  from public.profiles
  where role <> 'turista';

grant select on public.public_profiles to anon, authenticated;

-- ── Tour / eventi ────────────────────────────────────────────────────
-- id è uno slug leggibile (es. "colosseo-foro-a1b2c3"), usato anche nell'URL pubblico.
create table public.tours (
  id text primary key,
  guide_id uuid not null references public.profiles (id) on delete cascade,
  title text not null check (char_length(title) between 3 and 120),
  category text not null,
  language text not null,
  duration text not null,
  start_at timestamptz not null,
  price numeric(10, 2) not null check (price >= 0),
  meeting_point text not null,
  description text not null default '',
  seats int not null check (seats > 0),
  accessories text[] not null default '{}',
  visits int not null default 0,
  scans int not null default 0,
  created_at timestamptz not null default now()
);

create index tours_start_at_idx on public.tours (start_at);
create index tours_guide_id_idx on public.tours (guide_id);

alter table public.tours enable row level security;

create policy tours_select_all on public.tours
  for select to anon, authenticated using (true);
create policy tours_insert_own on public.tours
  for insert to authenticated
  with check (guide_id = auth.uid() and public.is_professional(auth.uid()));
create policy tours_update_own on public.tours
  for update to authenticated
  using (guide_id = auth.uid()) with check (guide_id = auth.uid());
create policy tours_delete_own on public.tours
  for delete to authenticated using (guide_id = auth.uid());

-- visits/scans si incrementano solo con record_tour_view.
revoke update on public.tours from anon, authenticated;
grant update (title, category, language, duration, start_at, price,
              meeting_point, description, seats, accessories)
  on public.tours to authenticated;

create function public.record_tour_view(p_tour_id text, p_scan boolean default false)
returns void language sql security definer set search_path = public as $$
  update tours
     set visits = visits + 1,
         scans = scans + case when p_scan then 1 else 0 end
   where id = p_tour_id
$$;

grant execute on function public.record_tour_view(text, boolean) to anon, authenticated;

-- ── Richieste di prenotazione (non vincolanti) ───────────────────────
create table public.booking_requests (
  id uuid primary key default gen_random_uuid(),
  tour_id text not null references public.tours (id) on delete cascade,
  user_id uuid references public.profiles (id) on delete set null,
  name text not null,
  email text not null,
  phone text not null default '',
  people int not null check (people between 1 and 100),
  message text not null default '',
  status text not null default 'inviata'
    check (status in ('inviata', 'confermata', 'rifiutata')),
  created_at timestamptz not null default now()
);

create index booking_requests_tour_id_idx on public.booking_requests (tour_id);
create index booking_requests_user_id_idx on public.booking_requests (user_id);

alter table public.booking_requests enable row level security;

-- Anche chi non è loggato può inviare una richiesta, ma non leggerla.
create policy requests_insert on public.booking_requests
  for insert to anon, authenticated
  with check (status = 'inviata' and (user_id is null or user_id = auth.uid()));
create policy requests_select on public.booking_requests
  for select to authenticated
  using (
    user_id = auth.uid()
    or exists (select 1 from public.tours t
               where t.id = tour_id and t.guide_id = auth.uid())
  );
create policy requests_update_owner on public.booking_requests
  for update to authenticated
  using (exists (select 1 from public.tours t
                 where t.id = tour_id and t.guide_id = auth.uid()))
  with check (exists (select 1 from public.tours t
                      where t.id = tour_id and t.guide_id = auth.uid()));

revoke update on public.booking_requests from anon, authenticated;
grant update (status) on public.booking_requests to authenticated;

-- ── Preferiti e carrello del turista ─────────────────────────────────
create table public.favorites (
  user_id uuid not null references public.profiles (id) on delete cascade,
  tour_id text not null references public.tours (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, tour_id)
);

create table public.cart_items (
  user_id uuid not null references public.profiles (id) on delete cascade,
  tour_id text not null references public.tours (id) on delete cascade,
  people int not null default 2 check (people between 1 and 100),
  created_at timestamptz not null default now(),
  primary key (user_id, tour_id)
);

alter table public.favorites enable row level security;
alter table public.cart_items enable row level security;

create policy favorites_own on public.favorites
  for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy cart_items_own on public.cart_items
  for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- ── Consensi WhatsApp (BR-011D) ──────────────────────────────────────
-- Prova del consenso: testo, mittente e momento esatti. Leggibili solo dagli admin.
create table public.whatsapp_consents (
  id uuid primary key default gen_random_uuid(),
  phone text not null,
  source text not null,
  consent_text text not null,
  sender text not null default 'GuidaTour',
  user_id uuid references public.profiles (id) on delete set null,
  created_at timestamptz not null default now(),
  revoked_at timestamptz
);

alter table public.whatsapp_consents enable row level security;

create policy consents_insert on public.whatsapp_consents
  for insert to anon, authenticated
  with check (revoked_at is null and (user_id is null or user_id = auth.uid()));
create policy consents_select_admin on public.whatsapp_consents
  for select to authenticated using (public.is_admin(auth.uid()));
create policy consents_update_admin on public.whatsapp_consents
  for update to authenticated
  using (public.is_admin(auth.uid())) with check (public.is_admin(auth.uid()));

revoke update on public.whatsapp_consents from anon, authenticated;
grant update (revoked_at) on public.whatsapp_consents to authenticated;

-- ── Cambio / cessione tour (BR-011A) ─────────────────────────────────
create table public.assignments (
  id uuid primary key default gen_random_uuid(),
  tour_id text not null references public.tours (id) on delete cascade,
  from_guide_id uuid not null references public.profiles (id) on delete cascade,
  to_guide_id uuid not null references public.profiles (id) on delete cascade,
  status text not null default 'proposto'
    check (status in ('proposto', 'accettato', 'rifiutato', 'annullato', 'completato')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (from_guide_id <> to_guide_id)
);

-- Una sola proposta aperta per tour.
create unique index assignments_one_open_per_tour
  on public.assignments (tour_id) where status = 'proposto';

alter table public.assignments enable row level security;

create policy assignments_select on public.assignments
  for select to authenticated
  using (auth.uid() in (from_guide_id, to_guide_id));
create policy assignments_insert on public.assignments
  for insert to authenticated
  with check (
    from_guide_id = auth.uid()
    and status = 'proposto'
    and public.is_professional(to_guide_id)
    and exists (select 1 from public.tours t
                where t.id = tour_id and t.guide_id = auth.uid())
  );
-- La destinataria può solo accettare o rifiutare, mai riassegnare (BR-011A.1).
create policy assignments_respond on public.assignments
  for update to authenticated
  using (to_guide_id = auth.uid() and status = 'proposto')
  with check (to_guide_id = auth.uid() and status in ('accettato', 'rifiutato'));
create policy assignments_owner_close on public.assignments
  for update to authenticated
  using (from_guide_id = auth.uid() and status in ('proposto', 'accettato'))
  with check (from_guide_id = auth.uid() and status in ('annullato', 'completato'));

revoke update on public.assignments from anon, authenticated;
grant update (status, updated_at) on public.assignments to authenticated;

-- ── Notifiche in-app ─────────────────────────────────────────────────
-- Scritte solo dai trigger qui sotto; un domani da qui partono email/WhatsApp.
create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  message text not null,
  read_at timestamptz,
  created_at timestamptz not null default now()
);

create index notifications_user_id_idx on public.notifications (user_id, created_at desc);

alter table public.notifications enable row level security;

create policy notifications_select_own on public.notifications
  for select to authenticated using (user_id = auth.uid());
create policy notifications_update_own on public.notifications
  for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

revoke insert, update, delete on public.notifications from anon, authenticated;
grant update (read_at) on public.notifications to authenticated;

create function public.notify_new_request() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into notifications (user_id, message)
  select t.guide_id,
         format('Nuova richiesta da %s per "%s" (%s persone).', new.name, t.title, new.people)
    from tours t where t.id = new.tour_id;
  return new;
end $$;

create trigger booking_requests_notify
  after insert on public.booking_requests
  for each row execute function public.notify_new_request();

create function public.notify_assignment() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  tour_title text;
  to_name text;
begin
  select title into tour_title from tours where id = new.tour_id;
  if tg_op = 'INSERT' then
    insert into notifications (user_id, message)
    values (new.to_guide_id, format('Ti è stato proposto il tour "%s".', tour_title));
  elsif new.status in ('accettato', 'rifiutato') and old.status = 'proposto' then
    select name into to_name from profiles where id = new.to_guide_id;
    insert into notifications (user_id, message)
    values (new.from_guide_id,
            format('%s ha %s "%s".', to_name, new.status, tour_title));
  end if;
  return new;
end $$;

create trigger assignments_notify
  after insert or update of status on public.assignments
  for each row execute function public.notify_assignment();
