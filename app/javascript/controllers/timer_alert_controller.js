import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

// While the workout's timer is paused, asks before the user carries on without it, so a paused
// timer is not forgotten (workout_logs/_timer_alert):
// - adding an exercise or a set (elements marked data-alert-when-paused="add"): keep it paused, or resume it?
// - leaving the workout page by a link of the app, except links inside [data-stays-in-workout]
//   (the workout's own exercises): keep it paused, or stop it?
// Whatever is answered, what was tapped then goes ahead; closing the box cancels it.
const REOPEN = "timer-alert-reopen"

export default class extends Controller {
  static targets = ["detail", "icon", "primary", "secondary"]
  static values = { paused: Boolean, leave: Boolean, url: String }

  connect() {
    this.click = this.click.bind(this)
    this.submit = this.submit.bind(this)
    // On window, in the capture phase: before Turbo, Bootstrap and the back button see the event.
    window.addEventListener("click", this.click, true)
    window.addEventListener("submit", this.submit, true)
    this.reopenPicker()
  }

  disconnect() {
    window.removeEventListener("click", this.click, true)
    window.removeEventListener("submit", this.submit, true)
  }

  click(event) {
    if (this.skip || !this.pausedValue) return

    const add = event.target.closest("button[data-alert-when-paused='add']")
    if (add) {
      // Resumed, the page reloads to show the running timer, then opens the "Add exercises" box again.
      return this.hold(event, "add", (resumed) => {
        if (!resumed) return this.again(() => add.click())
        sessionStorage.setItem(REOPEN, add.dataset.bsTarget)
        Turbo.visit(location.href, { action: "replace" })
      })
    }

    const link = event.target.closest("a[href]")
    if (link && this.leaving(link)) this.hold(event, "leave", () => this.again(() => link.click()))
  }

  submit(event) {
    const form = event.target
    if (this.skip || !this.pausedValue || !form.matches("[data-alert-when-paused='add']")) return

    const submitter = event.submitter
    this.hold(event, "add", () => this.again(() => form.requestSubmit(submitter)))
  }

  // The box's buttons
  choose({ params: { choice } }) {
    this.choice = choice
    window.bootstrap.Modal.getOrCreateInstance(this.element).hide()
  }

  // Stops the event, asks, does what was chosen (Resume or Stop), then carries on.
  hold(event, kind, carryOn) {
    event.preventDefault()
    event.stopImmediatePropagation()
    this.ask(kind).then(async (choice) => {
      if (!choice) return

      const acted = choice === "primary"
      if (acted) await this.send(kind === "add" ? "POST" : "DELETE")
      carryOn(acted)
    })
  }

  ask(kind) {
    const leaving = kind === "leave"
    this.detailTarget.textContent = leaving ? "Do you want to keep it paused, or stop it?" : "Do you want to keep it paused, or resume it?"
    this.primaryTarget.textContent = leaving ? "Stop timer" : "Resume"
    this.primaryTarget.className = `btn ${leaving ? "btn-danger" : "btn-primary"}`
    this.secondaryTarget.textContent = "Keep paused"
    // Stopping it is a stop; the box opens with the pause that explains why it asks.
    this.iconTarget.className = `fa-solid ${leaving ? "fa-stop" : "fa-pause"}`
    this.choice = null

    // Answered once the box has closed, so Turbo never caches the page with it open.
    return new Promise((resolve) => {
      this.element.addEventListener("hidden.bs.modal", () => resolve(this.choice), { once: true })
      window.bootstrap.Modal.getOrCreateInstance(this.element).show()
    })
  }

  // Resume (POST) or Stop (DELETE) the timer; its redirect is not followed.
  send(method) {
    const token = document.querySelector("meta[name='csrf-token']")?.content
    return fetch(this.urlValue, { method, headers: { "X-CSRF-Token": token }, redirect: "manual", credentials: "same-origin" })
  }

  // Repeats what was tapped, without asking again.
  again(action) {
    this.skip = true
    try { action() } finally { this.skip = false }
  }

  leaving(link) {
    if (!this.leaveValue || link.closest("[data-stays-in-workout], .modal")) return false
    if (link.target === "_blank" || link.hasAttribute("data-bs-toggle")) return false

    const url = new URL(link.href, location.href)
    return url.origin === location.origin && !(url.pathname === location.pathname && url.hash)
  }

  reopenPicker() {
    const target = sessionStorage.getItem(REOPEN)
    if (!target) return

    sessionStorage.removeItem(REOPEN)
    const picker = document.querySelector(target)
    if (picker) window.bootstrap.Modal.getOrCreateInstance(picker).show()
  }
}
