import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  submit() { this.element.requestSubmit() }
  debounced() {
    clearTimeout(this.timer)
    this.timer = setTimeout(() => this.submit(), 300)
  }
}
