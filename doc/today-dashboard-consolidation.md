# Today and Dashboard become one Home page

Branch: `today-dashboard-consolidation` (created as `claude/today-dashboard-consolidation-5f7cbc`, renamed before anything was pushed).

## 1. Summary

The app had two pages that showed almost the same thing: **Today** (`/`, the first tab) and the **Dashboard** (`/dashboard`). This branch merges them into one **Home** page at `/`, with everything both pages had. The phone's bottom bar goes from five tabs to four (Home, Splits, History, Account). `/dashboard` now redirects to `/`.

The branch also fixes what an impeccable audit of the merged page found:
- the rest day text losing its styles while its fold animates
- the browser's default (orange) focus ring on every Show/Hide toggle
- a skipped heading level
- the Cardio tile breaking its time over two lines

State: all 155 tests pass, rubocop and brakeman report nothing. The page was checked in headless Chrome at 390 px and 1280 px, on a rest day only.

## 2. Timeline

1. **"Read the latest feature … plan how to implement it"** (with the `plan-features` skill). I read the feature from `doc/Features/Features.md` and the code of both pages, and wrote a plan with five open questions. Nothing was changed.
2. **"Yes, build it"**, then the owner's answers:
   1. Home, with the home icon
   2. phone order: Today box, active split, calendar, Recent workouts
   3. heading "Today" (above the date)
   4. "make it retractable like other boxes to display the options for the rest day"
   5. rename the branch

   I built the page, updated the tests that checked for two pages, checked the page at 390 px and desktop width, and updated CLAUDE.md and `Issues.md`.
3. **The owner's screen recording: "When I open the text looks weird. Please use impeccable and ui-ux pro skills to audit the current home page and fix all the issues it encounters."** I read the video frame by frame (played in headless Chrome, since ffmpeg is not installed), ran the impeccable audit (16/20) and fixed four issues. There is no "ui-ux pro" skill in this environment, so only impeccable was used.
4. **"Yes, make them bigger"** (the audit's touch-target finding). Measured again with touch emulation: the buttons are already 44 px on a touch screen (an existing `(pointer: coarse)` rule). Only with a mouse are they 30 px. The audit finding was wrong for a phone. The owner chose **"Leave them"**, so nothing changed.
5. **"finalize the branch"**: this document, the feature and issue lists, the seed data, the commit, push and pull request.

## 3. Starting point

- `/` (`pages#home`) rendered `pages/today.html.erb`, the **Today page**, which held:
  - the date as the heading
  - the Today box with the rest day choices already open (`open: true`)
  - a "This week" card (week strip, Move a workout, Back to the plan)
  - the pop-ups
  - all in a narrow 40 rem column
- `/dashboard` (`pages#dashboard`) rendered `pages/dashboard.html.erb`, the **Dashboard**, which held:
  - "Dashboard / Ready to train?" as the heading, with an Exercises button on a phone
  - the calendar
  - the active split card (week strip, moves, This week overview)
  - the Today box (dated, rest day choices behind a "Start workout" button)
  - Recent workouts
- Both pages were built from the same `Dashboard` object and the same partials (`_today_box`, `splits/_week`, `_week_moves`, `_today_popups`). The Today page was a subset of the Dashboard.
- Nav: Today (`calendar-day` icon) and Dashboard (`house` icon) were separate tabs.
- Two open "Potential issues" came from having two pages:
  - deleting a workout opened from Today returned to the dashboard
  - a week move without a Referer landed on Today even when made on the dashboard

## 4. Changes

### Routes and controller
- `config/routes.rb`:
  - Before: `get "dashboard", to: "pages#dashboard"`.
  - After: `get "dashboard", to: redirect("/")`, so old links, bookmarks and the back button's saved trail (`back_trail.js`, which keeps visited paths in sessionStorage) still land on Home.
  - `/dashboard/month` (`dashboard_month_path`) is unchanged.
- `PagesController`:
  - Before: `home` rendered `:today`, and a separate `dashboard` action built the same `Dashboard`.
  - After: `home` renders `:dashboard`, and the `dashboard` action is removed.

### The page (`app/views/pages/dashboard.html.erb`)
- **Heading:** the eyebrow "Today" and the date as `h1` (the Today page's heading), with the Dashboard's phone-only Exercises button kept.
- **Layout:** one Bootstrap row:
  - `col-lg-7 order-lg-2`: the Today box (`dated: false`, since the heading has the date), then the active split card.
  - `col-lg-5 order-lg-1`: the calendar.
  - `col-lg-7 offset-lg-5 order-lg-3`: Recent workouts.

  On a phone (no `lg`) the source order gives Today box, split card, calendar, Recent workouts. From desktop width the calendar is the left column, Today and the split card the right one, and Recent workouts sits under the right column.
- `pages/today.html.erb` is deleted. The Today page's "This week" card was the active split card without its overview, so nothing of it is lost.

### Rest day choices fold (`app/views/pages/_today_box.html.erb`)
- Before:
  - On the Dashboard, a primary "Start workout" button in the box's header toggled the collapse.
  - On the Today page, the choices were always open (`open: true`, no button).
- After:
  - The choices sit in a collapse closed by default, opened by the shared "Show workouts / Hide workouts" toggle (`shared/_list_toggle`), the same control as "Show days" and "Show exercises".
  - The header's "Start workout" button for rest days is removed; the Cardio button stays.
  - The `open` local is gone.
- The collapse carries its own class, `rest-day-choices` (see the audit fix below).
- The two `today-title` headings went from `h3` to `h2`.

### Nav (`app/helpers/application_helper.rb`)
- `nav_sections`: the Today and Dashboard entries become one: `["Home", root_path, "house", controller_name == "pages" || todays_workout_page? || (phone && controller_name == "exercises")]`.
  - Today's workout pages still light Home, as they lit Today.
  - On a phone, Exercises (reached from the Home page's button) lights Home, as it lit Dashboard.
  - The unused `page` local is gone.
- `PAGE_TITLES`: `"pages#home" => "Today", "pages" => "Dashboard"` becomes `"pages" => "Home"`, so both `/` and the month page are titled "Home" in the phone's top bar.

### Links that went to the dashboard now go to Home
- `SplitsController#activate` (from "Change"): `redirect_to root_path`.
- `WorkoutLogsController#destroy` with `?from=dashboard`: `redirect_to root_path`.
- `splits/index`, `workout_logs/index` (a calendar day's list) and `pages/month`: `back_to root_path`.
- `?from=dashboard` keeps its name. It now means "opened from Home". Renaming it would have touched every link and test for no change in behaviour.

### Audit fixes
- **Text glitch while the fold opens** (`pages/_dashboard_rest_day.scss`):
  - Before: `.today .collapse > .today-last { … }`. While Bootstrap animates a collapse it replaces `.collapse` with `.collapsing`, so for about 0.35 s the text lost its small size, grey and padding, and showed big, dark and flush to the card's edge. This is what the owner's recording shows.
  - After: `.rest-day-choices > .today-last { … }`.
  - Checked: 120 ms into the animation the text is 12.8 px, padded 20 px, `#646B78`.
- **Focus ring** (`components/_list_toggle.scss`): `.toggle-days` (every Show/Hide toggle in the app) had no focus style, so it showed the browser's default ring, which takes the system's accent colour (orange in the recording). Now it has `&:focus { outline: 0 }` and `&:focus-visible { outline: 2px solid $blue; outline-offset: 2px; border-radius: .25rem }`: the app's blue, and only for keyboard focus.
- **Heading level:** the page went `h1` → `h3` once the Today box came first. `today-title` is now `h2`. The impeccable detector no longer reports it.
- **Cardio tile** (`pages/_summary_tiles.html.erb`, `pages/_dashboard_week.scss`): the Cardio tile gets `week-summary-wide` (`grid-column: span 2`), so "45 min 50 s" stays on one line on a phone instead of "45 min / 50 s" beside an empty half row. This also applies on the month page, which shares the partial.

### Comments and docs
- Comments that named the Today page or the dashboard were updated in:
  - `routes.rb`
  - `PagesController`, `ApplicationController`, `SplitsController`, `WorkoutLogsController`
  - `application_helper.rb`
  - `pages/home.html.erb` and `_today_box.html.erb`
  - `_dashboard_today.scss`, where the unused `.today-page` rule was removed
- CLAUDE.md's code map:
  - the week strip takes `states:` on the Home page only
  - only the Home page passes `plan:`
  - a new line describes the Home page (order, `/dashboard` redirect, one Home tab, what `?from=dashboard` means)
  - the Today box line points at `pages/_today_box`
  - the rest day panel folds behind "Show workouts"

## 5. Decisions

- **Merge into the Dashboard's view, not the Today page's.** The Dashboard already held everything the Today page had, so the merge was mostly deleting one page and taking three things from it: the heading, `dated: false`, and the Today box first.
- **`/dashboard` redirects instead of serving the same page.** One URL for one page, so tab highlighting and back links have a single answer.
  - Rejected: keeping `/dashboard` as an alias. Fewer test edits, but two URLs for one page.
  - Rejected: removing the route. Old links and the sessionStorage back trail would 404.
- **Tab name "Home", house icon:** the owner's answer 1.
- **Phone order Today → split → calendar → Recent:** the owner's answer 2. Doing it with one Bootstrap row and `order-lg-*` / `offset-lg-5` keeps the desktop's left calendar column without duplicating markup.
- **Heading "Today" + date:** the owner's answer 3, replacing "Dashboard / Ready to train?".
- **Rest day choices fold behind "Show workouts":** the owner's answer 4, "retractable like other boxes". The shared toggle is the control the other boxes use. The old header "Start workout" button, which toggled the same panel on the Dashboard, was removed so the panel has one control rather than two.
- **Kept the page's eyebrow labels** ("Today", "Active split"), although impeccable's craft floor bans eyebrows. They are an app-wide pattern, and the owner chose "Today".
- **Kept Inter**, which the detector flags as an overused font. It is the app's chosen font, and the request was a fix, not a redesign.
- **Did not enlarge the buttons:** they are already 44 px on touch screens. The owner chose to leave the mouse size.
- **Kept the `from=dashboard` parameter name** (see Changes).
- **Assumption:** the month page's phone title becomes "Home", like its tab, rather than "Month".

## 6. How it works now

- Signed out, `/` is the landing page as before. Signed in, `/` is Home:
  - "Today" and the date
  - the Today box:
    - a workout day: the workout's name, "Start workout" or "Continue", today's sets or last time's
    - a rest day: the Cardio button, what was logged today, and "Show workouts", which opens the split's workouts (each with its Move to today / Train as extra pop-up) and the other fixed workouts
  - the active split card (week strip, Move a workout, Back to the plan, This week, Change)
  - the calendar, with Month
  - Recent workouts
- `/dashboard` → 301 redirect to `/`. `/dashboard/month` is unchanged; its back arrow falls back to `/`.
- Nav:
  - phone: Home, Splits, History, Account
  - desktop: Home, Splits, History, Exercises

  Home is lit on `/`, the month page, today's workout pages, and Exercises on a phone.
- To try it: `bin/rails server -p 3005` from this branch, sign in, open `/`.

## 7. Tests and verification

- `bin/rails test`: 155 runs, 2161 assertions, 0 failures, 0 errors.
- `bundle exec rubocop`: no offenses. `bundle exec brakeman`: no warnings.
- `bin/rails test test/lib/seed_data_test.rb`: 4 runs, 0 failures.
- Tests changed:
  - Most edits are `get dashboard_path` → `get root_path` and `assert_redirected_to` / `back-link` expectations from `dashboard_path` to `root_path`, in:
    - `dashboard_flow_test`
    - `week_moves_flow_test`
    - `cardio_flow_test`
    - `splits_flow_test`
    - `navigation_flow_test`
  - Assertions that checked for two pages were changed, as listed in the plan the owner approved:
    - the tab lists (`%w[Home Splits History Account]` on a phone, `%w[Home Splits History Exercises]` on desktop) and the per-page title/tab table
    - the date as the page's `h1` rather than the box's eyebrow, with no eyebrow in the box
    - the Today box before the split card (`.card.today:has(+ .split-card.is-active)`)
    - the month page lighting "Home"
    - the rest day panel closed behind a "Show workouts" toggle, with no header button
  - Added: `get "/dashboard"` redirects to `root_path`.
- Browser:
  - Headless Chrome (WSL), driven over the DevTools protocol, because the chrome-devtools tool did not connect and the Chrome extension was not reachable. Signed in as the seeded development admin.
  - At 390 px: order Today box → split → calendar → Recent, no horizontal scroll, and the four tabs with Home lit.
  - At 1280 px: calendar left; Today, split and Recent right.
  - "Show workouts" opens to "Hide workouts" with the choices, and the text is styled mid-animation.
  - Keyboard focus shows the blue ring.
  - The impeccable detector reports only the font.
  - Buttons measured 44 px with touch emulation and 30 px with a mouse.
- **Not verified:**
  - a day with a planned workout in the browser (the development data's Tuesday is a rest day)
  - a user with no split
  - a real phone

## 8. Every file changed (27)

App:
- `config/routes.rb`: `/dashboard` redirects to `/`; comments.
- `app/controllers/pages_controller.rb`: `home` renders the merged view; `dashboard` action removed.
- `app/controllers/application_controller.rb`: comment on `from_dashboard?`.
- `app/controllers/splits_controller.rb`: "Change" returns to Home.
- `app/controllers/workout_logs_controller.rb`: deleting from Home returns to Home.
- `app/helpers/application_helper.rb`: one Home tab; page titles; comments.
- `app/views/pages/dashboard.html.erb`: the Home page (heading, order, layout).
- `app/views/pages/today.html.erb`: deleted.
- `app/views/pages/_today_box.html.erb`: rest day choices fold behind "Show workouts"; `h2` titles; `open` local removed.
- `app/views/pages/_summary_tiles.html.erb`: the Cardio tile is wide.
- `app/views/pages/home.html.erb`: comment.
- `app/views/pages/month.html.erb`: back to Home.
- `app/views/splits/index.html.erb`: back to Home.
- `app/views/workout_logs/index.html.erb`: back to Home.
- `app/assets/stylesheets/components/_list_toggle.scss`: the app's focus ring on Show/Hide toggles.
- `app/assets/stylesheets/pages/_dashboard_rest_day.scss`: rest day text styled by its own class.
- `app/assets/stylesheets/pages/_dashboard_today.scss`: unused `.today-page` removed; comment.
- `app/assets/stylesheets/pages/_dashboard_week.scss`: wide summary tile.

Tests:
- `test/integration/dashboard_flow_test.rb`
- `test/integration/navigation_flow_test.rb`
- `test/integration/week_moves_flow_test.rb`
- `test/integration/cardio_flow_test.rb`
- `test/integration/splits_flow_test.rb`

Docs:
- `CLAUDE.md`: code map for the Home page.
- `doc/Features/Features.md`: the feature moved to "Features added (DONE)".
- `doc/Issues/Issues.md`: two potential issues moved to resolved; one potential issue added.
- `doc/today-dashboard-consolidation.md`: this document.

`db/seeds/data.yml`: `bin/rails seed:dump` ran and the file came out unchanged (1 user, 3 splits, 6 workouts, 48 sets). No new data was logged on this branch.

## 9. Known gaps

- Not seen in a browser: a day with a planned workout, a user with no split, and a real phone. Recorded under "Potential issues".
- On a phone, the Exercises button sits on its own line under the long date heading (the old "Ready to train?" was short enough to share the line).
- From desktop width, Recent workouts sits under the right column. A calendar taller than the Today box and split card together would leave a gap above it.
- The saved impeccable report (`.impeccable/audit/`, not committed) still lists the touch-target finding. It does not apply to touch screens.

### Feature and issue lists
- `Features.md`: "Today and Dashboard pages seems redundant…" moved from "Home page" to "Features added (DONE) › Home page".
- `Issues.md`, moved from "Potential issues" to "Issues resolved › Home page", each with a "Fixed on `today-dashboard-consolidation`" line:
  - "Deleting a workout opened from Today goes to the dashboard"
  - "A week move without a Referer lands on Today"
- `Issues.md`, added under "Potential issues › Home page": "The Home page seen only on a rest day, in headless Chrome".
