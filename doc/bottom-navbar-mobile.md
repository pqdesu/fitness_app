# Bottom navigation bar and the Today page

Branch `bottom-navbar-mobile`, from `master` at `c13973e` (after pull requests 22, `workout-timer`, and 23, `plan-features-skill`). The worktree started on the generated name `claude/bottom-navbar-mobile-b2b51a`; it was renamed before anything was pushed.

## 1. Summary

On a phone the app now has a bottom tab bar, like a phone app (the owner's example: Instagram), instead of the hamburger menu. A new **Today** page is the app's main page.

- **Bottom bar (phones only, under 768 px):** Today · Dashboard · Splits · History · Account. Each tab is an icon with a small label under it. The active tab is blue, with a bolder label and a soft pill behind its icon. Tablet and desktop keep the top navbar.
- **No hamburger anywhere.** Signed out, Log in and Sign up sit in the top bar.
- **Top bar on a phone:** the logo and the name of the page (Today, Dashboard, Splits, Split, Workout, Exercise, History, Timer, Exercises, Users, Account). On a sub-page the round back arrow takes the logo's corner.
- **Today page at `/`:** opening the app, or signing in or up, shows it.
  - Workout day: today's workout with Start workout or Continue.
  - Rest day: everything the dashboard shows on a rest day, already open.
  - This week's strip, with Move a workout and Back to the plan.
- **Dashboard** moved to `/dashboard`.
- **Today's workout lights the Today tab** on a phone and on desktop. That covers its workout day, its exercises, its logged workout, and a workout started today outside the split.
- **Account tab:** opens the account page. That page is now titled "Account" and shows who is signed in, Users for an admin, and Log out.
- **Exercises:** a button on the dashboard on phones. On desktop it stays a top link.
- **iPhone:** the bar, the top bar and the page edges keep clear of the notch and the home indicator (`viewport-fit=cover` with `env(safe-area-inset-*)`).

**State:**
- `bin/rails test`: 101 runs, 1521 assertions, 0 failures.
- `bundle exec rubocop`: no offenses. `bundle exec brakeman`: no warnings.
- Checked in Chrome at 390 px (inside a same-origin 390 px frame, because the Chrome window could not be made narrower) and at 1200 px.
- Not tried on a real phone.

## 2. Timeline

Each request from the owner, in order, and what was done.

1. **"Use the plan-features skill for the bottom navbar feature under General. The navbar has to be only on mobile."**
   - Planned with `plan-features`. Read-only.
   - Three open questions were asked: signed-out pages, the Account tab, and what the top bar keeps on a phone.
2. **Answers: remove the hamburger everywhere; Account as a pop-up; keep the top bar and show the page's title in it.**
   - Built the first version: a bottom bar with Dashboard, Splits, History, Exercises and an Account pop-up, plus the page title in the top bar.
   - Tests and Chrome check. The Account label sat lower than the others, so its initial was resized to icon height.
3. **"Use the ui-ux pro skill and impeccable to check the bottom nav bar."**
   - There is no "UI UX Pro" skill on this machine; only `impeccable` is installed. The critique ran with `impeccable` alone.
   - Two isolated reviewers: one design review, one detector plus measurements.
   - Score 26/40, Acceptable. 1 major issue (iPhone safe area) and 4 smaller ones: colour-only active tab, small Account menu rows with Log out in the thumb zone, the title repeating the headings, and focus and screen-reader polish.
   - The detector found nothing in the markup. Its browser overlay was blocked by the app's content security policy.
   - The snapshot is in `.impeccable/critique/`, which is git-ignored.
4. **Answers: fix all 5; Account as a plain tab to its page; back arrow into the top bar; add a "Today" tab.** Then:
   - Exercises becomes a link on the dashboard.
   - Today is a normal page that shows everything a rest day shows on the dashboard, and can move workouts.
   - Order: Today, Dashboard, Splits, History, Account, all styled alike: "I want the today page to be the main one now so it is a quick open app log workouts type of thing."
   - Built the Today page at `/today` (signing in landed there), the five critique fixes, the Account page links, and the dashboard's Exercises button.
5. **"Fix: a workout opened from Today lights Splits; the account heading still says Edit User. And yes, open Today. Also make the Today tab and pages available on desktop."**
   - `/` became the Today page and the dashboard moved to `/dashboard`; `/today` was dropped.
   - Today's workout pages light Today.
   - The account page is titled "Account".
   - Desktop already had the Today link and page. The new tab rules apply to desktop too.
6. **"Yes, finalize it."** This document, the feature list, the seed data, and the pull request.

## 3. Starting point

- `shared/_navbar` was Bootstrap's `navbar-expand-md`. Under 768 px its links folded into a hamburger (`navbar-toggler`, `#mainNav`): Dashboard, Splits, History, Exercises, and a user dropdown (Account settings, Users for an admin, Log out).
- `/` was the dashboard for a signed-in user and the landing page signed out (`pages#home`). Today's workout lived only in the dashboard's "Today" box, below the calendar and the active split card.
- The back arrow (`back_to`, `.back-link`) was drawn inside `<main>`, above the page header.
- The viewport meta had no `viewport-fit=cover`, so `env(safe-area-inset-*)` was always 0.
- The account page was Devise's default, titled "Edit User".

## 4. Changes

### 4.1 One list of sections (`app/helpers/application_helper.rb`)

`nav_sections(phone: false)` is the one place that lists the sections. Each one is label, path, Font Awesome icon, and whether the current page belongs to it. Both bars read it.

| Section | Path | Icon | Active on |
|---|---|---|---|
| Today | `root_path` (`/`) | `calendar-day` | `pages#home`, or `todays_workout_page?` |
| Dashboard | `dashboard_path` | `house` | `pages#dashboard`; on a phone also the Exercises pages |
| Splits | `splits_path` | `layer-group` | splits, workout days, planned exercises, except today's workout |
| History | `workout_logs_path` | `clock-rotate-left` | logged workouts, their entries, the Edit timer page, except today's workout |
| Exercises (desktop only) | `exercises_path` | `dumbbell` | exercises |

- **Why History lights more pages:** before, the top nav lit nothing on a logged entry's edit page or Edit timer. A tab bar with no tab lit looks broken, so those now light History.
- **Why Splits got a new icon:** the layer stack is the icon the app already uses for splits (`splits/_empty`). The calendar now belongs to Today, so two calendars would look alike.

`todays_workout_page?` gives the date of the page and checks it against today:

```ruby
date =
  case "#{controller_name}##{action_name}"
  when "workout_days#show", "workout_exercises#show" then @date
  when "workout_logs#new" then Date.current
  when "workout_logs#show" then @workout_log.date
  end
date == Date.current
```

- `@date` is the logging date that `LoggingDate` already sets on a workout day's pages.
- Another day's workout still lights Splits, and an older log still lights History.

`page_title` reads a fixed map, `PAGE_TITLES`, keyed by `"controller#action"` or by the controller. Examples: `"pages#home" => "Today"`, `"pages" => "Dashboard"`, `"splits#index" => "Splits"`, `"splits" => "Split"`, `"users/registrations" => "Account"`. A fixed map can't show a long user-typed name, so the top bar never overflows.

### 4.2 The bottom bar (`shared/_bottom_nav`, `components/_bottom_nav.scss`)

- **Markup:**
  - A `<nav class="bottom-nav fixed-bottom d-md-none" aria-label="Sections">` with five links.
  - Each link holds `<span class="bottom-nav-icon" aria-hidden="true">` (the icon, or for Account the user's initial) and a label span.
  - The active one has `.active` and `aria-current="page"`.
  - The Account tab is active on the account page and on Users.
- **Rendered after `</main>`** in the layout, so a keyboard reaches the page before the tabs. The bar is fixed, so where it sits in the document doesn't change how it looks.
- **Styles:**
  - Five equal tabs, 3.75rem tall, plus the home-indicator inset, with padding of that inset (and the side insets).
  - Labels 0.6875rem (11 px), weight 500, `$muted`.
  - Active: `$blue`, weight 600, and a `$primary-soft` pill of 3.5 × 1.875rem behind the icon. It is the top navbar's active look, so the tab stands out by shape and weight, not colour alone. On the active Account tab the initial turns solid blue so it doesn't disappear into the pill.
  - A blue 2 px focus ring.
  - `-webkit-tap-highlight-color: transparent`, so there's no grey flash on tap.
  - A short colour and press transition.
- **Room under each page:** under `md`, `.app-main` gets `padding-bottom: 2rem + bar height + inset`, so the last card or button is never under the bar.

**History of the bar inside this branch:**
- First version: four links plus an Account dropup that held the user menu (`shared/_user_menu_items`, shared with the top dropdown).
- After the critique: Account became a plain link, and the partial was deleted, since only the top dropdown used it again.
- The bar's blur (`backdrop-filter` at .96 opacity) was dropped: at that opacity it showed nothing.

### 4.3 The top bar (`shared/_navbar`, `components/_navbar.scss`)

- **The hamburger is gone.**
  - Signed in: the links are in `<div class="navbar-collapse d-none d-md-flex">`. They show from 768 px up and never on a phone, where the bottom bar has them.
  - Signed out: Log in and Sign up sit outside the collapse, in a row, at every width.
- **Page name on a phone:** `<span class="navbar-page-title d-md-none me-auto">` after the logo.
  - The wordmark "FitnessApp" hides on a phone when there is a title; the mark stays.
  - The title's line is 2.75rem, as tall as the back arrow, so the bar keeps its height when the logo is hidden.
- **Back arrow in the corner:** when the page declared `back_to`, the navbar gets `.has-back`.
  - The logo hides on a phone (`d-none d-md-flex`), and the title moves right by 3.25rem.
  - `.back-link` is still drawn once, in `<main>`. Under `md` it is `position: fixed` at the top bar's left corner, at `top: .625rem + inset-top`, `left: .75rem + inset-left`, above the sticky bar (`$zindex-sticky + 1`).
  - It stays one element, so the existing "one back arrow per sub-page" test still holds, and `back_controller.js` is unchanged.
- **Safe area:** the bar's top padding adds `env(safe-area-inset-top)`.
- **`aria-label="Main"`** was added to the top `<nav>`, beside the bottom bar's "Sections".

### 4.4 The safe area (`layouts/application`, `components/_layout.scss`)

- The viewport meta gains `viewport-fit=cover`. Without it iOS keeps every `env(safe-area-inset-*)` at 0, and the tabs could sit in the home-swipe zone when Safari's toolbar collapses or the app runs from the Home Screen.
- `body` gets the left and right insets, for a phone turned sideways.
- The top bar, the bottom bar and the back arrow add their own top and bottom insets.
- The flash cards already used `safe-area-inset-top`; it now has an effect.

### 4.5 The Today page and the dashboard (`pages_controller`, `pages/*`, `config/routes.rb`)

**Before**, from `config/routes.rb` and `pages_controller.rb`:

```ruby
root to: "pages#home"
def home
  @dashboard = Dashboard.new(current_user, Date.current) if user_signed_in?
end
```

**After:**

```ruby
root to: "pages#home"
get "dashboard", to: "pages#dashboard"

def home
  return unless user_signed_in?

  @dashboard = Dashboard.new(current_user, Date.current)
  render :today
end

def dashboard
  @dashboard = Dashboard.new(current_user, Date.current)
end
```

- **`pages/home`** is now only the signed-out landing page.
- **`pages/dashboard`** is the old signed-in part, unchanged apart from two things:
  - the shared partials below
  - an "Exercises" button in its header, shown only on a phone (`d-md-none`)
- **`pages/today`:**
  - A header: eyebrow "Today", heading the date.
  - The Today box with `dated: false` (the heading has the date) and `open: true`. On a rest day the choices are open, not behind a "Start workout" button.
  - A "This week" card with the split's week strip (`splits/_week`) and the move buttons.
  - Without a split, the "Create your first split" empty state.
  - It is held to 40rem wide (`.today-page`).
- **Shared partials** (the dashboard and Today use one copy):
  - `pages/_today_box`: the Today box. It holds today's workout with Start workout or Continue, today's sets or last time's, and the rest-day panel with "From your split" (move to today or train as an extra) and "Something else" (a workout outside the split).
  - `pages/_week_moves`: "Moved this week", Back to the plan, and Move a workout.
  - `pages/_today_popups`: the Move a workout pop-up and the rest-day pop-ups.
- **Signing in or up** goes to `/` (Devise's default), which is Today. An earlier step had an `after_sign_in_path_for` override for `/today`; it was removed when `/` became Today.

### 4.6 Where "/" used to mean the dashboard

Each link that pointed to `root_path` was sorted by what it meant:

- **Now `/dashboard`.** These are reached only from the dashboard (`?from=dashboard`), and the documented rule says they return there:
  - `SplitsController#activate` after "Change" on the active split card
  - the back arrow on `splits#index?from=dashboard`
  - the back arrow on a calendar day with several workouts (`workout_logs#index?date=…&from=dashboard`)
  - `WorkoutLogsController#destroy` for a workout opened from the dashboard
- **Now Today** (unchanged code, new meaning):
  - the logo
  - the back-arrow fallbacks of a workout day, a logged workout, and "Start another workout"
  - the fallback of the double-tap rescue, `require_admin!`, and the timer controller
- **Week moves:** `WeekMovesController#create` and `#destroy` used to `redirect_to root_path`. They now `redirect_back_or_to root_path`, so a move made on Today returns to Today and one made on the dashboard returns to the dashboard. With no Referer they go to `/` (Today). "Move to today" with `open` still opens the workout day.

### 4.7 The account page (`devise/registrations/edit`)

- Heading "Account" (it was Devise's "Edit User").
- Above the form:
  - "Signed in as **email**", with the Admin badge for an admin.
  - A Users button for an admin.
  - Log out (`data-turbo-method: delete`).
- On a phone this page is the Account tab. On desktop the user dropdown is unchanged.

### 4.8 Tests

- **`navigation_flow_test.rb`, new test, "on a phone the sections are a bottom tab bar…".** For each of these pages it checks the phone title, that the bar has Today · Dashboard · Splits · History · Account in that order, that one tab is active with `aria-current`, and that there is no hamburger:
  - Today, Dashboard, Exercises (lights Dashboard), Splits, a split
  - today's workout day, its exercise, its log, and "start Legs today" (all light Today)
  - another day's workout (lights Splits)
  - History and Account

  It also checks:
  - the Account tab is a link, with no dropdown, and the initial is hidden from screen readers
  - the desktop links are Today, Dashboard, Splits, History, Exercises
  - the dashboard's phone Exercises button
  - the bar comes after `<main>`
  - `.has-back` and the hidden logo on a sub-page
  - the account page's "Signed in as", Log out, and the admin-only Users and badge
  - signed out: no bar, no hamburger, Log in and Sign up in the top bar
- **`week_moves_flow_test.rb`, two new tests:**
  - "the Today page is today's workout, or on a rest day the choices already open, and moves return to it":
    - signed out "/" is the landing page; signing in goes to "/"
    - Monday shows Push with Start workout and no date line
    - Tuesday shows the rest-day choices already open, Train as extra, and other workouts
    - Move a workout and Back to the plan return to the page they came from, and to "/" without a Referer
  - "the Today page without a split asks for one".
- **Existing tests changed because the owner changed the behaviour they checked** ("/" is Today, the heading is "Account"). What they check on the page is unchanged:
  - `dashboard_flow_test.rb`: every `get root_path` became `get dashboard_path`. Deleting a workout opened from the dashboard and a calendar day's back arrow now expect `dashboard_path`.
  - `splits_flow_test.rb`: the dashboard visit, the "Change" back arrow, and the activate redirect now use `dashboard_path`.
  - `week_moves_flow_test.rb`, the first rest-day test: its two dashboard visits now use `dashboard_path`. On Today the rest-day choices are open, so the dashboard's collapsed panel is checked on the dashboard.
  - `accounts_flow_test.rb`: the account page's h1 is "Account".

## 5. Decisions

- **Phone only:** the bar is hidden from 768 px up, Bootstrap's `md`, the same width at which the top navbar showed its links. The owner asked for mobile only.
- **No new JavaScript and no new gem:**
  - The bar is plain links.
  - The icons are Font Awesome, already installed.
  - The first version's Account pop-up was Bootstrap's dropdown.
- **The paused-timer alert:** it catches the bar's links with no change, because it listens to every link click (`timer_alert_controller.js`). Leaving a paused workout by a tab asks Keep paused / Stop timer, like the old menu did.
- **Account as a plain tab, not a pop-up** (owner's answer after the critique). All five tabs behave the same, settings is one tap, and Log out is no longer next to the tabs. Rejected: keeping the pop-up with bigger rows.
- **Back arrow drawn once and placed over the top bar with CSS**, rather than rendered twice (once in the bar, once in the page). Rendering it twice would break the "one back arrow per sub-page" rule and its test, and need a second element for `back_controller.js`.
- **Exercises on the dashboard on a phone** (owner's choice). Rejected: a link on the Account page, or a sixth tab (tabs about 65 px wide).
- **Today's tab first and styled like the others** (owner's choice). Rejected: a filled centre button.
- **"/" is Today and the dashboard moved to `/dashboard`.** Rejected: keeping `/today` beside a dashboard at `/`, which leaves "opening the app" on the dashboard. Rejected too: rendering Today at `/` while keeping `/today`, which would give one page two addresses.
- **Moves return to the page they came from** (`redirect_back_or_to`), since they can now be made on two pages.
- **Today's box keeps `from=dashboard` on its links.** Changing the marker would touch the logged-workout pages and their delete rule. The effect is in Known gaps.
- **"/" still lands on Today, never the dashboard, for every leftover `root_path` fallback.** Assumption: Today is the better default home for a lifter opening the app.
- **No change to `Dashboard` (the model).** Today reads the same object.

## 6. How it works now

- Open the app (`/`), or sign in or up: the Today page.
- On a phone, the bar is always at the bottom:
  - **Today:** today's workout, or what to train on a rest day, plus this week's moves.
  - **Dashboard:** the month, the active split's week, the Today box, recent workouts, and a button to Exercises.
  - **Splits:** the plans.
  - **History:** logged workouts.
  - **Account:** settings, Users for an admin, Log out.
- The tab of the current section is blue on a pill. Today's workout, its exercises and its log keep Today lit. Another day's workout lights Splits; an older log lights History.
- The top bar names the page. On a sub-page its left corner is the back arrow.
- On a tablet or desktop the top navbar has Today, Dashboard, Splits, History, Exercises and the user menu. No bottom bar.

To try it: in a checkout of this branch (or after merging), run `bin/rails server` and open the app at phone width (Chrome DevTools device mode, 390 px).

## 7. Tests and verification

- **`bin/rails test`:** 101 runs, 1521 assertions, 0 failures, 0 errors.
- **`bundle exec rubocop`:** no offenses. **`bundle exec brakeman`:** no warnings.
- **Chrome checks.** These used a throwaway account (`navcheck@example.test`, random password, deleted afterwards with its split), with the app inside a same-origin iframe of 390 × 740:
  - signed out: top bar without a hamburger
  - Today on a rest day: the choices open; Move a workout moved Pull to Saturday and came back to Today with the notice
  - Today on a workout day: Start workout opens the workout day and Today stays lit
  - a sub-page: back arrow at 12,10 in the 65 px bar, title beside it; the arrow went back to Today
  - the Account page and its tab
  - the dashboard's Exercises button
  - scrolled to the bottom: 32 px clear above the bar
- **Desktop at 1200 px:** no bottom bar; links Today, Dashboard, Splits, History, Exercises; Today lit on `/` and on today's workout; `/dashboard` lit Dashboard; the account heading "Account".
- **impeccable critique** (before the fixes):
  - 26/40.
  - Measured: tabs 75–78 × 59 px; labels 5.35:1 (inactive) and 6.27:1 (active) on white.
  - The fixes were checked by reading the computed styles and by the screenshots above. The critique was not re-run.
- **Not verified:**
  - a real iPhone or Android, so the home-indicator inset and the landscape notch padding are untested
  - a running or paused timer while switching tabs
  - an admin account live (covered by the test only)
  - the 768 px boundary on a large phone in landscape

## 8. Every file changed

29 files: 28 in `git diff master --stat`, plus this document. Then `doc/Features/Features.md`, `doc/Issues/Issues.md` and `db/seeds/data.yml` from the finalize steps (see 9a).

**Layout and navigation**
- `app/views/layouts/application.html.erb`: `viewport-fit=cover`; the bottom bar is rendered after `</main>` when signed in.
- `app/views/shared/_navbar.html.erb`: no hamburger; the page title on a phone; `.has-back` hides the logo on a phone; signed-out links in a row; `aria-label="Main"`; links from `nav_sections`.
- `app/views/shared/_bottom_nav.html.erb` (new): the phone tab bar.
- `app/helpers/application_helper.rb`: `nav_sections`, `todays_workout_page?`, `PAGE_TITLES` and `page_title`.

**Styles**
- `app/assets/stylesheets/components/_bottom_nav.scss` (new): the bar, the tabs, the active pill, focus, safe area, room under the page.
- `app/assets/stylesheets/components/_navbar.scss`: the top inset, the page title, `.has-back`.
- `app/assets/stylesheets/components/_layout.scss`: the body's side insets; the back arrow fixed in the top bar's corner on a phone; the dropped `.navbar-toggler` touch size.
- `app/assets/stylesheets/pages/_dashboard_today.scss`: `.today-page` width.
- `app/assets/stylesheets/application.scss`: imports `components/bottom_nav`.

**Pages**
- `config/routes.rb`: `get "dashboard", to: "pages#dashboard"`.
- `app/controllers/pages_controller.rb`: `home` renders Today when signed in; the new `dashboard` action.
- `app/views/pages/home.html.erb`: the signed-out landing page only.
- `app/views/pages/dashboard.html.erb` (new): the dashboard, from the old `home`, using the shared partials, plus the phone Exercises button.
- `app/views/pages/today.html.erb` (new): the Today page.
- `app/views/pages/_today_box.html.erb` (new): the Today box, with `dated` and `open`.
- `app/views/pages/_week_moves.html.erb` (new): the move buttons.
- `app/views/pages/_today_popups.html.erb` (new): the move and rest-day pop-ups.

**Where "/" meant the dashboard**
- `app/controllers/splits_controller.rb`: activate from the dashboard returns to `dashboard_path`.
- `app/controllers/workout_logs_controller.rb`: deleting a workout opened from the dashboard returns to `dashboard_path`.
- `app/controllers/week_moves_controller.rb`: moves return to the page they came from (`redirect_back_or_to`).
- `app/views/splits/index.html.erb`: back arrow to `dashboard_path` when opened from it.
- `app/views/workout_logs/index.html.erb`: a calendar day's back arrow to `dashboard_path`.

**Account**
- `app/views/devise/registrations/edit.html.erb`: heading "Account"; signed-in email, Admin badge, Users and Log out.

**Tests**
- `test/integration/navigation_flow_test.rb`: the bottom bar test.
- `test/integration/week_moves_flow_test.rb`: the two Today tests; the rest-day test reads the dashboard at `/dashboard`.
- `test/integration/dashboard_flow_test.rb`: the dashboard at `/dashboard`.
- `test/integration/splits_flow_test.rb`: the dashboard and the "Change" flow at `/dashboard`.
- `test/integration/accounts_flow_test.rb`: the heading "Account".

**Docs**
- `doc/bottom-navbar-mobile.md` (new): this document.

## 9. Known gaps

- **Deleting a workout opened from Today's box returns to the dashboard.** The box's links share the dashboard's `?from=dashboard` marker (see 5).
- **Not tried on a real phone:** the iPhone home-indicator and notch insets, the tap feel, and the fixed back arrow during Safari's toolbar animation.
- **A move falls back to "/" (Today) when the browser sends no Referer**, for example with a strict referrer policy or privacy setting. It still saves.
- **The flash card can cover the top bar's back arrow** for up to 5 seconds. Both sit at the top of the screen and the card is on top. It can be dismissed with ×.
- **CLAUDE.md and `doc/Prompt/project-context.md` still describe "/" as the dashboard** and the old navbar. `finalize-branch` may not edit them; they need a follow-up change.
- **Bookmarks** of `/` now open Today, not the dashboard.

## 9a. Feature list, issues and seed data

- **`doc/Features/Features.md`:** the General feature ("Make a bottom navigation bar instead of the hamburger menu…") moved to "Features added (DONE)" › General.
- **`doc/Issues/Issues.md`:** no open issue was fixed by this branch. New potential issues under "General", each from `bottom-navbar-mobile`:
  - "Deleting a workout opened from Today goes to the dashboard"
  - "Bottom bar not tried on a real phone"
  - "A week move without a Referer lands on Today"
- **`db/seeds/data.yml`:** see the commit. The seed dump's result is recorded in the pull request description.
