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
          .select('tour_id, people, status')
          .in(
            'tour_id',
            tours.map((t) => t.id),
          )
          .neq('status', 'rifiutata')
          .returns<{ tour_id: string; people: number; status: string }[]>(),
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
  for (const t of stats) {
    if (t.requestedPeople > t.seats) {
      alerts.push(
        `"${t.title}": ${t.requestedPeople} persone richieste per ${t.seats} posti disponibili.`,
      )
    }
  }
  // I tour sono ordinati per data: basta confrontare ognuno con i successivi
  // finché la distanza resta sotto la soglia.
  for (let i = 0; i < stats.length; i++) {
    for (let j = i + 1; j < stats.length; j++) {
      const a = stats[i]
      const b = stats[j]
      if (Date.parse(b.start) - Date.parse(a.start) >= OVERLAP_MS) break
      alerts.push(`"${a.title}" e "${b.title}" si sovrappongono (${fmtDate(a.start)}).`)
    }
  }

  return { tours: stats, alerts }
}
