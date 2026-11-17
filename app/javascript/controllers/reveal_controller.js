import { Controller } from "@hotwired/stimulus"

// Shows the panel only while the source field holds the "when" value.
// Used for the equipment of a lift: "Machine" -> machine brand.
export default class extends Controller {
  static targets = ["source", "panel"]
  static values = { when: String }

  connect() {
    this.toggle()
  }

  toggle() {
    const show = this.sourceTarget.value === this.whenValue
    this.panelTarget.hidden = !show
    // A hidden field is not submitted, so a stale value cannot be saved.
    this.panelTarget.querySelectorAll("input").forEach((input) => { input.disabled = !show })
  }
}
