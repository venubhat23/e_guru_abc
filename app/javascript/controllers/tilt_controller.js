import { Controller } from "@hotwired/stimulus"

// Subtle 3D tilt that follows the pointer. Disabled for touch / reduced motion.
export default class extends Controller {
  static targets = ["card"]
  static values = { max: { type: Number, default: 10 } }

  connect() {
    this.enabled = window.matchMedia("(hover: hover) and (prefers-reduced-motion: no-preference)").matches
  }

  move(event) {
    if (!this.enabled) return
    const r = this.element.getBoundingClientRect()
    const x = (event.clientX - r.left) / r.width - 0.5
    const y = (event.clientY - r.top) / r.height - 0.5
    this.cardTarget.style.transform = `perspective(1000px) rotateY(${x * this.maxValue}deg) rotateX(${-y * this.maxValue}deg)`
  }

  leave() { this.cardTarget.style.transform = "" }
}
