// ============================================================
// Cercle — Configuration Supabase
// Remplis ces deux valeurs (Supabase > Project Settings > API)
// puis laisse ce fichier tel quel : login.html et index.html
// le chargent tous les deux.
// ============================================================
const SUPABASE_URL = "https://qqeohykquqbbiqldvqzb.supabase.co";
const SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFxZW9oeWtxdXFiYmlxbGR2cXpiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODczMDk0OTQsImV4cCI6MjEwMjg4NTQ5NH0.QyV6Txgp3rzPJqO0w_OPufu5bd0P6O4qLUECuBzx30Y";

// Domaine technique utilisé pour transformer un "nom d'utilisateur"
// en email Supabase Auth (les membres ne voient jamais cet email).
const CERCLE_AUTH_DOMAIN = "cercle-app.org";

const cercleSupabase = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

function usernameToEmail(username) {
  return String(username || "").trim().toLowerCase().replace(/\s+/g, "") + "@" + CERCLE_AUTH_DOMAIN;
}
