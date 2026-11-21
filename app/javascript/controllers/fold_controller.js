import { Controller } from "@hotwired/stimulus"

// A card that folds (a Bootstrap collapse, the "panel", opened by the "toggle"): an exercise of a
// logged workout, a day of a split.
// - A card the address points to (#entry-12 after adding a set, #day-3 after planning) opens when
//   the page loads, and so does one a link on the page points to (a split's week circle), even when
//   the address already ends with it.
// - Saving a set refreshes the page in place (Turbo morph), which would put back the server's
//   folded state: keep() keeps the card as the user left it.
export default class extends Controller {
  static targets = ["panel", "toggle"]

  connect() {
    if (location.hash === `#${this.element.id}`) this.open()
  }

  openFromLink(event) {
    const link = event.target.closest("a[href]")
    if (link && new URL(link.href, location.href).hash === `#${this.element.id}`) this.open()
  }

  keep(event) {
    if (event.target !== this.panelTarget && event.target !== this.toggleTarget) return
    if (["class", "aria-expanded", "style"].includes(event.detail.attributeName)) event.preventDefault()
  }

  open() {
    this.panelTarget.classList.add("show")
    this.toggleTarget.classList.remove("collapsed")
    this.toggleTarget.setAttribute("aria-expanded", "true")
  }
}
