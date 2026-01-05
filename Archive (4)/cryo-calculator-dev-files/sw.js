// ---- VERSION ----
const CACHE_STATIC = 'cryo-static-v6';
const CACHE_RUNTIME = 'cryo-runtime-v6';

// Resolve paths relative to the service worker scope (safe for subpaths)
const SCOPE_URL = new URL(self.registration.scope);
const root = SCOPE_URL.pathname.endsWith('/') ? SCOPE_URL.pathname : SCOPE_URL.pathname + '/';
const url = (p) => (new URL(p, SCOPE_URL)).toString();

// Precache core assets (add any extra files you have)
const PRECACHE = [
  new URL('./', self.registration.scope).toString(),
  new URL('./index.html', self.registration.scope).toString(),
  new URL('./manifest.webmanifest', self.registration.scope).toString(),
  new URL('./icons/icon-192.png', self.registration.scope).toString(),
  new URL('./icons/icon-512.png', self.registration.scope).toString(),
  new URL('./icons/maskable-512.png', self.registration.scope).toString()
];



// ----- INSTALL -----
self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_STATIC).then((cache) => cache.addAll(PRECACHE))
  );
  self.skipWaiting();
});

// ----- ACTIVATE -----
self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(
        keys
          .filter((k) => ![CACHE_STATIC, CACHE_RUNTIME].includes(k))
          .map((k) => caches.delete(k))
      )
    )
  );
  self.clients.claim();
});

// Helper: same-origin?
const sameOrigin = (request) => new URL(request.url).origin === self.location.origin;

// ----- FETCH -----
self.addEventListener('fetch', (event) => {
  const req = event.request;

  // 1) HTML/doc navigations: network-first, fallback to cached index for offline
  if (req.mode === 'navigate') {
    event.respondWith(
      fetch(req)
        .then((res) => {
          // Cache a copy for offline
          const copy = res.clone();
          caches.open(CACHE_RUNTIME).then((c) => c.put(url('./index.html'), copy)).catch(()=>{});
          return res;
        })
        .catch(() => caches.match(url('./index.html')))
    );
    return;
  }

  // 2) Same-origin static assets: stale-while-revalidate
  if (sameOrigin(req)) {
    event.respondWith(
      caches.match(req).then((cached) => {
        const fetchPromise = fetch(req)
          .then((networkRes) => {
            // Only cache successful, basic/cors responses
            if (networkRes && networkRes.status === 200 && (networkRes.type === 'basic' || networkRes.type === 'cors')) {
              const copy = networkRes.clone();
              const whichCache = req.url.includes('/icons/') || req.url.endsWith('manifest.webmanifest')
                ? CACHE_STATIC
                : CACHE_RUNTIME;
              caches.open(whichCache).then((c) => c.put(req, copy)).catch(()=>{});
            }
            return networkRes;
          })
          .catch(() => cached); // if network fails, use cache
        return cached || fetchPromise;
      })
    );
    return;
  }

  // 3) Cross-origin: just pass through
  event.respondWith(fetch(req));
});

// Optional: allow page to tell the SW to activate immediately after an update
self.addEventListener('message', (event) => {
  if (event.data === 'SKIP_WAITING') self.skipWaiting();
});
