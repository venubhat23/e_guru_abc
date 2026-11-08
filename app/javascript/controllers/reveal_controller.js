import { Controller } from "@hotwired/stimulus"

// Fades items in as they scroll into view. Items already on screen (or when
// IntersectionObserver / motion is unavailable) are never hidden.
export default class extends Controller {
  static targets = ["item"]

  connect() {
    const reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches
    if (reduce || !("IntersectionObserver" in window)) return

    const below = this.itemTargets.filter((el) => el.getBoundingClientRect().top > window.innerHeight * 0.9)
    below.forEach((el) => el.classList.add("reveal-animate", "reveal-pending"))

    this.observer = new IntersectionObserver((entries) => {
      entries.forEach((entry) => {
        if (!entry.isIntersecting) return
        entry.target.classList.remove("reveal-pending")
        this.observer.unobserve(entry.target)
      })
    }, { threshold: 0.1, rootMargin: "0px 0px -40px 0px" })
    below.forEach((el) => this.observer.observe(el))
  }

  disconnect() { this.observer?.disconnect() }
}
