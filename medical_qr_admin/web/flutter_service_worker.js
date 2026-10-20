// Unregister-and-clean worker: when a browser holding an older cached
// service worker checks for updates it installs this file, which clears all
// Flutter caches and unregisters itself — ending stale-cache issues.
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys()
      .then((keys) => Promise.all(keys.map((k) => caches.delete(k))))
      .then(() => self.registration.unregister())
  );
});
self.addEventListener('fetch', () => {});
