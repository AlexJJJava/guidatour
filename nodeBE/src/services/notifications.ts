import { unwrap } from '../errors.js'
import type { Db } from '../supabase.js'

// Le notifiche le scrivono i trigger del database (nuova richiesta,
// proposta di cessione e relativa risposta); qui si leggono e si segnano lette.

export interface Notification {
  id: string
  message: string
  createdAt: string
  readAt: string | null
}

type NotificationRow = { id: string; message: string; created_at: string; read_at: string | null }

export async function listNotifications(
  db: Db,
  userId: string,
  unreadOnly: boolean,
): Promise<Notification[]> {
  let query = db
    .from('notifications')
    .select('id, message, created_at, read_at')
    .eq('user_id', userId)
    .order('created_at', { ascending: false })
    .limit(100)
  if (unreadOnly) query = query.is('read_at', null)
  const rows = unwrap(await query.returns<NotificationRow[]>())
  return rows.map((r) => ({
    id: r.id,
    message: r.message,
    createdAt: r.created_at,
    readAt: r.read_at,
  }))
}

// Senza id segna come lette tutte le notifiche dell'utente.
export async function markRead(db: Db, userId: string, id?: string): Promise<void> {
  let query = db
    .from('notifications')
    .update({ read_at: new Date().toISOString() })
    .eq('user_id', userId)
    .is('read_at', null)
  if (id) query = query.eq('id', id)
  unwrap(await query)
}
