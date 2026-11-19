# Design audit fixes

Branch `design-audit-fixes`. The session started on `claude/installed-skills-review-e2a46b`. When the fixes began, I renamed it `phone-logging-fixes`. When the P2 fixes widened the scope, I renamed it `design-audit-fixes`. Nothing had been pushed under either earlier name. The branch was moved onto `master` at `ba382d1` (PR #16, History table on a phone) before any commit.

## 1. Summary

This branch fixes everything the Impeccable **audit** of the whole app found, except one advisory (the Inter font), which was left to the owner. The audit scored the app 14/20 ("Good") and listed 3 P1, 5 P2 and 4 P3 issues. The branch fixes all 12:

- **P1:**
  - Deleting a set asks first.
  - Form fields are 16px, so an iPhone does not zoom into them.
  - The danger red passes WCAG AA contrast.
- **P2:**
  - Every button and field is 44px on a touch screen.
  - Error messages stay until closed, and notices pause while pointed at or focused.
  - The calendar is a table of cells, not a grid.
  - Google Fonts loads in parallel with the stylesheet, and Font Awesome brings only what the views use.
  - Every colour of the styles is named in `config/_colors.scss`.
- **P3:**
  - Devise pages have an `h1`.
  - No text is under 12px.
  - The calendar's days of other months pass contrast.
  - The landing page has no icon tile above its heading.
  - The logged workout's Details card stays in view on a wide screen.

State:

- **Checks:** all 87 tests pass (1153 assertions). Rubocop reports no offenses and Brakeman reports no warnings.
- **Browser:** the pages were checked in headless Chrome 158 at 390px and 360px with touch emulation, and at 1280px with a mouse. Impeccable's detector was run on the live pages.
- **Not done:** nothing was tried on a real phone.
- **Seed data:** the seed file was re-dumped and did not change.

## 2. Timeline

1. **"Check the new skills I have installed. Which skill from impeccable inspects the designs?"**
   - I listed the newly installed Impeccable skill (v4.10.0, in `~/.claude/skills/impeccable`) and its five helper agents.
   - My answer: `/impeccable critique` reviews the design, and `/impeccable audit` is the technical check.
2. **"run /impeccable audit in the whole app"**
   - I ran the audit: the detector over `app/views`, the stylesheets and the JavaScript, plus measurements of 14 signed-in pages at about 375px through the owner's Chrome.
   - Score 14/20. The report was saved under `.impeccable/audit/`, which is not committed.
3. **"I believe I installed Chrome on WSL can you please check if it was installed? If it was run the checks again"**
   - Chrome was not installed in WSL. I gave the install commands.
4. **"Failed to install check why"**
   - apt tried the Ubuntu server's IPv6 addresses first, and WSL has no IPv6 route. The IPv4 connections to `archive.ubuntu.com` also failed or crawled.
   - I gave a retry over IPv4 with retries. It worked, and Chrome 158 was installed.
5. **Rerun of the checks**
   - The detector scanned the public pages itself. For the signed-in pages, I signed in a headless Chrome on port 9222 and pointed the detector at it (`detect --cdp`), at 390px and 1280px.
   - Same score. It confirmed the red contrast and the calendar contrast, and added the landing icon tile and the uneven desktop columns.
   - A first attempt that scanned saved HTML copies was thrown away, because the stylesheet did not load in them.
6. **GitHub CLI key**
   - `apt update` showed `NO_PUBKEY 5612B36462313325` for `cli.github.com`. I gave the command to refresh the keyring, and the owner ran it. I confirmed that apt accepted the new index.
7. **"fix the three P1s using the impeccable skills"**
   - I followed the `harden`, `adapt` and `colorize` references (section 4.1).
8. **"I forgot to pull the latest version please check again, pull origin master and check"**
   - The owner's `master` was already at `ba382d1`. I did not touch the main folder.
   - I fetched and rebased this branch onto `origin/master`, keeping the uncommitted changes. One conflict in `pages/_workout_log.scss` was resolved by keeping both blocks.
   - I re-ran everything and re-checked in Chrome.
9. **"Now fix p2"**
   - I followed the `adapt`, `harden`, `optimize` and `extract` references (section 4.2).
10. **"so the fixes of P3 are also fixed?" / "Fix the P3s"**
    - No, the P3s had not been touched. I then fixed them (section 4.3).
11. **"Finalize the branch"**
    - This doc, the commit, the push and the pull request.

## 3. Starting point

The audit (rendered scans and source reading) found:

| Sev. | Issue | Where |
|---|---|---|
| P1 | A set's bin (28×30px) sat 4px from its pen (29×30px), with no confirm and no undo | `workout_sets/_set.html.erb` |
| P1 | Form fields were 15px (`$font-size-base: .9375rem`), and Safari on iPhone zooms into fields under 16px | `config/_bootstrap_variables.scss` |
| P1 | `$red` #E5484D as text: 3.91:1 on white, 3.65:1 on the page (AA asks 4.5:1). White on it was 3.91:1, so Bootstrap drew the confirm box's Delete button in black text | `config/_colors.scss` |
| P2 | Row icon buttons 25–30px wide, most buttons and fields 37px tall | everywhere |
| P2 | Every flash, errors included, left after 5 s with no pause | `flash_controller.js` |
| P2 | `role="grid"` on the calendar with no arrow-key navigation, and `role="gridcell"` on the links, which hid that they were links | `pages/_calendar.html.erb` |
| P2 | Google Fonts `@import`ed inside the stylesheet (it only starts after the stylesheet downloads); all of Font Awesome compiled in, brands included | `config/_fonts.scss`, `application.scss` |
| P2 | 12 colour literals and several rgba shadows outside the colour file; `$yellow` held a blue | components, pages |
| P3 | Devise pages start at `h2` | `app/views/devise/**` |
| P3 | 11.25–11.5px text (week summary labels, "kg", badges); days of other months at 2.1:1 | `_dashboard_week.scss`, Bootstrap badges, `_dashboard_calendar.scss` |
| P3 | 64px icon tile above the landing heading (detector: `icon-tile-stack`); Inter overused (advisory) | `pages/home.html.erb` |
| P3 | Desktop logged workout: the entries column is about 444% of the viewport tall, and Details ends at 46% | `workout_logs/show.html.erb` |

## 4. Changes

### 4.1 P1

**Deleting a set asks first** (`app/views/workout_sets/_set.html.erb`). The bin's `button_to` now carries the app's own confirm:

```erb
<%= button_to set_path, method: :delete, class: "btn btn-link btn-sm text-danger", "aria-label": "Delete set #{set.set_number}",
      form: { data: { turbo_confirm: "Delete set #{set.set_number}? #{weight_and_reps(set)}." } } do %>…
```

`confirm_dialog.js` splits the message at the "?", so the box reads **Delete set 1?** with "14 kg × 8 reps." under it, and a red **Delete** button. The test in `logging_flow_test.rb` checks the attribute.

**16px fields** (`config/_bootstrap_variables.scss`):

```scss
$input-font-size:        1rem;
$input-font-size-sm:     1rem;
```

This covers `.form-control`, `.form-control-sm` (the in-row set edit fields) and `.form-select`.

**Darker danger red** (`config/_colors.scss`): `$red` went from #E5484D to #CE2C31.

- As text, it reads 5.21:1 on white and 4.86:1 on the page background.
- White on it reads 5.21:1, so Bootstrap now draws the Delete button's text in white.
- Every `btn-outline-danger`, `text-danger`, `btn-danger` and the form error colour use it.

**Set table on a phone** (`pages/_workout_log.scss`). The bigger targets made a set being edited overflow the card, cutting off Cancel and the other rows' bins. That overflow already existed on `master`, by about 35px. Below 576px, the set table now:

- trims the side padding of its cells (number column `3.5rem` wide, first cell `1.25rem` from the card edge, last cell `.75rem`)
- lets the edit fields narrow to `3.5rem`

The note field in the edit bar is `width: 0; flex: 1`, so it only takes what Save and Cancel leave. "Add set" stays on one line at 360px (`.set-form .btn` with less padding and `nowrap`). That wrapping also existed before.

### 4.2 P2

**44px on touch** (`components/_layout.scss`, one rule for the app). This replaced the narrower rules first written in `_workout_log.scss` for P1:

```scss
@media (pointer: coarse) {
  .btn { --bs-btn-padding-y: .625rem; }
  .btn-sm { --bs-btn-padding-y: .7rem; min-width: 2.75rem; }
  .form-control, .form-select { min-height: 2.75rem; }
  .navbar-toggler { min-height: 2.75rem; }
  .back-link { width: 2.75rem; height: 2.75rem; }
}
```

- `_workout_log.scss` keeps only `.set-actions { gap: .5rem }` on touch, so the pen and the bin sit 8px apart.
- The flash × is `2.75rem` at all sizes (`components/_flash.scss`), since it is the only way to close an alert.

**Flash messages** (`app/javascript/controllers/flash_controller.js`, `app/views/shared/_flashes.html.erb`, `components/_flash.scss`):

- An **alert** renders with `data-flash-delay-value="0"` and no timer bar. The controller does not start a timer, so it stays until its × is pressed.
- A **notice** keeps 5 s, but its controller now has `pause`/`resume`, wired to `mouseenter`, `mouseleave`, `focusin` and `focusout`.
- `pause` stores the time left and adds `.is-paused`, which pauses the timer bar (`animation-play-state: paused`).
- `resume` restarts a timer for what is left, unless the pointer or the focus is still inside the card.
- `CLAUDE.md`'s line about flash messages was updated to describe this.

**Calendar** (`app/views/pages/_calendar.html.erb`):

- `role="grid"` → `role="table"`. Each day is now a `<div role="cell">` that holds the day: a link for a logged day, a span otherwise.
- Before, the link itself carried `role="gridcell"`, which replaced its link role.
- The dashboard test checks the table, rows and cells, and that no calendar element has `grid`, `gridcell` or a role on a link.

**Fonts and icons**:

- `config/_fonts.scss` no longer `@import`s Google Fonts. `layouts/application.html.erb` now has two `preconnect` links and the fonts `<link rel="stylesheet">` before the app's stylesheet.
- Measured in Chrome: the fonts stylesheet starts 3ms after the app's, instead of after it has downloaded.
- `config/initializers/content_security_policy.rb` already allowed both hosts; only its comment changed to say the layout links them.
- `application.scss` imports Font Awesome's functions, variables, mixins, core, icons, screen-reader, solid and regular partials, instead of the whole `font-awesome` bundle. Brands and the unused extras (animated, bordered-pulled, fixed-width, list, rotated-flipped, sizing, stacked) are gone. No view uses them.
- The development stylesheet went from 403 KB to 378 KB. All icons still render.

**Colours** (`config/_colors.scss`, then replaced in the files that used them):

| Name | Value | Used for |
|---|---|---|
| `$notice` | #3E63DD | was `$yellow`; Bootstrap's `$info` |
| `$surface-subtle` | #FAFBFC | table heads, card footers |
| `$line-strong` | #D5D9E0 | field borders, light button border on hover |
| `$icon-faint` | #B4BAC4 | empty state icon |
| `$shadow` | #101828 | every shadow, as `rgba($shadow, …)` |
| `$chip-bg` / `$chip-text` | #EEF0F3 / #3F4651 | plain chip |
| `$done-bg` / `$done-text` | #DDF3EE / #0B6B60 | chip of sets logged today |
| `$rest-bg` / `$rest-text` | #FFF1D6 / #8A5A00 | rest day chip |
| `$outside-day` | `$muted` | calendar days of other months (see 4.3) |

- The card hover shadow is `rgba($blue, .12)`, and the navbar is `rgba(white, .92)`.
- I checked the rendered values against the old ones (chip, table head, card footer, field border, navbar, card shadow), and they are identical.
- No hex or rgb literal is left in `components/`, `pages/` or the Bootstrap variables.

### 4.3 P3

**Devise headings**:

- The first heading of `sessions/new`, `registrations/new`, `registrations/edit`, `passwords/new`, `passwords/edit`, `confirmations/new` and `unlocks/new` is now `h1`.
- "Cancel my account" went from `h3` to `h2`.
- `pages/_auth.scss` styles `h1` as the old `h2` (1.5rem) and `h2` as the old `h3`. `#error_explanation h2` keeps no top margin.
- Tests in `accounts_flow_test.rb` check each title.

**12px floor**:

- `_dashboard_week.scss`: the `dt` labels go from `.72rem` to `.75rem`, and "kg" from `.7rem` to `.75rem`.
- `$badge-font-size: .8em` in the Bootstrap variables makes the Active and Admin badges 12px.

**Calendar days of other months** (`_dashboard_calendar.scss`):

- They use `$muted` at weight 400, which reads 5.36:1 on white and 4.74:1 on the current week's tinted row (#EEF0FF). Before, they were #A9AFB9 at 2.1:1.
- A logged one has a muted ring and number, and fills blue with white text when pointed at or focused. Before, it showed grey text on blue on hover.

**Landing** (`pages/home.html.erb`, `pages/_landing.scss`, `components/_navbar.scss`):

- The `brand-mark-lg` tile above the heading was removed, along with its now unused style. The heading's top margin went to 0.
- A test checks that the hero has no brand mark.

**Logged workout on a wide screen** (`workout_logs/show.html.erb`, `pages/_workout_log.scss`): the Details card has a `log-details` class and is `position: sticky; top: 5rem` from the `lg` breakpoint up. On phones, nothing changes.

## 5. Decisions

- **One darker red instead of a separate "red for text".**
  - Rejected: keeping #E5484D for fills and adding a text red. White on #E5484D also failed (3.91:1), so the Delete button would still fail.
- **Touch targets by `(pointer: coarse)`, not by screen width.** This follows the adapt reference: a mouse keeps Bootstrap's compact sizes, and any touch screen gets 44px.
  - Rejected: per-component rules (P1's first version). The single rule replaced them.
- **Buttons grow by padding, not `min-height`.** With padding, the text stays vertically centred in the inline-block buttons. `min-height` would have needed `display: inline-flex` on every `.btn`.
- **Alerts never auto-close; notices pause.**
  - Rejected: a longer timer for alerts. A timed error can still be missed.
- **A table of cells rather than a real `<table>`, or keyboard grid navigation.** This is the smallest change that stops promising arrow keys, and it keeps the CSS grid layout.
  - Rejected: adding arrow-key navigation, which would be JavaScript the owner did not ask for.
- **Font Awesome not cut down to the ~17 icons used.**
  - Its solid font is 155 KB, downloaded once and then cached.
  - A subset font would make any icon added later show blank with no warning.
  - Only the CSS parts no view uses were dropped. Assumption: no view or helper uses the brands style or the dropped extras. I checked this by searching `app/`.
- **Inter kept.** The detector calls it overused. Changing the app's font is a brand choice for the owner, who agreed to leave it.
- **Colour names by role**, kept in the one colour file the project already has.
  - Rejected: leaving single-use page colours local. The audit asked for one place.
- **Days of other months use `$muted`** rather than a new grey, with a lighter weight to stay secondary.
- **Sticky Details card** rather than moving Details above the entries. On a phone, Details stays where it was.

## 6. How it works now

- **Logging at the gym (phone):**
  - Every button and field is at least 44px, and fields are 16px, so the page should not zoom.
  - A set's pen and bin are 44×44, 8px apart. The bin opens "Delete set N?" with the set's weight and reps. Cancel keeps the set.
  - Editing a set in place fits in the card at 360px and 390px.
- **Messages:**
  - A green notice leaves after 5 s, and waits while pointed at or focused, its timer bar paused.
  - A red alert stays until its × (44px) is pressed.
- **Dashboard calendar:** a table of rows and cells; logged days are links inside their cells. Days of other months are readable but lighter.
- **Logged workout on a desktop:** the Details card stays in view while scrolling the exercises.
- **Colours:** change them in `config/_colors.scss`. Bootstrap's own variables are in `config/_bootstrap_variables.scss`.

To try it:

```bash
bin/rails server -p 3001 -b 0.0.0.0
```

Open it on a phone on the same network at `http://<your PC's IP>:3001`. Under WSL the port may need to be forwarded from Windows.

## 7. Tests and verification

**Run:**

- `bin/rails test`: 87 runs, 1153 assertions, 0 failures.
  - New or changed assertions: the set delete confirm (`logging_flow_test.rb`), the calendar's table and cell roles (`dashboard_flow_test.rb`), each Devise page's `h1` and the hero without a tile (`accounts_flow_test.rb`).
- `bundle exec rubocop`: no offenses. Tests are excluded by `.rubocop.yml`.
- `bundle exec brakeman`: no warnings.
- `bin/rails test test/lib/seed_data_test.rb`: passes after the dump.

**Checked in the browser** (headless Chrome 158 from WSL, signed in as the seed admin, against a server from this worktree on port 3001; the server shares the development database):

- **390px, touch:**
  - Every page has no sideways scroll.
  - The sweep found no `.btn`, `.form-control` or `.form-select` under 44px on Dashboard, Splits, a split, a workout day, an exercise, History, a logged workout, Exercises, Users, Account and New split.
  - No text is under 12px on Dashboard, Splits and Users.
- **Set table:** at 390px and 360px, with and without a set being edited, the table width equals the card's.
- **Delete set confirm:** opened through `Turbo.config.forms.confirm` and cancelled. No set was deleted (27 sets before and after).
- **Flash:** a notice pointed at after 1.3 s was still there at 7 s, and left 3–4.5 s after the pointer moved away. An alert was still there at 7 s and closed with ×. These were injected copies of the partial's markup, not real server flashes.
- **Fonts:** the fonts stylesheet starts 3ms after the app's. Inter, Plus Jakarta Sans and Font Awesome solid load, and icons render.
- **Colours:** the computed values of the renamed colours match the old ones.
- **Desktop (1280px):** the Details card has `position: sticky` and stays at 80px from the top at scroll 1200 and 2400.
- **Detector, live pages:**
  - No low-contrast finding left anywhere. Before, there were 5 pages with the red and the dashboard with the calendar.
  - No `icon-tile-stack` on the landing page.
  - Left:
    - `overused-font` (Inter, kept on purpose)
    - a `straggler` advisory on Exercises (a short last line of text, unchanged)
    - `first-viewport-column-overflow` on the logged workout at desktop width. The detector compares column heights and does not account for the sticky card.

**Not verified:**

- **Nothing on a real phone.** The iPhone zoom fix rests on the measured 16px.
- **Touch only in Chrome's emulation.** Touch was Chrome's emulation (`Emulation.setTouchEmulationEnabled`), which is not Safari.
- **No screen reader.** The calendar's new roles were not tried with one.

## 8. Every file changed (38)

Styles, config (5):

- `app/assets/stylesheets/application.scss`: Font Awesome imported part by part, without brands and unused extras.
- `app/assets/stylesheets/config/_bootstrap_variables.scss`: 16px fields, 12px badges, `$info: $notice`, `$input-border-color: $line-strong`.
- `app/assets/stylesheets/config/_colors.scss`: darker `$red`, `$notice` instead of `$yellow`, and the named neutrals, chip and calendar colours.
- `app/assets/stylesheets/config/_fonts.scss`: no more `@import` of Google Fonts; a note pointing to the layout.
- `config/initializers/content_security_policy.rb`: comment now says the layout links the fonts.

Styles, components (8):

- `components/_cards.scss`: shadows and footer use named colours.
- `components/_confirm.scss`: shadow uses `$shadow`.
- `components/_empty_state.scss`: icon uses `$icon-faint`.
- `components/_flash.scss`: 44px ×, paused timer bar, shadows use `$shadow`.
- `components/_layout.scss`: the 44px touch rule; back link shadow and light button border use named colours.
- `components/_lists.scss`: chips use named colours.
- `components/_navbar.scss`: `rgba(white, .92)`; unused `.brand-mark-lg` removed.
- `components/_tables.scss`: table head uses `$surface-subtle`.

(The paths above are under `app/assets/stylesheets/`.)

Styles, pages (5):

- `pages/_auth.scss`: `h1` and `h2` styles for the Devise pages; error heading margin.
- `pages/_dashboard_calendar.scss`: days of other months in `$muted`, with a logged one's ring and hover.
- `pages/_dashboard_week.scss`: labels and "kg" at 12px.
- `pages/_landing.scss`: heading without top margin.
- `pages/_workout_log.scss`: "Add set" on one line, note field width, pen and bin gap on touch, phone set table padding, sticky Details on wide screens. History rules from `master` are kept.

JavaScript (1):

- `app/javascript/controllers/flash_controller.js`: alerts stay; notices pause and resume.

Views (14):

- `app/views/devise/confirmations/new.html.erb`, `passwords/edit.html.erb`, `passwords/new.html.erb`, `registrations/new.html.erb`, `sessions/new.html.erb`, `unlocks/new.html.erb`: title is `h1`.
- `app/views/devise/registrations/edit.html.erb`: title `h1`, "Cancel my account" `h2`.
- `app/views/layouts/application.html.erb`: preconnect and Google Fonts links.
- `app/views/pages/_calendar.html.erb`: table, row and cell roles; links inside cells.
- `app/views/pages/home.html.erb`: landing without the icon tile.
- `app/views/shared/_flashes.html.erb`: alerts with no delay and no timer bar; pause and resume actions.
- `app/views/workout_logs/show.html.erb`: `log-details` class on the Details card.
- `app/views/workout_sets/_form.html.erb`: `set-form` class.
- `app/views/workout_sets/_set.html.erb`: confirm before deleting a set.

Tests (3):

- `test/integration/accounts_flow_test.rb`: landing without a tile; Devise `h1` titles and the account page `h2`.
- `test/integration/dashboard_flow_test.rb`: calendar table, rows and cells, no grid roles.
- `test/integration/logging_flow_test.rb`: set delete confirm.

Docs (2):

- `CLAUDE.md`: the flash messages line describes notices and alerts.
- `doc/design-audit-fixes.md`: this file.

`doc/Features/Features.md` and `doc/Issues/Issues.md` are not changed: no item on either list is finished by this branch. `db/seeds/data.yml` is not changed: `bin/rails seed:dump` wrote the same file (1 user, 3 splits, 3 workouts, 47 sets).

## 9. Known gaps

- **Real devices not tested.** Needs a real iPhone (zoom, 44px, the confirm) and an Android phone.
- **Screen reader not tested** with the new calendar roles.
- **Font Awesome's solid font is still 155 KB** (see Decisions).
- **Inter is still the main font** (owner's choice).
- **Two detector advisories remain:** the `straggler` advisory on Exercises, and the desktop `first-viewport-column-overflow` on the logged workout (see section 7).
- **The two open issues in `Issues.md` are not addressed** ("Future workout logs have present days logged" and "Dropdowns past visible screen").
- **The calendar's day circles (36px) and the split's week circles (43px wide)** are under 44px. They fit seven to a row at 390px, and pass WCAG 2.5.8 AA (24px).
