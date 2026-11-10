// Testi di informativa privacy e termini d'uso (IT/EN/ES).
//
// Bozza scritta sui dati che l'app tratta davvero (vedi
// nodeBE/supabase/schema.sql): va rivista da un legale prima del lancio e
// completata con titolare e contatti in app_config.dart. Testi lunghi, per
// questo stanno qui e non nei file .arb.

import 'app_config.dart';

enum LegalKind { privacy, terms }

/// Una sezione: titolo e paragrafi (le righe che iniziano con "• " sono voci
/// di elenco).
typedef LegalSection = (String title, List<String> paragraphs);

List<LegalSection> legalSections(LegalKind kind, String languageCode) {
  final lang = switch (languageCode) { 'en' => 'en', 'es' => 'es', _ => 'it' };
  return switch ((kind, lang)) {
    (LegalKind.privacy, 'en') => _privacyEn,
    (LegalKind.privacy, 'es') => _privacyEs,
    (LegalKind.privacy, _) => _privacyIt,
    (LegalKind.terms, 'en') => _termsEn,
    (LegalKind.terms, 'es') => _termsEs,
    (LegalKind.terms, _) => _termsIt,
  };
}

// ───────────────────────────── PRIVACY · IT ─────────────────────────────

final _privacyIt = <LegalSection>[
  (
    'Chi tratta i tuoi dati',
    [
      'Titolare del trattamento: $legalOwner. Per qualsiasi domanda sulla privacy o per esercitare i tuoi diritti scrivi a $legalContactEmail.',
      'GuidaTour è una piattaforma che mette in contatto turisti con guide, accompagnatori e tour operator. Non organizza i tour e non incassa pagamenti.',
    ]
  ),
  (
    'Quali dati raccogliamo',
    [
      '• Account: nome, email, password (custodita in forma cifrata dal fornitore di autenticazione), ruolo, lingue parlate, città, presentazione e, se la carichi, la foto profilo.',
      '• Richieste di disponibilità: nome, email, telefono (facoltativo), numero di persone, data scelta e messaggio. Si possono inviare anche senza account.',
      '• Preferiti e carrello, se hai un account turista.',
      '• Tour pubblicati dai professionisti e proposte tra colleghi.',
      '• Consenso WhatsApp: numero di telefono, testo del consenso, data ed eventuale revoca.',
      '• Visite e scansioni dei QR dei tour: solo come contatori complessivi, senza collegarle a una persona.',
      'Non usiamo cookie di profilazione né strumenti pubblicitari. Sul dispositivo salviamo solo la lingua e la città scelte e lo stato di lettura delle risposte.',
    ]
  ),
  (
    'Perché li usiamo e su quale base',
    [
      '• Creare e gestire l’account e mostrare i tour: esecuzione del servizio che hai chiesto.',
      '• Inoltrare la tua richiesta alla guida o all’operatore del tour, che la riceve con i tuoi dati di contatto per risponderti: esecuzione del servizio, sulla base del consenso che dai nel modulo.',
      '• Inviarti aggiornamenti su WhatsApp: solo con il tuo consenso, che puoi revocare in ogni momento.',
      '• Proteggere la piattaforma da abusi (limiti di richieste, verifica dei professionisti): legittimo interesse.',
    ]
  ),
  (
    'Chi vede i tuoi dati',
    [
      '• La guida o l’operatore del tour a cui invii una richiesta: vede nome, contatti e messaggio. Da quel momento è responsabile anche lui di come li usa.',
      '• Gli altri utenti vedono solo il profilo pubblico dei professionisti (nome, ruoli, lingue, città, presentazione, foto).',
      '• Gli amministratori di GuidaTour, per approvare i professionisti e gestire segnalazioni.',
      '• Fornitori tecnici che trattano i dati per nostro conto: Supabase (database, autenticazione e archivio foto), Render (server dell’applicazione), GitHub Pages (pubblicazione del sito). La mappa del punto d’incontro è caricata da OpenStreetMap, che riceve l’indirizzo IP del dispositivo.',
      'Alcuni fornitori possono avere server fuori dall’Unione europea: in quel caso il trasferimento avviene con le garanzie previste dal GDPR (clausole contrattuali standard).',
    ]
  ),
  (
    'Per quanto tempo',
    [
      '• Account e dati collegati: finché non elimini l’account.',
      '• Richieste di disponibilità: finché esiste il tour o finché non elimini l’account da cui le hai inviate.',
      '• Consenso WhatsApp: finché non lo revochi; dopo la revoca conserviamo solo la prova di quando è stato dato e revocato.',
    ]
  ),
  (
    'I tuoi diritti',
    [
      'Puoi chiedere in ogni momento di accedere ai tuoi dati, correggerli, cancellarli, limitarne l’uso, opporti al trattamento o riceverli in un formato leggibile (portabilità), e revocare i consensi dati.',
      '• Correggere: da Account › Modifica profilo.',
      '• Cancellare: da Account › Elimina account. Vengono cancellati subito profilo, foto, preferiti, carrello, richieste inviate e consensi WhatsApp; per un professionista anche i tour e le richieste ricevute.',
      '• Se hai inviato una richiesta senza account, o per tutti gli altri diritti, scrivi a $legalContactEmail: rispondiamo entro 30 giorni.',
      'Puoi anche presentare reclamo al Garante per la protezione dei dati personali (www.garanteprivacy.it).',
    ]
  ),
  (
    'Minori',
    [
      'GuidaTour non è pensata per i minori di 14 anni, che non possono creare un account. Le richieste per tour con bambini le invia un adulto.',
    ]
  ),
  (
    'Modifiche',
    [
      'Se cambiamo questa informativa aggiorniamo la data in cima alla pagina; per le modifiche importanti avvisiamo gli utenti nell’app.',
    ]
  ),
];

// ───────────────────────────── PRIVACY · EN ─────────────────────────────

final _privacyEn = <LegalSection>[
  (
    'Who processes your data',
    [
      'Data controller: $legalOwner. For any privacy question or to exercise your rights, write to $legalContactEmail.',
      'GuidaTour is a platform that connects tourists with guides, tour escorts and tour operators. It does not organise tours and does not collect payments.',
    ]
  ),
  (
    'What data we collect',
    [
      '• Account: name, email, password (stored encrypted by the authentication provider), role, languages spoken, city, bio and, if you upload one, your profile photo.',
      '• Availability requests: name, email, phone (optional), number of people, chosen date and message. They can be sent without an account.',
      '• Favourites and cart, if you have a tourist account.',
      '• Tours published by professionals and proposals between colleagues.',
      '• WhatsApp consent: phone number, consent text, date and any withdrawal.',
      '• Tour views and QR scans: only as overall counters, never linked to a person.',
      'We do not use profiling cookies or advertising tools. On your device we only store the chosen language and city and which replies you have read.',
    ]
  ),
  (
    'Why we use it and on what basis',
    [
      '• Creating and managing your account and showing tours: performance of the service you asked for.',
      '• Forwarding your request to the guide or operator of the tour, who receives your contact details to reply: performance of the service, based on the consent you give in the form.',
      '• Sending you updates on WhatsApp: only with your consent, which you can withdraw at any time.',
      '• Protecting the platform from abuse (request limits, checks on professionals): legitimate interest.',
    ]
  ),
  (
    'Who sees your data',
    [
      '• The guide or operator of the tour you send a request to: they see your name, contact details and message, and from then on they are also responsible for how they use them.',
      '• Other users only see the public profile of professionals (name, roles, languages, city, bio, photo).',
      '• GuidaTour administrators, to approve professionals and handle reports.',
      '• Technical providers processing data on our behalf: Supabase (database, authentication and photo storage), Render (application server), GitHub Pages (website hosting). The meeting-point map is loaded from OpenStreetMap, which receives your device’s IP address.',
      'Some providers may have servers outside the European Union: in that case transfers rely on the safeguards required by the GDPR (standard contractual clauses).',
    ]
  ),
  (
    'How long we keep it',
    [
      '• Account and related data: until you delete your account.',
      '• Availability requests: as long as the tour exists or until you delete the account you sent them from.',
      '• WhatsApp consent: until you withdraw it; afterwards we only keep proof of when it was given and withdrawn.',
    ]
  ),
  (
    'Your rights',
    [
      'You can ask at any time to access, correct or delete your data, restrict or object to its processing, receive it in a readable format (portability), and withdraw any consent given.',
      '• Correct: Account › Edit profile.',
      '• Delete: Account › Delete account. Your profile, photo, favourites, cart, sent requests and WhatsApp consents are erased immediately; for professionals, also their tours and received requests.',
      '• If you sent a request without an account, or for any other right, write to $legalContactEmail: we reply within 30 days.',
      'You can also lodge a complaint with the Italian data protection authority (www.garanteprivacy.it) or the authority of your country.',
    ]
  ),
  (
    'Children',
    [
      'GuidaTour is not intended for children under 14, who cannot create an account. Requests for family tours are sent by an adult.',
    ]
  ),
  (
    'Changes',
    [
      'If we change this policy we update the date at the top of the page; for important changes we notify users in the app.',
    ]
  ),
];

// ───────────────────────────── PRIVACY · ES ─────────────────────────────

final _privacyEs = <LegalSection>[
  (
    'Quién trata tus datos',
    [
      'Responsable del tratamiento: $legalOwner. Para cualquier pregunta sobre privacidad o para ejercer tus derechos escribe a $legalContactEmail.',
      'GuidaTour es una plataforma que pone en contacto a turistas con guías, acompañantes y touroperadores. No organiza los tours ni cobra pagos.',
    ]
  ),
  (
    'Qué datos recogemos',
    [
      '• Cuenta: nombre, email, contraseña (guardada cifrada por el proveedor de autenticación), rol, idiomas, ciudad, presentación y, si la subes, la foto de perfil.',
      '• Solicitudes de disponibilidad: nombre, email, teléfono (opcional), número de personas, fecha elegida y mensaje. Se pueden enviar sin cuenta.',
      '• Favoritos y carrito, si tienes una cuenta de turista.',
      '• Tours publicados por los profesionales y propuestas entre colegas.',
      '• Consentimiento de WhatsApp: número de teléfono, texto del consentimiento, fecha y posible revocación.',
      '• Visitas y escaneos de los QR de los tours: solo como contadores globales, sin relacionarlos con una persona.',
      'No usamos cookies de perfilado ni herramientas publicitarias. En el dispositivo solo guardamos el idioma y la ciudad elegidos y qué respuestas has leído.',
    ]
  ),
  (
    'Para qué los usamos y con qué base',
    [
      '• Crear y gestionar la cuenta y mostrar los tours: ejecución del servicio que has pedido.',
      '• Enviar tu solicitud al guía u operador del tour, que recibe tus datos de contacto para responderte: ejecución del servicio, con el consentimiento que das en el formulario.',
      '• Enviarte novedades por WhatsApp: solo con tu consentimiento, que puedes revocar en cualquier momento.',
      '• Proteger la plataforma de abusos (límites de solicitudes, verificación de profesionales): interés legítimo.',
    ]
  ),
  (
    'Quién ve tus datos',
    [
      '• El guía u operador del tour al que envías una solicitud: ve tu nombre, contactos y mensaje, y desde ese momento también es responsable de su uso.',
      '• Los demás usuarios solo ven el perfil público de los profesionales (nombre, roles, idiomas, ciudad, presentación, foto).',
      '• Los administradores de GuidaTour, para aprobar a los profesionales y gestionar avisos.',
      '• Proveedores técnicos que tratan los datos por cuenta nuestra: Supabase (base de datos, autenticación y archivo de fotos), Render (servidor de la aplicación), GitHub Pages (publicación del sitio). El mapa del punto de encuentro se carga desde OpenStreetMap, que recibe la dirección IP del dispositivo.',
      'Algunos proveedores pueden tener servidores fuera de la Unión Europea: en ese caso la transferencia se realiza con las garantías del RGPD (cláusulas contractuales tipo).',
    ]
  ),
  (
    'Durante cuánto tiempo',
    [
      '• Cuenta y datos relacionados: hasta que elimines la cuenta.',
      '• Solicitudes de disponibilidad: mientras exista el tour o hasta que elimines la cuenta desde la que las enviaste.',
      '• Consentimiento de WhatsApp: hasta que lo revoques; después solo conservamos la prueba de cuándo se dio y se revocó.',
    ]
  ),
  (
    'Tus derechos',
    [
      'Puedes pedir en cualquier momento acceder a tus datos, corregirlos, borrarlos, limitar su uso, oponerte al tratamiento o recibirlos en un formato legible (portabilidad), y revocar los consentimientos dados.',
      '• Corregir: Cuenta › Editar perfil.',
      '• Borrar: Cuenta › Eliminar cuenta. Se borran al momento perfil, foto, favoritos, carrito, solicitudes enviadas y consentimientos de WhatsApp; para un profesional también sus tours y las solicitudes recibidas.',
      '• Si enviaste una solicitud sin cuenta, o para los demás derechos, escribe a $legalContactEmail: respondemos en 30 días.',
      'También puedes presentar una reclamación ante la autoridad italiana de protección de datos (www.garanteprivacy.it) o la de tu país.',
    ]
  ),
  (
    'Menores',
    [
      'GuidaTour no está pensada para menores de 14 años, que no pueden crear una cuenta. Las solicitudes para tours con niños las envía un adulto.',
    ]
  ),
  (
    'Cambios',
    [
      'Si cambiamos esta política actualizamos la fecha al principio de la página; para los cambios importantes avisamos a los usuarios en la app.',
    ]
  ),
];

// ────────────────────────────── TERMINI · IT ──────────────────────────────

final _termsIt = <LegalSection>[
  (
    'Il servizio',
    [
      'GuidaTour ($legalOwner) è una piattaforma di promozione e contatto: permette a guide, accompagnatori e tour operator di presentare le loro offerte e ai turisti di trovarle e chiedere disponibilità.',
      'GuidaTour non organizza né svolge i tour, non è parte del contratto tra turista e professionista e non incassa pagamenti. Disponibilità, conferma, prezzo finale, pagamento e svolgimento sono accordi diretti tra turista e professionista.',
      'Usando l’app o il sito accetti questi termini.',
    ]
  ),
  (
    'Account',
    [
      '• Per creare un account devi avere almeno 14 anni e dare informazioni vere.',
      '• Sei responsabile della password e di ciò che succede con il tuo account.',
      '• Puoi eliminare l’account in ogni momento da Account › Elimina account.',
    ]
  ),
  (
    'Turisti',
    [
      '• Una richiesta di disponibilità non è una prenotazione: diventa un accordo solo quando il professionista la conferma.',
      '• Inserisci dati di contatto corretti e usa i contatti dei professionisti solo per il tour richiesto.',
    ]
  ),
  (
    'Professionisti',
    [
      '• Guide, accompagnatori e tour operator vengono approvati da un amministratore prima di poter pubblicare.',
      '• Sei responsabile dei contenuti che pubblichi (descrizioni, prezzi, date, foto) e del fatto che siano veri e aggiornati.',
      '• Sei responsabile di avere le abilitazioni, licenze, assicurazioni e autorizzazioni richieste dalla legge per l’attività che offri. In particolare, le visite guidate a musei, monumenti e siti culturali possono essere svolte solo da guide turistiche abilitate.',
      '• Tratti i dati dei turisti che ti scrivono solo per rispondere e svolgere il tour, nel rispetto della normativa privacy.',
    ]
  ),
  (
    'Cosa non è consentito',
    [
      '• Pubblicare contenuti falsi, ingannevoli, offensivi o che violano diritti di altri.',
      '• Usare la piattaforma per spam, pubblicità non richiesta o per raccogliere dati di altri utenti.',
      '• Tentare di aggirare le misure di sicurezza o di accedere ad account altrui.',
      'In questi casi possiamo rimuovere i contenuti e sospendere o chiudere l’account.',
    ]
  ),
  (
    'Responsabilità',
    [
      'Cerchiamo di mantenere il servizio disponibile e corretto, ma non possiamo garantire che sia sempre senza interruzioni o errori. Non rispondiamo dello svolgimento dei tour, delle informazioni pubblicate dai professionisti né degli accordi tra utenti, salvo i casi in cui la legge non consente di escludere la responsabilità.',
    ]
  ),
  (
    'Modifiche e legge applicabile',
    [
      'Possiamo aggiornare questi termini: la data in cima alla pagina indica l’ultima versione e per le modifiche importanti avvisiamo nell’app.',
      'Si applica la legge italiana. Restano salvi i diritti che la legge del tuo paese riconosce ai consumatori.',
      'Per domande: $legalContactEmail.',
    ]
  ),
];

// ────────────────────────────── TERMS · EN ──────────────────────────────

final _termsEn = <LegalSection>[
  (
    'The service',
    [
      'GuidaTour ($legalOwner) is a promotion and contact platform: it lets guides, tour escorts and tour operators present their offers and tourists find them and ask for availability.',
      'GuidaTour does not organise or run tours, is not a party to the contract between tourist and professional and does not collect payments. Availability, confirmation, final price, payment and the tour itself are agreed directly between tourist and professional.',
      'By using the app or the website you accept these terms.',
    ]
  ),
  (
    'Account',
    [
      '• You must be at least 14 years old and give truthful information to create an account.',
      '• You are responsible for your password and for what happens with your account.',
      '• You can delete your account at any time from Account › Delete account.',
    ]
  ),
  (
    'Tourists',
    [
      '• An availability request is not a booking: it becomes an agreement only when the professional confirms it.',
      '• Enter correct contact details and use professionals’ contacts only for the tour you asked about.',
    ]
  ),
  (
    'Professionals',
    [
      '• Guides, tour escorts and tour operators are approved by an administrator before they can publish.',
      '• You are responsible for the content you publish (descriptions, prices, dates, photos) and for it being true and up to date.',
      '• You are responsible for holding the qualifications, licences, insurance and permits required by law for the activity you offer. In particular, guided visits to museums, monuments and cultural sites in Italy may only be led by licensed tourist guides.',
      '• You process the data of tourists who contact you only to reply and run the tour, in compliance with privacy law.',
    ]
  ),
  (
    'What is not allowed',
    [
      '• Publishing false, misleading or offensive content, or content that infringes others’ rights.',
      '• Using the platform for spam, unsolicited advertising or to harvest other users’ data.',
      '• Trying to bypass security measures or access other people’s accounts.',
      'In these cases we may remove content and suspend or close the account.',
    ]
  ),
  (
    'Liability',
    [
      'We try to keep the service available and accurate, but we cannot guarantee it will always be free of interruptions or errors. We are not liable for how tours are carried out, for information published by professionals or for agreements between users, except where the law does not allow liability to be excluded.',
    ]
  ),
  (
    'Changes and governing law',
    [
      'We may update these terms: the date at the top of the page shows the latest version, and we notify important changes in the app.',
      'Italian law applies, without prejudice to the rights granted to consumers by the law of your country.',
      'Questions: $legalContactEmail.',
    ]
  ),
];

// ────────────────────────────── TÉRMINOS · ES ──────────────────────────────

final _termsEs = <LegalSection>[
  (
    'El servicio',
    [
      'GuidaTour ($legalOwner) es una plataforma de promoción y contacto: permite a guías, acompañantes y touroperadores presentar sus ofertas y a los turistas encontrarlas y pedir disponibilidad.',
      'GuidaTour no organiza ni realiza los tours, no es parte del contrato entre turista y profesional y no cobra pagos. Disponibilidad, confirmación, precio final, pago y realización se acuerdan directamente entre turista y profesional.',
      'Al usar la app o el sitio aceptas estos términos.',
    ]
  ),
  (
    'Cuenta',
    [
      '• Para crear una cuenta debes tener al menos 14 años y dar información verdadera.',
      '• Eres responsable de la contraseña y de lo que ocurra con tu cuenta.',
      '• Puedes eliminar la cuenta en cualquier momento desde Cuenta › Eliminar cuenta.',
    ]
  ),
  (
    'Turistas',
    [
      '• Una solicitud de disponibilidad no es una reserva: se convierte en acuerdo solo cuando el profesional la confirma.',
      '• Introduce datos de contacto correctos y usa los contactos de los profesionales solo para el tour solicitado.',
    ]
  ),
  (
    'Profesionales',
    [
      '• Guías, acompañantes y touroperadores son aprobados por un administrador antes de poder publicar.',
      '• Eres responsable de los contenidos que publicas (descripciones, precios, fechas, fotos) y de que sean verdaderos y estén actualizados.',
      '• Eres responsable de tener las habilitaciones, licencias, seguros y permisos exigidos por la ley para la actividad que ofreces. En particular, en Italia las visitas guiadas a museos, monumentos y sitios culturales solo pueden realizarlas guías turísticos habilitados.',
      '• Tratas los datos de los turistas que te escriben solo para responder y realizar el tour, respetando la normativa de privacidad.',
    ]
  ),
  (
    'Qué no está permitido',
    [
      '• Publicar contenidos falsos, engañosos, ofensivos o que vulneren derechos de otros.',
      '• Usar la plataforma para spam, publicidad no solicitada o para recoger datos de otros usuarios.',
      '• Intentar eludir las medidas de seguridad o acceder a cuentas ajenas.',
      'En estos casos podemos retirar los contenidos y suspender o cerrar la cuenta.',
    ]
  ),
  (
    'Responsabilidad',
    [
      'Intentamos mantener el servicio disponible y correcto, pero no podemos garantizar que esté siempre libre de interrupciones o errores. No respondemos de la realización de los tours, de la información publicada por los profesionales ni de los acuerdos entre usuarios, salvo cuando la ley no permite excluir la responsabilidad.',
    ]
  ),
  (
    'Cambios y ley aplicable',
    [
      'Podemos actualizar estos términos: la fecha al principio de la página indica la última versión y avisamos en la app de los cambios importantes.',
      'Se aplica la ley italiana, sin perjuicio de los derechos que la ley de tu país reconoce a los consumidores.',
      'Preguntas: $legalContactEmail.',
    ]
  ),
];
