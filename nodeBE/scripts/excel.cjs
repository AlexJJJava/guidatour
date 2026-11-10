const ExcelJS = require('exceljs');
// Excel di riepilogo per chi segue il progetto: `npm run docs:excel` dopo ogni attività.
const path = require('node:path');
const OUT = path.join(__dirname, '../../flutter/docs/GuidaTour_Ruoli_e_Funzionalita.xlsx');
const wb = new ExcelJS.Workbook();
const fill = (c) => ({ type: 'pattern', pattern: 'solid', fgColor: { argb: 'FF' + c } });
const border = { style: 'thin', color: { argb: 'FFD5D9DE' } };
const box = { top: border, left: border, bottom: border, right: border };
const col = (n) => String.fromCharCode(64 + n);

function sheet(title, intro, headers, rows, widths) {
  const ws = wb.addWorksheet(title, {
    views: [{ state: 'frozen', xSplit: 1, ySplit: 4, showGridLines: false }],
    pageSetup: { orientation: 'landscape', fitToPage: true, fitToWidth: 1, fitToHeight: 0 },
  });
  ws.getCell('A1').value = title;
  ws.getCell('A1').font = { name: 'Arial', size: 14, bold: true, color: { argb: 'FF1F2A37' } };
  ws.mergeCells(2, 1, 2, headers.length);
  ws.getCell('A2').value = intro;
  ws.getCell('A2').font = { name: 'Arial', size: 10, italic: true, color: { argb: 'FF5B6470' } };
  ws.getCell('A2').alignment = { wrapText: true, vertical: 'top' };
  ws.getRow(2).height = 30;
  headers.forEach((h, i) => {
    const c = ws.getCell(4, i + 1);
    c.value = h;
    c.font = { name: 'Arial', size: 10, bold: true, color: { argb: 'FFFFFFFF' } };
    c.fill = fill('1F2A37');
    c.border = box;
    c.alignment = { wrapText: true, vertical: 'middle', horizontal: 'center' };
  });
  ws.getRow(4).height = 32;
  rows.forEach((row, r) => {
    row.forEach((v, i) => {
      const c = ws.getCell(r + 5, i + 1);
      c.value = v;
      c.font = { name: 'Arial', size: 10, bold: i === 0 };
      c.border = box;
      c.alignment = { wrapText: true, vertical: 'top' };
      if (i === 0) c.fill = fill('F7EFE3');
    });
    // Excel non adatta l'altezza da solo con il testo a capo.
    const lines = Math.max(...row.map((v, i) => Math.ceil(String(v).length / (widths[i] * 1.05))));
    ws.getRow(r + 5).height = Math.max(18, lines * 14 + 4);
  });
  widths.forEach((w, i) => (ws.getColumn(i + 1).width = w));
  ws.autoFilter = { from: { row: 4, column: 1 }, to: { row: 4 + rows.length, column: headers.length } };
  return ws;
}

function colours(ws, ref, rules) {
  ws.addConditionalFormatting({
    ref,
    rules: rules.map(([text, c], i) => ({
      type: 'cellIs', operator: 'equal', formulae: [`"${text}"`], priority: i + 1,
      style: { fill: { type: 'pattern', pattern: 'solid', bgColor: { argb: 'FF' + c } } },
    })),
  });
}
const YES = [['Sì', 'D9F0DF'], ['No', 'F8D9D6'], ['Con accesso', 'FDEFC8']];
const PRO = 'Scopri, Tour, Scheda tour, Panoramica, I miei tour, Assegnazioni, Richieste, Account (dal pallino in alto a destra)';

const wsR = sheet('Ruoli', "Situazione dell'app al 5 novembre 2026, ricavata dal codice. Scheda tour = pagina che si apre toccando un tour.",
  ['Ruolo', 'Approvazione admin', 'Pagine visibili', 'Cosa può fare', 'Cosa non può fare', 'Accesso rapido di prova'], [
  ['Visitatore (senza account)', 'No: non serve un account', "Scopri, Tour, Scheda tour, Accesso/Registrazione. Preferiti e Account portano all'accesso",
    'Cercare e filtrare i tour; scegliere città e lingua; inviare una richiesta di prenotazione; iscriversi a WhatsApp; registrarsi',
    'Salvare preferiti; usare il carrello; vedere lo storico', 'Non serve'],
  ['Turista', 'No: attivo subito dopo la registrazione', 'Scopri, Tour, Scheda tour, Preferiti, Carrello e richieste (icona del carrello), Account (dal pallino in alto a destra)',
    'Tutto quello del visitatore; salvare i preferiti; inviare più richieste dal carrello; vedere storico e stato delle richieste; modificare il profilo',
    'Pubblicare tour; aprire dashboard, richieste ricevute e assegnazioni', 'Turista'],
  ['Guida turistica', 'Sì: fino ad allora è un turista', PRO,
    'Pubblicare, modificare ed eliminare le proprie visite; generare QR e locandina; confermare o rifiutare le richieste; proporre tour ad altri professionisti; accettare o rifiutare le proposte',
    'Pubblicare pacchetti o servizi accessori; proporre visite guidate a un accompagnatore; toccare tour e richieste altrui', 'Guida'],
  ['Accompagnatore turistico', 'Sì: fino ad allora è un turista', PRO,
    'Pubblicare, modificare ed eliminare attività di accompagnamento; generare QR e locandina; gestire richieste; accettare o rifiutare proposte di accompagnamento o pacchetti',
    "Pubblicare visite guidate, pacchetti o testi su beni culturali; presentarsi come guida abilitata (l'avviso compare nel modulo e nella scheda pubblica)", 'Accompagnatore'],
  ['Tour operator', 'Sì: fino ad allora è un turista', PRO, 'Le stesse funzioni della guida; pubblicare pacchetti completi con cena, transfer, biglietti, hotel o esperienze food',
    'Toccare tour e richieste altrui', 'Tour operator'],
  ['Admin', 'No: lo nomina il gestore da Supabase', 'Scopri, Tour, Scheda tour, Preferiti, Carrello e richieste, Gestione (Panoramica, Professionisti, Tour, Approvazioni, WhatsApp), Account dal pallino (account di prova con ruolo turista)',
    'Vedere i numeri della piattaforma; approvare o rifiutare le registrazioni; sospendere e riattivare i professionisti; eliminare qualunque tour; consultare e revocare i consensi WhatsApp; usare le funzioni del proprio ruolo',
    'Pubblicare tour, se il ruolo è turista; leggere i dati personali delle richieste (vede solo i totali)', 'Admin'],
], [26, 24, 44, 58, 50, 18]);

// Sì in verde (ruolo da approvare), No in grigio.
wsR.addConditionalFormatting({
  ref: 'B5:B10',
  rules: [
    { type: 'beginsWith', operator: 'beginsWith', text: 'Sì', priority: 1,
      style: { fill: { type: 'pattern', pattern: 'solid', bgColor: { argb: 'FFFDEFC8' } }, font: { bold: true } } },
    { type: 'beginsWith', operator: 'beginsWith', text: 'No', priority: 2,
      style: { fill: { type: 'pattern', pattern: 'solid', bgColor: { argb: 'FFEEF0F2' } } } },
  ],
});

// Regola unica: guide, accompagnatori e tour operator ottengono il ruolo solo con
// l'approvazione dell'admin; prima (o se rifiutati) sono turisti.
wsR.getCell(12, 1).value = "Un utente può avere più ruoli professionali (guida, accompagnatore, tour operator), scelti in registrazione e approvati insieme dall'admin con un'unica approvazione. Finché non è approvato (o se rifiutato) è un turista e in Account vede lo stato della richiesta. Le regole si sommano: chi è anche guida o tour operator non ha i limiti dell'accompagnatore; i pacchetti richiedono il ruolo tour operator.";
wsR.mergeCells(12, 1, 12, 6);
wsR.getCell(12, 1).font = { name: 'Arial', size: 10, italic: true, color: { argb: 'FF5B6470' } };
wsR.getCell(12, 1).alignment = { wrapText: true, vertical: 'top' };
wsR.getRow(12).height = 46;

const roles = ['Visitatore', 'Turista (e professionisti non approvati)', 'Guida', 'Accompagnatore', 'Tour operator', 'Admin (ruolo turista)'];
const P = 'Sì', N = 'No', L = 'Con accesso';
const pages = [
  ['Scopri (home)', P, P, P, P, P, P],
  ['Tour (ricerca)', P, P, P, P, P, P],
  ['Scheda tour', P, P, P, P, P, P],
  ['Accesso / Registrazione', P, N, N, N, N, N],
  ['Preferiti', L, P, N, N, N, P],
  ['Carrello e richieste inviate (icona del carrello)', L, P, N, N, N, P],
  ['Richieste ricevute (voce Richieste)', N, N, P, P, P, N],
  ['Panoramica', N, N, P, P, P, N],
  ['I miei tour', N, N, P, P, P, N],
  ['Modulo tour', N, N, P, P, P, N],
  ['QR e locandina (PDF da scaricare o stampare)', N, N, P, P, P, N],
  ['Assegnazioni', N, N, P, P, P, N],
  ['Gestione: panoramica, professionisti, tour, approvazioni, WhatsApp', N, N, N, N, N, P],
  ['Account e profilo (foto e ruoli inclusi), dal pallino se collegati', L, P, P, P, P, P],
  ['FAQ (dal footer)', P, P, P, P, P, P],
];
colours(sheet('Pagine per ruolo', 'Sì = visibile. Con accesso = la voce porta alla pagina di login. No = non disponibile.',
  ['Pagina', ...roles], pages, [32, 15, 20, 15, 15, 15, 15]), `B5:G${4 + pages.length}`, YES);

const ops = [
  ['Cercare tour e inviare richieste', P, P, P, P, P, P],
  ['Iscriversi a WhatsApp', P, P, P, P, P, P],
  ['Salvare preferiti', N, P, N, N, N, P],
  ['Inviare richieste dal carrello', N, P, N, N, N, P],
  ['Scegliere la data del tour (scheda, carrello, richiesta)', P, P, P, P, P, P],
  ['Pubblicare e modificare propri tour', N, N, P, 'Solo accompagnamento', P, N],
  ['Più date per tour (anche ogni settimana, max 60)', N, N, P, P, P, N],
  ['Pubblicare visite guidate', N, N, P, N, P, N],
  ['Pubblicare pacchetti con accessori', N, N, N, N, P, N],
  ['Generare QR e locandina PDF', N, N, P, P, P, N],
  ['Confermare o rifiutare richieste', N, N, P, P, P, N],
  ['Proporre tour ad altri professionisti', N, N, P, 'Sì (da decidere)', P, N],
  ['Ricevere proposte', N, N, P, 'Solo accompagnamento e pacchetti', P, N],
  ['Chiedere ruoli professionali dal profilo', N, P, P, P, P, P],
  ['Approvare registrazioni', N, N, N, N, N, P],
  ['Sospendere o riattivare professionisti', N, N, N, N, N, P],
  ['Eliminare tour di altri', N, N, N, N, N, P],
  ['Consultare consensi WhatsApp', N, N, N, N, N, P],
];
colours(sheet('Operazioni per ruolo', "Regole imposte dal backend, non solo dall'app.",
  ['Operazione', ...roles], ops, [38, 16, 20, 18, 18, 16, 16]), `B5:G${4 + ops.length}`, YES);

const tests = [
  ['Backend online', 'Account di prova', 1, 'Superato', 'Ruoli corretti'],
  ['Backend online', 'Visitatore', 5, 'Superato', 'Lettura pubblica, 401 sulle aree riservate, nessun dato privato leggibile da Supabase'],
  ['Backend online', 'Turista', 3, 'Superato', 'Preferiti, carrello, storico, nessun accesso professionale'],
  ['Backend online', 'Guida', 8, 'Superato', 'Tour, richieste, cessione, dati altrui protetti'],
  ['Backend online', 'Accompagnatore', 7, 'Superato', 'Categorie, parole riservate, pacchetti, proposte'],
  ['Backend online', 'Tour operator', 3, 'Superato', 'Pacchetti pubblicati da tour operator approvato'],
  ['Backend online', 'Ruoli dal profilo', 5, 'Superato', 'Togliere subito, aggiungere con approvazione, rifiuto che mantiene i ruoli, turista che chiede un ruolo, nessuna scrittura diretta'],
  ['Backend online', 'Gestione (admin)', 4, 'Superato', 'Panoramica ed elenchi; accesso negato agli altri ruoli; eliminazione tour, sospensione e riattivazione'],,
  ['Backend online', 'Più ruoli', 5, 'Superato', 'Guida + accompagnatore: visite e accompagnamenti senza blocchi, niente pacchetti, cessioni, elenchi per ruolo.'],
  ['Backend online', 'Professionista non approvato', 3, 'Superato', 'Guida rifiutata: niente funzioni professionali, preferiti, carrello e richieste come turista, assente dagli elenchi'],
  ['Backend online', 'Admin', 3, 'Superato', 'Registrazioni, consensi, limiti del ruolo'],
  ['Backend online', 'Tentativi di scavalcare i ruoli', 6, 'Superato', 'Revoca consensi provata solo su id inesistente: nel database non ci sono consensi'],
  ['Backend online', 'Date multiple', 6, 'Superato', 'Tour con più date in ordine; ricerca per data; richiesta e carrello con la data (data estranea rifiutata); modifica delle date senza toccare gli altri campi; tour con la sola data; limiti'],
  ['Backend online', 'Foto profilo', 5, 'Superato', 'Caricamento, rimozione, cartelle altrui, formato e indirizzi esterni'],
  ['Backend online', 'Pagine SEO', 12, 'Superato', 'npm run test:site: titolo, descrizione, canonical, hreflang, JSON-LD Event e ItemList, 404 e 410 noindex, sitemap senza [TEST], robots, immagini, API invariate'],
  ['App Flutter', 'Pagine, intestazione e footer, FAQ, copertina, una sola intestazione dopo login, home senza guide, professionisti non approvati come turisti, più ruoli e registrazione multipla, ruoli dal profilo, login senza cambio pagina, menu lingua, carrello e richieste, approvazioni, Gestione admin, Account e profilo, pallino, ritaglio foto, lettura delle foto (JPG vero, foto grandi ridotte, file non validi), locandina PDF, blocchi, link QR, date multiple, foto per tour, data leggibile, barra Prenota, ricerca dalla home sulla voce Tour, destinazioni dei pulsanti, ritorno ai tour dalla scheda, layout', 120, 'Superato', 'Totale della suite app, inclusi layout responsive e smoke test. Non clicca sul sito reale'],
  ['Non coperto', 'Prova end-to-end nel browser', 0, 'Da provare', 'Clic reali sul sito pubblicato'],
];
const wsT = sheet('Test', 'Esiti del 10 novembre 2026. Comandi backend: npm run test:roles e npm run test:site (cartella nodeBE).',
  ['Area', 'Gruppo', 'N. test', 'Esito', 'Note'], tests, [20, 34, 10, 14, 76]);
const lt = 4 + tests.length;
wsT.getCell(lt + 1, 2).value = 'Totale test';
wsT.getCell(lt + 1, 3).value = { formula: `SUM(C5:C${lt})`, result: tests.reduce((a, t) => a + t[2], 0) };
for (const n of [2, 3]) wsT.getCell(lt + 1, n).font = { name: 'Arial', size: 10, bold: true };

const F = 'Da fare';
const todo = [
  [1, 'MVP', 'QR funzionanti', 'Link al sito attuale con apertura diretta del tour e conteggio scansioni. Con un dominio definitivo i QR già stampati vanno rifatti', 'Fatto'],
  [2, 'MVP', 'Date multiple per tour', 'Fino a 60 date per tour, aggiunte una per una o ogni settimana; stesso link e QR finché ci sono date; data scelta da carrello e richiesta; posti per uscita (migrazione 0009)', 'Fatto'],
  [3, 'MVP', 'Notifiche email', "Oggi gli avvisi sono solo dentro l'app", F],
  [4, 'MVP', 'Locandina PDF', 'A4 con foto, QR, prezzo e organizzatore; pulsanti Scarica PDF e Stampa', 'Fatto'],
  [5, 'MVP', 'SEO', 'Pagine HTML dal backend: home, città, città + categoria, tour (IT/EN/ES), sitemap, robots.txt, dati strutturati Event, 404/410. Da portare sul dominio definitivo e inviare a Google Search Console', 'Fatto'],
  [6, 'MVP', 'Privacy e termini', 'Pagine vere e cancellazione dei dati su richiesta', F],
  [7, 'MVP', 'Admin completo', 'Area Gestione: panoramica, sospensione professionisti, eliminazione tour, approvazioni, consensi (migrazione 0007)', 'Fatto'],
  [8, 'MVP', 'Recupero password', "Non presente nell'app", F],
  [9, 'MVP', 'Conferma email e rimozione accessi rapidi', 'Da fare prima del lancio', F],
  [10, 'MVP', 'Hosting sempre attivo', 'Render free si addormenta, i QR devono essere sempre raggiungibili', 'Da decidere'],
  [11, 'Fase 2', 'Strutture partner', 'QR dedicati e statistiche', F],
  [12, 'Fase 2', 'Invio WhatsApp', 'Oggi si raccoglie solo il consenso', F],
  [13, 'Fase 2', 'Login Google e Facebook', "Oggi solo pulsanti 'in arrivo'", F],
  [14, 'Fase 2A', 'Ricerca accompagnatori dai tour operator', 'Previsto dal documento', F],
  [15, 'Fase 3', 'Piani a pagamento', 'Free, Premium, Business', F],
  [16, 'Fase 3', 'Collaborazione tour operator e guide', 'Stati proposta, vista, scaduta, richiesta informazioni', F],
  [17, 'Fase 4', 'Pagamenti online', 'Solo dopo verifica legale', F],
  [18, 'Fase 5', 'App sugli store', 'Android e iOS', F],
];
const wsD = sheet('Da sviluppare', 'Priorità e fase dal documento BRD v0.8, stato verificato sul codice. La colonna Stato si può aggiornare.',
  ['N.', 'Fase', 'Attività', 'Note', 'Stato'], todo, [6, 10, 40, 72, 16]);
const ld = 4 + todo.length;
for (let r = 5; r <= ld; r++) {
  wsD.getCell(r, 5).dataValidation = { type: 'list', allowBlank: false, formulae: ['"Da fare,In corso,Fatto,Da decidere"'] };
}
colours(wsD, `E5:E${ld}`, [['Fatto', 'D9F0DF'], ['In corso', 'FDEFC8'], ['Da decidere', 'FDEFC8']]);
['Da fare', 'In corso', 'Fatto', 'Da decidere'].forEach((s, i) => {
  const r = ld + 2 + i;
  wsD.getCell(r, 3).value = s;
  wsD.getCell(r, 3).font = { name: 'Arial', size: 10, bold: true };
  wsD.getCell(r, 4).value = { formula: `COUNTIF($E$5:$E$${ld},C${r})`, result: todo.filter((t) => t[4] === s).length };
  wsD.getCell(r, 4).font = { name: 'Arial', size: 10 };
  wsD.getCell(r, 4).alignment = { horizontal: 'left' };
});

const O = 'Owner';
const dec = [
  ['Dominio definitivo per i QR', 'Serve per non ristampare le locandine', O, ''],
  ['Documenti richiesti ad accompagnatori e tour operator', 'Domanda aperta BRD §24', O, ''],
  ["Attività consentite all'accompagnatore", 'Domanda aperta BRD §24', O, ''],
  ['Verifica documentale delle guide', "Oggi c'è solo l'approvazione admin", O, ''],
  ["L'accompagnatore può proporre tour ad altri?", 'Il BRD gli riconosce solo la ricezione; oggi può farlo', O, ''],
  ['Tour operator e accompagnatori: Fase 2 o Fase 3?', 'Domanda aperta BRD §24', O, ''],
  ['Struttura partner: account proprio o gestione admin?', 'Consiglio: partire da admin con QR dedicato', O, ''],
  ['Repository privato', 'Con GitHub Free, Pages va spostato altrove', O, ''],
  ['Architettura del BRD', 'Il BRD cita Spring Boot, Angular ed EC2: va aggiornato', O, ''],
];
const wsQ = sheet('Decisioni aperte', "Colonna Decisione da compilare (celle gialle). Esempio per la prima riga: un dominio come 'guidatour.app'.",
  ['Tema', 'Perché conta', 'Chi decide', 'Decisione'], dec, [50, 56, 14, 36]);
for (let r = 5; r < 5 + dec.length; r++) wsQ.getCell(r, 4).fill = fill('FFF9C4');

// Una riga per ogni attività completata, la più recente in alto.
const log = [
  ['10/11/2026', 'Dalla scheda si torna ai tour', 'In cima alla scheda tour c’è "Torna ai tour" (dall’elenco Tour) o "Indietro" (da home, preferiti, carrello…): si ritrova l’elenco con ricerca, filtri e scorrimento com’erano', 'Test app (120 superati, 2 nuovi: computer e telefono)'],
  ['10/11/2026', 'Controllo di tutti i pulsanti', 'Verificate le destinazioni di menu, intestazione, home, footer, carrello, account, scheda tour, I miei tour, richieste e Gestione: tutte corrette. Fix: carrello, pallino dell’account e FAQ del footer premuti di nuovo aprivano una seconda pagina uguale sopra la prima; ora riportano a quella già aperta', 'Test app (118 superati, 11 nuovi sui pulsanti)'],
  ['09/11/2026', 'Ricerca dalla home sulla voce Tour', '"Cerca tour" e i cerchi delle categorie in Scopri passano alla voce Tour del menu, con ricerca e categoria già impostate (prima si apriva una pagina sopra Scopri). Dal menu la pagina Tour si apre senza filtri; dai risultati si apre la scheda del tour', 'Test app (107 superati, 3 nuovi: computer e telefono); prova cliccando sul sito'],
  ['09/11/2026', 'Foto, date e scheda tour rinnovate', '4 foto per categoria (18 nuove da Pexels, crediti in assets/CREDITI_FOTO.txt): ogni tour ha sempre la sua e le card vicine non si ripetono. Date leggibili nella lingua scelta ("mar 26 gen · 21:00"); pallino della guida sulle card e nella scheda. Scheda tour con foto grande e titolo sopra; sul telefono barra fissa con prezzo e Prenota che porta al modulo. Cerchi delle categorie con anello oro; card che compaiono una dopo l’altra', 'Test app (104 superati, 4 nuovi); schermate a 1300 px e 375 px'],
  ['09/11/2026', 'Prezzo delle card più leggibile', 'Il prezzo sulle card dei tour torna in Inter grassetto: le cifre in Playfair si leggevano male', 'Test app'],
  ['09/11/2026', 'Grafica rifinita, stessi colori', 'Tema completato (campi di testo sabbia con bordo oro, messaggi blu notte, finestre e menu arrotondati, scala tipografica unica); rosso mattone al posto del rosso puro; card dei tour con colore per categoria, sfumatura sulla foto, effetto al passaggio del mouse e prezzo più grande; stati vuoti illustrati e segnaposto animati al posto delle rotelline; raggi e spaziature uniformi', 'Test app (100 superati), schermate del sito a 1300 e 400 px'],
  ['06/11/2026', 'Schema del database', 'Immagine dello schema del DB (tabelle, colonne, relazioni e azioni alla cancellazione) in docs/GuidaTour_Schema_DB.png e .svg; si rigenera con npm run docs:db. schema.sql allineato alle colonne aggiunte dalle migrazioni', 'Confronto con schema.sql e migrazioni 0002-0009'],
  ['06/11/2026', 'Città accanto alla lingua', 'Nelle finestre strette (sotto 1024 px) la scelta della città andava a capo sotto la barra: ora resta nella barra in alto a sinistra della lingua e si accorcia con i puntini se manca spazio', 'Test app (nessuna pagina sfora da 320 px in su); schermate del sito a 1000, 600 e 360 px'],
  ['06/11/2026', 'Fix foto profilo sul sito', 'Sul sito ogni foto risultava "non valida": la lettura usava una funzione di Flutter che sul web non esiste. Ora si legge in modo compatibile; messaggio con i formati accettati (JPG, PNG, WebP)', 'Test app; caricamento e salvataggio provati sul sito pubblicato'],
  ['06/11/2026', 'Date multiple per tour', 'Un tour ha più date (anche ogni settimana): il turista sceglie la data in scheda, carrello e richiesta, la guida la vede nelle richieste, gli avvisi contano i posti per data; pagine SEO con prossime date; locandina "Ogni martedì alle 21:00". Fix: la modifica parziale di un tour non svuota più la descrizione', 'Test app e backend online, schermate'],
  ['06/11/2026', 'SEO: pagine pubbliche', 'Il backend serve pagine HTML vere (home, /roma, /roma/visita-guidata, /tour/ID) con titolo e descrizione propri, dati strutturati, sitemap e robots; il pulsante Prenota apre l’app. L’app Flutter ha titolo vero ed è noindex', 'Test SEO e ruoli sul backend online, schermate'],
  ['05/11/2026', 'Tolto "verificato"', 'Non si parla più di tour operator verificato o non verificato: tolte l’etichetta “verificato” da Account e scheda tour e la parola dalle frasi su tour operator e pacchetti (home, modulo tour, FAQ, messaggio del backend)', 'Test app e backend'],
  ['05/11/2026', 'Approvazioni: Tutte di default', 'La scheda Approvazioni parte da Tutte, in ordine di data, con data e stato colorato su ogni registrazione; filtri In attesa, Approvate, Rifiutate. Fix: si approvano i nuovi ruoli di chi è già approvato', 'Test app e backend, schermata sul sito'],
  ['05/11/2026', 'Prenotazioni → Richieste', 'I professionisti hanno la voce Richieste; turista e visitatore non hanno più Prenotazioni: il carrello mostra Da inviare e Richieste inviate e l’icona conta anche le risposte nuove', 'Test app, schermate sul sito'],
  ['05/11/2026', 'Ruoli dal profilo, login senza cambio pagina, fix lingua', 'In Modifica profilo si scelgono più ruoli: togliere vale subito, i nuovi passano dall’admin (migrazione 0008); Account e Gestione mostrano i ruoli in attesa. Login e logout restano sulla pagina se consentita. Il menu lingua non duplica più l’intestazione', 'Test app e backend (migrazione 0008 attiva)'],
  ['05/11/2026', 'Sfondo giallo e pagine ridisegnate', 'Sfondo giallo chiaro e intestazione dorata con icona e spiegazione in tutte le pagine interne; Prenotazioni, Assegnazioni, Panoramica e I miei tour a schede bianche con stato colorato e foto', 'Test app, schermate sul sito'],
  ['05/11/2026', 'Migrazioni 0006 e 0007 attive', 'Ruoli multipli e area Gestione attivi; account di prova Guida + Accompagnatore (Marta Neri) con accesso rapido', 'Tutti i test backend superati, nessuno saltato'],
  ['05/11/2026', 'Area Gestione, Account e profilo', 'Voce Gestione per l’admin con Panoramica, Professionisti (sospendi/riattiva), Tour (elimina), Approvazioni, WhatsApp; Account e Modifica profilo ridisegnati con il giallo del tema (migrazione 0007)', 'Test app e backend (2 in attesa della 0007), schermate sul sito'],
  ['05/11/2026', 'Più ruoli per utente', 'In registrazione si scelgono uno o più profili professionali, con un’unica approvazione dell’admin; regole sommate per combinazione (migrazione 0006). Fix: Approvazioni mostrava Turista per le richieste in attesa', 'Test app e backend (5 in attesa della 0006)'],
  ['05/11/2026', 'Excel: colonna approvazione', 'Nel foglio Ruoli la colonna "Approvazione admin": la richiedono guida, accompagnatore e tour operator', '—'],
  ['05/11/2026', 'Non approvati = turisti', 'Professionisti in attesa o rifiutati usano l’app come turisti con avviso in Account; pacchetti per ogni tour operator approvato; tolto l’accesso rapido T.O. non verificato', 'Test app e backend'],
  ['05/11/2026', 'Footer più basso, home senza guide', 'Footer su una fascia (marchio, avvertenza accanto, link utili a destra), circa 60 px in meno; tolta dalla home la lista delle guide', 'Test app, prova sul sito'],
  ['05/11/2026', 'Fix intestazione doppia', 'Dopo il login o il logout la home mostrava due intestazioni', 'Test app (riproduce il bug)'],
  ['05/11/2026', 'Copertina più bassa', 'Sottotitolo su una riga su schermo largo, spazi ridotti, foto tagliata dal cielo e non dal fondo (40 px in meno a 1920 e 1280)', 'Test app, prova sul sito'],
  ['05/11/2026', 'Intestazione e footer ovunque', 'Pagine interne con intestazione e footer, niente freccia: logo e marchio del footer portano a Scopri; footer solo con FAQ; nuova pagina FAQ', 'Test app, prova sul sito'],
  ['05/11/2026', 'Locandina PDF', 'Scarica e stampa la locandina A4 con QR, dati del tour e organizzatore', 'Test app'],
  ['02/11/2026', 'Account dal pallino', 'Chi è collegato apre Account dal pallino; il menu non lo mostra più', 'Test app'],
  ['02/11/2026', 'Foto profilo', 'Pallino con foto o iniziali; caricamento con ritaglio (migrazione 0005)', 'Test app e backend'],
  ['02/11/2026', 'Accessi rapidi tour operator', 'Tour operator verificato e non verificato', 'Test backend'],
  ['02/11/2026', 'QR funzionanti', 'Link al sito con apertura diretta del tour e conteggio scansioni', 'Test app, prova sul sito'],
  ['02/11/2026', 'Test per ruolo', 'Suite Flutter e backend per tutti i ruoli', '—'],
  ['02/11/2026', 'Accompagnatore', 'Accesso rapido, regole del BRD §13.4, avvisi in form e scheda', 'Test backend'],
  ['02/11/2026', 'Approvazione registrazioni', 'Migrazione 0004 attiva, approvazione da admin', 'Prova sul backend'],
];
sheet('Registro', 'Attività completate, la più recente in alto. Si aggiorna insieme al resto del file.',
  ['Data', 'Attività', 'Cosa cambia', 'Verifica'], log, [12, 30, 72, 24]);

wb.xlsx.writeFile(OUT).then(async () => {
  const chk = new ExcelJS.Workbook();
  await chk.xlsx.readFile(OUT);
  chk.eachSheet((w) => console.log(w.name, w.rowCount, w.columnCount));
  console.log('test', chk.getWorksheet('Test').getCell(lt + 1, 3).value);
  console.log('todo', chk.getWorksheet('Da sviluppare').getCell(ld + 2, 4).value);
});
