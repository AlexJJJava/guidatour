import type { Context } from 'hono'
import { createMiddleware } from 'hono/factory'
import { HttpError } from './errors.js'

// Rate limiting semplice, in memoria, per IP. Adatto a un singolo server;
// se in futuro si scala su più istanze, va sostituito con uno store
// condiviso (es. Redis).
export function rateLimit(max: number, windowMs: number) {
  const log = new Map<string, number[]>()

  // Senza pulizia ogni IP mai visto resterebbe per sempre nella mappa.
  const cleanup = setInterval(() => {
    const now = Date.now()
    for (const [ip, timestamps] of log) {
      if (timestamps.every((t) => now - t >= windowMs)) log.delete(ip)
    }
  }, windowMs)
  cleanup.unref?.()

  return createMiddleware(async (c, next) => {
    const ip = clientIp(c)
    const now = Date.now()
    const recent = (log.get(ip) ?? []).filter((t) => now - t < windowMs)
    if (recent.length >= max) {
      log.set(ip, recent)
      throw new HttpError(429, 'Troppe richieste, riprova tra poco.')
    }
    recent.push(now)
    log.set(ip, recent)
    await next()
  })
}

function clientIp(c: Context): string {
  return (
    c.req.header('x-forwarded-for')?.split(',')[0].trim() ??
    c.req.header('x-real-ip') ??
    'unknown'
  )
}
