import { randomBytes } from 'node:crypto'
import { PUBLIC_TOUR_BASE_URL } from '../config.js'
import { HttpError, notFound, unwrap } from '../errors.js'
import type { Db } from '../supabase.js'
import { getPublicProfile, type Profile, type PublicProfile } from './profiles.js'

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
]

export interface TourInput {
  title: string
  city: string
  category: string
  language: string
  duration: string
  start: string
  price: number
  meetingPoint: string
  description: string
  seats: number
  accessories: string[]
}

export interface Tour extends TourInput {
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
  price: number | string
  meeting_point: string
  description: string
  seats: number
  accessories: string[]
  visits: number
  scans: number
}

export const toTour = (r: TourRow): Tour => ({
  id: r.id,
  guideId: r.guide_id,
  title: r.title,
  city: r.city,
  category: r.category,
  language: r.language,
  duration: r.duration,
  start: r.start_at,
  price: Number(r.price),
  meetingPoint: r.meeting_point,
  description: r.description,
  seats: r.seats,
  accessories: r.accessories,
  visits: r.visits,
  scans: r.scans,
  isPackage: r.accessories.length > 0,
  url: `${PUBLIC_TOUR_BASE_URL}/${r.id}`,
})

const toRow = (t: Partial<TourInput>) => ({
  title: t.title,
  city: t.city,
  category: t.category,
  language: t.language,
  duration: t.duration,
  start_at: t.start,
  price: t.price,
  meeting_point: t.meetingPoint,
  description: t.description,
  seats: t.seats,
  accessories: t.accessories,
})

/**
 * Chi può pubblicare cosa (BR-014D, BR-014G, BRD §13.4): stesse regole del
 * form in Flutter, ripetute qui perché l'app da sola non basta a imporle.
 * Restituisce il motivo del blocco, o null se si può pubblicare.
 */
export function tourBlockReason(author: Profile, t: TourInput): string | null {
  if (t.accessories.length > 0) {
    if (author.role !== 'tourOperator') {
      return (
        `Con servizi accessori (${t.accessories.join(', ')}) l'offerta diventa un ` +
        'pacchetto turistico, che solo un tour operator verificato può pubblicare.'
      )
    }
    if (!author.verified) {
      return 'I pacchetti completi richiedono un profilo Tour operator verificato.'
    }
  }
  if (author.role === 'accompagnatore') {
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
  let query = db.from('tours').select('*').order('start_at').limit(f.limit ?? 100)
  if (f.city) query = query.eq('city', f.city)
  if (f.category) query = query.eq('category', f.category)
  if (f.language) query = query.eq('language', f.language)
  if (f.guideId) query = query.eq('guide_id', f.guideId)
  if (f.from) query = query.gte('start_at', f.from)
  else if (!f.includePast) query = query.gte('start_at', new Date().toISOString())
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
  return unwrap(await query.returns<TourRow[]>()).map(toTour)
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
