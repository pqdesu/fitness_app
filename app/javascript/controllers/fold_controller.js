import { Controller } from "@hotwired/stimulus"

// A card that folds (a Bootstrap collapse, the "panel", opened by the "toggle"), as each exercise of
// a logged workout. Saving a set refreshes the page in place (Turbo morph), which would put back the
// server's folded state: keep() keeps the card as the user left it. A card the address points to
// (#entry-12, after adding a set or from "Added to this workout") opens when the page loads.
export default class extends Controller {
  static targets = ["panel", "toggle"]

  connect() {
    if (location.hash === `#${this.element.id}`) this.open()
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
