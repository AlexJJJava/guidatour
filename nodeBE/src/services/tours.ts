import { randomBytes } from 'node:crypto'
import { PUBLIC_SITE_URL } from '../config.js'
import { HttpError, notFound, unwrap } from '../errors.js'
import type { Db } from '../supabase.js'
import { getPublicProfile, type Profile, type PublicProfile, onlyAccompagnatore, rolesOf } from './profiles.js'

// Servizi accessori che trasformano un tour in pacchetto turistico (BR-014G).
export const ACCESSORY_SERVICES = [
  'Cena / ristorante',
  'Transfer / auto',
  'Biglietti / ingressi',
  'Hotel',
  'Esperienza food',
]

export const TOUR_CATEGORIES = [
  'Visita guidata',
  'Tour a piedi',
  'Enogastronomico',
  'Bambini e famiglie',
  'Serale',
  'Accompagnamento',
]

export const TOUR_LANGUAGES = ['Italiano', 'English', 'Español', 'Français', 'Deutsch']

// Città in cui l'app propone tour (selezione in home, come GetYourGuide).
export const CITIES = ['Roma', 'Milano', 'Firenze', 'Venezia', 'Napoli', 'Bologna', 'Torino']

// Parole che indicano visite specialistiche su beni culturali (BRD §13.4).
const CULTURAL_KEYWORDS = [
  'museo',
  'musei',
  'colosseo',
  'foro',
  'scavi',
  'catacombe',
  'monument',
  'basilica',
  'vaticano',
  'archeolog',
  'galleria',
  'pinacoteca',
  'visita guidata',
  'visite guidate',
  'guida turistica',
  'guida abilitata',
  'beni culturali',
]

export interface TourInput {
  title: string
  city: string
  category: string
  language: string
  duration: string
  /** Prima data (client vecchi); con dates diventa la prossima data. */
  start: string
  /** Tutte le date del tour, in ordine. */
  dates: string[]
  price: number
  meetingPoint: string
  description: string
  seats: number
  accessories: string[]
}

export interface Tour extends TourInput {
  /** Date ancora da svolgere, in ordine. */
  upcoming: string[]
  id: string
  guideId: string
  visits: number
  scans: number
  isPackage: boolean
  url: string
}

export type TourRow = {
  id: string
  guide_id: string
  title: string
  city: string
  category: string
  language: string
  duration: string
  start_at: string
  dates?: string[] | null
  last_start_at?: string | null
  price: number | string
  meeting_point: string
  description: string
  seats: number
  accessories: string[]
  visits: number
  scans: number
}

/** Date in ISO, ordinate e senza doppioni (confronto sull'istante). */
export function normalizeDates(dates: string[]): string[] {
  const ms = [...new Set(dates.map((d) => Date.parse(d)))].sort((a, b) => a - b)
  return ms.map((m) => new Date(m).toISOString())
}

export const toTour = (r: TourRow, now = Date.now()): Tour => {
  const dates = normalizeDates(r.dates?.length ? r.dates : [r.start_at])
  const upcoming = dates.filter((d) => Date.parse(d) >= now)
  return {
    id: r.id,
    guideId: r.guide_id,
    title: r.title,
    city: r.city,
    category: r.category,
    language: r.language,
    duration: r.duration,
    start: upcoming[0] ?? dates[dates.length - 1],
    dates,
    upcoming,
    price: Number(r.price),
    meetingPoint: r.meeting_point,
    description: r.description,
    seats: r.seats,
    accessories: r.accessories,
    visits: r.visits,
    scans: r.scans,
    isPackage: r.accessories.length > 0,
    url: `${PUBLIC_SITE_URL}?tour=${r.id}`,
  }
}

/** Data dell'ultima uscita: dopo, il tour è passato. */
export const lastDate = (t: Pick<Tour, 'dates'>) => t.dates[t.dates.length - 1]

/** Con dates le date sono quelle; con il solo start (client vecchi) è una data unica. */
const toRow = (t: Partial<TourInput>) => {
  const dates = t.dates?.length
    ? normalizeDates(t.dates)
    : t.start
      ? [new Date(t.start).toISOString()]
      : undefined
  return {
    title: t.title,
    city: t.city,
    category: t.category,
    language: t.language,
    duration: t.duration,
    start_at: dates?.[0],
    dates,
    price: t.price,
    meeting_point: t.meetingPoint,
    description: t.description,
    seats: t.seats,
    accessories: t.accessories,
  }
}

/**
 * Chi può pubblicare cosa (BR-014D, BR-014G, BRD §13.4): stesse regole del
 * form in Flutter, ripetute qui perché l'app da sola non basta a imporle.
 * Restituisce il motivo del blocco, o null se si può pubblicare.
 */
export function tourBlockReason(author: Profile, t: TourInput): string | null {
  if (t.accessories.length > 0) {
    if (!rolesOf(author).includes('tourOperator')) {
      return (
        `Con servizi accessori (${t.accessories.join(', ')}) l'offerta diventa un ` +
        'pacchetto turistico, che solo un tour operator può pubblicare.'
      )
    }
  }
  if (onlyAccompagnatore(author)) {
    if (t.category !== 'Accompagnamento') {
      return (
        "L'accompagnatore turistico può pubblicare solo attività di accompagnamento, " +
        'non visite guidate: la categoria è riservata alla guida abilitata.'
      )
    }
    const text = `${t.title} ${t.description}`.toLowerCase()
    if (CULTURAL_KEYWORDS.some((k) => text.includes(k))) {
      return (
        'Il testo sembra descrivere una visita guidata specialistica su beni culturali, ' +
        'riservata alla guida abilitata.'
      )
    }
  }
  return null
}

function slugify(title: string): string {
  const slug = title
    .toLowerCase()
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .slice(0, 60)
  return `${slug || 'tour'}-${randomBytes(3).toString('hex')}`
}

export interface TourFilters {
  q?: string
  city?: string
  category?: string
  language?: string
  guideId?: string
  from?: string
  to?: string
  // Di default solo i tour futuri; la dashboard della guida vuole anche i passati.
  includePast?: boolean
  limit?: number
}

export async function listTours(db: Db, f: TourFilters): Promise<Tour[]> {
  // Un tour è nel periodo se almeno una delle sue date ci cade: il database
  // filtra sull'intervallo prima–ultima data, qui sotto si guarda data per data.
  let query = db.from('tours').select('*').order('start_at').limit(f.limit ?? 100)
  if (f.city) query = query.eq('city', f.city)
  if (f.category) query = query.eq('category', f.category)
  if (f.language) query = query.eq('language', f.language)
  if (f.guideId) query = query.eq('guide_id', f.guideId)
  const from = f.from ?? (f.includePast ? undefined : new Date().toISOString())
  if (from) query = query.gte('last_start_at', from)
  if (f.to) query = query.lte('start_at', f.to)
  if (f.q) {
    // Virgole e parentesi hanno un significato nella sintassi di .or():
    // le togliamo perché non rompano (o manipolino) il filtro.
    const term = f.q.replace(/[,()%_\\*]/g, ' ').trim()
    if (term) {
      const like = `%${term}%`
      query = query.or(
        `title.ilike.${like},description.ilike.${like},meeting_point.ilike.${like}`,
      )
    }
  }
  const fromMs = from ? Date.parse(from) : -Infinity
  const toMs = f.to ? Date.parse(f.to) : Infinity
  const tours = unwrap(await query.returns<TourRow[]>())
    .map((r) => toTour(r))
    .filter((t) => t.dates.some((d) => Date.parse(d) >= fromMs && Date.parse(d) <= toMs))
  // In ordine di prossima uscita; i tour passati (solo con includePast) in fondo.
  const key = (t: Tour) => (t.upcoming.length ? Date.parse(t.upcoming[0]) : Infinity)
  return tours.sort((a, b) => key(a) - key(b) || Date.parse(lastDate(b)) - Date.parse(lastDate(a)))
}

export async function getTour(db: Db, id: string): Promise<Tour> {
  const row = unwrap(await db.from('tours').select('*').eq('id', id).maybeSingle<TourRow>())
  if (!row) throw notFound('Tour')
  return toTour(row)
}

export async function getTourWithGuide(
  db: Db,
  id: string,
): Promise<Tour & { guide: PublicProfile | null }> {
  const tour = await getTour(db, id)
  const guide = await getPublicProfile(db, tour.guideId).catch(() => null)
  return { ...tour, guide }
}

export async function createTour(db: Db, author: Profile, input: TourInput): Promise<Tour> {
  const reason = tourBlockReason(author, input)
  if (reason) throw new HttpError(422, reason)
  const row = unwrap(
    await db
      .from('tours')
      .insert({ id: slugify(input.title), guide_id: author.id, ...toRow(input) })
      .select('*')
      .single<TourRow>(),
  )
  return toTour(row)
}

export async function updateTour(
  db: Db,
  author: Profile,
  id: string,
  patch: Partial<TourInput>,
): Promise<Tour> {
  const current = await getTour(db, id)
  if (current.guideId !== author.id) throw new HttpError(403, 'Puoi modificare solo i tuoi tour')
  const reason = tourBlockReason(author, { ...current, ...patch })
  if (reason) throw new HttpError(422, reason)
  const row = unwrap(
    await db.from('tours').update(toRow(patch)).eq('id', id).select('*').single<TourRow>(),
  )
  return toTour(row)
}

export async function deleteTour(db: Db, userId: string, id: string): Promise<void> {
  const deleted = unwrap(
    await db.from('tours').delete().eq('id', id).eq('guide_id', userId).select('id'),
  )
  if (deleted.length === 0) throw notFound('Tour')
}

// Visita della scheda; con scan=true arriva dal QR della locandina.
export async function recordView(db: Db, id: string, scan: boolean): Promise<void> {
  unwrap(await db.rpc('record_tour_view', { p_tour_id: id, p_scan: scan }))
}
