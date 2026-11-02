// Permessi per ruolo contro un backend vero: `npm run test:roles`.
// Di default usa Render; con BACKEND_URL=http://localhost:3000 il server locale.
// Scrive sul database con gli account di prova: i tour hanno titolo [TEST],
// data 2099, e vengono cancellati alla fine insieme a richieste e assegnazioni.
import assert from 'node:assert/strict'
import { after, before, describe, test } from 'node:test'
import { SUPABASE_ANON_KEY, SUPABASE_URL } from '../src/config.js'

const BACKEND = process.env.BACKEND_URL ?? 'https://guidatour.onrender.com'
const PASSWORD = process.env.TEST_PASSWORD ?? 'GuidaTour2026!'
const NO_ID = '00000000-0000-0000-0000-000000000000'

const EMAILS = {
  turista: 'alessio.damico+turista1@gmail.com',
  guida: 'alessio.damico+guida1@gmail.com',
  accompagnatore: 'alessio.damico+accompagnatore1@gmail.com',
  operator: 'alessio.damico+operator1@gmail.com',
  admin: 'alessio.damico+admin1@gmail.com',
}
type Who = keyof typeof EMAILS

const tokens = {} as Record<Who, string>
const ids = {} as Record<Who, string>
const profiles = {} as Record<Who, { verified: boolean; role: string; isAdmin: boolean }>
const created: { id: string; owner: Who }[] = []

type Call = { method?: string; token?: string; body?: unknown }

async function call(base: string, path: string, c: Call, headers: Record<string, string> = {}) {
  const res = await fetch(base + path, {
    method: c.method ?? (c.body === undefined ? 'GET' : 'POST'),
    headers: {
      ...(c.body === undefined ? {} : { 'Content-Type': 'application/json' }),
      ...(c.token ? { Authorization: `Bearer ${c.token}` } : {}),
      ...headers,
    },
    body: c.body === undefined ? undefined : JSON.stringify(c.body),
  })
  const text = await res.text()
  let json: any = null
  try {
    json = text ? JSON.parse(text) : null
  } catch {
    json = text
  }
  return { status: res.status, json }
}

const api = (path: string, c: Call = {}) => call(BACKEND, path, c)

/** Direttamente su Supabase, come farebbe chi scavalca il nostro backend. */
const rest = (path: string, c: Call = {}) =>
  call(
    SUPABASE_URL,
    path,
    { ...c, token: c.token ?? SUPABASE_ANON_KEY },
    { apikey: SUPABASE_ANON_KEY, Prefer: 'return=representation' },
  )

async function login(email: string): Promise<string> {
  const r = await call(
    SUPABASE_URL,
    '/auth/v1/token?grant_type=password',
    { body: { email, password: PASSWORD } },
    { apikey: SUPABASE_ANON_KEY },
  )
  assert.equal(r.status, 200, `login ${email}: ${JSON.stringify(r.json)}`)
  return r.json.access_token
}

const tourBody = (over: Record<string, unknown> = {}) => ({
  title: '[TEST] Tour di prova',
  city: 'Roma',
  category: 'Tour a piedi',
  language: 'Italiano',
  duration: '2 ore',
  start: '2099-06-15T10:00:00Z',
  price: 10,
  meetingPoint: 'Piazza di prova',
  description: 'Creato dai test automatici',
  seats: 2,
  accessories: [] as string[],
  ...over,
})

async function newTour(owner: Who, over: Record<string, unknown> = {}) {
  const r = await api('/tours', { token: tokens[owner], body: tourBody(over) })
  assert.equal(r.status, 201, JSON.stringify(r.json))
  created.push({ id: r.json.id, owner })
  return r.json as { id: string; isPackage: boolean; category: string }
}

const requestBody = {
  name: 'Test Automatico',
  email: 'test@example.com',
  phone: '',
  people: 1,
  message: '[TEST]',
}

before(async () => {
  // Il piano free di Render si addormenta: la prima risposta può metterci un minuto.
  const health = await fetch(`${BACKEND}/health`, { signal: AbortSignal.timeout(90_000) })
  assert.equal(health.status, 200)
  for (const who of Object.keys(EMAILS) as Who[]) {
    tokens[who] = await login(EMAILS[who])
    const me = await api('/me', { token: tokens[who] })
    assert.equal(me.status, 200)
    ids[who] = me.json.id
    profiles[who] = me.json
  }
})

after(async () => {
  for (const t of created) {
    await api(`/tours/${t.id}`, { method: 'DELETE', token: tokens[t.owner] })
  }
})

describe('account di prova', () => {
  test('hanno il ruolo atteso', () => {
    assert.equal(profiles.turista.role, 'turista')
    assert.equal(profiles.guida.role, 'guida')
    assert.equal(profiles.accompagnatore.role, 'accompagnatore')
    assert.equal(profiles.operator.role, 'tourOperator')
    assert.equal(profiles.admin.isAdmin, true)
  })
})

describe('visitatore senza account', () => {
  test('vede tour, opzioni e professionisti', async () => {
    const tours = await api('/tours')
    assert.equal(tours.status, 200)
    assert.ok(tours.json.tours.length > 0, 'nessun tour futuro')
    assert.equal((await api('/tours/options')).status, 200)
    assert.equal((await api(`/tours/${tours.json.tours[0].id}`)).status, 200)
    assert.equal((await api('/guides')).status, 200)
    assert.equal((await api('/consents/text')).status, 200)
  })

  test('il profilo pubblico non espone dati riservati', async () => {
    const { json } = await api('/guides')
    for (const g of json.guides) {
      assert.equal(g.email, undefined)
      assert.equal(g.isAdmin, undefined)
    }
  })

  test('tutte le aree riservate rispondono 401', async () => {
    for (const [path, c] of [
      ['/me', {}],
      ['/me/requests', {}],
      ['/me/favorites', {}],
      ['/me/cart', {}],
      ['/me/dashboard', {}],
      ['/me/notifications', {}],
      ['/requests/received', {}],
      ['/assignments', {}],
      ['/admin/registrations', {}],
      ['/consents', {}],
      ['/tours', { body: tourBody() }],
      [`/consents/${NO_ID}/revoke`, { body: {} }],
    ] as [string, Call][]) {
      assert.equal((await api(path, c)).status, 401, path)
    }
  })

  test('può inviare una richiesta di prenotazione', async () => {
    const tour = await newTour('guida')
    const r = await api(`/tours/${tour.id}/requests`, { body: requestBody })
    assert.equal(r.status, 201, JSON.stringify(r.json))
  })

  test('non legge i dati privati direttamente da Supabase', async () => {
    for (const table of ['booking_requests', 'whatsapp_consents', 'profiles', 'notifications']) {
      const r = await rest(`/rest/v1/${table}?select=*&limit=5`)
      assert.ok(r.status >= 400 || r.json.length === 0, `${table} leggibile da anonimo`)
    }
  })
})

describe('turista', () => {
  test('non accede alle funzioni professionali o admin', async () => {
    const token = tokens.turista
    assert.equal((await api('/tours', { token, body: tourBody() })).status, 403)
    assert.equal((await api('/me/dashboard', { token })).status, 403)
    assert.equal((await api('/requests/received', { token })).status, 403)
    assert.equal((await api('/assignments', { token })).status, 403)
    assert.equal((await api('/admin/registrations', { token })).status, 403)
    assert.equal((await api('/consents', { token })).status, 403)
  })

  test('preferiti, carrello e invio dal carrello', async () => {
    const token = tokens.turista
    const tour = await newTour('guida')

    assert.ok((await api(`/me/favorites/${tour.id}`, { method: 'PUT', token })).status < 300)
    const favs = await api('/me/favorites', { token })
    assert.ok(JSON.stringify(favs.json).includes(tour.id))
    assert.ok((await api(`/me/favorites/${tour.id}`, { method: 'DELETE', token })).status < 300)

    const add = await api('/me/cart', { token, body: { tourId: tour.id, people: 1 } })
    assert.ok(add.status < 300, JSON.stringify(add.json))
    const up = await api(`/me/cart/${tour.id}`, { method: 'PATCH', token, body: { people: 2 } })
    assert.ok(up.status < 300, JSON.stringify(up.json))
    const out = await api('/me/cart/checkout', {
      token,
      body: { name: 'Test Automatico', email: 'test@example.com', phone: '', message: '[TEST]' },
    })
    assert.ok(out.status < 300, JSON.stringify(out.json))
    const sent = await api('/me/requests', { token })
    assert.ok(JSON.stringify(sent.json).includes(tour.id), 'richiesta assente dallo storico')
  })

  test('modifica solo nome e dati ammessi del proprio profilo', async () => {
    const token = tokens.turista
    const { name } = (await api('/me', { token })).json
    const body = { name, isAdmin: true, role: 'guida', verified: true }
    assert.ok((await api('/me', { method: 'PATCH', token, body })).status < 500)
    const me = await api('/me', { token })
    assert.equal(me.json.isAdmin, false)
    assert.equal(me.json.role, 'turista')
  })
})

describe('guida turistica', () => {
  test('crea, modifica ed elimina un proprio tour', async () => {
    const token = tokens.guida
    const tour = await newTour('guida')
    const up = await api(`/tours/${tour.id}`, { method: 'PATCH', token, body: { price: 11 } })
    assert.equal(up.status, 200, JSON.stringify(up.json))
    assert.equal(up.json.price, 11)
    assert.ok((await api(`/tours/${tour.id}`, { method: 'DELETE', token })).status < 300)
    assert.equal((await api(`/tours/${tour.id}`)).status, 404)
  })

  test('non può pubblicare pacchetti', async () => {
    const r = await api('/tours', {
      token: tokens.guida,
      body: tourBody({ accessories: ['Cena / ristorante'] }),
    })
    assert.equal(r.status, 422)
  })

  test('non tocca i tour degli altri', async () => {
    const tour = await newTour('operator')
    const token = tokens.guida
    const patch = await api(`/tours/${tour.id}`, { method: 'PATCH', token, body: { price: 1 } })
    assert.equal(patch.status, 403)
    assert.equal((await api(`/tours/${tour.id}`, { method: 'DELETE', token })).status, 404)
    assert.equal((await api(`/tours/${tour.id}`)).status, 200)
  })

  test('vede e gestisce solo le richieste dei propri tour', async () => {
    const tour = await newTour('guida')
    assert.equal((await api(`/tours/${tour.id}/requests`, { body: requestBody })).status, 201)

    const mine = await api(`/tours/${tour.id}/requests`, { token: tokens.guida })
    assert.equal(mine.status, 200, JSON.stringify(mine.json))
    const id = mine.json.requests[0].id

    const others = await api('/requests/received', { token: tokens.operator })
    assert.ok(!JSON.stringify(others.json).includes(id), 'richiesta visibile ad altri')
    const stolen = await api(`/requests/${id}`, {
      method: 'PATCH',
      token: tokens.operator,
      body: { status: 'confermata' },
    })
    assert.ok(stolen.status >= 400, 'un altro professionista ha confermato la richiesta')

    const ok = await api(`/requests/${id}`, {
      method: 'PATCH',
      token: tokens.guida,
      body: { status: 'confermata' },
    })
    assert.equal(ok.status, 200, JSON.stringify(ok.json))
  })

  test('cessione: la destinataria accetta ma non può riassegnare', async () => {
    const tour = await newTour('guida')
    const p = await api('/assignments', {
      token: tokens.guida,
      body: { tourId: tour.id, toGuideId: ids.operator },
    })
    assert.equal(p.status, 201, JSON.stringify(p.json))

    const third = await api(`/assignments/${p.json.id}/respond`, {
      token: tokens.accompagnatore,
      body: { accept: true },
    })
    assert.ok(third.status >= 400, 'un terzo ha risposto alla proposta')

    const accept = await api(`/assignments/${p.json.id}/respond`, {
      token: tokens.operator,
      body: { accept: true },
    })
    assert.equal(accept.status, 200, JSON.stringify(accept.json))

    const again = await api('/assignments', {
      token: tokens.operator,
      body: { tourId: tour.id, toGuideId: ids.accompagnatore },
    })
    assert.ok(again.status >= 400, 'la destinataria ha riassegnato il tour')
  })

  test('non propone visite guidate a un accompagnatore', async () => {
    const tour = await newTour('guida', { category: 'Visita guidata' })
    const r = await api('/assignments', {
      token: tokens.guida,
      body: { tourId: tour.id, toGuideId: ids.accompagnatore },
    })
    assert.equal(r.status, 422)
  })

  test('vede la propria dashboard', async () => {
    assert.equal((await api('/me/dashboard', { token: tokens.guida })).status, 200)
  })

  test('non accede alle funzioni admin', async () => {
    const token = tokens.guida
    assert.equal((await api('/admin/registrations', { token })).status, 403)
    assert.equal((await api('/consents', { token })).status, 403)
  })
})

describe('accompagnatore turistico', () => {
  const blocked = async (over: Record<string, unknown>) =>
    (await api('/tours', { token: tokens.accompagnatore, body: tourBody(over) })).status

  test('pubblica attività di accompagnamento', async () => {
    const tour = await newTour('accompagnatore', {
      category: 'Accompagnamento',
      title: '[TEST] Assistenza gruppi',
    })
    assert.equal(tour.category, 'Accompagnamento')
  })

  test('non pubblica altre categorie', async () => {
    assert.equal(await blocked({ category: 'Visita guidata' }), 422)
    assert.equal(await blocked({ category: 'Tour a piedi' }), 422)
  })

  test('non pubblica testi riservati alla guida abilitata', async () => {
    for (const word of ['Colosseo', 'museo', 'visita guidata', 'beni culturali', 'pinacoteca']) {
      assert.equal(
        await blocked({ category: 'Accompagnamento', description: `Assistenza: ${word}` }),
        422,
        word,
      )
    }
  })

  test('non aggira il blocco modificando un tour esistente', async () => {
    const tour = await newTour('accompagnatore', { category: 'Accompagnamento' })
    const token = tokens.accompagnatore
    for (const body of [{ category: 'Visita guidata' }, { description: 'Visita al Colosseo' }]) {
      const r = await api(`/tours/${tour.id}`, { method: 'PATCH', token, body })
      assert.equal(r.status, 422, JSON.stringify(body))
    }
  })

  test('non pubblica pacchetti', async () => {
    assert.equal(
      await blocked({ category: 'Accompagnamento', accessories: ['Cena / ristorante'] }),
      422,
    )
  })

  test('riceve e accetta proposte di accompagnamento', async () => {
    const tour = await newTour('guida', { category: 'Accompagnamento' })
    const p = await api('/assignments', {
      token: tokens.guida,
      body: { tourId: tour.id, toGuideId: ids.accompagnatore },
    })
    assert.equal(p.status, 201, JSON.stringify(p.json))
    const a = await api(`/assignments/${p.json.id}/respond`, {
      token: tokens.accompagnatore,
      body: { accept: false },
    })
    assert.equal(a.status, 200, JSON.stringify(a.json))
  })

  test('è elencato con il proprio ruolo', async () => {
    const { json } = await api('/guides?role=accompagnatore')
    const me = json.guides.find((g: { id: string }) => g.id === ids.accompagnatore)
    assert.equal(me?.role, 'accompagnatore')
  })
})

describe('tour operator', () => {
  test('pacchetti solo se verificato', async () => {
    const r = await api('/tours', {
      token: tokens.operator,
      body: tourBody({ accessories: ['Cena / ristorante'] }),
    })
    if (profiles.operator.verified) {
      assert.equal(r.status, 201, JSON.stringify(r.json))
      assert.equal(r.json.isPackage, true)
      created.push({ id: r.json.id, owner: 'operator' })
    } else {
      assert.equal(r.status, 422)
    }
  })

  test('crea tour senza servizi accessori', async () => {
    await newTour('operator')
  })

  test('non accede alle funzioni admin', async () => {
    const r = await api('/admin/registrations', { token: tokens.operator })
    assert.equal(r.status, 403)
  })
})

describe('admin', () => {
  test('consulta registrazioni e consensi', async () => {
    const token = tokens.admin
    for (const s of ['in_attesa', 'approvato', 'rifiutato']) {
      assert.equal((await api(`/admin/registrations?status=${s}`, { token })).status, 200)
    }
    assert.equal((await api('/consents', { token })).status, 200)
  })

  test('ha le funzioni del proprio ruolo, non quelle professionali', async () => {
    const r = await api('/tours', { token: tokens.admin, body: tourBody() })
    assert.equal(r.status, 403)
  })

  test('non può approvare un profilo inesistente', async () => {
    const r = await api(`/admin/registrations/${NO_ID}`, {
      token: tokens.admin,
      body: { status: 'approvato' },
    })
    assert.ok(r.status >= 400)
  })
})

describe('tentativi di scavalcare i ruoli', () => {
  test('nessuno approva registrazioni al posto dell\'admin', async () => {
    for (const who of ['turista', 'guida', 'accompagnatore', 'operator'] as Who[]) {
      const r = await api(`/admin/registrations/${ids.turista}`, {
        token: tokens[who],
        body: { status: 'approvato' },
      })
      assert.equal(r.status, 403, who)
      const rpc = await rest('/rest/v1/rpc/set_approval_status', {
        token: tokens[who],
        body: { p_user: ids[who], p_status: 'approvato' },
      })
      assert.ok(rpc.status >= 400, `rpc riuscita per ${who}`)
    }
  })

  test('nessuno cambia i propri flag scrivendo su Supabase', async () => {
    for (const [column, value] of [
      ['is_admin', true],
      ['verified', true],
      ['role', 'tourOperator'],
      ['approval_status', 'rifiutato'],
    ] as [string, unknown][]) {
      await rest(`/rest/v1/profiles?id=eq.${ids.turista}`, {
        method: 'PATCH',
        token: tokens.turista,
        body: { [column]: value },
      })
    }
    const me = await api('/me', { token: tokens.turista })
    assert.equal(me.json.isAdmin, false)
    assert.equal(me.json.verified, false)
    assert.equal(me.json.role, 'turista')
    assert.equal(me.json.approvalStatus, 'approvato')
  })

  test('nessun professionista pubblica scrivendo su Supabase al posto di un altro', async () => {
    const r = await rest('/rest/v1/tours', {
      token: tokens.turista,
      body: {
        id: 'test-abuso',
        guide_id: ids.guida,
        title: '[TEST] Abuso',
        category: 'Tour a piedi',
        language: 'Italiano',
        duration: '1 ora',
        start_at: '2099-01-01T10:00:00Z',
        price: 1,
        meeting_point: 'Prova',
        seats: 1,
      },
    })
    assert.ok(r.status >= 400, 'tour inserito per conto di un altro')
  })

  test('nessuno aumenta i contatori scrivendo su Supabase', async () => {
    const tour = await newTour('guida')
    const r = await rest(`/rest/v1/tours?id=eq.${tour.id}`, {
      method: 'PATCH',
      token: tokens.guida,
      body: { visits: 9999 },
    })
    const { json } = await api(`/tours/${tour.id}`)
    assert.ok(r.status >= 400 || json.visits === 0, 'contatore modificato a mano')
  })

  test('un consenso WhatsApp si revoca solo da admin', async () => {
    const list = await api('/consents', { token: tokens.admin })
    const open = list.json.consents.find((c: { revokedAt?: string }) => !c.revokedAt)
    const id = open?.id ?? NO_ID
    for (const who of ['turista', 'guida'] as Who[]) {
      const r = await api(`/consents/${id}/revoke`, { token: tokens[who], body: {} })
      assert.ok(r.status >= 400, `revocato da ${who}`)
    }
  })

  test('la lista dei tour non contiene tour scaduti', async () => {
    const { json } = await api('/tours')
    for (const t of json.tours) assert.ok(new Date(t.start) >= new Date(Date.now() - 60_000))
  })
})

describe('foto profilo', () => {
  // PNG di 1×1 pixel.
  const png = Buffer.from(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
    'base64',
  )
  const upload = (token: string, owner: string, type = 'image/png') =>
    fetch(`${SUPABASE_URL}/storage/v1/object/avatars/${owner}/avatar.png`, {
      method: 'POST',
      headers: {
        apikey: SUPABASE_ANON_KEY,
        Authorization: `Bearer ${token}`,
        'Content-Type': type,
        'x-upsert': 'true',
      },
      body: png,
    })
  const remove = (token: string, owner: string) =>
    fetch(`${SUPABASE_URL}/storage/v1/object/avatars/${owner}/avatar.png`, {
      method: 'DELETE',
      headers: { apikey: SUPABASE_ANON_KEY, Authorization: `Bearer ${token}` },
    })

  after(async () => {
    await remove(tokens.turista, ids.turista)
    await api('/me', { method: 'PATCH', token: tokens.turista, body: { avatarUrl: null } })
  })

  test('ognuno carica, salva e rimuove la propria', async () => {
    const token = tokens.turista
    assert.ok((await upload(token, ids.turista)).ok, 'caricamento rifiutato')
    const url = `${SUPABASE_URL}/storage/v1/object/public/avatars/${ids.turista}/avatar.png?v=1`
    const saved = await api('/me', { method: 'PATCH', token, body: { avatarUrl: url } })
    assert.equal(saved.status, 200, JSON.stringify(saved.json))
    assert.equal(saved.json.avatarUrl, url)
    const pub = await fetch(url)
    assert.equal(pub.status, 200)
    assert.equal(pub.headers.get('content-type'), 'image/png')
    const clear = await api('/me', { method: 'PATCH', token, body: { avatarUrl: null } })
    assert.equal(clear.json.avatarUrl, null)
  })

  test('nessuno scrive nella cartella di un altro', async () => {
    assert.ok(!(await upload(tokens.guida, ids.turista)).ok)
  })

  test('un visitatore non carica foto', async () => {
    assert.ok(!(await upload(SUPABASE_ANON_KEY, ids.turista)).ok)
  })

  test('accetta solo immagini PNG', async () => {
    assert.ok(!(await upload(tokens.turista, ids.turista, 'text/html')).ok)
  })

  test('non accetta indirizzi esterni o di altri utenti', async () => {
    const token = tokens.turista
    for (const avatarUrl of [
      'https://example.com/x.png',
      `${SUPABASE_URL}/storage/v1/object/public/avatars/${ids.guida}/avatar.png`,
    ]) {
      const r = await api('/me', { method: 'PATCH', token, body: { avatarUrl } })
      assert.equal(r.status, 422, avatarUrl)
    }
  })
})
