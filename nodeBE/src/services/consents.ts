import { randomUUID } from 'node:crypto'
import { WHATSAPP_CONSENT_TEXT, WHATSAPP_SENDER } from '../config.js'
import { HttpError, unwrap } from '../errors.js'
import type { Db } from '../supabase.js'

// Prova del consenso WhatsApp (BR-011D).
export interface WhatsAppConsent {
  id: string
  phone: string
  source: string
  text: string
  sender: string
  userId: string | null
  at: string
  revokedAt: string | null
}

type ConsentRow = {
  id: string
  phone: string
  source: string
  consent_text: string
  sender: string
  user_id: string | null
  created_at: string
  revoked_at: string | null
}

const toConsent = (r: ConsentRow): WhatsAppConsent => ({
  id: r.id,
  phone: r.phone,
  source: r.source,
  text: r.consent_text,
  sender: r.sender,
  userId: r.user_id,
  at: r.created_at,
  revokedAt: r.revoked_at,
})

export async function createConsent(
  db: Db,
  userId: string | null,
  phone: string,
  source: string,
): Promise<string> {
  const id = randomUUID()
  unwrap(
    await db.from('whatsapp_consents').insert({
      id,
      phone,
      source,
      consent_text: WHATSAPP_CONSENT_TEXT,
      sender: WHATSAPP_SENDER,
      user_id: userId,
    }),
  )
  return id
}

// Solo gli admin vedono le righe (RLS); per gli altri la lista è vuota.
export async function listConsents(db: Db): Promise<WhatsAppConsent[]> {
  const rows = unwrap(
    await db
      .from('whatsapp_consents')
      .select('*')
      .order('created_at', { ascending: false })
      .returns<ConsentRow[]>(),
  )
  return rows.map(toConsent)
}

export async function revokeConsent(db: Db, id: string): Promise<WhatsAppConsent> {
  const row = unwrap(
    await db
      .from('whatsapp_consents')
      .update({ revoked_at: new Date().toISOString() })
      .eq('id', id)
      .is('revoked_at', null)
      .select('*')
      .maybeSingle<ConsentRow>(),
  )
  if (!row) throw new HttpError(404, 'Consenso non trovato o già revocato')
  return toConsent(row)
}
