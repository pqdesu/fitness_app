import { Controller } from "@hotwired/stimulus"

// Edits a table row in place: "view" elements show the saved values, "field" elements
// (the inputs, and the row with Save and Cancel) replace them while editing.
// The inputs belong to the "form" target through their form attribute.
export default class extends Controller {
  static targets = ["view", "field", "form"]

  // From the ⋯ menu's Edit, or by tapping a value (a set's weight or reps), which then gets the cursor
  // (data-row-edit-focus-param: the id of its input).
  edit({ params } = {}) {
    this.toggle(true)
    // The first field, which may sit in a group (the weight of a bodyweight exercise, with its ±)
    const input = (params?.focus && document.getElementById(params.focus)) ||
      this.fieldTargets.map((field) => field.matches("input") ? field : field.querySelector("input")).find(Boolean)
    input.focus()
    input.select()
  }

  // The note field saves on its own when it is changed.
  save() {
    this.formTarget.requestSubmit()
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
