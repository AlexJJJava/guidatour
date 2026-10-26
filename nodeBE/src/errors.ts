import type { PostgrestError } from '@supabase/supabase-js'
import type { ContentfulStatusCode } from 'hono/utils/http-status'

export class HttpError extends Error {
  constructor(
    readonly status: ContentfulStatusCode,
    message: string,
  ) {
    super(message)
  }
}

export const notFound = (what: string) => new HttpError(404, `${what} non trovato`)

// Traduce gli errori di PostgREST/Postgres in risposte HTTP sensate.
// 42501 è la violazione di una policy RLS: l'utente non ha il permesso.
export function dbError(error: PostgrestError): HttpError {
  switch (error.code) {
    case '42501':
      return new HttpError(403, 'Operazione non consentita')
    case '23505':
      return new HttpError(409, 'Elemento già presente')
    case '23503':
      return new HttpError(404, 'Elemento collegato non trovato')
    case '23514':
    case '22P02':
      return new HttpError(400, 'Dati non validi')
    case 'PGRST116':
      return new HttpError(404, 'Elemento non trovato')
    default:
      console.error('Errore database:', error)
      return new HttpError(500, 'Errore del database')
  }
}

// Restituisce data o lancia l'errore tradotto: evita il solito
// `if (error) throw ...` dopo ogni query.
export function unwrap<T>(
  result: { data: T; error: null } | { data: null; error: PostgrestError },
): T {
  if (result.error) throw dbError(result.error)
  return result.data as T
}
