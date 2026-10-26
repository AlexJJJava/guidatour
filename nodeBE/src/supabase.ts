import { createClient, type SupabaseClient } from '@supabase/supabase-js'
import { SUPABASE_ANON_KEY, SUPABASE_URL } from './config.js'

export type Db = SupabaseClient

const options = { auth: { persistSession: false, autoRefreshToken: false } }

// Client per le richieste senza login: vede solo ciò che RLS concede ad anon.
export const anonDb: Db = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, options)

// Crea un client Supabase "impersonato" con il token dell'utente che ha
// fatto la richiesta: tutte le operazioni rispettano le Row Level Security
// policy, senza bisogno di usare la service_role key sul backend.
export function userDb(accessToken: string): Db {
  return createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    ...options,
    global: { headers: { Authorization: `Bearer ${accessToken}` } },
  })
}
