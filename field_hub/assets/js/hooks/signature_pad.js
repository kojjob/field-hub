export const SignaturePadHook = {
  mounted() {
    this.canvas = this.el
    this.ctx = this.canvas.getContext('2d')
    this.drawing = false
    this.targetInput = document.getElementById(this.el.dataset.targetId)
    this.clearButton = document.getElementById('clear-signature')

    // Resize canvas to match display size
    this.resize()
    window.addEventListener('resize', () => this.resize())

    // Touch events
    this.canvas.addEventListener('touchstart', (e) => this.startDrawing(e))
    this.canvas.addEventListener('touchend', (e) => this.stopDrawing(e))
    this.canvas.addEventListener('touchmove', (e) => this.draw(e))

    // Mouse events
    this.canvas.addEventListener('mousedown', (e) => this.startDrawing(e))
    this.canvas.addEventListener('mouseup', (e) => this.stopDrawing(e))
    this.canvas.addEventListener('mousemove', (e) => this.draw(e))

    // Clear button
    if (this.clearButton) {
      this.clearButton.addEventListener('click', () => this.clear())
    }
  },

  resize() {
    const rect = this.canvas.getBoundingClientRect()
    this.canvas.width = rect.width
    this.canvas.height = rect.height
    this.ctx.lineWidth = 2
    this.ctx.lineCap = 'round'
    this.ctx.strokeStyle = '#1e293b' // slate-800
  },

  startDrawing(e) {
    this.drawing = true
    this.draw(e)
  },

  stopDrawing() {
    this.drawing = false
    this.ctx.beginPath()
    this.save()
  },

  draw(e) {
    if (!this.drawing) return
    e.preventDefault()

    const rect = this.canvas.getBoundingClientRect()
    let x, y

    if (e.touches && e.touches[0]) {
      x = e.touches[0].clientX - rect.left
      y = e.touches[0].clientY - rect.top
    } else {
      x = e.clientX - rect.left
      y = e.clientY - rect.top
    }

    this.ctx.lineTo(x, y)
    this.ctx.stroke()
    this.ctx.beginPath()
    this.ctx.moveTo(x, y)
  },

  clear() {
    this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height)
    if (this.targetInput) {
      this.targetInput.value = ''
      // Trigger change event for LiveView
      this.targetInput.dispatchEvent(new Event('input', { bubbles: true }))
    }
  },

  save() {
    if (this.targetInput) {
      const dataUrl = this.canvas.toDataURL()
      this.targetInput.value = dataUrl
      // Trigger change event for LiveView
      this.targetInput.dispatchEvent(new Event('input', { bubbles: true }))
    }
  }
}
