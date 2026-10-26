import type { Context } from 'hono'
import { createMiddleware } from 'hono/factory'
import { HttpError } from './errors.js'
import { anonDb, userDb, type Db } from './supabase.js'

export type AppEnv = {
  Variables: {
    db: Db
    userId: string | null
  }
}

function bearerToken(c: Context): string | null {
  const header = c.req.header('Authorization')
  if (!header?.startsWith('Bearer ')) return null
  return header.slice('Bearer '.length).trim() || null
}

async function authenticate(c: Context<AppEnv>, token: string) {
  const db = userDb(token)
  // getUser verifica il token presso Supabase Auth (firma e scadenza).
  const { data, error } = await db.auth.getUser(token)
  if (error || !data.user) throw new HttpError(401, 'Sessione non valida o scaduta')
  c.set('db', db)
  c.set('userId', data.user.id)
}

// Rotte pubbliche che si comportano diversamente se l'utente è loggato
// (es. la richiesta di prenotazione viene legata al suo account).
export const optionalAuth = createMiddleware<AppEnv>(async (c, next) => {
  const token = bearerToken(c)
  if (token) {
    await authenticate(c, token)
  } else {
    c.set('db', anonDb)
    c.set('userId', null)
  }
  await next()
})

export const requireAuth = createMiddleware<AppEnv>(async (c, next) => {
  const token = bearerToken(c)
  if (!token) throw new HttpError(401, 'Accesso richiesto')
  await authenticate(c, token)
  await next()
})

// Da usare solo dopo requireAuth.
export function currentUserId(c: Context<AppEnv>): string {
  const id = c.get('userId')
  if (!id) throw new HttpError(401, 'Accesso richiesto')
  return id
}
