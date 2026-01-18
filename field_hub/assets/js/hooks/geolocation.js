/**
 * GeolocationHook
 * 
 * This hook tracks the user's GPS coordinates and pushes updates to the server.
 * It is designed for technician tracking while they are active on jobs.
 */
const GeolocationHook = {
  mounted() {
    this.watcher = null;
    this.lastUpdate = 0;
    this.MIN_INTERVAL = 10000; // 10 seconds minimum between updates

    this.handleEvent("start_tracking", () => this.startTracking());
    this.handleEvent("stop_tracking", () => this.stopTracking());

    if (this.el.dataset.autoStart === "true") {
      this.startTracking();
    }
  },

  destroyed() {
    this.stopTracking();
  },

  startTracking() {
    if (this.watcher) return;

    if (!("geolocation" in navigator)) {
      console.warn("Geolocation is not supported by this browser.");
      return;
    }

    const options = {
      enableHighAccuracy: true,
      maximumAge: 10000, 
      timeout: 10000     
    };

    this.watcher = navigator.geolocation.watchPosition(
      (position) => {
        const now = Date.now();
        if (now - this.lastUpdate < this.MIN_INTERVAL) return;

        const { latitude, longitude, accuracy, heading, speed } = position.coords;
        
        if (accuracy < 150) {
          this.pushEvent("update_location", {
            lat: latitude,
            lng: longitude,
            accuracy: accuracy,
            heading: heading || 0,
            speed: speed || 0,
            timestamp: position.timestamp
          });
          this.lastUpdate = now;
        }
      },
      (error) => {
        console.error("Geolocation error:", error);
        this.pushEvent("location_error", {
          code: error.code,
          message: error.message
        });
      },
      options
    );
    
    console.log("Geolocation tracking started");
  },

  stopTracking() {
    if (this.watcher) {
      navigator.geolocation.clearWatch(this.watcher);
      this.watcher = null;
      console.log("Geolocation tracking stopped");
    }
  }
};

export { GeolocationHook };
