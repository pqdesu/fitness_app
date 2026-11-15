import { Controller } from "@hotwired/stimulus"

// Edits a table row in place: "view" elements show the saved values, "field" elements
// (the inputs and the form that submits them) replace them while editing.
export default class extends Controller {
  static targets = ["view", "field", "form"]

  edit() {
    this.toggle(true)
    const input = this.fieldTargets.find((field) => field.matches("input"))
    input.focus()
    input.select()
  }

  cancel() {
    if (this.formTarget.hidden) return
    // Puts the saved values back into the fields.
    this.formTarget.reset()
    this.toggle(false)
  }

  toggle(editing) {
    this.viewTargets.forEach((element) => { element.hidden = editing })
    this.fieldTargets.forEach((element) => { element.hidden = !editing })
  }
}
