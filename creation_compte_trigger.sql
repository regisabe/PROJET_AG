-- =====================================================================
-- Cercle — Création fiable du membre + de l'utilisateur à l'inscription
-- =====================================================================
-- Problème résolu : quand un visiteur s'inscrit depuis login.html, le
-- code JS fait deux INSERT séparés (membres, puis app_users) alors que
-- l'utilisateur vient d'être créé et n'a AUCUN droit particulier tant
-- que sa ligne app_users n'existe pas. Si la policy RLS sur "membres"
-- exige un rôle admin/responsable/secrétaire pour insérer, ce premier
-- INSERT échoue silencieusement (RLS), et le membre n'est jamais créé.
--
-- Solution : une fonction Postgres en SECURITY DEFINER, déclenchée
-- automatiquement à la création du compte dans auth.users. Comme elle
-- s'exécute avec les droits du propriétaire de la fonction (pas ceux
-- du visiteur), elle n'est jamais bloquée par les policies RLS.
--
-- À exécuter dans Supabase : Dashboard > SQL Editor > New query.
-- =====================================================================

create or replace function public.handle_new_cercle_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_username   text;
  v_prenom     text;
  v_nom        text;
  v_telephone  text;
  v_email      text;
  v_membre_id  text;
begin
  v_username  := new.raw_user_meta_data->>'username';
  v_prenom    := coalesce(new.raw_user_meta_data->>'prenom', '');
  v_nom       := coalesce(new.raw_user_meta_data->>'nom', '');
  v_telephone := coalesce(new.raw_user_meta_data->>'telephone', '');
  v_email     := coalesce(new.raw_user_meta_data->>'email', new.email);
  v_membre_id := 'mem_' || substr(new.id::text, 1, 8) || '_' || substr(md5(random()::text), 1, 4);

  insert into public.membres (id, data)
  values (
    v_membre_id,
    jsonb_build_object(
      'matricule', '',
      'nom', v_nom,
      'prenom', v_prenom,
      'fonction', 'Membre',
      'departement', '',
      'statut', 'actif',
      'telephone', v_telephone,
      'email', v_email,
      'adresse', '',
      'dateAdhesion', to_char(now(), 'YYYY-MM-DD'),
      'photo', ''
    )
  );

  insert into public.app_users (id, username, data)
  values (
    new.id,
    v_username,
    jsonb_build_object(
      'role', 'membre',
      'poste', 'membre',
      'membreId', v_membre_id,
      'actif', true,
      'isAdminTotal', false,
      'modulesAccess', '{}'::jsonb
    )
  );

  return new;
end;
$$;

drop trigger if exists on_auth_user_created_cercle on auth.users;

create trigger on_auth_user_created_cercle
  after insert on auth.users
  for each row execute function public.handle_new_cercle_user();

-- =====================================================================
-- Suppression d'un utilisateur qui "revient" dans la liste
-- =====================================================================
-- Symptôme : la suppression ne renvoie AUCUNE erreur, mais l'utilisateur
-- réapparaît quand même. C'est le piège classique de Postgres/RLS : si
-- aucune policy DELETE ne matche la ligne, Postgres supprime 0 ligne —
-- sans erreur. Ça ressemble à un succès côté client alors que rien n'a
-- été supprimé côté base.
--
-- Cause la plus probable : il n'existe tout simplement PAS de policy
-- DELETE sur "app_users" (RLS activé + aucune policy = tout est refusé
-- par défaut). Voici comment vérifier et corriger :
--
--   1) Vérifier les policies existantes sur app_users :
--      select * from pg_policies where tablename = 'app_users';
--
--   2) Si aucune ligne avec cmd = 'DELETE' n'apparaît, il faut en créer une.
--
-- Une policy DELETE sur app_users a besoin de savoir si l'utilisateur
-- courant est admin — mais une policy qui interroge app_users POUR
-- vérifier les droits SUR app_users peut mal se comporter (récursion).
-- On utilise donc une fonction SECURITY DEFINER dédiée :

-- Le module "Utilisateurs" (index.html) n'est visible que par le rôle 'admin' ;
-- le module "Membres" est accessible à 'admin', 'responsable' et 'secretaire'.
-- Les policies ci-dessous reprennent exactement ces règles côté base.

create or replace function public.is_cercle_admin()
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select coalesce(
    (select (data->>'isAdminTotal')::boolean or (data->>'role') = 'admin'
     from public.app_users
     where id = auth.uid()),
    false
  );
$$;

create or replace function public.can_manage_membres()
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select coalesce(
    (select (data->>'isAdminTotal')::boolean or (data->>'role') in ('admin','responsable','secretaire')
     from public.app_users
     where id = auth.uid()),
    false
  );
$$;

drop policy if exists "Admins peuvent supprimer des comptes" on public.app_users;
create policy "Admins peuvent supprimer des comptes"
  on public.app_users for delete
  to authenticated
  using ( public.is_cercle_admin() );

drop policy if exists "Admins peuvent supprimer des membres" on public.membres;
create policy "Admins peuvent supprimer des membres"
  on public.membres for delete
  to authenticated
  using ( public.can_manage_membres() );

-- Si tes policies DELETE existaient déjà mais avec une condition différente,
-- inspecte-les d'abord avec :
--   select policyname, cmd, qual from pg_policies where tablename in ('app_users','membres');
-- puis adapte les policies ci-dessus plutôt que de les dupliquer.

-- =====================================================================
-- NOTE : ce trigger insère désormais membres + app_users lui-même.
-- Le fichier login.html a été modifié pour ne plus faire ces deux
-- INSERT côté client : il envoie juste prenom/nom/telephone/email/
-- username dans les métadonnées du signUp, et le trigger fait le reste.
--
-- Si tu préfères NE PAS utiliser ce trigger, il faut à minima ajouter
-- une policy RLS du type :
--   create policy "Auto-inscription membre"
--   on public.membres for insert
--   to authenticated
--   with check (auth.uid() is not null);
-- mais le trigger reste la solution la plus robuste (une seule
-- transaction, jamais de membre orphelin, jamais bloqué par RLS).
-- =====================================================================
