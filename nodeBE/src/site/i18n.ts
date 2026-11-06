// Testi delle pagine pubbliche (SEO). L'italiano è la lingua principale;
// inglese e spagnolo con ?lang=en / ?lang=es.

export const LANGS = ['it', 'en', 'es'] as const
export type Lang = (typeof LANGS)[number]

export const langFrom = (q: string | undefined): Lang =>
  (LANGS as readonly string[]).includes(q ?? '') ? (q as Lang) : 'it'

const it = {
  locale: 'it-IT',
  tagline: 'Tour ed esperienze autentiche',
  homeTitle: 'GuidaTour – Tour con guide locali in Italia',
  homeDescription:
    'Tour, visite guidate ed esperienze con guide abilitate, accompagnatori e tour operator locali. Scegli, scrivi alla guida, parti.',
  heroTitle: 'Scopri l’Italia con guide locali esperte',
  heroSub: 'Guide abilitate, accompagnatori e tour operator. Scegli, scrivi alla guida, parti.',
  citiesTitle: 'Città',
  categoriesTitle: 'Esperienze',
  upcomingTitle: 'Prossimi tour',
  cityTitle: (city: string) => `Tour e visite guidate a ${city}`,
  cityDescription: (city: string, n: number) =>
    `${n} tour in programma a ${city} con guide locali, accompagnatori e tour operator: date, prezzi e richiesta di prenotazione senza impegno.`,
  categoryTitle: (cat: string, city: string) => `${cat} a ${city}`,
  categoryDescription: (cat: string, city: string, n: number) =>
    `${n} esperienze "${cat}" a ${city}: date, durata, lingua e prezzi. Richiedi informazioni direttamente a chi organizza.`,
  noTours: 'Al momento non ci sono tour in programma. Torna a trovarci presto.',
  allTours: 'Tutti i tour',
  tourTitle: (title: string, city: string) => `${title} – ${city} | GuidaTour`,
  when: 'Quando',
  duration: 'Durata',
  language: 'Lingua',
  meetingPoint: 'Ritrovo',
  seats: (n: number) => `${n} posti`,
  pricePerPerson: (p: string) => `Da ${p} a persona`,
  organizer: 'Organizza',
  book: 'Richiedi informazioni e prenota',
  bookHint: 'Richiesta senza impegno: chi organizza ti risponde per confermare.',
  package: (s: string) => `Pacchetto completo con: ${s}`,
  accompagnatoreNotice:
    'L’accompagnatore turistico offre assistenza e supporto operativo ai gruppi: non è una guida turistica abilitata e non svolge visite guidate specialistiche.',
  goneTitle: 'Tour non più disponibile',
  goneBody: 'Questo tour si è già svolto o non è più in programma. Guarda gli altri tour della città.',
  notFoundTitle: 'Pagina non trovata',
  disclaimer:
    'GuidaTour è una piattaforma di promozione e contatto: non organizza i tour né incassa pagamenti. Disponibilità, conferma, pagamento ed esecuzione restano in capo a guida od operatore che pubblica l’offerta.',
  openApp: 'Apri l’app',
  faq: 'FAQ',
  roles: { guida: 'Guida turistica', accompagnatore: 'Accompagnatore turistico', tourOperator: 'Tour operator', turista: 'Turista' } as Record<string, string>,
  categories: {
    'Visita guidata': 'Visita guidata',
    'Tour a piedi': 'Tour a piedi',
    Enogastronomico: 'Enogastronomico',
    'Bambini e famiglie': 'Bambini e famiglie',
    Serale: 'Serale',
    Accompagnamento: 'Accompagnamento',
  } as Record<string, string>,
}

type Texts = typeof it

const en: Texts = {
  ...it,
  locale: 'en-GB',
  tagline: 'Authentic tours and experiences',
  homeTitle: 'GuidaTour – Tours with local guides in Italy',
  homeDescription:
    'Tours, guided visits and experiences with licensed guides, tour leaders and local tour operators. Choose, message the guide, go.',
  heroTitle: 'Discover Italy with expert local guides',
  heroSub: 'Licensed guides, tour leaders and tour operators. Choose, message the guide, go.',
  citiesTitle: 'Cities',
  categoriesTitle: 'Experiences',
  upcomingTitle: 'Upcoming tours',
  cityTitle: (city) => `Tours and guided visits in ${city}`,
  cityDescription: (city, n) =>
    `${n} upcoming tours in ${city} with local guides, tour leaders and tour operators: dates, prices and non-binding booking requests.`,
  categoryTitle: (cat, city) => `${cat} in ${city}`,
  categoryDescription: (cat, city, n) =>
    `${n} "${cat}" experiences in ${city}: dates, duration, language and prices. Ask the organiser directly.`,
  noTours: 'There are no upcoming tours at the moment. Please come back soon.',
  allTours: 'All tours',
  tourTitle: (title, city) => `${title} – ${city} | GuidaTour`,
  when: 'When',
  duration: 'Duration',
  language: 'Language',
  meetingPoint: 'Meeting point',
  seats: (n) => `${n} places`,
  pricePerPerson: (p) => `From ${p} per person`,
  organizer: 'Organised by',
  book: 'Ask for information and book',
  bookHint: 'Non-binding request: the organiser will reply to confirm.',
  package: (s) => `Complete package with: ${s}`,
  accompagnatoreNotice:
    'A tour leader provides assistance and operational support to groups: they are not a licensed tourist guide and do not lead specialist guided visits.',
  goneTitle: 'Tour no longer available',
  goneBody: 'This tour has already taken place or is no longer scheduled. See the other tours in the city.',
  notFoundTitle: 'Page not found',
  disclaimer:
    'GuidaTour is a promotion and contact platform: it does not organise tours or take payments. Availability, confirmation, payment and delivery are the responsibility of the guide or operator publishing the offer.',
  openApp: 'Open the app',
  roles: { guida: 'Tourist guide', accompagnatore: 'Tour leader', tourOperator: 'Tour operator', turista: 'Traveller' },
  categories: {
    'Visita guidata': 'Guided visit',
    'Tour a piedi': 'Walking tour',
    Enogastronomico: 'Food and wine',
    'Bambini e famiglie': 'Kids and families',
    Serale: 'Evening',
    Accompagnamento: 'Tour leading',
  },
}

const es: Texts = {
  ...it,
  locale: 'es-ES',
  tagline: 'Tours y experiencias auténticas',
  homeTitle: 'GuidaTour – Tours con guías locales en Italia',
  homeDescription:
    'Tours, visitas guiadas y experiencias con guías habilitados, acompañantes y touroperadores locales. Elige, escribe al guía, sal.',
  heroTitle: 'Descubre Italia con guías locales expertos',
  heroSub: 'Guías habilitados, acompañantes y operadores turísticos. Elige, escribe al guía, sal.',
  citiesTitle: 'Ciudades',
  categoriesTitle: 'Experiencias',
  upcomingTitle: 'Próximos tours',
  cityTitle: (city) => `Tours y visitas guiadas en ${city}`,
  cityDescription: (city, n) =>
    `${n} tours programados en ${city} con guías locales, acompañantes y touroperadores: fechas, precios y solicitud de reserva sin compromiso.`,
  categoryTitle: (cat, city) => `${cat} en ${city}`,
  categoryDescription: (cat, city, n) =>
    `${n} experiencias "${cat}" en ${city}: fechas, duración, idioma y precios. Pregunta directamente a quien organiza.`,
  noTours: 'Por ahora no hay tours programados. Vuelve pronto.',
  allTours: 'Todos los tours',
  tourTitle: (title, city) => `${title} – ${city} | GuidaTour`,
  when: 'Cuándo',
  duration: 'Duración',
  language: 'Idioma',
  meetingPoint: 'Punto de encuentro',
  seats: (n) => `${n} plazas`,
  pricePerPerson: (p) => `Desde ${p} por persona`,
  organizer: 'Organiza',
  book: 'Pide información y reserva',
  bookHint: 'Solicitud sin compromiso: quien organiza te responderá para confirmar.',
  package: (s) => `Paquete completo con: ${s}`,
  accompagnatoreNotice:
    'El acompañante turístico ofrece asistencia y apoyo operativo a los grupos: no es un guía turístico habilitado y no realiza visitas guiadas especializadas.',
  goneTitle: 'Tour ya no disponible',
  goneBody: 'Este tour ya se ha realizado o ya no está programado. Mira los demás tours de la ciudad.',
  notFoundTitle: 'Página no encontrada',
  disclaimer:
    'GuidaTour es una plataforma de promoción y contacto: no organiza los tours ni cobra pagos. Disponibilidad, confirmación, pago y realización corren a cargo del guía u operador que publica la oferta.',
  openApp: 'Abrir la app',
  roles: { guida: 'Guía turístico', accompagnatore: 'Acompañante turístico', tourOperator: 'Touroperador', turista: 'Turista' },
  categories: {
    'Visita guidata': 'Visita guiada',
    'Tour a piedi': 'Tour a pie',
    Enogastronomico: 'Gastronomía',
    'Bambini e famiglie': 'Niños y familias',
    Serale: 'Nocturno',
    Accompagnamento: 'Acompañamiento',
  },
}

export const TEXTS: Record<Lang, Texts> = { it, en, es }
