/**
 * FieldHub Offline Sync Hooks
 * Handles offline job updates and sync functionality
 */

import { offlineStorage } from '../lib/offline_storage';

/**
 * OfflineSync Hook
 * Main hook for managing offline state and syncing
 * Use on the tech dashboard container element
 */
const OfflineSync = {
  mounted() {
    this.isOnline = navigator.onLine;
    this.pendingCount = 0;
    
    // Initialize offline storage
    offlineStorage.init().then(() => {
      this.updatePendingCount();
    });
    
    // Handle online/offline events
    window.addEventListener('online', () => this.handleOnline());
    window.addEventListener('offline', () => this.handleOffline());
    
    // Listen for job action events from LiveView
    this.handleEvent('queue_offline_update', (payload) => {
      this.queueUpdate(payload.action, payload.job_id, payload.data);
    });
    
    // Expose sync method for manual trigger
    this.el.addEventListener('click', (e) => {
      if (e.target.closest('[data-sync-trigger]')) {
        this.syncNow();
      }
    });
    
    // Initial state push
    this.pushEvent('offline_status', { 
      online: this.isOnline, 
      pending_count: this.pendingCount 
    });
  },
  
  destroyed() {
    window.removeEventListener('online', () => this.handleOnline());
    window.removeEventListener('offline', () => this.handleOffline());
  },
  
  async handleOnline() {
    this.isOnline = true;
    console.log('[OfflineSync] Back online, starting sync...');
    
    this.pushEvent('offline_status', { 
      online: true, 
      pending_count: this.pendingCount,
      syncing: true
    });
    
    // Sync all pending updates
    const result = await this.syncNow();
    
    this.pushEvent('sync_complete', { 
      synced: result.synced, 
      failed: result.failed 
    });
  },
  
  handleOffline() {
    this.isOnline = false;
    console.log('[OfflineSync] Gone offline');
    
    this.pushEvent('offline_status', { 
      online: false, 
      pending_count: this.pendingCount 
    });
  },
  
  async queueUpdate(action, jobId, data = {}) {
    try {
      await offlineStorage.queueUpdate(action, jobId, data);
      await this.updatePendingCount();
      
      this.pushEvent('update_queued', { 
        action, 
        job_id: jobId,
        pending_count: this.pendingCount 
      });
      
      console.log('[OfflineSync] Update queued:', action, jobId);
    } catch (error) {
      console.error('[OfflineSync] Failed to queue update:', error);
    }
  },
  
  async syncNow() {
    if (!navigator.onLine) {
      console.log('[OfflineSync] Cannot sync while offline');
      return { synced: 0, failed: 0 };
    }
    
    const result = await offlineStorage.syncAll(window.liveSocket);
    await this.updatePendingCount();
    
    return result;
  },
  
  async updatePendingCount() {
    this.pendingCount = await offlineStorage.getPendingCount();
    this.updateBadge();
    return this.pendingCount;
  },
  
  updateBadge() {
    const badge = this.el.querySelector('[data-pending-badge]');
    if (badge) {
      if (this.pendingCount > 0) {
        badge.textContent = this.pendingCount;
        badge.classList.remove('hidden');
      } else {
        badge.classList.add('hidden');
      }
    }
  }
};

/**
 * OfflineAction Hook
 * Attach to job action buttons to handle offline actions
 * Use on buttons that trigger job status changes
 */
const OfflineAction = {
  mounted() {
    this.action = this.el.dataset.offlineAction;
    this.jobId = this.el.dataset.jobId;
    
    this.el.addEventListener('click', async (e) => {
      // If online, let LiveView handle it normally
      if (navigator.onLine) {
        return;
      }
      
      // If offline, prevent default and queue the update
      e.preventDefault();
      e.stopPropagation();
      
      await this.handleOfflineAction();
    });
  },
  
  async handleOfflineAction() {
    const data = {};
    
    // Collect any additional data from the form/button
    if (this.action === 'complete') {
      // For complete action, we might need more data
      const form = this.el.closest('form');
      if (form) {
        const formData = new FormData(form);
        for (const [key, value] of formData.entries()) {
          data[key] = value;
        }
      }
    }
    
    try {
      await offlineStorage.queueUpdate(this.action, this.jobId, data);
      
      // Update UI optimistically
      this.pushEvent('offline_action_queued', {
        action: this.action,
        job_id: this.jobId
      });
      
      // Show confirmation
      this.showOfflineConfirmation();
    } catch (error) {
      console.error('[OfflineAction] Failed:', error);
      this.showError('Failed to save offline action');
    }
  },
  
  showOfflineConfirmation() {
    // Create and show a toast
    this.pushEvent('show_toast', {
      message: `Action saved offline. Will sync when connected.`,
      type: 'info'
    });
    
    // Add visual indicator to the button
    this.el.classList.add('offline-queued');
    this.el.innerHTML = `
      <span class="flex items-center gap-2">
        <svg class="w-4 h-4 animate-pulse" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"/>
        </svg>
        Queued
      </span>
    `;
    this.el.disabled = true;
  },
  
  showError(message) {
    this.pushEvent('show_toast', { message, type: 'error' });
  }
};

/**
 * OfflineIndicator Hook
 * Shows current offline/online status with pending count
 * Use on a status indicator element
 */
const OfflineIndicator = {
  mounted() {
    this.update();
    
    window.addEventListener('online', () => this.update());
    window.addEventListener('offline', () => this.update());
    
    // Poll for pending count updates
    this.pollInterval = setInterval(() => this.updatePendingCount(), 5000);
  },
  
  destroyed() {
    clearInterval(this.pollInterval);
  },
  
  async update() {
    const isOnline = navigator.onLine;
    const pendingCount = await offlineStorage.getPendingCount();
    
    const indicator = this.el.querySelector('[data-indicator]');
    const text = this.el.querySelector('[data-text]');
    const badge = this.el.querySelector('[data-pending-badge]');
    
    if (indicator) {
      indicator.classList.toggle('bg-emerald-500', isOnline);
      indicator.classList.toggle('bg-amber-500', !isOnline);
      indicator.classList.toggle('animate-pulse', !isOnline || pendingCount > 0);
    }
    
    if (text) {
      if (!isOnline) {
        text.textContent = 'Offline';
      } else if (pendingCount > 0) {
        text.textContent = `Syncing (${pendingCount})`;
      } else {
        text.textContent = 'Online';
      }
    }
    
    if (badge) {
      if (pendingCount > 0) {
        badge.textContent = pendingCount;
        badge.classList.remove('hidden');
      } else {
        badge.classList.add('hidden');
      }
    }
  },
  
  async updatePendingCount() {
    if (navigator.onLine) {
      await this.update();
    }
  }
};

export { OfflineSync, OfflineAction, OfflineIndicator };
