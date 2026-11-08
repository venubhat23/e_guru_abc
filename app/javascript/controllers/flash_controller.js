import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() { this.timeout = setTimeout(() => this.dismiss(), 5000) }
  dismiss() {
    clearTimeout(this.timeout)
    this.element.style.transition = "opacity .3s, transform .3s"
    this.element.style.opacity = "0"
    this.element.style.transform = "translateY(8px)"
    setTimeout(() => this.element.remove(), 300)
  }
}
