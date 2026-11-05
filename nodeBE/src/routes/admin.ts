import { Hono } from 'hono'
import { z } from 'zod'
import { currentUserId, requireAuth, type AppEnv } from '../auth.js'
import {
  deleteTourAsAdmin,
  getOverview,
  listProfessionalsForAdmin,
  listToursForAdmin,
} from '../services/admin.js'
import {
  APPROVAL_STATUSES,
  listRegistrations,
  requireAdmin,
  setApprovalStatus,
} from '../services/profiles.js'
import { parseBody, parseQuery } from '../validate.js'

// Area di gestione: panoramica, professionisti, tour e approvazioni.
export const admin = new Hono<AppEnv>()

admin.use('*', requireAuth)
admin.use('*', async (c, next) => {
  await requireAdmin(c.get('db'), currentUserId(c))
  await next()
})

admin.get('/overview', async (c) => c.json(await getOverview(c.get('db'))))

admin.get('/registrations', async (c) => {
  const { status } = parseQuery(
    c,
    z.object({ status: z.enum(APPROVAL_STATUSES).default('in_attesa') }),
  )
  return c.json({ registrations: await listRegistrations(c.get('db'), status) })
})

admin.post('/registrations/:id', async (c) => {
  const { status } = await parseBody(
    c,
    z.object({ status: z.enum(['approvato', 'rifiutato']) }),
  )
  await setApprovalStatus(c.get('db'), c.req.param('id'), status)
  return c.body(null, 204)
})

admin.get('/professionals', async (c) =>
  c.json({ professionals: await listProfessionalsForAdmin(c.get('db')) }),
)

// Sospende o riattiva un professionista (BR-009).
admin.post('/professionals/:id', async (c) => {
  const { suspended } = await parseBody(c, z.object({ suspended: z.boolean() }))
  await setApprovalStatus(c.get('db'), c.req.param('id'), suspended ? 'sospeso' : 'approvato')
  return c.body(null, 204)
})

admin.get('/tours', async (c) => c.json({ tours: await listToursForAdmin(c.get('db')) }))

admin.delete('/tours/:id', async (c) => {
  await deleteTourAsAdmin(c.get('db'), c.req.param('id'))
  return c.body(null, 204)
})
