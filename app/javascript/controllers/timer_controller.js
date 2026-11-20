import { Controller } from "@hotwired/stimulus"

// Counts up from a saved moment, as 0:42:13, plus an offset in seconds; nothing is saved while it
// counts. The workout timer (workout_logs/_timer) uses it twice: running, from the start less the
// time paused (offset -paused_seconds); paused, from the pause plus the earlier pauses (offset
// paused_seconds), so the paused time goes up while the recorded time stands still.
export default class extends Controller {
  static values = { start: String, offset: Number }

  connect() {
    this.tick()
    this.interval = setInterval(() => this.tick(), 1000)
  }

  disconnect() {
    clearInterval(this.interval)
  }

  tick() {
    const seconds = Math.max(0, Math.floor((Date.now() - Date.parse(this.startValue)) / 1000) + this.offsetValue)
    const pad = (n) => String(n).padStart(2, "0")
    this.element.textContent = `${Math.floor(seconds / 3600)}:${pad(Math.floor(seconds / 60) % 60)}:${pad(seconds % 60)}`
  }
}
