# GuidaTour – backend Java (Spring Boot)

Scheletro del backend: **Spring Boot 4.2.0**, **Spring Security**, Java **25**, Maven, packaging **WAR**
(si avvia da solo con `java -jar` oppure si installa su un Tomcat esterno).
Monolite modulare predisposto a microservizi: un package per modulo sotto `it.guidatour`.

| Package | Modulo |
| --- | --- |
| `config` | sicurezza, CORS |
| `auth` | autenticazione e autorizzazione |
| `users` | account, ruoli, profili professionali |
| `tours` | tour, date, servizi accessori, slug e redirect 301 |
| `bookings` | preferiti, carrello, richieste di prenotazione |
| `assignments` | cessione di un tour tra professionisti |
| `notifications` | avvisi nell'app, consensi WhatsApp |
| `publicsite` | pagine pubbliche per la SEO |
| `admin` | approvazioni e statistiche |

Le dipendenze tra moduli vanno in una sola direzione (identità ← offerta ← domanda/collaborazione).

## Sicurezza (stato attuale)
- Tutto è **chiuso di default**: le richieste non autenticate ricevono `401`.
- Pubblici: `/actuator/health`, `/actuator/info` e le `GET` su `/api/public/**`.
- API senza stato: nessuna sessione, nessun cookie, CSRF disattivato, niente login con form o HTTP Basic.
- Header di sicurezza: `X-Content-Type-Options`, `X-Frame-Options: DENY`, `Content-Security-Policy`.
- CORS: nessuna origine ammessa di default; si impostano con la variabile `GUIDATOUR_CORS_ALLOWED_ORIGINS`.
- **Il meccanismo di autenticazione è una decisione aperta** (account propri con Spring Security oppure JWT
  di Supabase Auth / Cognito): finché non è presa nessuno può autenticarsi.
- Database non ancora collegato: si aggiunge dopo la scelta MySQL 8 / Postgres (modello in `docs/data-model/mysql`).

## Comandi
```bash
mvn verify                                   # compila, esegue i test, crea target/guidatour-backend-*.war
java -jar target/guidatour-backend-0.0.1-SNAPSHOT.war
curl http://localhost:8080/actuator/health   # {"status":"UP"}
```

## Eclipse / STS
File › Import › Maven › Existing Maven Projects › cartella `JavaBE`.
Avvio: tasto destro su `GuidaTourApplication` › Run As › Spring Boot App.
Il JDK del progetto deve essere il 25.
