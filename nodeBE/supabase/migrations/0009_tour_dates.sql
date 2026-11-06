-- Date multiple per tour: lo stesso tour (stesso link e QR) può uscire più
-- volte. Le date stanno in tours.dates; un trigger tiene start_at = prima data
-- e last_start_at = ultima, così "tour futuro" = last_start_at >= now() senza
-- job programmati. Richieste e carrello ricordano la data scelta.
-- Da eseguire una sola volta nello SQL editor del progetto Supabase già in uso.

alter table public.tours add column if not exists dates timestamptz[] not null default '{}';
alter table public.tours add column if not exists last_start_at timestamptz;

update public.tours
   set dates = array[start_at], last_start_at = start_at
 where cardinality(dates) = 0;

create or replace function public.tours_normalize_dates() returns trigger
language plpgsql as $$
begin
  -- Client vecchi che cambiano solo start_at: diventa l'unica data.
  if cardinality(new.dates) = 0
     or (tg_op = 'UPDATE' and new.dates = old.dates
         and new.start_at is distinct from old.start_at) then
    new.dates := array[new.start_at];
  end if;
  new.dates := array(select distinct d from unnest(new.dates) d order by d);
  if cardinality(new.dates) not between 1 and 60 then
    raise exception 'Un tour deve avere da 1 a 60 date';
  end if;
  new.start_at := new.dates[1];
  new.last_start_at := new.dates[cardinality(new.dates)];
  return new;
end $$;

drop trigger if exists tours_normalize_dates on public.tours;
create trigger tours_normalize_dates
  before insert or update of dates, start_at on public.tours
  for each row execute function public.tours_normalize_dates();

create index if not exists tours_last_start_at_idx on public.tours (last_start_at);

grant update (dates) on public.tours to authenticated;

-- Data scelta dal turista (le righe vecchie restano senza).
alter table public.booking_requests add column if not exists start_at timestamptz;
alter table public.cart_items add column if not exists start_at timestamptz;

create or replace function public.notify_new_request() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into notifications (user_id, message)
  select t.guide_id,
         format('Nuova richiesta da %s per "%s"%s (%s persone).',
                new.name, t.title,
                coalesce(' del ' || to_char(new.start_at at time zone 'Europe/Rome',
                                            'DD/MM/YYYY HH24:MI'), ''),
                new.people)
    from tours t where t.id = new.tour_id;
  return new;
end $$;
