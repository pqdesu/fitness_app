import { Controller } from "@hotwired/stimulus"

// Shows each panel only while the checked source radio holds the panel's value (data-reveal-value,
// or the controller's "when" value). Used for the equipment of a lift: "Free weights" -> which
// one, "Machine" -> its type, which machine and its brand.
export default class extends Controller {
  static targets = ["source", "panel"]
  static values = { when: String }

  connect() {
    this.toggle()
  }

  toggle() {
    const value = this.sourceTargets.find((input) => input.checked)?.value
    this.panelTargets.forEach((panel) => {
      const show = value === (panel.dataset.revealValue ?? this.whenValue)
      panel.hidden = !show
      // A hidden field is not submitted, so a stale value cannot be saved.
      panel.querySelectorAll("input").forEach((input) => { input.disabled = !show })
    })
  }
}
