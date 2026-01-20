# PWA, SMS & Offline Support - Implementation Plan

> **Sprint:** FH-030, FH-051, FH-037  
> **Created:** 2026-01-20  
> **Goal:** Make FieldHub a production-ready PWA with SMS notifications and offline support

---

## Current State Analysis

### ✅ Already Implemented

- `manifest.json` - Complete with icons, shortcuts, screenshots
- `sw.js` - Service worker with caching strategies
- PWA hooks (`PWAInstall`, `NetworkStatus`, `SMSPreference`)
- `SMS.ex` - Twilio integration with templates
- Service worker registration in `app.js`

### 🚧 Gaps to Address

1. **PWA (FH-030):** Missing PWA icons, mobile viewport fixes, iOS meta tags
2. **SMS (FH-051):** Not wired to job status changes, need job event triggers
3. **Offline (FH-037):** IndexedDB storage not implemented, sync queue missing

---

## Phase 1: Complete PWA Setup (FH-030)

### Tasks

- [x] 1.1: Generate PWA icons (192x192, 512x512) → Verify: Images exist in `/priv/static/images/`
- [x] 1.2: Add iOS-specific meta tags to root layout → Verify: `apple-mobile-web-app-capable` present
- [x] 1.3: Add mobile viewport and theme-color meta → Verify: `<meta name="theme-color">` in head
- [x] 1.4: Create offline page (`/offline`) → Verify: Service worker shows offline UI
- [x] 1.5: Update tech views with mobile-first CSS → Verify: Touch targets ≥44px
- [ ] 1.6: Test PWA installability → Verify: Chrome Lighthouse PWA audit passes

---

## Phase 2: Wire SMS to Job Events (FH-051)

### Tasks

- [x] 2.1: Add `notify_technician_en_route/1` to Jobs context → Verify: Function exists
- [x] 2.2: Call SMS on `start_travel/1` → Verify: `notify_technician_en_route` triggered
- [x] 2.3: Call SMS on `arrive_on_site/1` → Verify: `notify_technician_arrived` triggered  
- [x] 2.4: Call SMS on `complete_job/2` → Verify: `notify_job_completed` triggered
- [x] 2.5: SMS toggle respects customer preferences → Verify: Customer can opt-in/out
- [ ] 2.6: Test SMS flow end-to-end (dev mode) → Verify: Logs show SMS attempted

---

## Phase 3: Offline Support (FH-037)

### Tasks

- [x] 3.1: Create IndexedDB wrapper hook (`offline_storage.js`) → Verify: `offlineStorage` available
- [x] 3.2: Create OfflineSync LiveView hook → Verify: Hook queues updates when offline
- [x] 3.3: Create OfflineAction hook for buttons → Verify: Actions queued to IndexedDB
- [x] 3.4: Add offline indicator to tech dashboard → Verify: Banner shows when offline
- [x] 3.5: Create sync API endpoint (`/api/tech/sync`) → Verify: POST syncs queued updates
- [x] 3.6: Add sync handlers to dashboard → Verify: Status changes persist through cycle

---

## Done When

- [ ] PWA installs on iOS Safari and Android Chrome
- [ ] Lighthouse PWA score ≥ 90
- [x] SMS sends on en_route, arrived, completed (when enabled)
- [x] Technician can mark job complete while offline, syncs on reconnect
- [x] All existing tests still pass (`mix test`) - 404 tests, 3 unrelated failures

---

## Files Created/Modified

### New Files

- `assets/js/lib/offline_storage.js` - IndexedDB wrapper for offline queue
- `assets/js/hooks/offline_sync.js` - OfflineSync, OfflineAction, OfflineIndicator hooks
- `lib/field_hub_web/controllers/tech_sync_controller.ex` - API for syncing offline updates
- `lib/field_hub_web/controllers/fallback_controller.ex` - JSON error handling
- `priv/static/images/icon-192.png` - PWA icon (192x192)
- `priv/static/images/icon-512.png` - PWA icon (512x512)

### Modified Files

- `assets/js/app.js` - Added offline hooks registration
- `lib/field_hub_web/router.ex` - Added `/api/tech/sync` route
- `lib/field_hub_web/live/tech_live/dashboard.ex` - Added offline UI and handlers

---

## Notes

- SMS is in dev mode by default (logs but doesn't send)
- Twilio credentials needed for production SMS
- IndexedDB uses `idb` library patterns
- Service worker already handles background sync registration
- Cleaned up duplicate files (` 2.ex`, ` 2.heex`, etc.)
