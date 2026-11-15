// Tells the server which time zone the browser is in, so dates ("today", this week, this month)
// follow the user's own clock. The server reads the cookie on every request.
//
// When the page was rendered for a different zone than the browser's, the cookie is set and the
// page is loaded again once, so even the first visit shows the user's own date.
const COOKIE = "time_zone"

function storedZone() {
  const entry = document.cookie.split("; ").find((part) => part.startsWith(`${COOKIE}=`))
  return entry ? decodeURIComponent(entry.slice(COOKIE.length + 1)) : null
}

function syncTimeZone() {
  const zone = Intl.DateTimeFormat().resolvedOptions().timeZone
  if (!zone || zone === document.body.dataset.timeZone) return
  // Already reported: the server does not know this zone (or names it differently). Do not loop.
  if (storedZone() === zone) return

  document.cookie = `${COOKIE}=${encodeURIComponent(zone)}; path=/; max-age=31536000; samesite=lax`
  // Only reload if the cookie was accepted, and never a page that came from a form submission.
  if (storedZone() === zone && document.body.dataset.reloadable === "true") window.location.reload()
}

document.addEventListener("turbo:load", syncTimeZone)
