import { Controller } from "@hotwired/stimulus"

// Sends its form as soon as the page is on screen: the automatic workout timer presses Start when
// a workout opens. A POST from the open page, so a link Turbo prefetches on hover starts nothing,
// and not from the cached copy Turbo shows for a moment while the page reloads.
export default class extends Controller {
  connect() {
    if (document.documentElement.hasAttribute("data-turbo-preview")) return

    this.element.requestSubmit()
  }
}
