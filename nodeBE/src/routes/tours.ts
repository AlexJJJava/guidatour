import { Hono } from 'hono'
import { z } from 'zod'
import { currentUserId, optionalAuth, requireAuth, type AppEnv } from '../auth.js'
import { rateLimit } from '../rateLimit.js'
import { requireProfessional } from '../services/profiles.js'
import { createRequest, listReceived } from '../services/requests.js'
import {
  ACCESSORY_SERVICES,
  TOUR_CATEGORIES,
  TOUR_LANGUAGES,
  createTour,
  deleteTour,
  getTourWithGuide,
  listTours,
  recordView,
  updateTour,
} from '../services/tours.js'
import { parseBody, parseQuery } from '../validate.js'

const tourSchema = z.object({
  title: z.string().trim().min(3).max(120),
  category: z.enum(TOUR_CATEGORIES),
  language: z.enum(TOUR_LANGUAGES),
  duration: z.string().trim().min(1).max(40),
  start: z.iso.datetime({ offset: true }),
  price: z.number().min(0).max(100_000),
  meetingPoint: z.string().trim().min(3).max(200),
  description: z.string().trim().max(5000).default(''),
  seats: z.int().min(1).max(1000),
  accessories: z.array(z.enum(ACCESSORY_SERVICES)).max(10).default([]),
})

const listQuery = z.object({
  q: z.string().max(100).optional(),
  category: z.string().optional(),
  language: z.string().optional(),
  guideId: z.uuid().optional(),
  from: z.iso.datetime({ offset: true }).optional(),
  to: z.iso.datetime({ offset: true }).optional(),
  includePast: z.stringbool().optional(),
  limit: z.coerce.number().int().min(1).max(200).optional(),
})

const requestSchema = z.object({
  name: z.string().trim().min(2).max(100),
  email: z.email().max(200),
  phone: z.string().trim().max(30).default(''),
  people: z.int().min(1).max(100),
  message: z.string().trim().max(2000).default(''),
})

export const tours = new Hono<AppEnv>()

// Valori ammessi nei form dell'app.
tours.get('/options', (c) =>
  c.json({
    categories: TOUR_CATEGORIES,
    languages: TOUR_LANGUAGES,
    accessories: ACCESSORY_SERVICES,
  }),
)

tours.get('/', optionalAuth, async (c) => {
  const filters = parseQuery(c, listQuery)
  return c.json({ tours: await listTours(c.get('db'), filters) })
})

tours.get('/:id', optionalAuth, async (c) => {
  return c.json(await getTourWithGuide(c.get('db'), c.req.param('id')))
})

tours.post('/', requireAuth, async (c) => {
  const db = c.get('db')
  const author = await requireProfessional(db, currentUserId(c))
  const input = await parseBody(c, tourSchema)
  return c.json(await createTour(db, author, input), 201)
})

tours.patch('/:id', requireAuth, async (c) => {
  const db = c.get('db')
  const author = await requireProfessional(db, currentUserId(c))
  const patch = await parseBody(c, tourSchema.partial())
  return c.json(await updateTour(db, author, c.req.param('id'), patch))
})

tours.delete('/:id', requireAuth, async (c) => {
  await deleteTour(c.get('db'), currentUserId(c), c.req.param('id'))
  return c.body(null, 204)
})

const viewLimit = rateLimit(60, 60_000)

tours.post('/:id/visit', viewLimit, optionalAuth, async (c) => {
  await recordView(c.get('db'), c.req.param('id'), false)
  return c.body(null, 204)
})

tours.post('/:id/scan', viewLimit, optionalAuth, async (c) => {
  await recordView(c.get('db'), c.req.param('id'), true)
  return c.body(null, 204)
})

// Richiesta di prenotazione non vincolante, anche senza login.
tours.post('/:id/requests', rateLimit(5, 60_000), optionalAuth, async (c) => {
  const input = await parseBody(c, requestSchema)
  const id = await createRequest(c.get('db'), c.get('userId'), c.req.param('id'), input)
  return c.json({ id }, 201)
})

// Richieste ricevute per uno dei propri tour.
tours.get('/:id/requests', requireAuth, async (c) => {
  const requests = await listReceived(c.get('db'), currentUserId(c), c.req.param('id'))
  return c.json({ requests })
})
