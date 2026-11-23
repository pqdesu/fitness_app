import { Controller } from "@hotwired/stimulus"

// The ± beside the weight of a bodyweight exercise: a positive weight is added to the body, a
// negative one taken off it (an assisted pull-up). A phone's number keypad has no minus key, so
// the button changes the sign of what was typed; with nothing typed yet it only focuses the field.
export default class extends Controller {
  static targets = ["input"]

  flip() {
    const value = this.inputTarget.value.trim()
    if (value !== "") this.inputTarget.value = value.startsWith("-") ? value.slice(1) : `-${value}`
    this.inputTarget.focus()
  }
}
