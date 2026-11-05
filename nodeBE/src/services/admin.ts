import { notFound, unwrap } from '../errors.js'
import type { Db } from '../supabase.js'
import { listRegistrations, type Profile } from './profiles.js'
import { toTour, type Tour, type TourRow } from './tours.js'

// Area di gestione: le policy RLS fanno vedere all'admin tutti i profili e i
// tour; le richieste dei turisti solo come totali (funzione admin_stats).

export interface AdminOverview {
  professionals: number
  pending: number
  suspended: number
  rejected: number
  tourists: number
  tours: number
  upcomingTours: number
  packages: number
  consents: number
  // null finché la migrazione 0007 non è applicata.
  requests: number | null
  requestsConfirmed: number | null
  visits: number
  scans: number
}

type Stats = { requests: number; requestsConfirmed: number; visits: number; scans: number }

export async function getOverview(db: Db): Promise<AdminOverview> {
  const [profiles, tours, consents, stats] = await Promise.all([
    db.from('profiles').select('*').returns<
      { role: string; approval_status?: string; pending_roles?: string[] }[]
    >(),
    db.from('tours').select('start_at, accessories, visits, scans').returns<
      { start_at: string; accessories: string[]; visits: number; scans: number }[]
    >(),
    db.from('whatsapp_consents').select('id', { count: 'exact', head: true }),
    db.rpc('admin_stats'),
  ])
  const people = unwrap(profiles)
  const allTours = unwrap(tours)
  const pros = people.filter((p) => p.role !== 'turista')
  const status = (s: string) => pros.filter((p) => (p.approval_status ?? 'approvato') === s).length
  const now = Date.now()
  const s = stats.error ? null : (stats.data as Stats)
  return {
    professionals: status('approvato'),
    // Registrazioni in attesa più professionisti che chiedono nuovi ruoli.
    pending:
      status('in_attesa') +
      pros.filter((p) => (p.approval_status ?? 'approvato') === 'approvato' && p.pending_roles?.length)
        .length,
    suspended: status('sospeso'),
    rejected: status('rifiutato'),
    tourists: people.length - pros.length,
    tours: allTours.length,
    upcomingTours: allTours.filter((t) => new Date(t.start_at).getTime() >= now).length,
    packages: allTours.filter((t) => t.accessories.length > 0).length,
    consents: consents.count ?? 0,
    requests: s?.requests ?? null,
    requestsConfirmed: s?.requestsConfirmed ?? null,
    visits: s?.visits ?? allTours.reduce((a, t) => a + t.visits, 0),
    scans: s?.scans ?? allTours.reduce((a, t) => a + t.scans, 0),
  }
}

/** Professionisti approvati o sospesi, con il numero dei loro tour. */
export async function listProfessionalsForAdmin(
  db: Db,
): Promise<(Profile & { tours: number })[]> {
  const [active, suspended, tours] = await Promise.all([
    listRegistrations(db, 'approvato'),
    listRegistrations(db, 'sospeso').catch(() => [] as Profile[]),
    db.from('tours').select('guide_id').returns<{ guide_id: string }[]>(),
  ])
  const counts = new Map<string, number>()
  for (const t of unwrap(tours)) counts.set(t.guide_id, (counts.get(t.guide_id) ?? 0) + 1)
  return [...active, ...suspended]
    .sort((a, b) => a.name.localeCompare(b.name))
    .map((p) => ({ ...p, tours: counts.get(p.id) ?? 0 }))
}

/** Tutti i tour, anche passati e di professionisti sospesi. */
export async function listToursForAdmin(
  db: Db,
): Promise<(Tour & { guideName: string; guideStatus: string })[]> {
  const rows = unwrap(
    await db.from('tours').select('*').order('start_at', { ascending: false }).returns<TourRow[]>(),
  )
  const ids = [...new Set(rows.map((r) => r.guide_id))]
  const owners = ids.length
    ? unwrap(
        await db
          .from('profiles')
          .select('id, name, approval_status')
          .in('id', ids)
          .returns<{ id: string; name: string; approval_status?: string }[]>(),
      )
    : []
  const byId = new Map(owners.map((o) => [o.id, o]))
  return rows.map((r) => ({
    ...toTour(r),
    guideName: byId.get(r.guide_id)?.name ?? '',
    guideStatus: byId.get(r.guide_id)?.approval_status ?? 'approvato',
  }))
}

export async function deleteTourAsAdmin(db: Db, id: string): Promise<void> {
  const deleted = unwrap(await db.from('tours').delete().eq('id', id).select('id'))
  if (deleted.length === 0) throw notFound('Tour')
}
