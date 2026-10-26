import { Hono } from 'hono'
import { z } from 'zod'
import { optionalAuth, type AppEnv } from '../auth.js'
import { ROLES, getPublicProfile, listProfessionals } from '../services/profiles.js'
import { parseQuery } from '../validate.js'

// Profili pubblici dei professionisti (senza email).
export const guides = new Hono<AppEnv>()

guides.get('/', optionalAuth, async (c) => {
  const { role } = parseQuery(c, z.object({ role: z.enum(ROLES).optional() }))
  return c.json({ guides: await listProfessionals(c.get('db'), role) })
})

guides.get('/:id', optionalAuth, async (c) => {
  return c.json(await getPublicProfile(c.get('db'), c.req.param('id')))
})
