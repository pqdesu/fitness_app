import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"

// A list reordered by drag and drop (a day's plan on the split page, the cards of a logged
// workout), with a finger or a mouse, by each item's .drag-handle. Each item carries the address
// of its move (data-sortable-url). Dropping one in a new place sends it there as a Turbo form:
// the server saves the order and the page refreshes in place (morph) with the moved item lit up.
export default class extends Controller {
  connect() {
    this.sortable = Sortable.create(this.element, {
      handle: ".drag-handle",
      draggable: "[data-sortable-url]",
      animation: 150,
      onEnd: ({ item, oldDraggableIndex, newDraggableIndex }) => {
        if (oldDraggableIndex !== newDraggableIndex) this.move(item.dataset.sortableUrl, newDraggableIndex + 1)
      }
    })
  }

  disconnect() {
    this.sortable.destroy()
  }

  move(url, to) {
    const form = document.createElement("form")
    form.method = "post"
    form.action = url
    form.hidden = true
    const token = document.querySelector("meta[name=csrf-token]")?.content
    for (const [name, value] of [["_method", "patch"], ["authenticity_token", token], ["to", to]]) {
      const input = document.createElement("input")
      input.type = "hidden"
      input.name = name
      input.value = value
      form.append(input)
    }
    document.body.append(form)
    form.requestSubmit()
  }
}
