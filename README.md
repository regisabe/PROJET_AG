# L'AG — L'Avenir de Gbegbessou · Gestion de groupe

Application web installable (PWA) pour gérer les membres, cotisations,
paiements, activités et documents de L'AG. Fonctionne dans le navigateur,
et peut être **installée comme une vraie app** sur Android, iOS et
ordinateur (Windows/Mac/Linux).

## 📁 Structure du projet

```
.
├── index.html            → page principale, balises PWA/iOS, chargement des scripts
├── manifest.json          → identité de l'app (nom, icônes, couleurs) pour l'installation
├── service-worker.js       → mise en cache pour un fonctionnement hors-ligne
├── css/
│   └── styles.css          → tous les styles de l'application
├── js/
│   └── app.js              → toute la logique de l'application (React)
├── icons/                   → icônes de l'app (écran d'accueil, favicon, etc.)
└── .nojekyll               → désactive le traitement Jekyll sur GitHub Pages
```

L'app est toujours "sans build" : React, ReactDOM et Babel sont chargés
depuis un CDN, et `js/app.js` est transformé dans le navigateur. Aucune
étape de compilation n'est nécessaire pour déployer.

## 🧪 Tester en local

Le chargement de `js/app.js` par Babel se fait via une requête réseau :
ça ne fonctionne pas en ouvrant simplement le fichier `index.html`
(protocole `file://`). Il faut un petit serveur local :

```bash
# Depuis le dossier du projet
python3 -m http.server 8080
# puis ouvrir http://localhost:8080
```

ou avec Node :

```bash
npx serve .
```

## 🚀 Déployer sur GitHub Pages

1. Crée un nouveau dépôt GitHub (public), par exemple `lag-gestion`.
2. Pousse tous les fichiers de ce dossier à la racine du dépôt :
   ```bash
   git init
   git add .
   git commit -m "Première version de l'app L'AG"
   git branch -M main
   git remote add origin https://github.com/<ton-compte>/lag-gestion.git
   git push -u origin main
   ```
3. Sur GitHub : **Settings → Pages**.
4. Dans **Build and deployment → Source**, choisis **Deploy from a branch**.
5. Branche : `main`, dossier : `/ (root)` → **Save**.
6. Après 1–2 minutes, ton app est en ligne à :
   `https://<ton-compte>.github.io/lag-gestion/`

C'est cette adresse que tu partages aux membres et que tu utilises pour
l'installation sur mobile.

> ⚠️ Le site doit être servi en HTTPS pour que l'installation (PWA) et
> le service worker fonctionnent — GitHub Pages le fait automatiquement.

## 📲 Installer comme une application

**Android / Chrome :**
Ouvrir le lien GitHub Pages → menu ⋮ → **"Installer l'application"**
(ou bannière automatique en bas de l'écran).

**iOS / iPhone (Safari uniquement) :**
Ouvrir le lien dans **Safari** → bouton Partager (le carré avec la
flèche) → **"Sur l'écran d'accueil"** → Ajouter.
*(Sur iOS, l'installation ne fonctionne que depuis Safari, pas Chrome.)*

**Ordinateur (Chrome / Edge) :**
Icône d'installation ⊕ dans la barre d'adresse → **Installer**.

Une fois installée, l'app s'ouvre en plein écran avec sa propre icône,
sans barre d'adresse, comme une app native.

## 🖼️ Changer le logo de l'app

Il y a deux logos distincts :

1. **Logo affiché dans l'app** (écran de connexion, barre latérale) :
   se change directement dans l'application, une fois connecté en admin,
   via **Paramètres → Général → Changer le logo**. Il est stocké dans le
   navigateur de chaque utilisateur.

2. **Icône de l'app sur l'écran d'accueil du téléphone / favicon** :
   remplace les fichiers dans `icons/` par ton vrai logo, **en gardant
   exactement les mêmes noms et tailles** :
   - `icon-192.png` (192×192), `icon-512.png` (512×512)
   - `icon-maskable-192.png`, `icon-maskable-512.png` (mêmes tailles,
     avec ~12% de marge autour du logo pour la découpe "maskable")
   - `apple-touch-icon.png` (180×180, coins déjà carrés — iOS arrondit lui-même)
   - `favicon.ico`, `favicon-16.png`, `favicon-32.png`

   Puis recommite et repousse sur GitHub (`git add . && git commit -m "Nouveau logo" && git push`).
   Pense à changer `CACHE_VERSION` dans `service-worker.js` (ex. `lag-cache-v2`)
   pour forcer la mise à jour chez les personnes qui ont déjà installé l'app.

## 💾 À propos des données

L'application stocke toutes ses données (membres, paiements, activités…)
**localement dans le navigateur** de chaque appareil (`localStorage`), il
n'y a pas de serveur ni de base de données partagée pour l'instant.
Cela veut dire :
- Chaque appareil/navigateur a ses propres données.
- Utilise **Paramètres → Données → Exporter une sauvegarde** régulièrement,
  et partage/rimporte ce fichier si besoin de synchroniser un autre poste.
- Une vraie synchronisation multi-appareils nécessiterait un petit serveur
  ou une base de données en ligne — possible comme prochaine étape.
