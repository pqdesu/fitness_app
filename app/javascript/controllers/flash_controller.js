import { Controller } from "@hotwired/stimulus"

// A flash message (shared/_flashes): leaves by itself after `delay` ms, or at once on its ×.
// It fades out (0.5 s) with the "is-leaving" class, then is removed from the page.
export default class extends Controller {
  static values = { delay: { type: Number, default: 5000 } }

  connect() {
    this.timeout = setTimeout(() => this.dismiss(), this.delayValue)
  }

  disconnect() {
    clearTimeout(this.timeout)
  }

  dismiss() {
    clearTimeout(this.timeout)
    if (this.element.classList.contains("is-leaving")) return

    this.element.classList.add("is-leaving")
    const remove = () => this.element.remove()
    // Only the card's own fade: the timer bar inside ends its animation at about the same moment,
    // and its animationend bubbles up here, which would cut the fade short.
    this.element.addEventListener("animationend", (event) => {
      if (event.target === this.element) remove()
    })
    // With reduced motion there is no animation, so no animationend: remove it anyway.
    setTimeout(remove, 600)
  }
}
