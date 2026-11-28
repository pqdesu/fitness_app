import { Controller } from "@hotwired/stimulus"

// A flash message (shared/_flashes). A notice leaves by itself after `delay` ms, and waits while
// the pointer is on it or focus is inside it, so it can be read or closed. An alert (delay 0) stays until its × is pressed: an error is not
// missed. Either way it fades out (0.2 s) with the "is-leaving" class, then is removed from the page.
export default class extends Controller {
  static values = { delay: { type: Number, default: 5000 } }

  connect() {
    if (this.delayValue <= 0) return

    this.remaining = this.delayValue
    this.resume()
  }

  disconnect() {
    clearTimeout(this.timeout)
  }

  pause() {
    if (!this.timeout) return

    clearTimeout(this.timeout)
    this.timeout = null
    this.remaining -= Date.now() - this.startedAt
    this.element.classList.add("is-paused")
  }

  // Not while the pointer is still on the card or focus is still inside it (leaving one but not the other).
  resume(event) {
    if (this.timeout || this.remaining === undefined || this.element.classList.contains("is-leaving")) return
    if (event?.type === "focusout" && (this.element.contains(event.relatedTarget) || this.element.matches(":hover"))) return
    if (event?.type === "mouseleave" && this.element.contains(document.activeElement)) return

    this.element.classList.remove("is-paused")
    this.startedAt = Date.now()
    this.timeout = setTimeout(() => this.dismiss(), Math.max(this.remaining, 0))
  }

  dismiss() {
    clearTimeout(this.timeout)
    if (this.element.classList.contains("is-leaving")) return

    this.element.classList.add("is-leaving")
    const remove = () => this.element.remove()
    this.element.addEventListener("animationend", remove)
    // With reduced motion there is no animation, so no animationend: remove it anyway.
    setTimeout(remove, 250)
  }
}
