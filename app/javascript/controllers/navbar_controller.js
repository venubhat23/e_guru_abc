import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["bar", "mobile"]
  static values = { sticky: Boolean }

  connect() { this.onScroll() }

  onScroll() {
    const scrolled = this.stickyValue || window.scrollY > 12
    this.barTarget.classList.toggle("glass", scrolled)
    this.barTarget.classList.toggle("shadow-lg", scrolled)
    this.barTarget.classList.toggle("ring-1", scrolled)
    this.barTarget.classList.toggle("ring-slate-200/60", scrolled)
  }

  toggle() { this.mobileTarget.classList.toggle("hidden") }
  close() { this.mobileTarget.classList.add("hidden") }
}
