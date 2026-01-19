import L from "leaflet"

// Fix Leaflet's default icon paths for bundlers (webpack/esbuild)
// This is a common issue where bundlers can't resolve the marker images
import markerIcon2x from 'leaflet/dist/images/marker-icon-2x.png'
import markerIcon from 'leaflet/dist/images/marker-icon.png'
import markerShadow from 'leaflet/dist/images/marker-shadow.png'

// Configure default icon
delete L.Icon.Default.prototype._getIconUrl
L.Icon.Default.mergeOptions({
  iconUrl: markerIcon,
  iconRetinaUrl: markerIcon2x,
  shadowUrl: markerShadow,
})

export const MapHook = {
  mounted() {
    this.map = null
    this.markers = {}
    this.resizeObserver = null
    
    // Wait for the container to have proper dimensions before initializing
    this.waitForContainer().then(() => {
      this.initializeMap()
    })
  },

  // Wait until container has valid dimensions
  waitForContainer() {
    return new Promise((resolve) => {
      const checkSize = () => {
        const rect = this.el.getBoundingClientRect()
        if (rect.width > 0 && rect.height > 0) {
          resolve()
        } else {
          requestAnimationFrame(checkSize)
        }
      }
      checkSize()
    })
  },

  initializeMap() {
    // Ensure container has explicit dimensions
    const rect = this.el.getBoundingClientRect()
    if (rect.width === 0 || rect.height === 0) {
      console.warn('Map container has no dimensions, retrying...')
      setTimeout(() => this.initializeMap(), 100)
      return
    }

    // Parse initial coordinates
    const lat = parseFloat(this.el.dataset.lat || 37.7749) // Default SF
    const lng = parseFloat(this.el.dataset.lng || -122.4194)
    
    // Create map instance
    this.map = L.map(this.el, {
      zoomControl: true,
      scrollWheelZoom: true,
      attributionControl: true
    }).setView([lat, lng], 12)

    // Add tile layer
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      maxZoom: 19,
      attribution: '&copy; <a href="https://openstreetmap.org/copyright">OpenStreetMap</a>'
    }).addTo(this.map)

    // Handle LiveView push events
    this.handleEvent("update_map_data", ({technicians, jobs}) => {
      this.updateMarkers(technicians, jobs)
    })

    // Setup ResizeObserver for container size changes
    this.setupResizeObserver()

    // Initial data load from data attributes
    this.loadInitialData()

    // Force multiple invalidateSize calls to ensure proper rendering
    // This is necessary because Leaflet needs the final container size
    this.forceMapRefresh()
  },

  setupResizeObserver() {
    if (typeof ResizeObserver !== 'undefined') {
      this.resizeObserver = new ResizeObserver(() => {
        if (this.map) {
          this.map.invalidateSize({ animate: false })
        }
      })
      this.resizeObserver.observe(this.el)
    }
  },

  forceMapRefresh() {
    // Multiple refresh attempts to handle various timing issues
    const timings = [0, 100, 250, 500]
    timings.forEach(delay => {
      setTimeout(() => {
        if (this.map) {
          this.map.invalidateSize({ animate: false })
        }
      }, delay)
    })
  },

  loadInitialData() {
    try {
      const techniciansData = this.el.dataset.technicians
      const jobsData = this.el.dataset.jobs
      
      if (techniciansData) {
        const technicians = JSON.parse(techniciansData)
        const jobs = jobsData ? JSON.parse(jobsData) : []
        this.updateMarkers(technicians, jobs)
      }
    } catch (e) {
      console.error("Error parsing initial map data:", e)
    }
  },

  updateMarkers(technicians, jobs) {
    if (!this.map) return

    const newMarkerIds = new Set()
    const allLatLngs = []

    // 1. Technicians with custom styled markers
    technicians.forEach(tech => {
      if (tech.current_lat && tech.current_lng) {
        const id = `tech-${tech.id}`
        newMarkerIds.add(id)

        const latLng = [tech.current_lat, tech.current_lng]
        allLatLngs.push(latLng)
        
        if (this.markers[id]) {
          this.markers[id].setLatLng(latLng)
        } else {
          // Create custom styled icon for technician
          const statusColor = this.getTechStatusColor(tech.status)
          const techIcon = L.divIcon({
            className: 'tech-marker',
            html: `
              <div style="
                background-color: ${tech.color || '#14b8a6'};
                width: 32px;
                height: 32px;
                border-radius: 50%;
                border: 3px solid white;
                box-shadow: 0 2px 8px rgba(0,0,0,0.3);
                display: flex;
                align-items: center;
                justify-content: center;
                font-weight: bold;
                font-size: 11px;
                color: white;
                position: relative;
              ">
                ${this.getInitials(tech.name)}
                <span style="
                  position: absolute;
                  bottom: -2px;
                  right: -2px;
                  width: 10px;
                  height: 10px;
                  background-color: ${statusColor};
                  border-radius: 50%;
                  border: 2px solid white;
                "></span>
              </div>
            `,
            iconSize: [32, 32],
            iconAnchor: [16, 16]
          })

          const marker = L.marker(latLng, {icon: techIcon}).addTo(this.map)
          marker.bindPopup(`
            <div style="text-align: center; padding: 4px;">
              <strong style="font-size: 14px;">${tech.name}</strong><br>
              <span style="color: #666; font-size: 12px; text-transform: capitalize;">
                ${tech.status?.replace('_', ' ') || 'Unknown'}
              </span>
            </div>
          `)
          this.markers[id] = marker
        }
      }
    })

    // 2. Job markers with status-based styling
    jobs.forEach(job => {
      if (job.service_lat && job.service_lng) {
        const id = `job-${job.id}`
        newMarkerIds.add(id)
        
        const latLng = [job.service_lat, job.service_lng]
        allLatLngs.push(latLng)

        if (this.markers[id]) {
          this.markers[id].setLatLng(latLng)
        } else {
          // Create custom job marker
          const statusColor = this.getJobStatusColor(job.status)
          const jobIcon = L.divIcon({
            className: 'job-marker',
            html: `
              <div style="
                background-color: white;
                width: 28px;
                height: 28px;
                border-radius: 6px;
                border: 2px solid ${statusColor};
                box-shadow: 0 2px 6px rgba(0,0,0,0.2);
                display: flex;
                align-items: center;
                justify-content: center;
              ">
                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="${statusColor}" style="width: 16px; height: 16px;">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M11.42 15.17L17.25 21A2.652 2.652 0 0021 17.25l-5.877-5.877M11.42 15.17l2.496-3.03c.317-.384.74-.626 1.208-.766M11.42 15.17l-4.655 5.653a2.548 2.548 0 11-3.586-3.586l6.837-5.63m5.108-.233c.55-.164 1.163-.188 1.743-.14a4.5 4.5 0 004.486-6.336l-3.276 3.277a3.004 3.004 0 01-2.25-2.25l3.276-3.276a4.5 4.5 0 00-6.336 4.486c.091 1.076-.071 2.264-.904 2.95l-.102.085m-1.745 1.437L5.909 7.5H4.5L2.25 3.75l1.5-1.5L7.5 4.5v1.409l4.26 4.26m-1.745 1.437l1.745-1.437m6.615 8.206L15.75 15.75M4.867 19.125h.008v.008h-.008v-.008z" />
                </svg>
              </div>
            `,
            iconSize: [28, 28],
            iconAnchor: [14, 14]
          })
             
          const marker = L.marker(latLng, {icon: jobIcon}).addTo(this.map)
          marker.bindTooltip(`
            <div style="text-align: center;">
              <strong>#${job.number}</strong><br>
              <span style="font-size: 11px;">${job.title}</span>
            </div>
          `, {direction: 'top', offset: [0, -8]})
          
          marker.on('click', () => {
            this.pushEvent("show_job_details", {job_id: job.id})
          })
          
          this.markers[id] = marker
        }
      }
    })

    // Remove old markers that are no longer in the data
    Object.keys(this.markers).forEach(id => {
      if (!newMarkerIds.has(id)) {
        this.map.removeLayer(this.markers[id])
        delete this.markers[id]
      }
    })

    // Auto-fit bounds to show all markers
    if (allLatLngs.length > 0) {
      const bounds = L.latLngBounds(allLatLngs)
      this.map.fitBounds(bounds, { 
        padding: [50, 50],
        maxZoom: 15 
      })
    }
  },

  // Helper: Get initials from name
  getInitials(name) {
    if (!name) return '?'
    return name.split(' ')
      .slice(0, 2)
      .map(part => part.charAt(0))
      .join('')
      .toUpperCase()
  },

  // Helper: Get color based on technician status
  getTechStatusColor(status) {
    const colors = {
      'available': '#10b981',    // emerald
      'on_job': '#14b8a6',       // teal/primary
      'traveling': '#f59e0b',    // amber
      'break': '#8b5cf6',        // purple
      'off_duty': '#9ca3af'      // gray
    }
    return colors[status] || '#9ca3af'
  },

  // Helper: Get color based on job status
  getJobStatusColor(status) {
    const colors = {
      'unscheduled': '#71717a',  // zinc
      'scheduled': '#14b8a6',    // teal
      'en_route': '#f59e0b',     // amber
      'on_site': '#8b5cf6',      // purple
      'in_progress': '#3b82f6',  // blue
      'completed': '#10b981',    // emerald
      'cancelled': '#ef4444'     // red
    }
    return colors[status] || '#71717a'
  },

  // Cleanup when element is removed
  destroyed() {
    // Clean up ResizeObserver
    if (this.resizeObserver) {
      this.resizeObserver.disconnect()
      this.resizeObserver = null
    }
    
    // Clean up map
    if (this.map) {
      this.map.remove()
      this.map = null
      this.markers = {}
    }
  }
}
