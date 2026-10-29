import { Hono } from 'hono'
import { z } from 'zod'
import { currentUserId, requireAuth, type AppEnv } from '../auth.js'
import {
  APPROVAL_STATUSES,
  listRegistrations,
  requireAdmin,
  setApprovalStatus,
} from '../services/profiles.js'
import { parseBody, parseQuery } from '../validate.js'

// Approvazione delle registrazioni di guide, accompagnatori e tour operator.
export const admin = new Hono<AppEnv>()

admin.use('*', requireAuth)

admin.get('/registrations', async (c) => {
  const db = c.get('db')
  await requireAdmin(db, currentUserId(c))
  const { status } = parseQuery(
    c,
    z.object({ status: z.enum(APPROVAL_STATUSES).default('in_attesa') }),
  )
  return c.json({ registrations: await listRegistrations(db, status) })
})

admin.post('/registrations/:id', async (c) => {
  const db = c.get('db')
  await requireAdmin(db, currentUserId(c))
  const { status } = await parseBody(
    c,
    z.object({ status: z.enum(['approvato', 'rifiutato']) }),
  )
  await setApprovalStatus(db, c.req.param('id'), status)
  return c.body(null, 204)
})
