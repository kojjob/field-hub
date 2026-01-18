// Drag and Drop Hook using Sortable.js
import Sortable from "sortablejs"

export const DragDropHook = {
  mounted() {
    const group = this.el.dataset.group || "jobs"
    const type = this.el.dataset.type // "source" (unassigned) or "target" (technician slot)
    
    this.sortable = new Sortable(this.el, {
      group: group,
      animation: 150,
      ghostClass: "opacity-50",
      chosenClass: "ring-2 ring-primary",
      dragClass: "shadow-lg",
      handle: ".drag-handle",
      fallbackOnBody: true,
      swapThreshold: 0.65,
      
      onEnd: (evt) => {
        // Get job info
        const jobId = evt.item.dataset.jobId
        if (!jobId) return
        
        // Get target info
        const targetEl = evt.to.closest("[data-technician-id]") || evt.to
        const technicianId = targetEl.dataset.technicianId || null
        const hour = targetEl.dataset.hour || null
        
        // Check if dropped in unassigned area
        const isUnassigned = evt.to.dataset.type === "source"
        
        if (isUnassigned) {
          // Unassign the job
          this.pushEvent("unassign_job", {
            job_id: jobId
          })
        } else if (technicianId) {
          // Assign to technician
          this.pushEvent("assign_job", {
            job_id: jobId,
            technician_id: technicianId,
            hour: hour ? parseInt(hour) : null
          })
        }
      },
      
      onStart: (_evt) => {
        // Add visual feedback
        document.body.classList.add("dragging")
      },
      
      onUnchoose: (_evt) => {
        document.body.classList.remove("dragging")
      }
    })
  },
  
  destroyed() {
    if (this.sortable) {
      this.sortable.destroy()
    }
  }
}

export default { DragDropHook }
