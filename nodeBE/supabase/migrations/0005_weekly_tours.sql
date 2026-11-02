-- Tour periodici: ogni settimana, stesso giorno e stessa ora italiana.
-- Un job orario sposta avanti i tour passati, quindi link e QR non cambiano.

alter table public.tours
  add column if not exists repeat_weekly boolean not null default false;

-- La richiesta conserva la data scelta: il tour intanto si sposta in avanti.
alter table public.booking_requests
  add column if not exists tour_start timestamptz;

update public.booking_requests r
  set tour_start = t.start_at
  from public.tours t
  where t.id = r.tour_id and r.tour_start is null;

create or replace function public.set_request_tour_start() returns trigger
language plpgsql as $$
begin
  select start_at into new.tour_start from public.tours where id = new.tour_id;
  return new;
end;
$$;

drop trigger if exists booking_requests_tour_start on public.booking_requests;
create trigger booking_requests_tour_start
  before insert on public.booking_requests
  for each row execute function public.set_request_tour_start();

-- Calcolato sull'ora di Roma, così l'orario resta uguale col cambio dell'ora.
create or replace function public.roll_weekly_tours() returns void
language sql security definer set search_path = public as $$
  update public.tours
  set start_at = (
    (start_at at time zone 'Europe/Rome')
    + ceil(extract(epoch from now() - start_at) / 604800) * interval '7 days'
  ) at time zone 'Europe/Rome'
  where repeat_weekly and start_at < now();
$$;

revoke execute on function public.roll_weekly_tours() from public, anon, authenticated;

create extension if not exists pg_cron;
select cron.schedule('roll-weekly-tours', '0 * * * *', 'select public.roll_weekly_tours()');

-- Tour di prova già presenti: diventano settimanali e tornano subito visibili.
update public.tours set repeat_weekly = true;
select public.roll_weekly_tours();
