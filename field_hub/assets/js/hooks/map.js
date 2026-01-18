import L from "leaflet"

export const MapHook = {
  mounted() {
    this.map = null
    this.markers = {}

    // Initialize map
    const lat = parseFloat(this.el.dataset.lat || 37.7749) // Default SF
    const lng = parseFloat(this.el.dataset.lng || -122.4194)
    
    this.map = L.map(this.el).setView([lat, lng], 13)

    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      maxZoom: 19,
      attribution: '© OpenStreetMap'
    }).addTo(this.map)

    // Handle updates
    this.handleEvent("update_map_data", ({technicians, jobs}) => {
      this.updateMarkers(technicians, jobs)
    })

    // Initial data if valid JSON is present
    try {
      if (this.el.dataset.technicians) {
        const technicians = JSON.parse(this.el.dataset.technicians)
        const jobs = this.el.dataset.jobs ? JSON.parse(this.el.dataset.jobs) : []
        this.updateMarkers(technicians, jobs)
      }
    } catch (e) {
      console.error("Error parsing map data", e)
    }
  },

  updateMarkers(technicians, jobs) {
    if (!this.map) return

    // Clear existing markers
    // Note: In a real app, we might want to update positions smoothly instead of clear/redraw
    // But for MVP, clearing is easier.
    // However, keeping track of markers by ID is better.
    
    // For now, let's just clear all and redraw to ensure correctness
    // Or better, let's start fresh each time to avoid stale markers
    // Ideally we track them in this.markers = { 'tech-1': marker, 'job-ABC': marker }
    
    // Simple implementation: Remove all layers that are markers
    // But we need to keep the tile layer.
    
    // Let's implement a simple tracking system
    const newMarkerIds = new Set()

    // 1. Technicians
    technicians.forEach(tech => {
      if (tech.current_lat && tech.current_lng) {
        const id = `tech-${tech.id}`
        newMarkerIds.add(id)

        const latLng = [tech.current_lat, tech.current_lng]
        
        if (this.markers[id]) {
          this.markers[id].setLatLng(latLng)
        } else {
          // Create custom icon for tech
          const techIcon = L.divIcon({
            className: 'custom-div-icon',
            html: `<div style="background-color:${tech.color}; width: 24px; height: 24px; border-radius: 50%; border: 2px solid white; box-shadow: 0 2px 4px rgba(0,0,0,0.3);"></div>`,
            iconSize: [24, 24],
            iconAnchor: [12, 12]
          })

          const marker = L.marker(latLng, {icon: techIcon}).addTo(this.map)
          marker.bindPopup(`<b>${tech.name}</b><br>${tech.status}`)
          this.markers[id] = marker
        }
      }
    })

    // 2. Jobs
    jobs.forEach(job => {
      if (job.service_lat && job.service_lng) {
        const id = `job-${job.id}`
        newMarkerIds.add(id)
        
        const latLng = [job.service_lat, job.service_lng]

        if (this.markers[id]) {
          this.markers[id].setLatLng(latLng)
        } else {
             // Simple default marker for jobs
             const marker = L.marker(latLng).addTo(this.map)
             marker.bindTooltip(`<b>${job.number}</b><br>${job.title}`, {direction: 'top'})
             
             marker.on('click', () => {
               this.pushEvent("show_job_details", {job_id: job.id})
             })
             
             this.markers[id] = marker
        }
      }
    })

    // Remove old markers
    Object.keys(this.markers).forEach(id => {
      if (!newMarkerIds.has(id)) {
        this.map.removeLayer(this.markers[id])
        delete this.markers[id]
      }
    })
  }
}
