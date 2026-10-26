import { Hono } from 'hono'
import { z } from 'zod'
import { currentUserId, requireAuth, type AppEnv } from '../auth.js'
import { REQUEST_STATUSES, listReceived, setRequestStatus } from '../services/requests.js'
import { parseBody } from '../validate.js'

// Richieste ricevute dalla guida. L'invio è in POST /tours/:id/requests,
// quelle inviate dal turista in GET /me/requests.
export const requests = new Hono<AppEnv>()

requests.use('*', requireAuth)

requests.get('/received', async (c) => {
  return c.json({ requests: await listReceived(c.get('db'), currentUserId(c)) })
})

requests.patch('/:id', async (c) => {
  const { status } = await parseBody(c, z.object({ status: z.enum(REQUEST_STATUSES) }))
  return c.json(await setRequestStatus(c.get('db'), c.req.param('id'), status))
})
