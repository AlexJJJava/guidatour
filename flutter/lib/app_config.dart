/// URL del backend GuidaTour. In locale: `flutter run
/// --dart-define=BACKEND_URL=http://localhost:3000` (da emulatore Android:
/// `http://10.0.2.2:3000`). Senza dart-define punta al backend su Render.
const backendUrl = String.fromEnvironment(
  'BACKEND_URL',
  defaultValue: 'https://guidatour.onrender.com',
);

/// Sito pubblico: da qui partono i link dei tour e quindi i QR delle locandine.
/// Cambiandolo, i QR già stampati continuano a puntare al vecchio indirizzo.
const publicSiteUrl = String.fromEnvironment(
  'PUBLIC_SITE_URL',
  defaultValue: 'https://alexjjjava.github.io/guidatour/',
);

/// La anon key è pensata per essere pubblica: la sicurezza è nelle policy
/// RLS del progetto Supabase (vedi nodeBE/supabase/schema.sql).
const supabaseUrl = 'https://oetmzmnysdblzulxhywt.supabase.co';
const supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9ldG16bW55c2RibHp1bHhoeXd0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTMwMDkzMjAsImV4cCI6MjEwODU4NTMyMH0.sZ7d66UvjNofidouXWEyyA-5vWoWngQYzHB7coV67d8';
