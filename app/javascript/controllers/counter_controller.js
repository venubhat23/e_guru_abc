import { Controller } from "@hotwired/stimulus"

// Animates numbers counting up when visible. Uses Indian digit grouping.
export default class extends Controller {
  static targets = ["number"]

  connect() {
    const io = new IntersectionObserver((entries) => {
      if (entries.some((e) => e.isIntersecting)) { this.animate(); io.disconnect() }
    })
    io.observe(this.element)
  }

  animate() {
    this.numberTargets.forEach((el) => {
      const target = parseInt(el.dataset.value, 10)
      const start = performance.now()
      const step = (now) => {
        const p = Math.min((now - start) / 1400, 1)
        el.textContent = Math.round(target * (1 - Math.pow(1 - p, 3))).toLocaleString("en-IN")
        if (p < 1) requestAnimationFrame(step)
      }
      requestAnimationFrame(step)
    })
  }
}
