// Força a atualização do Service Worker imediatamente
self.addEventListener('install', function(e) {
  self.skipWaiting(); 
});

// Ao ativar, ele apaga todos os cachês antigos do Flutter
self.addEventListener('activate', function(e) {
  e.waitUntil(
    caches.keys().then(function(cacheNames) {
      return Promise.all(
        cacheNames.map(function(cacheName) {
          return caches.delete(cacheName);
        })
      );
    }).then(function() {
      return self.clients.claim();
    })
  );
});