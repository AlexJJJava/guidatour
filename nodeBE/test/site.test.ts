// Pagine pubbliche SEO contro un backend vero: `npm run test:site`.
// Di default usa Render; con BACKEND_URL=http://localhost:3000 il server locale.
// Solo letture: nessun dato viene scritto (le visite dei test usano un
// user-agent da bot, che il backend non conta).
import assert from 'node:assert/strict'
import { before, describe, test } from 'node:test'
import { SUPABASE_ANON_KEY, SUPABASE_URL } from '../src/config.js'

const BACKEND = process.env.BACKEND_URL ?? 'https://guidatour.onrender.com'
const UA = { 'User-Agent': 'GuidaTourTestBot/1.0' }

async function page(path: string) {
  const res = await fetch(BACKEND + path, { headers: UA })
  return { status: res.status, type: res.headers.get('content-type') ?? '', text: await res.text() }
}

const title = (html: string) => /<title>([^<]*)<\/title>/.exec(html)?.[1] ?? ''
const meta = (html: string, name: string) =>
  new RegExp(`<meta name="${name}" content="([^"]*)"`).exec(html)?.[1] ?? ''
const canonical = (html: string) => /<link rel="canonical" href="([^"]*)"/.exec(html)?.[1] ?? ''
const ldBlocks = (html: string) =>
  [...html.matchAll(/<script type="application\/ld\+json">([\s\S]*?)<\/script>/g)].map((m) => JSON.parse(m[1]))

type Tour = { id: string; title: string; city: string; price: number; start: string; upcoming?: string[] }
let tours: Tour[] = []

before(async () => {
  // Il primo giro sveglia Render (piano gratuito): può servire un minuto.
  const res = await fetch(`${BACKEND}/tours?limit=50`, { signal: AbortSignal.timeout(90_000) })
  assert.equal(res.status, 200)
  tours = ((await res.json()).tours as Tour[]).filter((t) => !t.title.startsWith('[TEST]'))
  assert.ok(tours.length > 0, 'servono tour futuri pubblici per i test')
})

describe('pagine SEO', () => {
  test('home: HTML con titolo, descrizione, canonical e JSON-LD', async () => {
    const p = await page('/')
    assert.equal(p.status, 200)
    assert.match(p.type, /text\/html/)
    assert.match(title(p.text), /GuidaTour/)
    assert.ok(meta(p.text, 'description').length > 50)
    assert.match(canonical(p.text), /^https?:\/\/[^/]+\/$/)
    const types = ldBlocks(p.text).flat().map((x) => x['@type'])
    assert.deepEqual(types.sort(), ['ItemList', 'WebSite'])
    assert.doesNotMatch(p.text, /name="robots" content="noindex"/)
  })

  test('home in inglese e spagnolo, con hreflang', async () => {
    const en = await page('/?lang=en')
    assert.match(en.text, /<html lang="en">/)
    assert.match(title(en.text), /local guides/)
    const es = await page('/?lang=es')
    assert.match(es.text, /<html lang="es">/)
    for (const l of ['it', 'en', 'es', 'x-default']) assert.match(es.text, new RegExp(`hreflang="${l}"`))
  })

  test('pagina della città con i suoi tour', async () => {
    const p = await page('/roma')
    assert.equal(p.status, 200)
    assert.match(title(p.text), /Roma/)
    const romeTours = tours.filter((t) => t.city === 'Roma')
    for (const t of romeTours.slice(0, 3)) assert.ok(p.text.includes(`/tour/${t.id}`), t.title)
  })

  test('città + categoria', async () => {
    const p = await page('/roma/visita-guidata')
    assert.equal(p.status, 200)
    assert.match(title(p.text), /Visita guidata a Roma/)
  })

  test('pagina del tour: testo, prezzo, Event JSON-LD e link all\'app', async () => {
    const t = tours[0]
    const p = await page(`/tour/${t.id}`)
    assert.equal(p.status, 200)
    assert.ok(title(p.text).includes(t.title.replace(/&/g, '&amp;').replace(/'/g, '&#39;')))
    assert.ok(p.text.includes(`${t.price}`))
    // Un Event per ogni prossima data (al massimo 12), il primo è la prossima uscita.
    const events = ldBlocks(p.text).flat()
    assert.equal(events.length, Math.min(t.upcoming?.length ?? 1, 12))
    const ev = events[0]
    assert.equal(ev['@type'], 'Event')
    assert.equal(ev.name, t.title)
    assert.equal(ev.startDate, t.start)
    assert.equal(ev.offers.price, t.price)
    assert.equal(ev.offers.priceCurrency, 'EUR')
    assert.match(canonical(p.text), new RegExp(`/tour/${t.id}$`))
    assert.ok(p.text.includes(`?tour=${t.id}`), 'pulsante verso l\'app')
  })

  test('tour inesistente: 404 HTML non indicizzabile', async () => {
    const p = await page('/tour/non-esiste-davvero')
    assert.equal(p.status, 404)
    assert.match(p.text, /name="robots" content="noindex"/)
  })

  test('tour passato: 410 non indicizzabile', async () => {
    const res = await fetch(
      `${SUPABASE_URL}/rest/v1/tours?select=id,title&start_at=lt.${new Date().toISOString()}&limit=5`,
      { headers: { apikey: SUPABASE_ANON_KEY, Authorization: `Bearer ${SUPABASE_ANON_KEY}` } },
    )
    const past = ((await res.json()) as { id: string; title: string }[]).filter((t) => !t.title.startsWith('[TEST]'))
    if (!past.length) return // nessun tour passato visibile: niente da verificare
    const p = await page(`/tour/${past[0].id}`)
    assert.equal(p.status, 410)
    assert.match(p.text, /name="robots" content="noindex"/)
  })

  test('slug sconosciuto: resta il 404 delle API', async () => {
    const p = await page('/citta-che-non-esiste')
    assert.equal(p.status, 404)
    assert.doesNotMatch(p.type, /text\/html/)
  })

  test('sitemap: XML con home, città e tour futuri, senza [TEST]', async () => {
    const p = await page('/sitemap.xml')
    assert.equal(p.status, 200)
    assert.match(p.type, /xml/)
    assert.match(p.text, /<urlset/)
    assert.match(p.text, /\/roma<\/loc>/)
    for (const t of tours.slice(0, 5)) assert.ok(p.text.includes(`/tour/${t.id}</loc>`), t.title)
    assert.doesNotMatch(p.text, /TEST/)
  })

  test('robots.txt indica la sitemap', async () => {
    const p = await page('/robots.txt')
    assert.equal(p.status, 200)
    assert.match(p.text, /Sitemap: .*\/sitemap\.xml/)
  })

  test('foto delle categorie servite come immagini', async () => {
    const res = await fetch(`${BACKEND}/img/cat_visita.jpg`)
    assert.equal(res.status, 200)
    assert.match(res.headers.get('content-type') ?? '', /image\/jpeg/)
  })

  test('le API restano JSON', async () => {
    const res = await fetch(`${BACKEND}/health`)
    assert.deepEqual(await res.json(), { status: 'ok' })
  })
})
