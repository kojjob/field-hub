// PWA Install Prompt Hook
// Shows an install banner when the app can be installed

const PWAInstall = {
  mounted() {
    this.deferredPrompt = null;
    this.isInstalled = false;
    
    // Check if already installed
    if (window.matchMedia('(display-mode: standalone)').matches) {
      this.isInstalled = true;
      this.el.style.display = 'none';
      return;
    }
    
    // Listen for beforeinstallprompt event
    window.addEventListener('beforeinstallprompt', (e) => {
      e.preventDefault();
      this.deferredPrompt = e;
      this.showInstallButton();
    });
    
    // Listen for successful install
    window.addEventListener('appinstalled', () => {
      this.isInstalled = true;
      this.hideInstallButton();
      this.showToast('App installed successfully! 🎉');
    });
    
    // Handle install button click
    this.el.addEventListener('click', () => this.handleInstall());
  },
  
  showInstallButton() {
    this.el.classList.remove('hidden');
    this.el.classList.add('animate-slide-in');
  },
  
  hideInstallButton() {
    this.el.classList.add('hidden');
  },
  
  async handleInstall() {
    if (!this.deferredPrompt) {
      // Show manual install instructions
      this.showManualInstructions();
      return;
    }
    
    // Show the install prompt
    this.deferredPrompt.prompt();
    
    const { outcome } = await this.deferredPrompt.userChoice;
    
    if (outcome === 'accepted') {
      console.log('[PWA] User accepted install prompt');
    } else {
      console.log('[PWA] User dismissed install prompt');
    }
    
    this.deferredPrompt = null;
  },
  
  showManualInstructions() {
    const isIOS = /iPad|iPhone|iPod/.test(navigator.userAgent);
    const isSafari = /^((?!chrome|android).)*safari/i.test(navigator.userAgent);
    
    let message = '';
    
    if (isIOS && isSafari) {
      message = 'Tap the Share button, then "Add to Home Screen"';
    } else if (isIOS) {
      message = 'Open in Safari, tap Share, then "Add to Home Screen"';
    } else {
      message = 'Use your browser menu to "Install App" or "Add to Home Screen"';
    }
    
    this.showToast(message, 5000);
  },
  
  showToast(message, duration = 3000) {
    // Push event to LiveView to show flash
    this.pushEvent('show_toast', { message, type: 'info' });
  }
};

// Network Status Hook
// Shows online/offline status and syncs pending data

const NetworkStatus = {
  mounted() {
    this.updateStatus();
    
    window.addEventListener('online', () => {
      this.updateStatus();
      this.showNotification('You\'re back online! 🌐', 'success');
      this.pushEvent('network_status_changed', { online: true });
    });
    
    window.addEventListener('offline', () => {
      this.updateStatus();
      this.showNotification('You\'re offline. Changes will sync when reconnected.', 'warning');
      this.pushEvent('network_status_changed', { online: false });
    });
  },
  
  updateStatus() {
    const isOnline = navigator.onLine;
    const indicator = this.el.querySelector('[data-indicator]');
    const text = this.el.querySelector('[data-text]');
    
    if (indicator) {
      indicator.classList.toggle('bg-emerald-500', isOnline);
      indicator.classList.toggle('bg-amber-500', !isOnline);
      indicator.classList.toggle('animate-pulse', !isOnline);
    }
    
    if (text) {
      text.textContent = isOnline ? 'Online' : 'Offline';
    }
    
    // Update body class for CSS targeting
    document.body.classList.toggle('is-offline', !isOnline);
  },
  
  showNotification(message, type) {
    this.pushEvent('show_toast', { message, type });
  }
};

// SMS Preference Toggle Hook
// Handles SMS opt-in/opt-out with confirmation

const SMSPreference = {
  mounted() {
    const toggle = this.el.querySelector('input[type="checkbox"]');
    
    if (toggle) {
      toggle.addEventListener('change', (e) => {
        const enabled = e.target.checked;
        
        if (!enabled) {
          // Confirm opt-out
          const confirmed = confirm(
            'Are you sure you want to disable SMS notifications? ' +
            'You won\'t receive text updates about your service appointments.'
          );
          
          if (!confirmed) {
            e.target.checked = true;
            return;
          }
        }
        
        this.pushEvent('update_sms_preference', { enabled });
      });
    }
  }
};

export { PWAInstall, NetworkStatus, SMSPreference };
