import { Controller } from "@hotwired/stimulus"

// While a rest timer runs (workout_sets/_rest_alert), asks before (owner, 2026-11-22):
// - adding a set to that exercise (its form carries data-rest-url): save the rest until now
//   (Stop), or no rest (throw it away)? Then the set is added.
// - leaving the page by a link of the app: stop the rest (then leave), or go back to the page?
// Closing the box cancels. It sits beside the paused-timer alert (timer_alert_controller.js):
// whichever asks first repeats the action, and the other then asks in turn, each only once.
export default class extends Controller {
  static targets = ["title", "detail", "primary", "secondary"]

  connect() {
    this.click = this.click.bind(this)
    this.submit = this.submit.bind(this)
    // On window, in the capture phase: before Turbo and the back button see the event.
    window.addEventListener("click", this.click, true)
    window.addEventListener("submit", this.submit, true)
  }

  disconnect() {
    window.removeEventListener("click", this.click, true)
    window.removeEventListener("submit", this.submit, true)
  }

  submit(event) {
    const form = event.target
    if (!form.dataset.restUrl) return

    const submitter = event.submitter
    this.hold(event, {
      title: "Your rest timer is running",
      detail: "Save the rest until now, or no rest for this set?",
      primary: "Save rest", secondary: "No rest"
    }, async (choice) => {
      await this.send(form.dataset.restUrl, choice === "primary" ? "PATCH" : "DELETE")
      form.requestSubmit(submitter)
    })
  }

  click(event) {
    const link = event.target.closest("a[href]")
    if (!link || !this.leaving(link)) return

    const running = [...document.querySelectorAll("[data-rest-running]")].map((element) => element.dataset.restRunning)
    if (running.length === 0) return

    this.hold(event, {
      title: "Did you forget to stop your rest timer?",
      detail: "Stop it before you go, or go back to the page.",
      primary: "Stop rest", secondary: "Back to page"
    }, async (choice) => {
      if (choice !== "primary") return

      await Promise.all(running.map((url) => this.send(url, "PATCH")))
      link.click()
    })
  }

  // The box's buttons
  choose({ params: { choice } }) {
    this.choice = choice
    window.bootstrap.Modal.getOrCreateInstance(this.element).hide()
  }

  hold(event, text, carryOn) {
    event.preventDefault()
    event.stopImmediatePropagation()
    this.titleTarget.textContent = text.title
    this.detailTarget.textContent = text.detail
    this.primaryTarget.textContent = text.primary
    this.secondaryTarget.textContent = text.secondary
    this.choice = null

    // Answered once the box has closed, so Turbo never caches the page with it open.
    this.element.addEventListener("hidden.bs.modal", () => { if (this.choice) carryOn(this.choice) }, { once: true })
    window.bootstrap.Modal.getOrCreateInstance(this.element).show()
  }

  // Stop (PATCH) or throw away (DELETE) the rest; its redirect is not followed. The page then
  // forgets that rest, so repeating the tap (here, or after the paused-timer alert asks) does not ask again.
  async send(url, method) {
    const token = document.querySelector("meta[name='csrf-token']")?.content
    await fetch(url, { method, headers: { "X-CSRF-Token": token }, redirect: "manual", credentials: "same-origin" })
    document.querySelectorAll(`[data-rest-url="${url}"]`).forEach((element) => delete element.dataset.restUrl)
    document.querySelectorAll(`[data-rest-running="${url}"]`).forEach((element) => delete element.dataset.restRunning)
  }

  leaving(link) {
    if (link.closest(".modal") || link.target === "_blank" || link.hasAttribute("data-bs-toggle")) return false

    const url = new URL(link.href, location.href)
    return url.origin === location.origin && !(url.pathname === location.pathname && url.hash)
  }
}
