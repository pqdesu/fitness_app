import { Turbo } from "@hotwired/turbo-rails"

// Every data-turbo-confirm opens the app's own box (shared/_confirm) instead of the browser's
// confirm(). The message is split at its first "?": the question is the title, the rest the
// detail ("Delete this split and its days?" / "Your logged workouts are kept."). The first word
// picks the icon and the button: Delete (trash, red), Remove (x, red), Stop (stop, blue), else "Yes" (blue).
//
// The answer is given only once the box has finished closing, so the page Turbo keeps in its
// cache (for the Back button) is never saved with the box still open.
const LOOKS = {
  Delete: { icon: "fa-trash-can", button: "btn-danger" },
  Remove: { icon: "fa-xmark", button: "btn-danger" },
  Stop: { icon: "fa-stop", button: "btn-primary" },
  other: { icon: "fa-circle-question", button: "btn-primary", text: "Yes" }
}

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
  const look = LOOKS[verb] || LOOKS.other
  accept.textContent = look.text || verb
  accept.className = `btn ${look.button}`
  const icon = element.querySelector("[data-confirm-icon]")
  icon.classList.toggle("is-neutral", look.button !== "btn-danger")
  icon.querySelector("i").className = `fa-solid ${look.icon}`

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
