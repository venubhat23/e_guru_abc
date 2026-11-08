import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]

  connect() { this.outside = (e) => { if (!this.element.contains(e.target)) this.hide() } }

  toggle(event) {
    event.stopPropagation()
    this.menuTarget.classList.contains("hidden") ? this.show() : this.hide()
  }

  show() {
    this.menuTarget.classList.remove("hidden")
    document.addEventListener("click", this.outside)
  }

  hide() {
    this.menuTarget.classList.add("hidden")
    document.removeEventListener("click", this.outside)
  }

  disconnect() { document.removeEventListener("click", this.outside) }
}
