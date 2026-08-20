// ============================================================
// Cercle — Configuration Supabase
// Remplis ces deux valeurs (Supabase > Project Settings > API)
// puis laisse ce fichier tel quel : login.html et index.html
// le chargent tous les deux.
// ============================================================
const SUPABASE_URL = "https://VOTRE-PROJET.supabase.co";
const SUPABASE_ANON_KEY = "VOTRE_CLE_ANON_PUBLIC";

// Domaine technique utilisé pour transformer un "nom d'utilisateur"
// en email Supabase Auth (les membres ne voient jamais cet email).
const CERCLE_AUTH_DOMAIN = "cercle.local";

const cercleSupabase = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

function usernameToEmail(username) {
  return String(username || "").trim().toLowerCase().replace(/\s+/g, "") + "@" + CERCLE_AUTH_DOMAIN;
}
