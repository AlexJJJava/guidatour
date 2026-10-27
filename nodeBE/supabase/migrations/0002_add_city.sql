-- Aggiunge la città ai tour (selezione città in home, come GetYourGuide).
-- Da eseguire una sola volta nello SQL editor del progetto Supabase già in uso
-- (schema.sql resta il riferimento per un database nuovo, dove include già
-- questa colonna).

alter table public.tours add column if not exists city text not null default 'Roma';
create index if not exists tours_city_idx on public.tours (city);
