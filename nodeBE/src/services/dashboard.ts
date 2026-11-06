import { unwrap } from '../errors.js'
import type { Db } from '../supabase.js'
import { listTours, type Tour } from './tours.js'

// Sotto questa distanza due tour della stessa guida si considerano sovrapposti.
const OVERLAP_MS = 3 * 60 * 60 * 1000

export interface TourStats extends Tour {
  requestedPeople: number
  pendingRequests: number
}

export interface Dashboard {
  tours: TourStats[]
  alerts: string[]
}

function fmtDate(iso: string): string {
  return new Date(iso).toLocaleString('it-IT', {
    timeZone: 'Europe/Rome',
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  })
}

/** Tour futuri della guida con i numeri delle richieste e gli avvisi di overbooking (BR-011B). */
export async function getDashboard(db: Db, guideId: string): Promise<Dashboard> {
  const tours = await listTours(db, { guideId, limit: 500 })
  const requests = tours.length
    ? unwrap(
        await db
          .from('booking_requests')
          .select('tour_id, people, status, start_at')
          .in(
            'tour_id',
            tours.map((t) => t.id),
          )
          .neq('status', 'rifiutata')
          .returns<{ tour_id: string; people: number; status: string; start_at: string | null }[]>(),
      )
    : []

  const stats: TourStats[] = tours.map((t) => {
    const mine = requests.filter((r) => r.tour_id === t.id)
    return {
      ...t,
      requestedPeople: mine.reduce((sum, r) => sum + r.people, 0),
      pendingRequests: mine.filter((r) => r.status === 'inviata').length,
    }
  })

  const alerts: string[] = []
  // I posti valgono per ogni uscita: si contano le persone data per data
  // (le richieste vecchie, senza data, vanno sulla prossima uscita).
  for (const t of stats) {
    const perDate = new Map<string, number>()
    for (const r of requests.filter((r) => r.tour_id === t.id)) {
      const d = r.start_at ? new Date(r.start_at).toISOString() : t.start
      perDate.set(d, (perDate.get(d) ?? 0) + r.people)
    }
    for (const [d, n] of perDate) {
      if (n > t.seats && Date.parse(d) >= Date.now()) {
        const when = t.dates.length > 1 ? ` (${fmtDate(d)})` : ''
        alerts.push(`"${t.title}"${when}: ${n} persone richieste per ${t.seats} posti disponibili.`)
      }
    }
  }
  // Ogni uscita futura di ogni tour, in ordine: basta confrontare ognuna con
  // le successive finché la distanza resta sotto la soglia.
  const slots = stats
    .flatMap((t) => t.upcoming.map((d) => ({ t, at: Date.parse(d), d })))
    .sort((a, b) => a.at - b.at)
  for (let i = 0; i < slots.length; i++) {
    for (let j = i + 1; j < slots.length; j++) {
      const a = slots[i]
      const b = slots[j]
      if (b.at - a.at >= OVERLAP_MS) break
      if (a.t.id === b.t.id) continue
      alerts.push(`"${a.t.title}" e "${b.t.title}" si sovrappongono (${fmtDate(a.d)}).`)
    }
  }

  return { tours: stats, alerts }
}
