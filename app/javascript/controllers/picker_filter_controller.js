import { Controller } from "@hotwired/stimulus"

// Search box of the "Add exercises" modal: hides the exercises that do not match and opens the
// groups that still have one. With the box empty, every group goes back to how it was.
// With no match at all, the query fills the "Create your own" name.
export default class extends Controller {
  static targets = ["query", "name"]

  connect() {
    this.groups = [...this.element.querySelectorAll("button.picker-group")].map((button) => {
      const panel = this.element.querySelector(button.dataset.bsTarget)
      return { button, panel, open: panel.classList.contains("show") }
    })
    this.filled = ""
  }

  filter() {
    const query = this.queryTarget.value.trim().toLowerCase()
    let matches = 0

    this.groups.forEach(({ button, panel, open }) => {
      let found = 0
      panel.querySelectorAll(".picker-row").forEach((row) => {
        const match = row.querySelector(".picker-name").textContent.toLowerCase().includes(query)
        row.hidden = !match
        if (match) found += 1
      })
      matches += found
      const show = query === "" ? open : found > 0
      button.hidden = query !== "" && found === 0
      panel.classList.toggle("show", show)
      button.classList.toggle("collapsed", !show)
      button.setAttribute("aria-expanded", show)
    })

    if (this.hasNameTarget && (this.nameTarget.value === "" || this.nameTarget.value === this.filled)) {
      this.filled = query !== "" && matches === 0 ? this.queryTarget.value.trim() : ""
      this.nameTarget.value = this.filled
    }
  }
}
