import { Hono } from 'hono'
import { z } from 'zod'
import { currentUserId, requireAuth, type AppEnv } from '../auth.js'
import {
  cancelAssignment,
  completeAssignment,
  listAssignments,
  proposeAssignment,
  respondAssignment,
} from '../services/assignments.js'
import { requireProfessional } from '../services/profiles.js'
import { parseBody } from '../validate.js'

// Cambio / cessione tour (BR-011A).
export const assignments = new Hono<AppEnv>()

assignments.use('*', requireAuth)

assignments.get('/', async (c) => c.json({ assignments: await listAssignments(c.get('db')) }))

assignments.post('/', async (c) => {
  const db = c.get('db')
  const profile = await requireProfessional(db, currentUserId(c))
  const { tourId, toGuideId } = await parseBody(
    c,
    z.object({ tourId: z.string().min(1), toGuideId: z.uuid() }),
  )
  return c.json(await proposeAssignment(db, profile.id, tourId, toGuideId), 201)
})

assignments.post('/:id/respond', async (c) => {
  const { accept } = await parseBody(c, z.object({ accept: z.boolean() }))
  return c.json(await respondAssignment(c.get('db'), c.req.param('id'), accept))
})

assignments.post('/:id/cancel', async (c) => {
  return c.json(await cancelAssignment(c.get('db'), c.req.param('id')))
})

assignments.post('/:id/complete', async (c) => {
  return c.json(await completeAssignment(c.get('db'), c.req.param('id')))
})
