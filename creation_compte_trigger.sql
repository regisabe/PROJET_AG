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
