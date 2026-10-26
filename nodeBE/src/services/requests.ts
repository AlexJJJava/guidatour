import { randomUUID } from 'node:crypto'
import { HttpError, unwrap } from '../errors.js'
import type { Db } from '../supabase.js'
import { getTour } from './tours.js'

export const REQUEST_STATUSES = ['inviata', 'confermata', 'rifiutata'] as const
export type RequestStatus = (typeof REQUEST_STATUSES)[number]

export interface RequestInput {
  name: string
  email: string
  phone: string
  people: number
  message: string
}

export interface BookingRequest extends RequestInput {
  id: string
  tourId: string
  userId: string | null
  status: RequestStatus
  createdAt: string
  tour?: { id: string; title: string; start: string }
}

type RequestRow = {
  id: string
  tour_id: string
  user_id: string | null
  name: string
  email: string
  phone: string
  people: number
  message: string
  status: RequestStatus
  created_at: string
  tours?: { id: string; title: string; start_at: string }
}

const SELECT_WITH_TOUR = '*, tours!inner(id, title, start_at, guide_id)'

export const toRequest = (r: RequestRow): BookingRequest => ({
  id: r.id,
  tourId: r.tour_id,
  userId: r.user_id,
  name: r.name,
  email: r.email,
  phone: r.phone,
  people: r.people,
  message: r.message,
  status: r.status,
  createdAt: r.created_at,
  ...(r.tours && { tour: { id: r.tours.id, title: r.tours.title, start: r.tours.start_at } }),
})

/**
 * Richiesta non vincolante (niente pagamento). Può arrivare anche da chi non è
 * loggato: in quel caso RLS consente l'inserimento ma non la rilettura, per
 * questo l'id lo generiamo qui invece di farcelo restituire dal database.
 */
export async function createRequests(
  db: Db,
  userId: string | null,
  items: (RequestInput & { tourId: string })[],
): Promise<string[]> {
  const rows = items.map((r) => ({
    id: randomUUID(),
    tour_id: r.tourId,
    user_id: userId,
    name: r.name,
    email: r.email,
    phone: r.phone,
    people: r.people,
    message: r.message,
  }))
  unwrap(await db.from('booking_requests').insert(rows))
  return rows.map((r) => r.id)
}

export async function createRequest(
  db: Db,
  userId: string | null,
  tourId: string,
  input: RequestInput,
): Promise<string> {
  const tour = await getTour(db, tourId)
  if (new Date(tour.start) < new Date()) {
    throw new HttpError(422, 'Il tour si è già svolto')
  }
  const [id] = await createRequests(db, userId, [{ ...input, tourId }])
  return id
}

// Richieste ricevute dalla guida per i propri tour.
export async function listReceived(
  db: Db,
  guideId: string,
  tourId?: string,
): Promise<BookingRequest[]> {
  let query = db
    .from('booking_requests')
    .select(SELECT_WITH_TOUR)
    .eq('tours.guide_id', guideId)
    .order('created_at', { ascending: false })
  if (tourId) query = query.eq('tour_id', tourId)
  return unwrap(await query.returns<RequestRow[]>()).map(toRequest)
}

// Richieste inviate dal turista loggato.
export async function listSent(db: Db, userId: string): Promise<BookingRequest[]> {
  const rows = unwrap(
    await db
      .from('booking_requests')
      .select(SELECT_WITH_TOUR)
      .eq('user_id', userId)
      .order('created_at', { ascending: false })
      .returns<RequestRow[]>(),
  )
  return rows.map(toRequest)
}

export async function setRequestStatus(
  db: Db,
  id: string,
  status: RequestStatus,
): Promise<BookingRequest> {
  // RLS fa passare solo le richieste dei tour della guida: per le altre
  // l'update non tocca righe e qui arriva null.
  const row = unwrap(
    await db
      .from('booking_requests')
      .update({ status })
      .eq('id', id)
      .select(SELECT_WITH_TOUR)
      .maybeSingle<RequestRow>(),
  )
  if (!row) throw new HttpError(404, 'Richiesta non trovata')
  return toRequest(row)
}
