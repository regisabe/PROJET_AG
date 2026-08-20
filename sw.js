// Incrémente ce numéro à CHAQUE fois que tu modifies sw.js lui-même (rare).
// Ce n'est PAS ce qui fait apparaître tes mises à jour de index.html/login.html :
// celles-ci sont désormais toujours allées chercher sur le réseau en priorité
// (voir stratégie "network-first" ci-dessous), donc plus besoin d'y toucher
// à chaque déploiement de l'app.
const CACHE_NAME = 'ag-cercle-v2';
const CORE_ASSETS = [
  './index.html',
  './manifest.json',
  './icon-192.png',
  './icon-512.png'
];

// Fichiers pour lesquels on veut TOUJOURS la dernière version quand le réseau
// est disponible (le code de l'app change souvent) : le HTML et les pages.
// Le cache ne sert que de secours hors-ligne.
function isNetworkFirst(url){
  return url.endsWith('/') || url.endsWith('.html') || url.endsWith('/index.html') || url.endsWith('/login.html');
}

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => cache.addAll(CORE_ASSETS)).catch(() => {})
  );
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(keys.filter((k) => k !== CACHE_NAME).map((k) => caches.delete(k)))
    )
  );
  self.clients.claim();
});

self.addEventListener('fetch', (event) => {
  if (event.request.method !== 'GET') return;
  const url = event.request.url;

  if (isNetworkFirst(url)) {
    // Réseau d'abord : on essaie toujours d'avoir la dernière version en ligne.
    // On ne retombe sur le cache que si le réseau échoue (mode hors-ligne).
    event.respondWith(
      fetch(event.request, { cache: 'no-store' })
        .then((networkResponse) => {
          if (networkResponse && networkResponse.status === 200 && url.startsWith(self.location.origin)) {
            const clone = networkResponse.clone();
            caches.open(CACHE_NAME).then((cache) => cache.put(event.request, clone));
          }
          return networkResponse;
        })
        .catch(() => caches.match(event.request))
    );
    return;
  }

  // Le reste (icônes, manifest, polices…) change rarement : cache d'abord,
  // avec mise à jour silencieuse en arrière-plan.
  event.respondWith(
    caches.match(event.request).then((cached) => {
      const fetchPromise = fetch(event.request)
        .then((networkResponse) => {
          if (networkResponse && networkResponse.status === 200 && url.startsWith(self.location.origin)) {
            const clone = networkResponse.clone();
            caches.open(CACHE_NAME).then((cache) => cache.put(event.request, clone));
          }
          return networkResponse;
        })
        .catch(() => cached);
      return cached || fetchPromise;
    })
  );
});
