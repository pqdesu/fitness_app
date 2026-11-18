// The pages this tab has visited, so the back button (back_controller.js) returns to the page the
// user was really on, not to a fixed parent. It lives in sessionStorage: one trail per tab, gone
// when the tab closes.
//
// Every page load (a link, a form's redirect, the browser's own Back) updates the trail:
// - the same page again (a reload, or a form that redirects to its own page) changes nothing;
// - the page before the current one (the browser's Back, or a link to it) steps back to it;
// - any other page is added at the end.
// A page is "skipped" when it is a form (new, edit: body data-back-skip): after saving, back goes
// past the form, not into it. Deleting the record a page shows takes that page out of the trail.
const KEY = "back-trail"
const LIMIT = 50

function here() {
  return window.location.pathname + window.location.search
}

function read() {
  try {
    return JSON.parse(window.sessionStorage.getItem(KEY)) || []
  } catch {
    return []
  }
}

function write(trail) {
  try {
    window.sessionStorage.setItem(KEY, JSON.stringify(trail.slice(-LIMIT)))
  } catch {
    // Storage blocked (private mode): the back button falls back to its fixed parent link.
  }
}

function record() {
  const trail = read()
  const url = here()
  const skip = document.body.dataset.backSkip === "true"
  const last = trail.length - 1

  if (trail[last]?.url === url) {
    trail[last].skip = skip
  } else if (trail[last - 1]?.url === url) {
    trail.pop()
  } else {
    trail.push({ url, skip })
  }
  write(trail)
}

// A delete sent from the page of the record it deletes (Delete workout, Delete split): that page
// is gone, so it leaves the trail, edit pages included.
function forgetDeleted(event) {
  const form = event.target
  const method = form.querySelector("input[name=_method]")?.value || form.method
  if (method.toLowerCase() !== "delete") return

  const deleted = new URL(form.action, window.location.href).pathname
  if (deleted !== window.location.pathname) return

  write(read().filter(({ url }) => {
    const path = url.split("?")[0]
    return path !== deleted && !path.startsWith(`${deleted}/`)
  }))
}

// The page the back button leads to, or null when this tab has none (a page opened directly).
// The trail is cut back to it, so arriving there is not counted as a new page.
export function takePreviousPage() {
  const trail = read()
  const current = here()
  for (let index = trail.length - 1; index >= 0; index--) {
    const { url, skip } = trail[index]
    if (url !== current && !skip) {
      write(trail.slice(0, index + 1))
      return url
    }
  }
  return null
}

document.addEventListener("turbo:load", record)
document.addEventListener("turbo:submit-start", forgetDeleted)
