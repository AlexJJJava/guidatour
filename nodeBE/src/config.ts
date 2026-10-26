// La anon key è pensata per essere pubblica: la sicurezza è garantita dalle
// Row Level Security policy di Supabase (supabase/schema.sql), non dalla
// segretezza di questa chiave.
export const SUPABASE_URL = 'https://oetmzmnysdblzulxhywt.supabase.co'
export const SUPABASE_ANON_KEY =
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9ldG16bW55c2RibHp1bHhoeXd0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTMwMDkzMjAsImV4cCI6MjEwODU4NTMyMH0.sZ7d66UvjNofidouXWEyyA-5vWoWngQYzHB7coV67d8'

// Se ALLOWED_ORIGIN è impostata (es. in produzione), CORS viene ristretto
// a quel dominio. Senza impostarla (es. in sviluppo locale) resta aperta a '*'.
export const allowedOrigin = process.env.ALLOWED_ORIGIN || '*'

export const PORT = Number(process.env.PORT) || 3000

// Testo esatto mostrato all'utente: viene salvato con il consenso come prova
// (BR-011D), quindi lo fissa il backend e non lo manda l'app.
export const WHATSAPP_CONSENT_TEXT =
  'Acconsento a ricevere su WhatsApp la lista aggiornata di tour ed ' +
  'escursioni a Roma da GuidaTour. Posso revocare il consenso in qualsiasi ' +
  'momento rispondendo STOP.'
export const WHATSAPP_SENDER = 'GuidaTour'

export const PUBLIC_TOUR_BASE_URL = 'https://guidatour.it/roma/tour'
