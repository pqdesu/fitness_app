import { Controller } from "@hotwired/stimulus"

// A folded list of pills (shared/_choices with fold): the row shows the current choice, and
// picking a pill writes it there and folds the list again, so the form stays short. Bootstrap is
// its UMD build (config/importmap.rb), so its Collapse is on window.bootstrap, not an import.
export default class extends Controller {
  static targets = ["current", "list"]

  pick(event) {
    this.currentTarget.textContent = this.element.querySelector(`label[for="${event.target.id}"]`).textContent
    window.bootstrap.Collapse.getOrCreateInstance(this.listTarget, { toggle: false }).hide()
  }
}
