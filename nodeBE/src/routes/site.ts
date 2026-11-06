import { serveStatic } from '@hono/node-server/serve-static'
import { Hono, type Context } from 'hono'
import type { AppEnv } from '../auth.js'
import { APP_URL, SEO_SITE_URL } from '../config.js'
import { onlyAccompagnatore } from '../services/profiles.js'
import {
  CITIES,
  TOUR_CATEGORIES,
  getTourWithGuide,
  listTours,
  recordView,
  type Tour,
} from '../services/tours.js'
import { anonDb } from '../supabase.js'
import { type Lang, TEXTS, langFrom } from '../site/i18n.js'
import { esc, layout, withLang } from '../site/render.js'

// Pagine pubbliche in HTML vero, leggibili da Google e veloci da aprire
// (BR-003, BR-004A, BRD §14.3). Per prenotare si passa all'app Flutter.
export const site = new Hono<AppEnv>()

const slug = (s: string) =>
  s
    .toLowerCase()
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')

const cityBySlug = new Map(CITIES.map((c) => [slug(c), c]))
const categoryBySlug = new Map(TOUR_CATEGORIES.map((c) => [slug(c), c]))

const CATEGORY_IMAGES: Record<string, string> = {
  'Visita guidata': 'cat_visita.jpg',
  'Tour a piedi': 'cat_piedi.jpg',
  Enogastronomico: 'cat_food.jpg',
  'Bambini e famiglie': 'cat_famiglie.jpg',
  Serale: 'cat_serale.jpg',
  Accompagnamento: 'cat_accompagnamento.jpg',
}
const imageFor = (category: string) => `/img/${CATEGORY_IMAGES[category] ?? 'cat_visita.jpg'}`

/** I tour di prova dei test automatici non vanno mostrati né indicizzati. */
const isPublic = (t: Tour) => !t.title.startsWith('[TEST]')

const money = (lang: Lang, n: number) =>
  new Intl.NumberFormat(TEXTS[lang].locale, { style: 'currency', currency: 'EUR', maximumFractionDigits: 0 }).format(n)

const when = (lang: Lang, iso: string) =>
  new Intl.DateTimeFormat(TEXTS[lang].locale, {
    timeZone: 'Europe/Rome',
    weekday: 'short',
    day: 'numeric',
    month: 'long',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  }).format(new Date(iso))

const appTour = (id: string) => `${APP_URL}?tour=${encodeURIComponent(id)}`

const html = (c: Context<AppEnv>, page: string, status = 200) => {
  c.header('Cache-Control', 'public, max-age=300')
  return c.html(page, status as 200)
}

function card(lang: Lang, t: Tour) {
  const tx = TEXTS[lang]
  return `<li class="card"><a href="${esc(withLang(`/tour/${t.id}`, lang))}">
<img src="${imageFor(t.category)}" alt="${esc(tx.categories[t.category] ?? t.category)}" loading="lazy" width="400" height="150">
<div class="b"><span class="d">${esc(when(lang, t.start))}</span><h3>${esc(t.title)}</h3>
<span class="m">${esc(t.city)} · ${esc(tx.categories[t.category] ?? t.category)} · ${esc(t.duration)} · ${esc(t.language)}</span>
<span class="p">${esc(tx.pricePerPerson(money(lang, t.price)))}</span></div></a></li>`
}

const grid = (lang: Lang, tours: Tour[]) =>
  tours.length
    ? `<ul class="grid">${tours.map((t) => card(lang, t)).join('')}</ul>`
    : `<p class="muted">${esc(TEXTS[lang].noTours)}</p>`

/** Elenco di tour della pagina, in forma che Google capisce. */
const itemList = (tours: Tour[], lang: Lang) => ({
  '@context': 'https://schema.org',
  '@type': 'ItemList',
  itemListElement: tours.map((t, i) => ({
    '@type': 'ListItem',
    position: i + 1,
    url: SEO_SITE_URL + withLang(`/tour/${t.id}`, lang),
    name: t.title,
  })),
})

// ── file statici: foto delle categorie e favicon
site.use('/img/*', serveStatic({ root: './public' }))

site.get('/robots.txt', (c) =>
  c.text(`User-agent: *\nAllow: /\nDisallow: /me\nDisallow: /admin\nSitemap: ${SEO_SITE_URL}/sitemap.xml\n`),
)

site.get('/sitemap.xml', async (c) => {
  const tours = (await listTours(anonDb, { limit: 200 })).filter(isPublic)
  const paths = ['/', ...CITIES.map((x) => `/${slug(x)}`)]
  for (const city of new Set(tours.map((t) => t.city))) {
    for (const cat of new Set(tours.filter((t) => t.city === city).map((t) => t.category))) {
      paths.push(`/${slug(city)}/${slug(cat)}`)
    }
  }
  paths.push(...tours.map((t) => `/tour/${t.id}`))
  const urls = paths
    .map((p) => {
      const alts = (['it', 'en', 'es'] as Lang[])
        .map((l) => `<xhtml:link rel="alternate" hreflang="${l}" href="${esc(SEO_SITE_URL + withLang(p, l))}"/>`)
        .join('')
      return `<url><loc>${esc(SEO_SITE_URL + p)}</loc>${alts}</url>`
    })
    .join('')
  c.header('Content-Type', 'application/xml; charset=utf-8')
  return c.body(
    `<?xml version="1.0" encoding="UTF-8"?><urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" xmlns:xhtml="http://www.w3.org/1999/xhtml">${urls}</urlset>`,
  )
})

site.get('/', async (c) => {
  const lang = langFrom(c.req.query('lang'))
  const tx = TEXTS[lang]
  const tours = (await listTours(anonDb, { limit: 12 })).filter(isPublic)
  const body = `<section class="hero"><h1>${esc(tx.heroTitle)}</h1><p>${esc(tx.heroSub)}</p></section>
<h2>${esc(tx.citiesTitle)}</h2><ul class="chips">${CITIES.map((x) => `<li><a href="${esc(withLang(`/${slug(x)}`, lang))}">${esc(x)}</a></li>`).join('')}</ul>
<h2>${esc(tx.upcomingTitle)}</h2>${grid(lang, tours)}`
  return html(
    c,
    layout(SEO_SITE_URL, APP_URL, {
      lang,
      title: tx.homeTitle,
      description: tx.homeDescription,
      path: '/',
      body,
      image: tours[0] ? SEO_SITE_URL + imageFor(tours[0].category) : undefined,
      ld: [
        { '@context': 'https://schema.org', '@type': 'WebSite', name: 'GuidaTour', url: SEO_SITE_URL },
        itemList(tours, lang),
      ],
    }),
  )
})

site.get('/tour/:id', async (c) => {
  const lang = langFrom(c.req.query('lang'))
  const tx = TEXTS[lang]
  const id = c.req.param('id')
  const tour = await getTourWithGuide(anonDb, id).catch(() => null)
  if (!tour || !isPublic(tour)) return notFoundPage(c, lang)
  if (new Date(tour.start) < new Date()) return gonePage(c, lang, tour.city)

  // Conteggi: la scansione dal QR sempre, le visite solo da persone.
  const scan = c.req.query('src') === 'qr'
  const ua = c.req.header('user-agent') ?? ''
  if (scan || !/bot|crawl|spider|preview|facebookexternalhit|whatsapp|slurp/i.test(ua)) {
    await recordView(anonDb, id, scan).catch(() => {})
  }

  const guide = tour.guide
  const roles = guide ? (guide.roles ?? [guide.role]).map((r) => tx.roles[r] ?? r).join(' · ') : ''
  const category = tx.categories[tour.category] ?? tour.category
  const image = SEO_SITE_URL + imageFor(tour.category)
  const description = `${when(lang, tour.start)} · ${tour.city} · ${category} · ${tour.duration} · ${tx.pricePerPerson(money(lang, tour.price))}. ${tour.description}`.slice(0, 300)
  const body = `<article class="tour">
<p class="muted">${esc(category)} · <a href="${esc(withLang(`/${slug(tour.city)}`, lang))}">${esc(tour.city)}</a></p>
<h1>${esc(tour.title)}</h1>
<img src="${imageFor(tour.category)}" alt="${esc(category)}" width="1100" height="320">
<ul class="facts">
<li><b>${esc(tx.when)}</b>${esc(when(lang, tour.start))}</li>
<li><b>${esc(tx.duration)}</b>${esc(tour.duration)}</li>
<li><b>${esc(tx.language)}</b>${esc(tour.language)}</li>
<li><b>${esc(tx.meetingPoint)}</b>${esc(tour.meetingPoint)}</li>
<li><b>${esc(tx.pricePerPerson(money(lang, tour.price)))}</b>${esc(tx.seats(tour.seats))}</li>
${guide ? `<li><b>${esc(tx.organizer)}</b>${esc(guide.name)} · ${esc(roles)}</li>` : ''}
</ul>
${tour.isPackage ? `<p class="note">${esc(tx.package(tour.accessories.join(', ')))}</p>` : ''}
${guide && onlyAccompagnatore(guide) ? `<p class="note">${esc(tx.accompagnatoreNotice)}</p>` : ''}
<p>${esc(tour.description).replace(/\n/g, '<br>')}</p>
<a class="cta" href="${esc(appTour(tour.id))}">${esc(tx.book)}</a>
<p class="muted">${esc(tx.bookHint)}</p>
</article>`
  return html(
    c,
    layout(SEO_SITE_URL, APP_URL, {
      lang,
      title: tx.tourTitle(tour.title, tour.city),
      description,
      path: `/tour/${tour.id}`,
      body,
      image,
      ld: {
        '@context': 'https://schema.org',
        '@type': 'Event',
        name: tour.title,
        description: tour.description || description,
        startDate: tour.start,
        eventStatus: 'https://schema.org/EventScheduled',
        eventAttendanceMode: 'https://schema.org/OfflineEventAttendanceMode',
        inLanguage: tour.language,
        image: [image],
        location: {
          '@type': 'Place',
          name: tour.meetingPoint,
          address: { '@type': 'PostalAddress', addressLocality: tour.city, addressCountry: 'IT' },
        },
        offers: {
          '@type': 'Offer',
          price: tour.price,
          priceCurrency: 'EUR',
          availability: 'https://schema.org/InStock',
          url: SEO_SITE_URL + `/tour/${tour.id}`,
        },
        ...(guide && {
          organizer: {
            '@type': guide.role === 'tourOperator' ? 'Organization' : 'Person',
            name: guide.name,
          },
        }),
      },
    }),
  )
})

// Città e città + categoria: solo per valori conosciuti, il resto è 404.
site.get('/:city', async (c, next) => {
  const city = cityBySlug.get(c.req.param('city'))
  if (!city) return next()
  const lang = langFrom(c.req.query('lang'))
  const tx = TEXTS[lang]
  const tours = (await listTours(anonDb, { city, limit: 100 })).filter(isPublic)
  const cats = TOUR_CATEGORIES.filter((k) => tours.some((t) => t.category === k))
  const body = `<section class="hero"><h1>${esc(tx.cityTitle(city))}</h1><p>${esc(tx.cityDescription(city, tours.length))}</p></section>
${cats.length ? `<h2>${esc(tx.categoriesTitle)}</h2><ul class="chips">${cats.map((k) => `<li><a href="${esc(withLang(`/${slug(city)}/${slug(k)}`, lang))}">${esc(tx.categories[k] ?? k)}</a></li>`).join('')}</ul>` : ''}
<h2>${esc(tx.upcomingTitle)}</h2>${grid(lang, tours)}`
  return html(
    c,
    layout(SEO_SITE_URL, APP_URL, {
      lang,
      title: `${tx.cityTitle(city)} | GuidaTour`,
      description: tx.cityDescription(city, tours.length),
      path: `/${slug(city)}`,
      body,
      image: tours[0] ? SEO_SITE_URL + imageFor(tours[0].category) : undefined,
      ld: itemList(tours, lang),
    }),
  )
})

site.get('/:city/:category', async (c, next) => {
  const city = cityBySlug.get(c.req.param('city'))
  const category = categoryBySlug.get(c.req.param('category'))
  if (!city || !category) return next()
  const lang = langFrom(c.req.query('lang'))
  const tx = TEXTS[lang]
  const label = tx.categories[category] ?? category
  const tours = (await listTours(anonDb, { city, category, limit: 100 })).filter(isPublic)
  const body = `<section class="hero"><h1>${esc(tx.categoryTitle(label, city))}</h1><p>${esc(tx.categoryDescription(label, city, tours.length))}</p></section>
<p><a href="${esc(withLang(`/${slug(city)}`, lang))}">← ${esc(tx.allTours)} · ${esc(city)}</a></p>${grid(lang, tours)}`
  return html(
    c,
    layout(SEO_SITE_URL, APP_URL, {
      lang,
      title: `${tx.categoryTitle(label, city)} | GuidaTour`,
      description: tx.categoryDescription(label, city, tours.length),
      path: `/${slug(city)}/${slug(category)}`,
      body,
      image: SEO_SITE_URL + imageFor(category),
      ld: itemList(tours, lang),
    }),
  )
})

function notFoundPage(c: Context<AppEnv>, lang: Lang) {
  const tx = TEXTS[lang]
  return html(
    c,
    layout(SEO_SITE_URL, APP_URL, {
      lang,
      title: `${tx.notFoundTitle} | GuidaTour`,
      description: tx.notFoundTitle,
      path: '/',
      noindex: true,
      body: `<section class="hero"><h1>${esc(tx.notFoundTitle)}</h1></section><p><a href="${esc(withLang('/', lang))}">GuidaTour</a></p>`,
    }),
    404,
  )
}

/** Tour passato: 410 così Google lo toglie dall'indice, con i tour della città. */
async function gonePage(c: Context<AppEnv>, lang: Lang, city: string) {
  const tx = TEXTS[lang]
  const tours = (await listTours(anonDb, { city, limit: 6 })).filter(isPublic)
  return html(
    c,
    layout(SEO_SITE_URL, APP_URL, {
      lang,
      title: `${tx.goneTitle} | GuidaTour`,
      description: tx.goneBody,
      path: `/${slug(city)}`,
      noindex: true,
      body: `<section class="hero"><h1>${esc(tx.goneTitle)}</h1><p>${esc(tx.goneBody)}</p></section>${grid(lang, tours)}`,
    }),
    410,
  )
}
