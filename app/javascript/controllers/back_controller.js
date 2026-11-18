import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"
import { takePreviousPage } from "back_trail"

// The back button (ApplicationHelper#back_to): goes to the page the user was on before, from the
// trail back_trail.js keeps. With no earlier page in this tab (a link opened directly), the link
// is followed as it is, to the page's parent.
export default class extends Controller {
  go(event) {
    if (event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return

    const previous = takePreviousPage()
    if (!previous) return

    event.preventDefault()
    Turbo.visit(previous)
  }
}
