import { HttpError, unwrap } from '../errors.js'
import type { Db } from '../supabase.js'
import { getPublicProfiles, type PublicProfile } from './profiles.js'

// Cambio / cessione tour tra professionisti (BR-011A). Le transizioni di
// stato consentite sono imposte dalle policy RLS su assignments.

export type AssignmentStatus = 'proposto' | 'accettato' | 'rifiutato' | 'annullato' | 'completato'

export interface Assignment {
  id: string
  tourId: string
  fromGuideId: string
  toGuideId: string
  status: AssignmentStatus
  createdAt: string
  updatedAt: string
  tour: { id: string; title: string; start: string } | null
  fromGuide: PublicProfile | null
  toGuide: PublicProfile | null
}

type AssignmentRow = {
  id: string
  tour_id: string
  from_guide_id: string
  to_guide_id: string
  status: AssignmentStatus
  created_at: string
  updated_at: string
  tours: { id: string; title: string; start_at: string } | null
}

const SELECT = '*, tours(id, title, start_at)'

async function withProfiles(db: Db, rows: AssignmentRow[]): Promise<Assignment[]> {
  const profiles = await getPublicProfiles(
    db,
    rows.flatMap((r) => [r.from_guide_id, r.to_guide_id]),
  )
  return rows.map((r) => ({
    id: r.id,
    tourId: r.tour_id,
    fromGuideId: r.from_guide_id,
    toGuideId: r.to_guide_id,
    status: r.status,
    createdAt: r.created_at,
    updatedAt: r.updated_at,
    tour: r.tours && { id: r.tours.id, title: r.tours.title, start: r.tours.start_at },
    fromGuide: profiles.get(r.from_guide_id) ?? null,
    toGuide: profiles.get(r.to_guide_id) ?? null,
  }))
}

// Proposte fatte e ricevute dall'utente.
export async function listAssignments(db: Db): Promise<Assignment[]> {
  const rows = unwrap(
    await db
      .from('assignments')
      .select(SELECT)
      .order('created_at', { ascending: false })
      .returns<AssignmentRow[]>(),
  )
  return withProfiles(db, rows)
}

export async function proposeAssignment(
  db: Db,
  userId: string,
  tourId: string,
  toGuideId: string,
): Promise<Assignment> {
  if (toGuideId === userId) throw new HttpError(422, 'Non puoi proporre il tour a te stesso')
  const row = unwrap(
    await db
      .from('assignments')
      .insert({ tour_id: tourId, from_guide_id: userId, to_guide_id: toGuideId })
      .select(SELECT)
      .single<AssignmentRow>(),
  )
  const [assignment] = await withProfiles(db, [row])
  return assignment
}

async function setStatus(db: Db, id: string, status: AssignmentStatus): Promise<Assignment> {
  const row = unwrap(
    await db
      .from('assignments')
      .update({ status, updated_at: new Date().toISOString() })
      .eq('id', id)
      .select(SELECT)
      .maybeSingle<AssignmentRow>(),
  )
  if (!row) throw new HttpError(409, 'Proposta non trovata o non più modificabile')
  const [assignment] = await withProfiles(db, [row])
  return assignment
}

/** La destinataria può solo accettare o rifiutare, mai riassegnare (BR-011A.1). */
export const respondAssignment = (db: Db, id: string, accept: boolean) =>
  setStatus(db, id, accept ? 'accettato' : 'rifiutato')

export const cancelAssignment = (db: Db, id: string) => setStatus(db, id, 'annullato')

export const completeAssignment = (db: Db, id: string) => setStatus(db, id, 'completato')
