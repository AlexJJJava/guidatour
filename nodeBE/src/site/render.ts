import { LANGS, type Lang, TEXTS } from './i18n.js'

/** Testo sicuro dentro l'HTML. */
export const esc = (s: unknown) =>
  String(s ?? '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;')

/** JSON-LD dentro <script>: niente "</" che chiuderebbe il tag. */
export const jsonLd = (data: unknown) =>
  `<script type="application/ld+json">${JSON.stringify(data).replace(/</g, '\\u003c')}</script>`

// Stile in pagina, senza font esterni né JavaScript: la pagina si mostra subito.
const CSS = `
:root{--night:#1f2a33;--gold:#f2c36b;--gold-d:#b4832f;--ink:#1e2a33;--muted:#6b6f76;--bg:#fcf1d4;--line:#eae2d3}
*{box-sizing:border-box}body{margin:0;font-family:system-ui,-apple-system,"Segoe UI",Roboto,sans-serif;color:var(--ink);background:var(--bg);line-height:1.5}
a{color:inherit}h1,h2,h3{font-family:Georgia,"Times New Roman",serif;line-height:1.15;margin:0 0 .4em}
header{background:var(--night);color:#fff}header .in,main,footer .in{max-width:1100px;margin:0 auto;padding:0 20px}
header .in{display:flex;align-items:center;justify-content:space-between;gap:12px;min-height:64px;flex-wrap:wrap}
.brand{text-decoration:none;display:flex;flex-direction:column}.brand b{font-family:Georgia,serif;font-size:22px;letter-spacing:.5px}.brand small{color:var(--gold);font-size:11px;letter-spacing:2px;text-transform:uppercase}
nav a{color:#fff;text-decoration:none;margin-left:14px;font-size:14px}nav a.btn{background:var(--gold);color:var(--ink);padding:8px 14px;border-radius:999px;font-weight:600}
.hero{background:linear-gradient(135deg,#f2c36b,#f8dfa8);border-radius:14px;padding:26px;margin:24px 0}
.hero p{margin:0;font-size:17px}main{padding-bottom:40px}
.chips{display:flex;flex-wrap:wrap;gap:8px;margin:0 0 24px;padding:0;list-style:none}.chips a{display:inline-block;background:#fff;border:1px solid var(--line);border-radius:999px;padding:6px 14px;text-decoration:none;font-size:14px}
.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(250px,1fr));gap:16px;padding:0;list-style:none}
.card{background:#fff;border-radius:12px;overflow:hidden;border:1px solid var(--line);display:flex;flex-direction:column;height:100%}
.card a{text-decoration:none;display:flex;flex-direction:column;height:100%}.card img{width:100%;height:150px;object-fit:cover;display:block}
.card .b{padding:12px 14px;display:flex;flex-direction:column;gap:4px;flex:1}.card .d{color:var(--gold-d);font-size:13px;font-weight:600}.card .m{color:var(--muted);font-size:13px}.card .p{margin-top:auto;font-weight:700}
.tour img{width:100%;max-height:320px;object-fit:cover;border-radius:12px}.facts{display:grid;grid-template-columns:repeat(auto-fill,minmax(180px,1fr));gap:10px;padding:0;list-style:none;margin:18px 0}
.facts li{background:#fff;border:1px solid var(--line);border-radius:10px;padding:10px 12px}.facts b{display:block;font-size:12px;color:var(--muted);font-weight:600}
.cta{display:inline-block;background:var(--gold);color:var(--ink);font-weight:700;text-decoration:none;padding:14px 22px;border-radius:12px;margin:8px 0}
.note{background:#fff7e3;border-left:4px solid var(--gold);padding:10px 14px;border-radius:8px;margin:14px 0}.muted{color:var(--muted)}
footer{background:var(--night);color:#ffffffaa;font-size:13px;padding:24px 0}footer a{color:#fff}.langs a{margin-right:10px}
@media(max-width:600px){nav a:not(.btn){display:none}.hero{padding:18px}}
`

export interface Page {
  lang: Lang
  title: string
  description: string
  /** Percorso senza lingua, es. "/roma": canonical e versioni nelle altre lingue. */
  path: string
  body: string
  image?: string
  ld?: unknown
  /** Pagine di errore: non vanno nell'indice. */
  noindex?: boolean
}

export const withLang = (path: string, lang: Lang) =>
  lang === 'it' ? path : `${path}${path.includes('?') ? '&' : '?'}lang=${lang}`

export function layout(base: string, appUrl: string, p: Page): string {
  const t = TEXTS[p.lang]
  const url = base + withLang(p.path, p.lang)
  const alternates = LANGS.map(
    (l) => `<link rel="alternate" hreflang="${l}" href="${esc(base + withLang(p.path, l))}">`,
  ).join('')
  return `<!doctype html>
<html lang="${p.lang}"><head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>${esc(p.title)}</title>
<meta name="description" content="${esc(p.description)}">
<link rel="canonical" href="${esc(url)}">${alternates}<link rel="alternate" hreflang="x-default" href="${esc(base + p.path)}">
${p.noindex ? '<meta name="robots" content="noindex">' : ''}
<meta property="og:type" content="website"><meta property="og:site_name" content="GuidaTour">
<meta property="og:title" content="${esc(p.title)}"><meta property="og:description" content="${esc(p.description)}">
<meta property="og:url" content="${esc(url)}">${p.image ? `<meta property="og:image" content="${esc(p.image)}">` : ''}
<meta name="twitter:card" content="summary_large_image">
<link rel="icon" type="image/png" href="/img/favicon.png">
<style>${CSS}</style>${p.ld ? jsonLd(p.ld) : ''}
</head><body>
<header><div class="in"><a class="brand" href="${esc(withLang('/', p.lang))}"><b>GUIDATOUR</b><small>${esc(t.tagline)}</small></a>
<nav><a href="${esc(withLang('/roma', p.lang))}">Roma</a><a class="btn" href="${esc(appUrl)}">${esc(t.openApp)}</a></nav></div></header>
<main>${p.body}</main>
<footer><div class="in"><p>${esc(t.disclaimer)}</p>
<p class="langs">${LANGS.map((l) => `<a href="${esc(withLang(p.path, l))}" hreflang="${l}">${l.toUpperCase()}</a>`).join('')}</p>
<p>© ${new Date().getFullYear()} GuidaTour</p></div></footer>
</body></html>`
}
