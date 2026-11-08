import { Controller } from "@hotwired/stimulus"

// Off-canvas sidebar on mobile; always visible on lg+.
export default class extends Controller {
  static targets = ["panel", "overlay"]

  open() {
    this.panelTarget.classList.remove("-translate-x-full")
    this.overlayTarget.classList.remove("opacity-0", "pointer-events-none")
    document.body.classList.add("overflow-hidden")
  }

  close() {
    this.panelTarget.classList.add("-translate-x-full")
    this.overlayTarget.classList.add("opacity-0", "pointer-events-none")
    document.body.classList.remove("overflow-hidden")
  }
}
