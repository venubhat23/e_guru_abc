import { Controller } from "@hotwired/stimulus"

// Feeds pointer position to CSS (--mx/--my) for a soft glow that follows the cursor.
export default class extends Controller {
  move(event) {
    const r = this.element.getBoundingClientRect()
    this.element.style.setProperty("--mx", `${event.clientX - r.left}px`)
    this.element.style.setProperty("--my", `${event.clientY - r.top}px`)
  }
}
