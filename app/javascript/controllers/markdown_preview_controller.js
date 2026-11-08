import { Controller } from "@hotwired/stimulus"

// Tiny client-side Markdown preview for the legal page editor (headings, lists, bold, links).
export default class extends Controller {
  static targets = ["input", "output"]

  render() {
    const esc = (s) => s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
    const inline = (s) => esc(s).replace(/\*\*(.+?)\*\*/g, "<strong>$1</strong>").replace(/\*(.+?)\*/g, "<em>$1</em>")
      .replace(/\[(.+?)\]\((https?:\/\/[^)]+|\/[^)]*)\)/g, '<a href="$2">$1</a>')
    let html = "", list = null
    const closeList = () => { if (list) { html += `</${list}>`; list = null } }
    this.inputTarget.value.split(/\n/).forEach((line) => {
      let m
      if ((m = line.match(/^(#{1,3})\s+(.*)/))) { closeList(); const l = m[1].length + 1; html += `<h${l}>${inline(m[2])}</h${l}>` }
      else if ((m = line.match(/^\s*[-*]\s+(.*)/))) { if (list !== "ul") { closeList(); html += "<ul>"; list = "ul" } html += `<li>${inline(m[1])}</li>` }
      else if ((m = line.match(/^\s*\d+\.\s+(.*)/))) { if (list !== "ol") { closeList(); html += "<ol>"; list = "ol" } html += `<li>${inline(m[1])}</li>` }
      else if (line.trim() === "") { closeList() }
      else { closeList(); html += `<p>${inline(line)}</p>` }
    })
    closeList()
    this.outputTarget.innerHTML = html
  }
}
