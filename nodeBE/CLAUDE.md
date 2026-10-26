# CLAUDE.md — backend GuidaTour

## Comandi

```bash
npm run dev       # tsx watch src/index.ts
npm run build     # tsc → dist/
npm start         # node dist/index.js (quello che gira su Render)
npx tsc --noEmit  # solo type-check
```

Nessuna suite di test. Node 18+.

## Setup Supabase

1. Creare il progetto Supabase ed eseguire `supabase/schema.sql` nell'SQL editor (pensato per un database vuoto).
2. Mettere URL e anon key in `src/config.ts` (la anon key è pubblica: la sicurezza è nelle policy RLS).
3. `role`, `verified` e `is_admin` dei profili si cambiano solo dalla dashboard Supabase. Alla registrazione il ruolo arriva da `options.data.role` di `signUp` (default `turista`); `verified` parte sempre `false`.

## Architettura

- `src/index.ts`: app Hono, CORS, gestione errori, montaggio rotte.
- `src/routes/*`: solo HTTP (validazione zod, auth, status code).
- `src/services/*`: accesso ai dati e regole di business; ricevono un client Supabase già legato all'utente.
- `src/auth.ts`: `requireAuth`/`optionalAuth` verificano il bearer token di Supabase Auth e mettono in contesto `db` (client con il token dell'utente, o anon) e `userId`.

La sicurezza vera è nelle RLS di `supabase/schema.sql`; il backend aggiunge le regole che RLS non esprime bene (chi può pubblicare pacchetti o visite culturali, in `tourBlockReason`, copia delle regole del form Flutter).

Accorgimenti:
- Le richieste di prenotazione e i consensi WhatsApp possono arrivare senza login: RLS permette l'insert ma non la rilettura, quindi l'id lo genera il backend.
- Il testo del consenso WhatsApp lo fissa il backend (`config.ts`), non l'app, perché fa da prova.
- Le notifiche le scrivono i trigger del database; contatori `visits`/`scans` solo tramite la funzione `record_tour_view`.
- Rate limit in memoria: vale per una sola istanza.
- JSON in camelCase; stati in minuscolo (`inviata|confermata|rifiutata`, `proposto|accettato|rifiutato|annullato|completato`); ruoli `turista|guida|accompagnatore|tourOperator` come l'enum Dart.

## Endpoint

Pubblici (token opzionale):
- `GET /health`
- `GET /tours?q=&category=&language=&guideId=&from=&to=&includePast=&limit=` — di default solo tour futuri
- `GET /tours/options` — categorie, lingue, servizi accessori
- `GET /tours/:id` — tour + `guide` (profilo pubblico)
- `POST /tours/:id/visit`, `POST /tours/:id/scan` — contatori
- `POST /tours/:id/requests` — `{name, email, phone?, people, message?}`
- `GET /guides?role=`, `GET /guides/:id`
- `GET /consents/text`, `POST /consents` — `{phone: "+39...", source}`

Con login:
- `POST /tours`, `PATCH /tours/:id`, `DELETE /tours/:id` — solo professionisti, solo propri tour
- `GET /tours/:id/requests`, `GET /requests/received`, `PATCH /requests/:id` `{status}`
- `GET|PATCH /me`, `GET /me/requests`, `GET /me/dashboard` (tour con richieste + avvisi overbooking)
- `GET /me/favorites`, `PUT|DELETE /me/favorites/:tourId`
- `GET|POST /me/cart`, `PATCH|DELETE /me/cart/:tourId`, `POST /me/cart/checkout`
- `GET /me/notifications?unread=`, `POST /me/notifications/read`, `POST /me/notifications/:id/read`
- `GET /assignments`, `POST /assignments` `{tourId, toGuideId}`, `POST /assignments/:id/respond` `{accept}`, `/cancel`, `/complete`
- `GET /consents`, `POST /consents/:id/revoke` — solo admin
