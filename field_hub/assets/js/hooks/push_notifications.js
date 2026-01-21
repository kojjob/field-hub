/**
 * A hook to request permission for push notifications and save the subscription.
 * 
 * Usage:
 * <div phx-hook="PushNotifications" id="push-handler" data-vapid-key="..." />
 */

function urlBase64ToUint8Array(base64String) {
  const padding = '='.repeat((4 - base64String.length % 4) % 4);
  const base64 = (base64String + padding)
    .replace(/\-/g, '+')
    .replace(/_/g, '/');

  const rawData = window.atob(base64);
  const outputArray = new Uint8Array(rawData.length);

  for (let i = 0; i < rawData.length; ++i) {
    outputArray[i] = rawData.charCodeAt(i);
  }
  return outputArray;
}

export default {
  mounted() {
    this.vapidKey = this.el.dataset.vapidKey;
    
    if (!this.vapidKey) {
      console.warn("PushNotifications: Missing data-vapid-key");
      return;
    }

    if (!("Notification" in window)) {
      console.warn("This browser does not support desktop notification");
      return;
    }

    this.pushEvent("permission_status", {status: Notification.permission});

    // Handle user action to request permission
    this.handleEvent("request_permission", () => {
      this.requestPermission();
    });

    // Auto-check if already granted to ensure subscription is up to date
    if (Notification.permission === "granted") {
      this.ensureSubscription();
    }
  },

  requestPermission() {
    if (!("Notification" in window)) {
      console.warn("This browser does not support desktop notification");
      return;
    }

    Notification.requestPermission().then((permission) => {
      if (permission === "granted") {
        this.ensureSubscription();
      }
    });
  },

  async ensureSubscription() {
    if (!('serviceWorker' in navigator)) return;

    try {
      const registration = await navigator.serviceWorker.ready;
      
      let subscription = await registration.pushManager.getSubscription();

      if (!subscription) {
        subscription = await registration.pushManager.subscribe({
          userVisibleOnly: true,
          applicationServerKey: urlBase64ToUint8Array(this.vapidKey)
        });
      }

      // Send subscription to server
      this.sendSubscriptionToServer(subscription);

    } catch (err) {
      console.error("Push subscription failed:", err);
    }
  },

  sendSubscriptionToServer(subscription) {
    const subJson = JSON.parse(JSON.stringify(subscription));
    
    this.pushEvent("save_subscription", {
      endpoint: subJson.endpoint,
      keys: subJson.keys,
      user_agent: navigator.userAgent
    });
  }
};
