import { Controller } from "@hotwired/stimulus"

// Auto-rotating crossfade hero slider with dots, arrows and pause on hover.
export default class extends Controller {
  static targets = ["slide", "dot"]
  static values = { interval: { type: Number, default: 6000 } }

  connect() {
    this.index = 0
    this.show(0)
    if (!window.matchMedia("(prefers-reduced-motion: reduce)").matches) this.play()
  }

  disconnect() { this.pause() }

  play() { this.pause(); this.timer = setInterval(() => this.next(), this.intervalValue) }
  pause() { clearInterval(this.timer) }

  next() { this.show((this.index + 1) % this.slideTargets.length) }
  prev() { this.show((this.index - 1 + this.slideTargets.length) % this.slideTargets.length) }
  go(event) { this.show(parseInt(event.currentTarget.dataset.index, 10)); this.play() }

  show(i) {
    this.index = i
    this.slideTargets.forEach((el, n) => {
      const active = n === i
      el.classList.toggle("opacity-100", active)
      el.classList.toggle("opacity-0", !active)
      el.classList.toggle("pointer-events-none", !active)
      el.setAttribute("aria-hidden", !active)
      el.querySelector("[data-zoom]")?.classList.toggle("scale-110", active)
    })
    this.dotTargets.forEach((el, n) => el.setAttribute("aria-current", n === i))
  }
}
