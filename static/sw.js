// Empty Service Worker - Prevents 404 errors
// This file exists only to stop browsers from requesting a non-existent service worker

self.addEventListener('install', function(event) {
    // Do nothing - just prevent 404 errors
});

self.addEventListener('fetch', function(event) {
    // Do nothing - just prevent 404 errors
});
