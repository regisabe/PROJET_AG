-- ============================================================
-- Cercle — Gestion de groupe
-- Schéma Supabase (à exécuter dans SQL Editor > New query)
-- ============================================================

-- Extension utile pour horodatage auto (souvent déjà activée)
create extension if not exists pgcrypto;

-- ------------------------------------------------------------
-- Tables de données (chaque ligne = un enregistrement métier,
-- stocké en jsonb pour rester proche du modèle actuel de l'app)
-- ------------------------------------------------------------

create table if not exists public.settings (
  id text primary key default 'main',
  data jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

create table if not exists public.membres (
  id text primary key,
  data jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

create table if not exists public.cotisation_types (
  id text primary key,
  data jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

create table if not exists public.paiements (
  id text primary key,
  data jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

create table if not exists public.activites (
  id text primary key,
  data jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

create table if not exists public.documents (
  id text primary key,
  data jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

create table if not exists public.chat_messages (
  id text primary key,
  data jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

-- Profil applicatif lié 1-1 à un compte Supabase Auth
-- (le login se fait par "nom d'utilisateur", traduit en email
--  technique username@cercle.local côté client)
create table if not exists public.app_users (
  id uuid primary key references auth.users(id) on delete cascade,
  username text not null unique,
  data jsonb not null default '{}'::jsonb, -- role, poste, membreId, actif, isAdminTotal, modulesAccess
  updated_at timestamptz not null default now()
);

-- ------------------------------------------------------------
-- Row Level Security : app privée, réservée aux comptes connectés,
-- tout le monde authentifié voit/modifie les mêmes données.
-- ------------------------------------------------------------
alter table public.settings enable row level security;
alter table public.membres enable row level security;
alter table public.cotisation_types enable row level security;
alter table public.paiements enable row level security;
alter table public.activites enable row level security;
alter table public.documents enable row level security;
alter table public.chat_messages enable row level security;
alter table public.app_users enable row level security;

do $$
declare
  t text;
begin
  foreach t in array array['settings','membres','cotisation_types','paiements','activites','documents','chat_messages','app_users']
  loop
    execute format('drop policy if exists "authenticated_all" on public.%I;', t);
    execute format(
      'create policy "authenticated_all" on public.%I for all to authenticated using (true) with check (true);',
      t
    );
  end loop;
end $$;

-- La page de connexion (avant authentification) affiche le nom, le logo
-- et la description de l'association : lecture publique limitée à cette table.
drop policy if exists "anon_read_settings" on public.settings;
create policy "anon_read_settings" on public.settings
  for select to anon using (true);

-- ------------------------------------------------------------
-- Stockage des médias (photos membres, publications, documents)
-- ------------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('cercle-media', 'cercle-media', true)
on conflict (id) do nothing;

drop policy if exists "cercle_media_public_read" on storage.objects;
create policy "cercle_media_public_read" on storage.objects
  for select to public using (bucket_id = 'cercle-media');

drop policy if exists "cercle_media_auth_write" on storage.objects;
create policy "cercle_media_auth_write" on storage.objects
  for insert to authenticated with check (bucket_id = 'cercle-media');

drop policy if exists "cercle_media_auth_update" on storage.objects;
create policy "cercle_media_auth_update" on storage.objects
  for update to authenticated using (bucket_id = 'cercle-media');

drop policy if exists "cercle_media_auth_delete" on storage.objects;
create policy "cercle_media_auth_delete" on storage.objects
  for delete to authenticated using (bucket_id = 'cercle-media');

-- ------------------------------------------------------------
-- Réglages par défaut (facultatif — Paramètres reste éditable
-- ensuite dans l'app)
-- ------------------------------------------------------------
insert into public.settings (id, data) values (
  'main',
  '{"nomAssociation":"Cercle","devise":"FCFA"}'::jsonb
) on conflict (id) do nothing;

-- ============================================================
-- IMPORTANT — étapes manuelles après exécution de ce script :
-- 1) Authentication > Providers > Email : désactiver "Confirm email"
--    (les comptes utilisent un email technique @cercle.local, non
--     joignable, donc la confirmation par email doit rester désactivée).
-- 2) Créer le tout premier compte admin en s'inscrivant depuis
--    login.html ("Créer mon profil"), puis dans Table Editor >
--    app_users, éditer sa ligne "data" pour mettre :
--      {"role":"admin","poste":"president","isAdminTotal":true,"actif":true}
-- ============================================================
