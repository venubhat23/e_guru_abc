import { Controller } from "@hotwired/stimulus"

// Interactive "build your gift box" teaser. No prices are shown — it collects
// occasion, headcount and gift styles, then hands them to the contact form
// as a pre-filled quote request. Every chip/button click is also picked up by
// the traffic controller (data-track labels) for the admin Traffic report.
export default class extends Controller {
  static targets = ["occasion", "style", "delivery", "headcount", "headcountLabel", "fill", "summary", "box", "emptyHint", "cta", "progress", "step"]
  static values = { url: String }

  connect() { this.update() }

  pickOccasion(event) {
    this.occasionTargets.forEach((el) => el.setAttribute("aria-pressed", el === event.currentTarget))
    this.update()
  }

  toggleStyle(event) {
    const el = event.currentTarget
    el.setAttribute("aria-pressed", el.getAttribute("aria-pressed") !== "true")
    this.update()
    if (el.getAttribute("aria-pressed") === "true") this.pop(el.dataset.emoji)
  }

  pickDelivery(event) {
    this.deliveryTargets.forEach((el) => el.setAttribute("aria-pressed", el === event.currentTarget))
    this.update()
  }

  update() {
    const occasion = this.occasionTargets.find((el) => el.getAttribute("aria-pressed") === "true")
    const styles = this.styleTargets.filter((el) => el.getAttribute("aria-pressed") === "true")
    const delivery = this.deliveryTargets.find((el) => el.getAttribute("aria-pressed") === "true")
    const count = parseInt(this.headcountTarget.value, 10)
    const min = parseInt(this.headcountTarget.min, 10), max = parseInt(this.headcountTarget.max, 10)

    this.headcountLabelTarget.textContent = count >= max ? `${max.toLocaleString("en-IN")}+` : count.toLocaleString("en-IN")
    this.fillTarget.style.width = `${((count - min) / (max - min)) * 100}%`

    // Items in the box
    this.boxTarget.innerHTML = styles.map((el) =>
      `<span class="grid h-14 w-14 place-items-center rounded-2xl bg-white text-3xl shadow-lg ring-1 ring-plum-100 animate-fade-up">${el.dataset.emoji}</span>`
    ).join("")
    this.emptyHintTarget.hidden = styles.length > 0

    const done = [occasion, styles.length, delivery].filter(Boolean).length + 1
    this.progressTarget.style.width = `${(done / 4) * 100}%`
    this.stepTargets.forEach((el, i) => el.classList.toggle("is-done", i < done))

    this.summaryTarget.textContent =
      `${occasion ? occasion.dataset.name : "Any occasion"} · ${this.headcountLabelTarget.textContent} people` +
      (delivery ? ` · ${delivery.dataset.name}` : "")

    const message = [
      "Quote builder request",
      styles.length ? `Gift styles: ${styles.map((el) => el.dataset.name).join(", ")}` : null,
      delivery ? `Delivery: ${delivery.dataset.name}` : null
    ].filter(Boolean).join("\n")
    const params = new URLSearchParams({ employees: count, message })
    if (occasion) params.set("occasion", occasion.dataset.slug)
    this.ctaTarget.href = `${this.urlValue}?${params}`
  }

  pop(emoji) {
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return
    const r = this.boxTarget.getBoundingClientRect()
    for (let i = 0; i < 10; i++) {
      const s = document.createElement("span")
      s.textContent = i % 2 ? "✨" : emoji
      s.className = "pointer-events-none fixed z-50 text-xl"
      s.style.left = `${r.left + r.width / 2}px`
      s.style.top = `${r.top + r.height / 2}px`
      document.body.appendChild(s)
      const angle = Math.random() * Math.PI * 2, dist = 60 + Math.random() * 80
      s.animate([
        { transform: "translate(-50%,-50%) scale(.4)", opacity: 1 },
        { transform: `translate(calc(-50% + ${Math.cos(angle) * dist}px), calc(-50% + ${Math.sin(angle) * dist}px)) scale(1.2)`, opacity: 0 }
      ], { duration: 800 + Math.random() * 300, easing: "cubic-bezier(.2,.7,.2,1)" }).onfinish = () => s.remove()
    }
  }
}
