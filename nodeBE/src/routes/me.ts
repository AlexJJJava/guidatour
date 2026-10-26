import { Hono } from 'hono'
import { z } from 'zod'
import { currentUserId, requireAuth, type AppEnv } from '../auth.js'
import { listNotifications, markRead } from '../services/notifications.js'
import { getMyProfile, requireProfessional, updateMyProfile } from '../services/profiles.js'
import { listSent } from '../services/requests.js'
import {
  addFavorite,
  addToCart,
  checkout,
  getCart,
  listFavorites,
  removeFavorite,
  removeFromCart,
  setCartPeople,
} from '../services/tourist.js'
import { TOUR_LANGUAGES } from '../services/tours.js'
import { getDashboard } from '../services/dashboard.js'
import { parseBody, parseQuery } from '../validate.js'

const profilePatch = z.object({
  name: z.string().trim().min(2).max(100).optional(),
  bio: z.string().trim().max(2000).optional(),
  languages: z.array(z.enum(TOUR_LANGUAGES)).min(1).max(10).optional(),
})

const people = z.int().min(1).max(100)

// Tutto ciò che riguarda l'utente loggato.
export const me = new Hono<AppEnv>()

me.use('*', requireAuth)

me.get('/', async (c) => c.json(await getMyProfile(c.get('db'), currentUserId(c))))

me.patch('/', async (c) => {
  const patch = await parseBody(c, profilePatch)
  return c.json(await updateMyProfile(c.get('db'), currentUserId(c), patch))
})

// ── Turista ──
me.get('/requests', async (c) => {
  return c.json({ requests: await listSent(c.get('db'), currentUserId(c)) })
})

me.get('/favorites', async (c) => {
  return c.json({ tours: await listFavorites(c.get('db'), currentUserId(c)) })
})

me.put('/favorites/:tourId', async (c) => {
  await addFavorite(c.get('db'), currentUserId(c), c.req.param('tourId'))
  return c.body(null, 204)
})

me.delete('/favorites/:tourId', async (c) => {
  await removeFavorite(c.get('db'), currentUserId(c), c.req.param('tourId'))
  return c.body(null, 204)
})

me.get('/cart', async (c) => c.json(await getCart(c.get('db'), currentUserId(c))))

me.post('/cart', async (c) => {
  const body = await parseBody(c, z.object({ tourId: z.string().min(1), people: people.default(2) }))
  const db = c.get('db')
  const userId = currentUserId(c)
  await addToCart(db, userId, body.tourId, body.people)
  return c.json(await getCart(db, userId), 201)
})

me.patch('/cart/:tourId', async (c) => {
  const body = await parseBody(c, z.object({ people }))
  const db = c.get('db')
  const userId = currentUserId(c)
  await setCartPeople(db, userId, c.req.param('tourId'), body.people)
  return c.json(await getCart(db, userId))
})

me.delete('/cart/:tourId', async (c) => {
  const db = c.get('db')
  const userId = currentUserId(c)
  await removeFromCart(db, userId, c.req.param('tourId'))
  return c.json(await getCart(db, userId))
})

me.post('/cart/checkout', async (c) => {
  const body = await parseBody(
    c,
    z.object({
      phone: z.string().trim().max(30).default(''),
      message: z.string().trim().max(2000).default('Richiesta dal carrello'),
    }),
  )
  return c.json(await checkout(c.get('db'), currentUserId(c), body), 201)
})

// ── Professionista ──
me.get('/dashboard', async (c) => {
  const db = c.get('db')
  const profile = await requireProfessional(db, currentUserId(c))
  return c.json(await getDashboard(db, profile.id))
})

// ── Notifiche ──
me.get('/notifications', async (c) => {
  const { unread } = parseQuery(c, z.object({ unread: z.stringbool().default(false) }))
  return c.json({
    notifications: await listNotifications(c.get('db'), currentUserId(c), unread),
  })
})

me.post('/notifications/read', async (c) => {
  await markRead(c.get('db'), currentUserId(c))
  return c.body(null, 204)
})

me.post('/notifications/:id/read', async (c) => {
  await markRead(c.get('db'), currentUserId(c), c.req.param('id'))
  return c.body(null, 204)
})
