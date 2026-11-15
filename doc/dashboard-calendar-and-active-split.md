# Dashboard calendar, active split and workouts that outlive splits

Branch: `dashboard-calendar-and-active-split` (started as `claude/home-page-issues-review-af3ced`, with a sub-branch `claude/active-split` that was fast-forwarded into it).

## 1. Summary

This branch resolves the two "Home page" issues in `doc/Issues/Issues.md` and the follow-up requests made while building them.

- The dashboard no longer lists splits. It shows a calendar of the month, the three stat boxes, the **active split** with its week (today ringed), a box with today's workout and the heaviest set of each exercise from the last session of that workout, and recent workouts.
- A user has one **active split**, chosen on the Splits page (ringed there) or on a split's own page.
- Dates follow the **user's own time zone**, reported by the browser.
- Workout days are chosen from a **fixed list** (Push, Pull, Legs, Lower, Upper, Anterior, Posterior, Full Body). Legs and Lower are the same workout.
- **Logged workouts belong to the user**, not to a split: deleting a day or a whole split keeps the history, and "last time" is found by workout across splits.

State: the test suite passes (39 runs, 376 assertions, 0 failures). **Nothing was checked in a real browser** — the Chrome extension was not connected and no local browser was installed — so the layout, the styles and the time-zone script are verified only through rendered HTML in tests.

## 2. Timeline

| # | Request | What was done |
|---|---------|---------------|
| 1 | Read `Issues.md`, focus on the Home page issues, and first check how each could be implemented | Read the issues and the code; reported an approach for both and one open decision: which split drives the dashboard when there are several |
| 2 | "Add active split", on a sub-branch; ring around the active split, an option to change it, shown on the home page | Branch `claude/active-split`: `users.active_split_id`, "Set as active" action, ring and badge on the Splits page, "Active split" card on the dashboard |
| 3 | "I forgot to git pull for the universal back button" | Fetched; fast-forwarded the parent branch to `origin/master` and rebased the active split work onto it (no conflicts) |
| 4 | After setting a split as active, go back to the home page | `activate` redirected to the dashboard |
| 5 | Only when the change started from the dashboard; on the Splits page, stay | "Change" on the dashboard opens `/splits?from=dashboard`; choosing a split from there returns to the dashboard, otherwise the user stays where they were |
| 6 | Commit, and continue with the Home page issues | Committed the active split; fast-forwarded the parent branch; built the calendar, today's ring, today's workout and last session's heaviest sets |
| 7 | Use the user's own month and time zone, dynamically | Browser reports its time zone in a cookie; every request runs in that zone |
| 8 | Bodyweight should show the Bodyweight text; active split approach confirmed; workout days from a fixed list; compare with the latest workout even across splits | Bodyweight already showed "Bodyweight × N reps". Workout day name became a dropdown of the fixed list; "last time" looked up across splits, with Legs = Lower |
| 9 | A workout logged in a split that is later deleted must still be found | Logs now belong to the user and store their workout; deleting a day or split only unlinks them |
| 10 | Should exercise lists be shared per workout across splits? "No, the list may change" | Left as is: exercises stay per split day |
| 11 | `/finalize-branch` (interrupted) then: back button from "Last time" should return to the home page; ring only around the split, exercises in a box below | "Last time" link carries `from=dashboard`; the log page then shows a "Dashboard" back button. The dashboard card was split in two: ringed split card, and a separate "Today" card |
| 12 | Resume finalizing | This doc, commit, push, pull request |

## 3. Starting point

- The dashboard (`pages#home`) showed three stat tiles, a "Your splits" list with a "New split" button, and recent workouts.
- A user could have several splits with nothing saying which one they were training, so "today's workout" was undefined.
- A workout day's name was free text.
- `workout_logs` belonged to a `workout_day` (`null: false`), and `WorkoutDay has_many :workout_logs, dependent: :destroy`. Deleting a split deleted every workout logged in it.
- No time zone was configured: `Date.current` was the UTC date for everyone.

The issues asked for:

1. Splits off the home page; the split's week on the dashboard with today highlighted and today's workout named.
2. A month calendar on the left, above the stat boxes, with the current week highlighted; a text saying which workout of the split today is; last week's exercises with the heaviest set and reps.

## 4. Changes

### 4.1 Active split

Before: no notion of a current split.

After:

```ruby
# app/models/user.rb
belongs_to :active_split, class_name: "Split", optional: true
validate :active_split_is_own

def current_split
  active_split || splits.order(:id).first
end
```

- Migration `20261116120000_add_active_split_to_users.rb`: `users.active_split_id`, foreign key to `splits` with `on_delete: :nullify`.
- `Split#active?` compares with `user.current_split`.
- Route `PATCH /splits/:id/activate`; `SplitsController#activate` sets it.
- Splits page: each split is a card; the active one has class `is-active` (a 2px ring) and an "Active" badge, the others a "Set as active" button. The card title is a Bootstrap `stretched-link`, so the button can live inside the card.
- Split page: "Set as active" button, or an "Active split" badge.

Reason: the dashboard needs exactly one split to follow.

### 4.2 Where "Set as active" sends the user

```ruby
if params[:from] == "dashboard"
  redirect_to root_path, notice: notice, status: :see_other
else
  redirect_back fallback_location: splits_path, notice: notice, status: :see_other
end
```

The dashboard's "Change" link goes to `splits_path(from: "dashboard")`. On that visit the Splits page shows a "Dashboard" back button and its "Set as active" buttons carry `from=dashboard`.

Reason: requested — return to the dashboard only when the change started there.

### 4.3 Dashboard

Before: stat tiles on top, "Your splits" list (left), recent workouts (right).

After (`app/views/pages/home.html.erb`):

- Left column: `pages/_calendar` (month of today, Sunday first, the current week's row highlighted, today filled, a dot on days that have a workout in the active split), then the three stat tiles.
- Right column:
  1. **Active split** card (ringed): name, "Change" link when there is more than one split, and the week partial with today ringed.
  2. **Today** card: "Today · Monday, November 16", then "Push day" with an "Open workout" button, or "Rest day". Under it "Last time · <date>" (a link to that logged workout) and one row per exercise with its heaviest set, e.g. `80 kg × 6 reps`.
  3. **Recent workouts**, unchanged in content.
- The splits list and the "New split" button were removed.

Supporting code:

- `ApplicationHelper#month_weeks(date)`: the Sunday-to-Saturday weeks covering the month.
- `splits/_week` takes an optional `today` local (weekday number) and adds `is-today` and `aria-current="date"`.
- `WorkoutLogExercise#top_set`: `workout_sets.max_by { |set| [set.weight_used || 0, set.reps_completed] }`.
- `PagesController#last_session_of(workout_day)`: the most recent log of the same workout before today.

### 4.4 Back button from "Last time"

The "Last time" link is `workout_log_path(log, from: "dashboard")`. `workout_logs/show` then declares `back_to "Dashboard", root_path`; otherwise it goes back to the workout day, or to History when the day no longer exists.

### 4.5 The user's time zone

Before: UTC for everyone.

After:

```ruby
# app/controllers/application_controller.rb
around_action :use_browser_time_zone

def browser_time_zone
  ActiveSupport::TimeZone[cookies[:time_zone].to_s] || Time.zone_default
end
```

- `app/javascript/time_zone.js` runs on `turbo:load`. It reads `Intl.DateTimeFormat().resolvedOptions().timeZone`; if that differs from the zone the page was rendered in (`<body data-time-zone>`), it sets the `time_zone` cookie and reloads once.
- Guards: no reload if the cookie already holds that zone (the server does not know it), if the cookie was not accepted, or if the page came from a non-GET request (`data-reloadable`).

Reason: requested — "today", the week and the month must be the user's own. Because it is an `around_action`, sets are also logged under the user's date.

### 4.6 Fixed workout days

Before: `validates :day, presence: true`, a text field.

After:

```ruby
# app/models/workout_day.rb
NAMES = ["Push", "Pull", "Legs", "Lower", "Upper", "Anterior", "Posterior", "Full Body"].freeze
SAME_WORKOUT = [%w[Legs Lower]].freeze
validates :day, inclusion: { in: NAMES, message: "must be one of the listed workouts" }

def self.names_for(name)
  SAME_WORKOUT.find { |names| names.include?(name) } || [name]
end
```

The form field is a dropdown labelled "Workout". No data migration was needed: every existing workout day in the development database was already named Push, Pull, Legs, Upper or Lower.

Reason: requested — a workout must be comparable over time regardless of split.

### 4.7 Logged workouts outlive splits

Before: `workout_logs.workout_day_id NOT NULL`; logs destroyed with their day.

After (migration `20261116130000_make_workout_logs_outlive_splits.rb`):

- `workout_logs.user_id` (not null, foreign key) and `workout_logs.workout` (not null string), backfilled from each log's day and split.
- `workout_logs.workout_day_id` nullable, foreign key `on_delete: :nullify`.
- Index on `[user_id, workout, date]`.

```ruby
# app/models/workout_log.rb
belongs_to :user
belongs_to :workout_day, optional: true
before_validation :copy_from_workout_day, on: :create
validates :workout, inclusion: { in: WorkoutDay::NAMES }
scope :of_workout, ->(name) { where(workout: WorkoutDay.names_for(name)) }
```

- `WorkoutDay has_many :workout_logs, dependent: :nullify`; `User has_many :workout_logs, dependent: :destroy` (direct, no longer through splits).
- Ownership checks in `WorkoutSetsController`, `WorkoutLogExercisesController` and the dashboard's set count now use `workout_logs.user_id` instead of joining through the split.
- Views use `log.workout` for the name and cope with a missing day: History shows "Deleted" in the Split column; the dashboard says "Push, from a deleted split".
- The delete confirmations for a split and a workout day now say the logged workouts are kept.

Reason: requested — "If I do Chest Monday, change split, delete the split and do Chest again on Tuesday I should still see the Monday record".

## 5. Decisions

| Decision | Alternative rejected | Why |
|----------|----------------------|-----|
| One active split per user | Show every split's week on the dashboard | Confirmed by the user; one "today" instead of repeated blocks |
| Until one is chosen, the oldest split counts as active | Force a choice / show nothing | **Assumption.** Works without any setup for a user with one split |
| "Last time" = most recent earlier session of that workout | Strictly seven days ago | Proposed and not objected to; a skipped week still shows something |
| Heaviest set; ties and bodyweight sets settled by most reps; shown as "Bodyweight × N reps" | — | User confirmed the Bodyweight text |
| Time zone from the browser via a cookie | A setting on the user; a fixed app zone | Requested to be dynamic; needs no input and follows travel |
| One page reload on the first visit | Leave the first page in UTC | So the very first view already shows the right day |
| Keep `day` as a validated string | An enum or a `workouts` table | Smallest change; existing data already fits |
| Logs store the workout name at creation | Follow the day's current name | A later rename of a day must not rewrite history |
| Exercise lists stay per split day | One list per workout shared across splits | User: "the list may change" |
| `from=dashboard` query parameter for the two "return to dashboard" flows | Relying on the Referer header | Explicit and survives the intermediate page |
| Calendar dots on days with a workout | Plain calendar | **Not requested**; added because it makes the month readable. Easy to remove (`has-workout` in `_calendar.html.erb` and `_app.scss`) |

## 6. How it works now

Data model (changes only):

```
users          + active_split_id -> splits (nullify on delete)
workout_logs   + user_id -> users (required)
               + workout (required: one of WorkoutDay::NAMES)
               ~ workout_day_id optional (nullify on delete)
```

Flow:

1. Create a split, add workout days by choosing a workout and a weekday, add exercises to each day.
2. The dashboard follows the active split. Change it from the Splits page, a split's page, or "Change" on the dashboard.
3. Adding a set from a day's exercise creates today's log (in the user's time zone) with the user and the workout name.
4. On a day with a workout, the dashboard shows the last earlier session of that workout — from any split, including deleted ones.

To try it:

```bash
bin/rails db:migrate
bin/rails server
```

Both migrations were already run against the development database used during the session.

## 7. Tests and verification

Run: `bin/rails test` → **39 runs, 376 assertions, 0 failures, 0 errors, 0 skips**.

New or extended coverage:

- `test/models/user_test.rb`: current split, clearing on deletion, ownership validation.
- `test/models/workout_day_test.rb`: fixed list, Legs = Lower.
- `test/models/workout_log_test.rb`: log copies user and workout; survives split deletion; removed with the account.
- `test/integration/workout_flow_test.rb`: active split ring and both redirect paths; dashboard calendar, week, today's workout, heaviest sets, cross-split lookup, separate Today card, Dashboard back button; deleted-split scenario end to end; time zone (same instant seen from UTC, São Paulo and Tokyo, plus an unknown zone).

Not verified:

- **No browser check at all.** Layout, spacing, the ring, the calendar's appearance and responsive behaviour are unseen.
- `time_zone.js` was never executed; only the server side (cookie → zone) is tested. It was confirmed to be pinned in the importmap and served.
- The migration's `down` was not run.

## 8. Every file changed (37)

Styles
- `app/assets/stylesheets/components/_app.scss` — split card ring, today ring, calendar, Today card

Controllers
- `app/controllers/application_controller.rb` — per-request browser time zone
- `app/controllers/pages_controller.rb` — dashboard data: active split, today, last session
- `app/controllers/splits_controller.rb` — `activate`, active split on index
- `app/controllers/workout_log_exercises_controller.rb` — ownership via `workout_logs.user_id`
- `app/controllers/workout_logs_controller.rb` — copes with a log whose day is gone
- `app/controllers/workout_sets_controller.rb` — ownership via `workout_logs.user_id`

Helpers and JavaScript
- `app/helpers/application_helper.rb` — `month_weeks`
- `app/javascript/application.js` — imports `time_zone`
- `app/javascript/time_zone.js` — new: reports the browser time zone
- `config/importmap.rb` — pins `time_zone`

Models
- `app/models/split.rb` — `active?`
- `app/models/user.rb` — active split, `current_split`, direct `workout_logs`
- `app/models/workout_day.rb` — fixed names, `names_for`, logs nullified on delete
- `app/models/workout_log.rb` — belongs to user, stores workout, `of_workout`
- `app/models/workout_log_exercise.rb` — `top_set`

Views
- `app/views/layouts/application.html.erb` — `data-time-zone`, `data-reloadable` on body
- `app/views/pages/_calendar.html.erb` — new: month calendar
- `app/views/pages/home.html.erb` — new dashboard layout
- `app/views/splits/_week.html.erb` — optional today ring
- `app/views/splits/index.html.erb` — active ring, badge, "Set as active", Dashboard back button
- `app/views/splits/show.html.erb` — "Set as active" / badge, new delete wording
- `app/views/workout_days/_form.html.erb` — workout dropdown
- `app/views/workout_days/show.html.erb` — new delete wording
- `app/views/workout_log_exercises/edit.html.erb` — uses the log's workout name
- `app/views/workout_logs/index.html.erb` — workout name, "Deleted" split
- `app/views/workout_logs/show.html.erb` — back to Dashboard / day / History

Routes and database
- `config/routes.rb` — `PATCH /splits/:id/activate`
- `db/migrate/20261116120000_add_active_split_to_users.rb` — new
- `db/migrate/20261116130000_make_workout_logs_outlive_splits.rb` — new
- `db/schema.rb` — regenerated

Tests
- `test/integration/workout_flow_test.rb`
- `test/models/user_test.rb`
- `test/models/workout_day_test.rb`
- `test/models/workout_log_test.rb`
- `test/models/workout_recording_test.rb`

Docs
- `doc/dashboard-calendar-and-active-split.md` — this file

## 9. Known gaps

- Nothing was looked at in a browser; expect to adjust spacing or sizes.
- The first page of a new browser session renders in UTC and reloads once. With JavaScript or cookies disabled the app stays in UTC.
- Today's log is still found per workout day: training the same workout from two different splits on the same date creates two logs.
- A log from a deleted day can no longer offer "planned exercises" to add; exercises can still be added from the catalogue.
- `doc/Issues/Issues.md` lives in the main folder (untracked) and was not updated: the two Home page issues still need moving to "Issues Resolved".
- The local sub-branch `claude/active-split` still exists; its single commit is contained in this branch.
