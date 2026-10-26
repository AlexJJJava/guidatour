import { Hono } from 'hono'
import { z } from 'zod'
import { currentUserId, optionalAuth, requireAuth, type AppEnv } from '../auth.js'
import { WHATSAPP_CONSENT_TEXT, WHATSAPP_SENDER } from '../config.js'
import { HttpError } from '../errors.js'
import { rateLimit } from '../rateLimit.js'
import { createConsent, listConsents, revokeConsent } from '../services/consents.js'
import { getMyProfile } from '../services/profiles.js'
import { parseBody } from '../validate.js'

// Consensi WhatsApp (BR-011D).
export const consents = new Hono<AppEnv>()

// Testo da mostrare all'utente: è quello che verrà salvato come prova.
consents.get('/text', (c) => c.json({ text: WHATSAPP_CONSENT_TEXT, sender: WHATSAPP_SENDER }))

consents.post('/', rateLimit(5, 60_000), optionalAuth, async (c) => {
  const { phone, source } = await parseBody(
    c,
    z.object({
      phone: z
        .string()
        .trim()
        .regex(/^\+[1-9]\d{6,14}$/, 'numero in formato internazionale, es. +393331234567'),
      source: z.string().trim().min(1).max(100),
    }),
  )
  const id = await createConsent(c.get('db'), c.get('userId'), phone, source)
  return c.json({ id }, 201)
})

consents.get('/', requireAuth, async (c) => {
  const db = c.get('db')
  const profile = await getMyProfile(db, currentUserId(c))
  if (!profile.isAdmin) throw new HttpError(403, 'Riservato agli amministratori')
  return c.json({ consents: await listConsents(db) })
})

consents.post('/:id/revoke', requireAuth, async (c) => {
  return c.json(await revokeConsent(c.get('db'), c.req.param('id')))
})
