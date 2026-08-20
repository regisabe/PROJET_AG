// ============================================================
// Cercle — Configuration Supabase
// Remplis ces deux valeurs (Supabase > Project Settings > API)
// puis laisse ce fichier tel quel : login.html et index.html
// le chargent tous les deux.
// ============================================================
const SUPABASE_URL = "https://iohoiamrfxnsqlbdpyul.supabase.co";
const SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlvaG9pYW1yZnhuc3FsYmRweXVsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODcxOTcwOTcsImV4cCI6MjEwMjc3MzA5N30.28f33toj5u11sDoQWpYfwx73V1s8sMqDlIw9MT0-FJo";

// Domaine technique utilisé pour transformer un "nom d'utilisateur"
// en email Supabase Auth (les membres ne voient jamais cet email).
const CERCLE_AUTH_DOMAIN = "cercle.local";

const cercleSupabase = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

function usernameToEmail(username) {
  return String(username || "").trim().toLowerCase().replace(/\s+/g, "") + "@" + CERCLE_AUTH_DOMAIN;
}
