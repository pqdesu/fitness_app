import { Controller } from "@hotwired/stimulus"

// Edits a table row in place: "view" elements show the saved values, "field" elements
// (the inputs, and the row with the note, Save and Cancel) replace them while editing.
// The inputs belong to the "form" target through their form attribute.
export default class extends Controller {
  static targets = ["view", "field", "form"]

  edit() {
    this.toggle(true)
    const input = this.fieldTargets.find((field) => field.matches("input"))
    input.focus()
    input.select()
  }

  cancel() {
    if (!this.editing) return
    // Puts the saved values back into the fields.
    this.formTarget.reset()
    this.toggle(false)
  }

  toggle(editing) {
    this.editing = editing
    this.viewTargets.forEach((element) => { element.hidden = editing })
    this.fieldTargets.forEach((element) => { element.hidden = !editing })
  }
}
