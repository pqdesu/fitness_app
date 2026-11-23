import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"

// A list reordered by drag and drop (a day's plan on the split page, the cards of a logged
// workout), with a finger or a mouse, by each item's .drag-handle. Each item carries the address
// of its move (data-sortable-url). Dropping one in a new place sends it there as a Turbo form:
// the server saves the order and the page refreshes in place (morph) with the moved item lit up.
// A workout day's page has two such lists (group "day"): an item dropped in the other list is put
// back where it was at once, and its data-sortable-into-url (with -method, and -confirm to ask
// first) is sent, so a cancelled box or a refused drop leaves the page as it was.
export default class extends Controller {
  static values = { group: String, sort: { type: Boolean, default: true } }

  connect() {
    this.sortable = Sortable.create(this.element, {
      handle: ".drag-handle",
      draggable: "[data-sortable-url], [data-sortable-into-url]",
      animation: 150,
      sort: this.sortValue,
      // Only an item that has an address into the other list can be dropped there.
      group: this.hasGroupValue ? { name: this.groupValue, put: (_to, _from, item) => "sortableIntoUrl" in item.dataset } : undefined,
      onEnd: ({ item, from, to, oldIndex, oldDraggableIndex, newDraggableIndex }) => {
        if (from !== to) {
          from.insertBefore(item, from.children[oldIndex] || null)
          this.submit(item.dataset.sortableIntoUrl, item.dataset.sortableIntoMethod, newDraggableIndex + 1, item.dataset.sortableConfirm)
        } else if (oldDraggableIndex !== newDraggableIndex) {
          this.submit(item.dataset.sortableUrl, "patch", newDraggableIndex + 1)
        }
      }
    })
  }

  disconnect() {
    this.sortable.destroy()
  }

  submit(url, method, to, confirm) {
    const form = document.createElement("form")
    form.method = "post"
    form.action = url
    form.hidden = true
    if (confirm) form.dataset.turboConfirm = confirm
    // Dropped into the workout is adding to it: with the timer paused, it asks first (timer_alert_controller.js).
    if (method === "post") form.dataset.alertWhenPaused = "add"
    const token = document.querySelector("meta[name=csrf-token]")?.content
    for (const [name, value] of [["_method", method], ["authenticity_token", token], ["to", to]]) {
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
