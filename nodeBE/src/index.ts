import { serve } from '@hono/node-server'
import { Hono } from 'hono'
import { cors } from 'hono/cors'
import type { AppEnv } from './auth.js'
import { PORT, SUPABASE_ANON_KEY, allowedOrigin } from './config.js'
import { HttpError } from './errors.js'
import { assignments } from './routes/assignments.js'
import { consents } from './routes/consents.js'
import { guides } from './routes/guides.js'
import { me } from './routes/me.js'
import { requests } from './routes/requests.js'
import { tours } from './routes/tours.js'

const app = new Hono<AppEnv>()

app.use(
  '*',
  cors({
    origin: allowedOrigin,
    allowHeaders: ['Content-Type', 'Authorization'],
    allowMethods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  }),
)

app.get('/health', (c) => c.json({ status: 'ok' }))

app.route('/tours', tours)
app.route('/guides', guides)
app.route('/me', me)
app.route('/requests', requests)
app.route('/consents', consents)
app.route('/assignments', assignments)

app.notFound((c) => c.json({ error: 'Risorsa non trovata' }, 404))

app.onError((err, c) => {
  if (err instanceof HttpError) return c.json({ error: err.message }, err.status)
  console.error(err)
  return c.json({ error: 'Errore interno del server' }, 500)
})

if (SUPABASE_ANON_KEY.startsWith('YOUR-')) {
  console.warn('Supabase non configurato: imposta SUPABASE_URL e SUPABASE_ANON_KEY in src/config.ts')
}

serve({ fetch: app.fetch, port: PORT }, (info) => {
  console.log(`GuidaTour backend in ascolto su http://localhost:${info.port}`)
})
