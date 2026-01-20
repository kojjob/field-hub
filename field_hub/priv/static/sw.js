// FieldHub Service Worker
// Version: 1.0.0 - PWA Support with Offline Caching

const CACHE_NAME = 'fieldhub-v1';
const STATIC_CACHE = 'fieldhub-static-v1';
const DYNAMIC_CACHE = 'fieldhub-dynamic-v1';

// Assets to pre-cache for offline support
const STATIC_ASSETS = [
  '/?source=pwa',
  '/tech?source=pwa',
  '/offline',
  '/assets/css/app.css',
  '/assets/js/app.js',
  '/images/logo.svg',
  '/images/icon-192.png',
  '/images/icon-512.png',
  '/manifest.json'
];

// API routes that should always go to network
const API_ROUTES = [
  '/api/',
  '/live/',
  '/socket/'
];

// Install event - cache static assets
self.addEventListener('install', event => {
  console.log('[SW] Installing service worker...');
  
  event.waitUntil(
    caches.open(STATIC_CACHE)
      .then(cache => {
        console.log('[SW] Pre-caching static assets');
        return cache.addAll(STATIC_ASSETS.filter(url => !url.includes('?')));
      })
      .then(() => self.skipWaiting())
      .catch(err => {
        console.warn('[SW] Pre-cache failed for some assets:', err);
        return self.skipWaiting();
      })
  );
});

// Activate event - clean up old caches
self.addEventListener('activate', event => {
  console.log('[SW] Activating service worker...');
  
  event.waitUntil(
    Promise.all([
      // Clean old caches
      caches.keys().then(keys => {
        return Promise.all(
          keys
            .filter(key => key !== STATIC_CACHE && key !== DYNAMIC_CACHE)
            .map(key => {
              console.log('[SW] Removing old cache:', key);
              return caches.delete(key);
            })
        );
      }),
      // Take control immediately
      self.clients.claim()
    ])
  );
});

// Fetch event - serve from cache or network
self.addEventListener('fetch', event => {
  const { request } = event;
  const url = new URL(request.url);
  
  // Skip non-GET requests
  if (request.method !== 'GET') {
    return;
  }
  
  // Skip API and WebSocket routes - always network
  if (API_ROUTES.some(route => url.pathname.startsWith(route))) {
    return;
  }
  
  // Skip Chrome extensions and other protocols
  if (!url.protocol.startsWith('http')) {
    return;
  }
  
  // Handle LiveView/Phoenix requests - Network first with fallback
  if (request.headers.get('accept')?.includes('text/html')) {
    event.respondWith(networkFirstWithFallback(request));
    return;
  }
  
  // Static assets - Cache first
  if (isStaticAsset(url.pathname)) {
    event.respondWith(cacheFirst(request));
    return;
  }
  
  // Everything else - Stale while revalidate
  event.respondWith(staleWhileRevalidate(request));
});

// Cache-first strategy (for static assets)
async function cacheFirst(request) {
  const cached = await caches.match(request);
  if (cached) {
    return cached;
  }
  
  try {
    const response = await fetch(request);
    if (response.ok) {
      const cache = await caches.open(STATIC_CACHE);
      cache.put(request, response.clone());
    }
    return response;
  } catch (error) {
    console.warn('[SW] Network failed for:', request.url);
    return new Response('Offline', { status: 503 });
  }
}

// Network-first with offline fallback (for HTML pages)
async function networkFirstWithFallback(request) {
  try {
    const response = await fetch(request);
    
    // Cache successful responses
    if (response.ok) {
      const cache = await caches.open(DYNAMIC_CACHE);
      cache.put(request, response.clone());
    }
    
    return response;
  } catch (error) {
    console.log('[SW] Network failed, checking cache for:', request.url);
    
    // Try cache
    const cached = await caches.match(request);
    if (cached) {
      return cached;
    }
    
    // Return offline page
    const offlinePage = await caches.match('/offline');
    if (offlinePage) {
      return offlinePage;
    }
    
    // Fallback response
    return new Response(offlineHtml(), {
      status: 503,
      headers: { 'Content-Type': 'text/html' }
    });
  }
}

// Stale-while-revalidate strategy
async function staleWhileRevalidate(request) {
  const cached = await caches.match(request);
  
  const fetchPromise = fetch(request)
    .then(response => {
      if (response.ok) {
        const cache = caches.open(DYNAMIC_CACHE);
        cache.then(c => c.put(request, response.clone()));
      }
      return response;
    })
    .catch(() => null);
  
  return cached || fetchPromise;
}

// Check if URL is a static asset
function isStaticAsset(pathname) {
  return pathname.startsWith('/assets/') ||
         pathname.startsWith('/images/') ||
         pathname.endsWith('.css') ||
         pathname.endsWith('.js') ||
         pathname.endsWith('.png') ||
         pathname.endsWith('.jpg') ||
         pathname.endsWith('.svg') ||
         pathname.endsWith('.woff2');
}

// Offline HTML fallback
function offlineHtml() {
  return `
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Offline - FieldHub</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      background: linear-gradient(135deg, #09090b 0%, #18181b 100%);
      color: #fff;
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 20px;
    }
    .container {
      text-align: center;
      max-width: 400px;
    }
    .icon {
      width: 80px;
      height: 80px;
      margin: 0 auto 24px;
      background: #27272a;
      border-radius: 20px;
      display: flex;
      align-items: center;
      justify-content: center;
    }
    .icon svg {
      width: 40px;
      height: 40px;
      color: #71717a;
    }
    h1 {
      font-size: 24px;
      font-weight: 800;
      margin-bottom: 12px;
      color: #fafafa;
    }
    p {
      color: #a1a1aa;
      line-height: 1.6;
      margin-bottom: 24px;
    }
    button {
      background: #0d9488;
      color: white;
      border: none;
      padding: 14px 28px;
      border-radius: 12px;
      font-size: 16px;
      font-weight: 600;
      cursor: pointer;
      transition: background 0.2s;
    }
    button:hover {
      background: #0f766e;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="icon">
      <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M18.364 5.636a9 9 0 010 12.728m0 0l-2.829-2.829m2.829 2.829L21 21M15.536 8.464a5 5 0 010 7.072m0 0l-2.829-2.829m-4.243 2.829a4.978 4.978 0 01-1.414-2.83m-1.414 5.658a9 9 0 01-2.167-9.238m7.824 2.167a1 1 0 111.414 1.414m-1.414-1.414L3 3m8.293 8.293l1.414 1.414"/>
      </svg>
    </div>
    <h1>You're Offline</h1>
    <p>
      It looks like you've lost your internet connection. 
      Don't worry - your work is saved and will sync when you're back online.
    </p>
    <button onclick="location.reload()">Try Again</button>
  </div>
</body>
</html>
  `.trim();
}

// Handle push notifications
self.addEventListener('push', event => {
  console.log('[SW] Push received:', event);
  
  const data = event.data?.json() || {
    title: 'FieldHub',
    body: 'You have a new notification',
    icon: '/images/icon-192.png'
  };
  
  event.waitUntil(
    self.registration.showNotification(data.title, {
      body: data.body,
      icon: data.icon || '/images/icon-192.png',
      badge: '/images/icon-192.png',
      vibrate: [200, 100, 200],
      data: data.data || {},
      actions: data.actions || []
    })
  );
});

// Handle notification clicks
self.addEventListener('notificationclick', event => {
  console.log('[SW] Notification clicked:', event.notification.tag);
  
  event.notification.close();
  
  const urlToOpen = event.notification.data?.url || '/tech';
  
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true })
      .then(windowClients => {
        // Check if there's already an open window
        for (const client of windowClients) {
          if (client.url.includes(urlToOpen) && 'focus' in client) {
            return client.focus();
          }
        }
        // Open new window
        if (clients.openWindow) {
          return clients.openWindow(urlToOpen);
        }
      })
  );
});

// Background sync for offline job updates
self.addEventListener('sync', event => {
  console.log('[SW] Background sync:', event.tag);
  
  if (event.tag === 'sync-job-updates') {
    event.waitUntil(syncPendingUpdates());
  }
});

async function syncPendingUpdates() {
  // This would sync IndexedDB pending updates when back online
  console.log('[SW] Syncing pending updates...');
  // Implementation would be in conjunction with IndexedDB storage
}

console.log('[SW] Service Worker loaded');
