import { Controller } from "@hotwired/stimulus"

// Adds/removes nested rows (accepts_nested_attributes_for) from a <template>.
export default class extends Controller {
  static targets = ["template", "list"]

  connect() { this.element.dataset.nestedFormConnected = "true" }

  add(event) {
    event.preventDefault()
    const html = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, Date.now().toString())
    this.listTarget.insertAdjacentHTML("beforeend", html)
  }

  remove(event) {
    event.preventDefault()
    const row = event.target.closest("[data-nested-row]")
    const destroy = row.querySelector("input[name*='_destroy']")
    if (destroy && row.dataset.persisted === "true") {
      destroy.value = "1"
      row.classList.add("hidden")
    } else {
      row.remove()
    }
  }
}
