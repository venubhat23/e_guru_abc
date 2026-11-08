import { Controller } from "@hotwired/stimulus"

// Sends a beacon for every link/button click on the public site (Traffic analytics).
export default class extends Controller {
  static values = { url: String }

  connect() {
    this.onClick = this.track.bind(this)
    this.element.addEventListener("click", this.onClick, { capture: true })
  }

  disconnect() {
    this.element.removeEventListener("click", this.onClick, { capture: true })
  }

  track(event) {
    const el = event.target.closest("a, button, [data-track]")
    if (!el || !navigator.sendBeacon) return

    const label = el.dataset.track || el.getAttribute("aria-label") || el.innerText || el.value || ""
    const data = new FormData()
    data.append("path", window.location.pathname)
    data.append("label", label.trim().replace(/\s+/g, " ").slice(0, 120))
    if (el.getAttribute("href")) data.append("href", el.getAttribute("href"))
    navigator.sendBeacon(this.urlValue, data)
  }
}
