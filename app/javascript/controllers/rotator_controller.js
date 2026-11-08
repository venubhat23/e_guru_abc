import { Controller } from "@hotwired/stimulus"

// Cycles through a list of words with an entrance animation.
export default class extends Controller {
  static targets = ["word"]
  static values = { words: Array, interval: { type: Number, default: 2400 } }

  connect() {
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches || this.wordsValue.length < 2) return
    this.index = 0
    this.timer = setInterval(() => this.next(), this.intervalValue)
  }

  disconnect() { clearInterval(this.timer) }

  next() {
    this.index = (this.index + 1) % this.wordsValue.length
    const el = this.wordTarget
    el.textContent = this.wordsValue[this.index]
    el.classList.remove("animate-word-in")
    void el.offsetWidth
    el.classList.add("animate-word-in")
  }
}
