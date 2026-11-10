// Disegna lo schema del database (tabelle, colonne, relazioni) in
// flutter/docs/GuidaTour_Schema_DB.svg e .png.
// Uso: npm run docs:db   (il PNG richiede Google Chrome installato)
// Quando cambia lo schema (schema.sql / migrazioni) aggiornare `tables`.
const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');

const OUT = path.join(__dirname, '..', '..', 'flutter', 'docs');
const NIGHT = '#14213D', GOLD = '#C9963A', INK = '#1F2937', MUTED = '#6B7280';
const W = 300, HEAD = 48, ROW = 22, PAD = 8;

// [nome, tipo, 'pk' | 'fk' | 'pkfk' | '']
const tables = {
  users: { title: 'auth.users', note: 'Account di Supabase Auth', color: '#4B5563',
    cols: [['id', 'uuid', 'pk'], ['email, password…', 'gestiti da Supabase', '']] },
  profiles: { title: 'profiles', note: 'Un profilo per ogni account', cols: [
    ['id', 'uuid', 'pkfk'], ['name', 'text', ''], ['email', 'text', ''],
    ['role', 'text', ''], ['roles', 'text[]', ''], ['pending_roles', 'text[]', ''],
    ['approval_status', 'text', ''], ['provider', 'text', ''], ['verified', 'boolean', ''],
    ['is_admin', 'boolean', ''], ['languages', 'text[]', ''], ['bio', 'text', ''],
    ['city', 'text', ''], ['avatar_url', 'text', ''], ['created_at', 'timestamptz', '']] },
  tours: { title: 'tours', note: 'Tour pubblicati dai professionisti', cols: [
    ['id', 'text (slug)', 'pk'], ['guide_id', 'uuid', 'fk'], ['title', 'text', ''],
    ['city', 'text', ''], ['category', 'text', ''], ['language', 'text', ''],
    ['duration', 'text', ''], ['start_at', 'timestamptz', ''], ['dates', 'timestamptz[]', ''],
    ['last_start_at', 'timestamptz', ''], ['price', 'numeric(10,2)', ''],
    ['meeting_point', 'text', ''], ['description', 'text', ''], ['seats', 'int', ''],
    ['accessories', 'text[]', ''], ['visits', 'int', ''], ['scans', 'int', ''],
    ['created_at', 'timestamptz', '']] },
  favorites: { title: 'favorites', note: 'Tour preferiti del turista', cols: [
    ['user_id', 'uuid', 'pkfk'], ['tour_id', 'text', 'pkfk'], ['created_at', 'timestamptz', '']] },
  cart: { title: 'cart_items', note: 'Carrello del turista', cols: [
    ['user_id', 'uuid', 'pkfk'], ['tour_id', 'text', 'pkfk'], ['people', 'int', ''],
    ['start_at', 'timestamptz', ''], ['created_at', 'timestamptz', '']] },
  requests: { title: 'booking_requests', note: 'Richieste di prenotazione', cols: [
    ['id', 'uuid', 'pk'], ['tour_id', 'text', 'fk'], ['user_id', 'uuid (facoltativo)', 'fk'],
    ['name', 'text', ''], ['email', 'text', ''], ['phone', 'text', ''], ['people', 'int', ''],
    ['message', 'text', ''], ['start_at', 'timestamptz', ''], ['status', 'text', ''],
    ['created_at', 'timestamptz', '']] },
  assignments: { title: 'assignments', note: 'Cessione di un tour a un collega', cols: [
    ['id', 'uuid', 'pk'], ['tour_id', 'text', 'fk'], ['from_guide_id', 'uuid', 'fk'],
    ['to_guide_id', 'uuid', 'fk'], ['status', 'text', ''], ['created_at', 'timestamptz', ''],
    ['updated_at', 'timestamptz', '']] },
  notifications: { title: 'notifications', note: 'Avvisi nell\'app', cols: [
    ['id', 'uuid', 'pk'], ['user_id', 'uuid', 'fk'], ['message', 'text', ''],
    ['read_at', 'timestamptz', ''], ['created_at', 'timestamptz', '']] },
  whatsapp: { title: 'whatsapp_consents', note: 'Consensi agli aggiornamenti WhatsApp', cols: [
    ['id', 'uuid', 'pk'], ['user_id', 'uuid (facoltativo)', 'fk'], ['phone', 'text', ''],
    ['source', 'text', ''], ['consent_text', 'text', ''], ['sender', 'text', ''],
    ['created_at', 'timestamptz', ''], ['revoked_at', 'timestamptz', '']] },
  avatars: { title: 'storage: avatars', note: 'Bucket delle foto profilo', bucket: true, cols: [
    ['avatars/<uid>/…', 'PNG, max 2 MB', '']] },
};

// Colonne della griglia e tabelle impilate dall'alto.
const COLS = [40, 420, 840, 1260];
const layout = [
  [0, 300, ['notifications', 'whatsapp', 'avatars']],
  [1, 150, ['users', 'profiles']],
  [2, 150, ['favorites', 'cart', 'requests', 'assignments']],
  [3, 150, ['tours']],
];
for (const [c, top, names] of layout) {
  let y = top;
  for (const n of names) {
    const t = tables[n];
    t.x = COLS[c];
    t.y = y;
    t.h = HEAD + t.cols.length * ROW + PAD;
    y += t.h + 36;
  }
}
const rowY = (t, col) => t.y + HEAD + t.cols.findIndex((c) => c[0] === col) * ROW + ROW / 2;

// [da tabella, colonna FK, a tabella, colonna, azione alla cancellazione]
const fks = [
  ['profiles', 'id', 'users', 'id', 'cascade'],
  ['tours', 'guide_id', 'profiles', 'id', 'cascade'],
  ['favorites', 'user_id', 'profiles', 'id', 'cascade'],
  ['favorites', 'tour_id', 'tours', 'id', 'cascade'],
  ['cart', 'user_id', 'profiles', 'id', 'cascade'],
  ['cart', 'tour_id', 'tours', 'id', 'cascade'],
  ['requests', 'user_id', 'profiles', 'id', 'set null'],
  ['requests', 'tour_id', 'tours', 'id', 'cascade'],
  ['assignments', 'from_guide_id', 'profiles', 'id', 'cascade'],
  ['assignments', 'to_guide_id', 'profiles', 'id', 'cascade'],
  ['assignments', 'tour_id', 'tours', 'id', 'cascade'],
  ['notifications', 'user_id', 'profiles', 'id', 'cascade'],
  ['whatsapp', 'user_id', 'profiles', 'id', 'set null'],
];

const esc = (s) => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
const out = [];

function drawTable(t) {
  const head = t.color || (t.bucket ? '#7C5E2A' : NIGHT);
  out.push(`<g>`,
    `<rect x="${t.x + 3}" y="${t.y + 4}" width="${W}" height="${t.h}" rx="10" fill="#000" opacity=".08"/>`,
    `<rect x="${t.x}" y="${t.y}" width="${W}" height="${t.h}" rx="10" fill="#fff" stroke="${head}" stroke-width="1.5"${t.bucket ? ' stroke-dasharray="6 4"' : ''}/>`,
    `<path d="M${t.x} ${t.y + 10} a10 10 0 0 1 10 -10 h${W - 20} a10 10 0 0 1 10 10 v${HEAD - 10} h-${W} z" fill="${head}"/>`,
    `<text x="${t.x + 14}" y="${t.y + 21}" class="title">${esc(t.title)}</text>`,
    `<text x="${t.x + 14}" y="${t.y + 38}" class="note">${esc(t.note)}</text>`);
  t.cols.forEach(([name, type, key], i) => {
    const y = t.y + HEAD + i * ROW;
    if (i % 2) out.push(`<rect x="${t.x + 1}" y="${y}" width="${W - 2}" height="${ROW}" fill="#F7F4EE"/>`);
    let x = t.x + 12;
    const badge = (label, fill) => {
      out.push(`<rect x="${x}" y="${y + 5}" width="20" height="12" rx="3" fill="${fill}"/>`,
        `<text x="${x + 10}" y="${y + 14}" class="badge">${label}</text>`);
      x += 23;
    };
    if (key.startsWith('pk')) badge('PK', GOLD);
    if (key.endsWith('fk')) badge('FK', '#3B6EA5');
    const cls = key.startsWith('pk') ? 'col pk' : 'col';
    out.push(`<text x="${Math.max(x + 2, t.x + 58)}" y="${y + 15}" class="${cls}">${esc(name)}</text>`,
      `<text x="${t.x + W - 12}" y="${y + 15}" class="type">${esc(type)}</text>`);
  });
  out.push('</g>');
}

// Frecce: dalla colonna FK (pallino = "molti") alla chiave (freccia = "uno").
const lanes = {};
function lane(key, base, step) {
  lanes[key] = (lanes[key] ?? -1) + 1;
  return base + lanes[key] * step;
}
const lines = [];
for (const [ft, fc, tt, tc, action] of fks) {
  const a = tables[ft], b = tables[tt];
  const y1 = rowY(a, fc), y2 = rowY(b, tc);
  let d, lx, ly;
  if (ft === 'profiles') { // profiles.id → auth.users.id, in verticale
    const x = b.x + W / 2;
    d = `M${x} ${a.y} V${b.y + b.h}`;
    lx = x + 8; ly = (a.y + b.y + b.h) / 2 + 4;
  } else if (ft === 'tours') { // sopra le tabelle ponte
    const top = 118, xm = lane(`L${tt}`, b.x + W + 14, 11);
    d = `M${a.x + 40} ${a.y} V${top} H${xm} V${y2} H${b.x + W}`;
    lx = (a.x + xm) / 2; ly = top - 6;
  } else if (a.x > b.x) { // da destra verso sinistra
    const xm = lane(`L${tt}`, b.x + W + 14, 11);
    d = `M${a.x} ${y1} H${xm} V${y2} H${b.x + W}`;
    lx = a.x - 50; ly = y1 - 5;
  } else { // da sinistra verso destra
    const xm = lane(`R${tt}`, b.x - 18, -11);
    d = `M${a.x + W} ${y1} H${xm} V${y2} H${b.x}`;
    lx = a.x + W + 6; ly = y1 - 5;
  }
  const color = action === 'set null' ? '#9A6B1F' : '#3B6EA5';
  lines.push(`<path d="${d}" fill="none" stroke="${color}" stroke-width="1.6" marker-start="url(#many)" marker-end="url(#one-${action === 'set null' ? 'n' : 'c'})" opacity=".85"/>`);
  if (ft !== 'profiles' && ft !== 'tours' && a.x < b.x) {
    lines.push(`<text x="${lx}" y="${ly}" class="action" fill="${color}">${action}</text>`);
  } else if (ft !== 'profiles' && ft !== 'tours') {
    lines.push(`<text x="${lx}" y="${ly}" class="action" fill="${color}">${action}</text>`);
  } else {
    lines.push(`<text x="${lx}" y="${ly}" class="action" fill="${color}">${ft === 'tours' ? 'guida del tour · cascade' : 'cascade'}</text>`);
  }
}
// Foto profilo: avatar_url punta a un file del bucket (non è una FK).
{
  const a = tables.profiles, b = tables.avatars;
  const y1 = rowY(a, 'avatar_url'), y2 = b.y + b.h / 2;
  lines.push(`<path d="M${a.x} ${y1} H${a.x - 22} V${y2} H${b.x + W}" fill="none" stroke="#7C5E2A" stroke-width="1.5" stroke-dasharray="5 4" marker-end="url(#one-n)"/>`,
    `<text x="${b.x + W + 4}" y="${y2 - 6}" class="action" fill="#7C5E2A">URL</text>`);
}

for (const t of Object.values(tables)) drawTable(t);

const width = COLS[3] + W + 40;
const height = Math.max(...Object.values(tables).map((t) => t.y + t.h)) + 136;
const today = new Date().toLocaleDateString('it-IT');
const legendY = height - 86;
const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}" viewBox="0 0 ${width} ${height}">
<defs>
  <marker id="many" viewBox="0 0 10 10" refX="5" refY="5" markerWidth="7" markerHeight="7"><circle cx="5" cy="5" r="4" fill="#fff" stroke="#3B6EA5" stroke-width="2"/></marker>
  <marker id="one-c" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="8" markerHeight="8" orient="auto"><path d="M0 0 L10 5 L0 10 z" fill="#3B6EA5"/></marker>
  <marker id="one-n" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="8" markerHeight="8" orient="auto"><path d="M0 0 L10 5 L0 10 z" fill="#9A6B1F"/></marker>
</defs>
<style>
  text { font-family: Inter, 'Segoe UI', Arial, sans-serif; }
  .h1 { font-size: 26px; font-weight: 700; fill: ${NIGHT}; font-family: 'Playfair Display', Georgia, serif; }
  .sub { font-size: 13px; fill: ${MUTED}; }
  .title { font-size: 15px; font-weight: 700; fill: #fff; }
  .note { font-size: 11px; fill: #E5D3A8; font-style: italic; }
  .col { font-size: 12.5px; fill: ${INK}; }
  .pk { font-weight: 700; }
  .type { font-size: 11px; fill: ${MUTED}; text-anchor: end; font-family: Consolas, monospace; }
  .badge { font-size: 8.5px; font-weight: 700; fill: #fff; text-anchor: middle; }
  .action { font-size: 10px; font-style: italic; }
  .legend { font-size: 12px; fill: ${INK}; }
</style>
<rect width="100%" height="100%" fill="#FBF8F2"/>
<text x="40" y="52" class="h1">GuidaTour · schema del database</text>
<text x="40" y="76" class="sub">Supabase Postgres (schema public) · tabelle, colonne e relazioni · aggiornato al ${today}</text>
${lines.join('\n')}
${out.join('\n')}
<g transform="translate(40 ${legendY})">
  <rect x="0" y="-22" width="${width - 80}" height="72" rx="10" fill="#fff" stroke="#E5E0D6"/>
  <rect x="16" y="-6" width="20" height="12" rx="3" fill="${GOLD}"/><text x="26" y="3" class="badge">PK</text>
  <text x="44" y="4" class="legend">chiave primaria</text>
  <rect x="160" y="-6" width="20" height="12" rx="3" fill="#3B6EA5"/><text x="170" y="3" class="badge">FK</text>
  <text x="188" y="4" class="legend">chiave esterna</text>
  <circle cx="310" cy="0" r="4" fill="#fff" stroke="#3B6EA5" stroke-width="2"/><line x1="314" y1="0" x2="350" y2="0" stroke="#3B6EA5" stroke-width="1.6"/><path d="M350 -4 L358 0 L350 4 z" fill="#3B6EA5"/>
  <text x="368" y="4" class="legend">molti → uno; cancellando il record puntato si cancellano anche questi (cascade)</text>
  <line x1="880" y1="0" x2="916" y2="0" stroke="#9A6B1F" stroke-width="1.6"/><path d="M916 -4 L924 0 L916 4 z" fill="#9A6B1F"/>
  <text x="934" y="4" class="legend">set null: il record resta, il collegamento si svuota</text>
  <text x="16" y="24" class="sub" style="font-size:11px">Tutte le tabelle sono protette da RLS; avatar_url non è una FK ma l'indirizzo di un file nel bucket avatars.</text>
  <text x="16" y="40" class="sub" style="font-size:11px">Elimina account: la funzione delete_my_account() (migrazione 0010) cancella le richieste inviate e i consensi WhatsApp dell'utente e il suo account in auth.users; il resto sparisce a cascata. Gli admin non possono cancellarsi.</text>
</g>
</svg>`;

fs.mkdirSync(OUT, { recursive: true });
const svgPath = path.join(OUT, 'GuidaTour_Schema_DB.svg');
fs.writeFileSync(svgPath, svg);
console.log('SVG:', svgPath, `${width}x${height}`);

const chrome = ['C:/Program Files/Google/Chrome/Application/chrome.exe',
  'C:/Program Files (x86)/Google/Chrome/Application/chrome.exe',
  '/usr/bin/google-chrome', '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome']
  .find((p) => fs.existsSync(p));
if (!chrome) {
  console.log('Chrome non trovato: creato solo lo SVG.');
} else {
  const pngPath = path.join(OUT, 'GuidaTour_Schema_DB.png');
  const profile = fs.mkdtempSync(path.join(require('os').tmpdir(), 'dbdiag-'));
  execFileSync(chrome, ['--headless=new', '--disable-gpu', '--hide-scrollbars',
    `--user-data-dir=${profile}`, '--force-device-scale-factor=2',
    `--window-size=${width},${height}`, `--screenshot=${pngPath}`,
    'file:///' + svgPath.replace(/\\/g, '/')], { stdio: 'ignore' });
  console.log('PNG:', pngPath);
}
