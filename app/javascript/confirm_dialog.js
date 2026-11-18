import { Turbo } from "@hotwired/turbo-rails"

// Every data-turbo-confirm opens the app's own box (shared/_confirm) instead of the browser's
// confirm(). The message is split at its first "?": the question is the title, the rest the
// detail ("Delete this split and its days?" / "Your logged workouts are kept."). The red button
// says the message's first word when it is Delete or Remove, otherwise "Yes".
//
// The answer is given only once the box has finished closing, so the page Turbo keeps in its
// cache (for the Back button) is never saved with the box still open.
Turbo.config.forms.confirm = (message) => {
  const element = document.getElementById("confirm-modal")
  if (!element) return Promise.resolve(window.confirm(message))

  const cut = message.indexOf("?") + 1
  const title = cut > 0 ? message.slice(0, cut) : message
  const detail = cut > 0 ? message.slice(cut).trim() : ""
  const verb = message.split(" ")[0]

  element.querySelector("[data-confirm-title]").textContent = title
  const detailElement = element.querySelector("[data-confirm-detail]")
  detailElement.textContent = detail
  detailElement.hidden = detail === ""
  const accept = element.querySelector("[data-confirm-accept]")
  accept.textContent = ["Delete", "Remove"].includes(verb) ? verb : "Yes"

  const modal = window.bootstrap.Modal.getOrCreateInstance(element)

  return new Promise((resolve) => {
    let accepted = false
    const onAccept = () => { accepted = true; modal.hide() }

    accept.addEventListener("click", onAccept)
    // Bootstrap focuses the box itself, not a button, so a stray Enter deletes nothing.
    element.addEventListener("hidden.bs.modal", () => {
      accept.removeEventListener("click", onAccept)
      resolve(accepted)
    }, { once: true })

    modal.show()
  })
}
