import { HttpError, unwrap } from '../errors.js'
import type { Db } from '../supabase.js'
import { getMyProfile } from './profiles.js'
import { createRequests, pickDate } from './requests.js'
import { getTour, toTour, type Tour, type TourRow } from './tours.js'

// Preferiti e carrello del turista. Ogni tabella è filtrata da RLS sull'utente,
// gli eq('user_id') servono solo a rendere esplicita l'intenzione.

export async function listFavorites(db: Db, userId: string): Promise<Tour[]> {
  const rows = unwrap(
    await db
      .from('favorites')
      .select('tours!inner(*)')
      .eq('user_id', userId)
      .order('created_at', { ascending: false })
      .returns<{ tours: TourRow }[]>(),
  )
  return rows.map((r) => toTour(r.tours))
}

export async function addFavorite(db: Db, userId: string, tourId: string): Promise<void> {
  unwrap(
    await db
      .from('favorites')
      .upsert({ user_id: userId, tour_id: tourId }, { ignoreDuplicates: true }),
  )
}

export async function removeFavorite(db: Db, userId: string, tourId: string): Promise<void> {
  unwrap(await db.from('favorites').delete().eq('user_id', userId).eq('tour_id', tourId))
}

export interface CartItem {
  tourId: string
  people: number
  /** Data scelta; se è passata o manca si usa la prossima uscita. */
  start: string | null
  tour: Tour
  subtotal: number
}

export interface Cart {
  items: CartItem[]
  total: number
}

export async function getCart(db: Db, userId: string): Promise<Cart> {
  const rows = unwrap(
    await db
      .from('cart_items')
      .select('people, start_at, tours!inner(*)')
      .eq('user_id', userId)
      .order('created_at')
      .returns<{ people: number; start_at: string | null; tours: TourRow }[]>(),
  )
  const items = rows.map((r) => {
    const tour = toTour(r.tours)
    const at = r.start_at ? Date.parse(r.start_at) : NaN
    const chosen = tour.upcoming.find((d) => Date.parse(d) === at)
    return {
      tourId: tour.id,
      people: r.people,
      start: chosen ?? tour.upcoming[0] ?? null,
      tour,
      subtotal: tour.price * r.people,
    }
  })
  return { items, total: items.reduce((sum, i) => sum + i.subtotal, 0) }
}

export async function addToCart(
  db: Db,
  userId: string,
  tourId: string,
  people: number,
  start?: string,
): Promise<void> {
  const start_at = pickDate(await getTour(db, tourId), start)
  // Se il tour è già nel carrello lo lasciamo com'è, come nel prototipo.
  unwrap(
    await db
      .from('cart_items')
      .upsert({ user_id: userId, tour_id: tourId, people, start_at }, { ignoreDuplicates: true }),
  )
}

export async function updateCartItem(
  db: Db,
  userId: string,
  tourId: string,
  patch: { people?: number; start?: string },
): Promise<void> {
  const row: { people?: number; start_at?: string } = {}
  if (patch.people !== undefined) row.people = patch.people
  if (patch.start !== undefined) row.start_at = pickDate(await getTour(db, tourId), patch.start)
  const updated = unwrap(
    await db
      .from('cart_items')
      .update(row)
      .eq('user_id', userId)
      .eq('tour_id', tourId)
      .select('tour_id'),
  )
  if (updated.length === 0) throw new HttpError(404, 'Tour non presente nel carrello')
}

export async function removeFromCart(db: Db, userId: string, tourId: string): Promise<void> {
  unwrap(await db.from('cart_items').delete().eq('user_id', userId).eq('tour_id', tourId))
}

/** Invia una richiesta non vincolante per ogni tour nel carrello (nessun pagamento). */
export async function checkout(
  db: Db,
  userId: string,
  contact: { phone: string; message: string },
): Promise<{ requestIds: string[] }> {
  const [cart, profile] = await Promise.all([getCart(db, userId), getMyProfile(db, userId)])
  if (cart.items.length === 0) throw new HttpError(422, 'Il carrello è vuoto')
  if (cart.items.some((i) => !i.start)) {
    throw new HttpError(422, "Nel carrello c'è un tour che non ha più date in programma")
  }
  const requestIds = await createRequests(
    db,
    userId,
    cart.items.map((i) => ({
      tourId: i.tourId,
      name: profile.name,
      email: profile.email,
      phone: contact.phone,
      people: i.people,
      message: contact.message,
      start: i.start!,
    })),
  )
  unwrap(await db.from('cart_items').delete().eq('user_id', userId))
  return { requestIds }
}
