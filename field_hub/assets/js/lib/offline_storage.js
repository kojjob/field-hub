/**
 * FieldHub Offline Storage
 * IndexedDB wrapper for offline job updates
 */

const DB_NAME = 'fieldhub-offline';
const DB_VERSION = 1;
const PENDING_UPDATES_STORE = 'pending_updates';

class OfflineStorage {
  constructor() {
    this.db = null;
    this.isReady = false;
  }

  async init() {
    if (this.db) return this.db;

    return new Promise((resolve, reject) => {
      const request = indexedDB.open(DB_NAME, DB_VERSION);

      request.onerror = () => reject(request.error);

      request.onsuccess = () => {
        this.db = request.result;
        this.isReady = true;
        console.log('[OfflineStorage] Database initialized');
        resolve(this.db);
      };

      request.onupgradeneeded = (event) => {
        const db = event.target.result;

        // Store for pending job updates
        if (!db.objectStoreNames.contains(PENDING_UPDATES_STORE)) {
          const store = db.createObjectStore(PENDING_UPDATES_STORE, {
            keyPath: 'id',
            autoIncrement: true
          });
          store.createIndex('jobId', 'jobId', { unique: false });
          store.createIndex('action', 'action', { unique: false });
          store.createIndex('timestamp', 'timestamp', { unique: false });
          console.log('[OfflineStorage] Created pending_updates store');
        }
      };
    });
  }

  /**
   * Queue a job update for later sync
   * @param {string} action - 'start_travel' | 'arrive' | 'start_work' | 'complete'
   * @param {string} jobId - The job ID
   * @param {object} data - Additional data for the action
   */
  async queueUpdate(action, jobId, data = {}) {
    await this.init();

    const update = {
      action,
      jobId,
      data,
      timestamp: new Date().toISOString(),
      synced: false
    };

    return new Promise((resolve, reject) => {
      const transaction = this.db.transaction([PENDING_UPDATES_STORE], 'readwrite');
      const store = transaction.objectStore(PENDING_UPDATES_STORE);
      const request = store.add(update);

      request.onsuccess = () => {
        console.log('[OfflineStorage] Queued update:', action, jobId);
        this.triggerBackgroundSync();
        resolve(request.result);
      };

      request.onerror = () => reject(request.error);
    });
  }

  /**
   * Get all pending updates
   */
  async getPendingUpdates() {
    await this.init();

    return new Promise((resolve, reject) => {
      const transaction = this.db.transaction([PENDING_UPDATES_STORE], 'readonly');
      const store = transaction.objectStore(PENDING_UPDATES_STORE);
      const request = store.getAll();

      request.onsuccess = () => resolve(request.result);
      request.onerror = () => reject(request.error);
    });
  }

  /**
   * Get count of pending updates
   */
  async getPendingCount() {
    await this.init();

    return new Promise((resolve, reject) => {
      const transaction = this.db.transaction([PENDING_UPDATES_STORE], 'readonly');
      const store = transaction.objectStore(PENDING_UPDATES_STORE);
      const request = store.count();

      request.onsuccess = () => resolve(request.result);
      request.onerror = () => reject(request.error);
    });
  }

  /**
   * Remove a synced update
   */
  async removeUpdate(id) {
    await this.init();

    return new Promise((resolve, reject) => {
      const transaction = this.db.transaction([PENDING_UPDATES_STORE], 'readwrite');
      const store = transaction.objectStore(PENDING_UPDATES_STORE);
      const request = store.delete(id);

      request.onsuccess = () => {
        console.log('[OfflineStorage] Removed update:', id);
        resolve();
      };
      request.onerror = () => reject(request.error);
    });
  }

  /**
   * Sync all pending updates to the server
   */
  async syncAll(liveSocket) {
    const updates = await this.getPendingUpdates();

    if (updates.length === 0) {
      console.log('[OfflineStorage] No pending updates to sync');
      return { synced: 0, failed: 0 };
    }

    console.log(`[OfflineStorage] Syncing ${updates.length} pending updates...`);

    let synced = 0;
    let failed = 0;

    for (const update of updates) {
      try {
        const success = await this.syncUpdate(update, liveSocket);
        if (success) {
          await this.removeUpdate(update.id);
          synced++;
        } else {
          failed++;
        }
      } catch (error) {
        console.error('[OfflineStorage] Sync failed for update:', update, error);
        failed++;
      }
    }

    console.log(`[OfflineStorage] Sync complete: ${synced} synced, ${failed} failed`);
    return { synced, failed };
  }

  /**
   * Sync a single update via the LiveSocket
   */
  async syncUpdate(update, liveSocket) {
    // Map actions to LiveView event names
    const eventMap = {
      'start_travel': 'start_travel',
      'arrive': 'mark_arrived',
      'start_work': 'start_work',
      'complete': 'complete_job'
    };

    const eventName = eventMap[update.action];
    if (!eventName) {
      console.error('[OfflineStorage] Unknown action:', update.action);
      return false;
    }

    return new Promise((resolve) => {
      // Use fetch for direct API call since we might not have a LiveView connection
      fetch('/api/tech/sync', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.content
        },
        body: JSON.stringify({
          action: update.action,
          job_id: update.jobId,
          data: update.data,
          offline_timestamp: update.timestamp
        })
      })
        .then(response => {
          if (response.ok) {
            resolve(true);
          } else {
            console.error('[OfflineStorage] Sync API error:', response.status);
            resolve(false);
          }
        })
        .catch(error => {
          console.error('[OfflineStorage] Sync network error:', error);
          resolve(false);
        });
    });
  }

  /**
   * Register for background sync when coming online
   */
  triggerBackgroundSync() {
    if ('serviceWorker' in navigator && 'sync' in window.SyncManager) {
      navigator.serviceWorker.ready
        .then(registration => {
          return registration.sync.register('sync-job-updates');
        })
        .then(() => {
          console.log('[OfflineStorage] Background sync registered');
        })
        .catch(err => {
          console.warn('[OfflineStorage] Background sync not supported:', err);
        });
    }
  }
}

// Singleton instance
const offlineStorage = new OfflineStorage();

// Initialize on load
offlineStorage.init().catch(console.error);

// Export for use in hooks
export { offlineStorage };
export default offlineStorage;
