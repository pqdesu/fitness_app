# calendar-month-and-missed-days

Branch `calendar-month-and-missed-days` (started as the generated `claude/calendar-feature-planning-04119d`, then `calendar-month-page`; renamed before anything was pushed). Worktree: `.claude/worktrees/calendar-feature-planning-04119d`. Date of the work: 2026-11-24.

## 1. Summary

The dashboard calendar and the week strip now say how each day stands, a month page opens from the calendar, and a missed day is a link to log a forgotten workout.

- **Month page.** Tapping "Month" in the calendar header opens `/dashboard/month`: the month's totals, each split's share, each exercise's sets and heaviest weight, and the calendar again.
- **Calendar fold.** Tapping the month's name folds and unfolds the calendar (starts open).
- **Day states (both the calendar and the week strip).** Planned day: filled blue. Planned day that passed with nothing logged: dotted. A workout on a day the plan did not have: light ring. Today: a ring. Nothing: plain white.
- **A workout with nothing in it is not logged.** "Logged" is an exercise added or the timer started.
- **Missed day is a link** to the plan's workout on that date, so a workout forgotten in the app can be added late. A day with no plan is never a link.
- **Tooltips** on every day, and a **hover halo** on every day.

State: tested. `bin/rails test`: 155 runs, 2163 assertions, 0 failures; `bundle exec rubocop`: no offenses; `bundle exec brakeman`: 0 warnings. Looked at in headless Chrome at 390 px. Not tried on a real phone or with a real mouse (see section 9).

## 2. Timeline (what was asked, what was done)

1. **Plan the "Calendar" features from Features.md** (`plan-features` skill, nothing changed). Two features: open the month by its name to a page with the month's data, and make the month a dropdown. The plan found the two clash on one tap and suggested: the name folds the calendar, a "Month" link opens the page.
2. **"Continue with the implementation plan."** Built both, using the plan's suggestions for the four open questions (current month only, heaviest weight only, calendar starts open, name folds and "Month" opens). Checked at phone width. One layout fix: a long exercise name pushed its row's numbers onto three lines.
3. **`opusplan`.** The owner asked to use `opusplan` all the time. I set `"model": "opusplan"` in `~/.claude/settings.json` (user level, so it covers every project). The first plan was written on Opus before the switch, which I should have said at the start (CLAUDE.md).
4. **Investigate "Calendar and week" in Issues.md** (`investigate-issues` skill, nothing changed). Causes found: the calendar's only filled circle was today; the week strip filled every planned day; an empty Upper log on Friday 20 counted as logged. The "numbers slightly off centre" issue could not be reproduced (within 0.25 px).
5. **The owner answered my three questions, then corrected the plan twice.** Final rules, see section 5.
6. **"When I hover there is no indication."** Added a hover halo on every day.
7. **"Add the tooltip text, and make the missed days accessible so I can add a forgotten workout."** Added tooltips and made a missed day a link. The owner confirmed the rule: only missed days link, a day with no plan does not.
8. **"Yes, finalize."** This doc, the feature and issue lists, the pull request.

## 3. Starting point

- `pages/_calendar` showed the month. A day with any logged workout was a white ring and a link; today was a solid blue circle. So the only filled circle on the month was today, whether or not it was trained.
- `splits/_week` (the week strip on the dashboard and the Today page, also the plan on the split page) filled every weekday that has a workout day (`is-set`). It never looked at what was trained, so a missed day still looked done.
- A log with no exercise and no timer (for example after the last exercise was removed) counted as a workout everywhere. Nothing deletes an empty log: `WorkoutSetsController#destroy` and `WorkoutLogExercisesController#destroy` only destroy the set or entry. The owner's Friday 20 was one.
- The month name was plain text, and the only totals the app had were for "This week".
- Nothing reacted when pointing at a day that was not a logged link; a logged day turned blue, which stopped being visible once planned days were filled.

## 4. Changes (before and after, and why)

### 4.1 Month page and fold
- **Before:** month name is a heading; no month totals.
- **After:** `pages/_calendar` has `<h2><button class="calendar-toggle" data-bs-toggle="collapse" data-bs-target="#calendar-body">November 2026 ⌄</button></h2>` and a "Month" link (`dashboard_month_path`); the body is a Bootstrap collapse (`collapse show`). When folded the header's bottom line is hidden (`.card-header:has(+ .collapse:not(.show))`). `pages#month` (`GET /dashboard/month`, `config/routes.rb`) builds the same `Dashboard` and renders `pages/month.html.erb`, with `back_to dashboard_path`. The page shows totals (`pages/_summary_tiles`, extracted from `_week_overview` and shared with it), a "Splits" list and an "Exercises" list (`.month-list`, `_dashboard_month.scss`), and the calendar again with `foldable: false` (no fold button, no "Month" link, plain heading).
- **Data:** `Dashboard#month_logs` (`workout_logs` of `today.all_month` with `with_sets` and `workout_day: :split`), `#month_summary` (`WorkoutSummary`), `#month_by_split` (logs grouped by `workout_day&.split`, `nil` is "No split", busiest first). `WorkoutSummary#by_exercise` returns `[name, sets, heaviest weight, cardio seconds]`, most sets first; the heaviest weight goes through a private `heaviest(entries)` that `top_weight` now uses too (bodyweight sets are not a weight).
- **Nav:** `nav_sections` lights the Dashboard tab on `pages#month` too.
- **Why:** the two Features.md bullets. Reasons for the shared partial: one set of tiles, one place.

### 4.2 A workout with nothing in it is not logged
- `WorkoutLog#logged?` = `started_at.present? || workout_log_exercises.any?` (one-line method; the class was at rubocop's length limit).
- `WorkoutSummary#workouts` counts `logged?` logs. `_week_overview` and `_calendar` treat a day as logged only when one of its logs is `logged?` (a day's list still names all its logs).
- **Why:** Friday 20's empty Upper looked done. The owner's answers: an exercise added counts, a timer started counts, nothing does not.

### 4.3 Day states (`DayStates`)
- **New** `app/models/day_states.rb` (plain Ruby): `of(dates, logs_by_date)` gives `date => :planned | :missed | :extra`, and `day_on(date)` the workout day the plan has on a date.
  - `:planned` = a day of the split's week plan (with that week's moves, through `Split#week_plan`, asked once per week) that is today or later, or was trained.
  - `:missed` = a day of the plan that has passed with nothing logged, from the user's first logged workout on (`user.workout_logs.minimum(:date)`), so the weeks before the app was used are not all dotted.
  - `:extra` = trained, but not on the plan.
  - No state otherwise. With no split, a trained day is `:extra`.
- `Dashboard#calendar_states`, `#week_states` (by weekday) and `#day_states` (public) use it; `calendar_logs` now loads `workout_log_exercises`.
- **Why:** one place decides, so the calendar, the strip and the tests agree. It is a class of its own because `Dashboard` hit rubocop's 100-line limit.

### 4.4 Calendar look (`pages/_calendar`, `_dashboard_calendar.scss`, `_colors.scss`)
- Classes per day: `is-planned` (blue fill, white number), `is-missed` (2 px dotted blue), `is-extra` (light-indigo inset ring), `is-today` (inset blue ring; with `is-planned` the old white inner ring on the fill), `has-workout` still means "logged" and keeps the link. Days of the months before and after only show a grey ring when something was trained, never filled or dotted (`state` is only read for them when logged).
- New colours: `$extra-ring` (#8C93F0) and `$hover-halo`.
- **Before/after example (screenshot data):** Mon 16 trained → was a white ring, now filled; Wed 18 not trained → was plain, now dotted; today → was solid, now a ring.

### 4.5 Week strip (`splits/_week`, `_split_week.scss`)
- New optional local `states:` (`dashboard.week_states`), passed on the dashboard and the Today page only. Planned days keep today's `is-set` fill; `is-missed` (dotted blue border on white, wins over the fill and the moved dashes) and `is-extra` (light ring) are added. The split page passes nothing and looks as before.
- "This week" shows an empty log's day as "Rest".

### 4.6 Missed day is a link, and tooltips
- `pages/_calendar`: a missed day is `link_to workout_day_path(plan_day, date: date.iso8601)`. The workout day's page already takes `?date=` for any past date (`LoggingDate`), shows "Pull, Tuesday, November 3" and logs on that date on the first exercise or set. No new route, controller or model.
- `CalendarHelper#day_title(date, state, logs, workout_day)`: "Monday, November 16: Push workout" (logged), "Tuesday, November 3: Pull missed. Add it.", "Tuesday, November 24: Pull planned", or just the date. Used as `title` and `aria-label`.
- The strip: `label` gets ", missed. Add it." or ", trained off the plan" appended; `title` and `aria-label` are the same text. Its missed link already opened the workout on the right date.
- CSS: `a.calendar-day.is-missed` gets `text-decoration: none` and the keyboard focus outline.

### 4.7 Hover halo
- `.calendar-day` and `.week-circle` get `outline: 2px solid transparent; outline-offset: 2px`, and on `:hover` inside `@media (hover: hover)` the outline becomes `$hover-halo` (a 35 % blue). An outline stacks with every fill, dotted border and inset ring, so no state needs its own rule. Today's circle on the strip uses offset 6 px so it clears its double ring.

### 4.8 Tests
See section 7.

### 4.9 CLAUDE.md
The code-map lines for the calendar and the week strip were rewritten for the new meaning, and lines were added for the fold, the month page and the tooltips.

## 5. Decisions

| Decision | Alternative rejected | Why |
|---|---|---|
| The month name folds the calendar; a separate "Month" link opens the page | Name opens the page, a chevron folds | Both features asked for the same tap. *Assumption:* the owner accepted this by saying "continue". |
| Month page: current month only, heaviest weight only | ‹ › to earlier months, total volume | Only what was asked. *Assumption* (open questions not answered). |
| Planned days are filled from the start of the week, dotted once they pass with nothing logged | Fill only when trained | The owner's correction: "keep the filled blue until the next day". |
| A workout counts as logged with an exercise or a started timer | Only sets or cardio rows | The owner: keep timer-only logged; an exercise added is logged. |
| A log with nothing in it is ignored where the calendar, "This week" and totals look, not deleted | Delete a log when its last exercise is removed | Deleting breaks the redirect to a logged workout's page, and `db:seed` would bring old empty logs back from `data.yml`. The owner's answer on this was unclear, so I did the safe thing. |
| "Missed" only from the first logged workout | All past planned days of the month | Otherwise a new user's whole month is dotted. |
| Hover: an outline halo for every day | Per-state hover colours | One rule, works on every look. |
| The strip's `states` is optional | Always show states | The split page is the plan and has no logs. |
| Stayed on one branch (month page plus these changes) | A branch started from the month branch | The month page was uncommitted, so a new branch from it would have been empty. The owner chose "on top of month page". |
| An old test line (`> a.calendar-day`, 3) was changed to `> a.calendar-day.has-workout` | Leave it failing | Asked first; the owner confirmed missed days must be links. |
| `DayStates` as its own class | More methods on `Dashboard` | `Dashboard` was at rubocop's 100-line class limit. |

## 6. How it works now

- **Dashboard** (`pages#dashboard`) and **Today** (`pages#home`) build `Dashboard`. The calendar gets `states: dashboard.calendar_states, day_states: dashboard.day_states`; the strip gets `states: dashboard.week_states`.
- **A day's story:** the plan says which weekdays have a workout (`Split#week_plan(date)`, moves included). Trained = a log with an exercise or a started timer. `DayStates` combines the two with today's date into planned, missed, extra, or nothing.
- **Forgot to log Tuesday's Pull?** On the dashboard, tap the dotted 3 (or the dotted circle on the strip). The Pull page opens on Tuesday, November 3. Add an exercise or a set: the log is created on that date, and the day turns filled.
- **Try it:** `bin/rails server`, sign in, open Dashboard. Month name folds; "Month" opens the page; hover the days for the halo and tooltips.

## 7. Tests and verification

- `bin/rails test`: 155 runs, 2163 assertions, 0 failures, 0 errors. `bundle exec rubocop`: 57 files, no offenses. `bundle exec brakeman`: 0 warnings. `test/lib/seed_data_test.rb`: 4 runs, 0 failures.
- **New tests:** `test/models/workout_log_test.rb` (`logged?`), `test/models/workout_summary_test.rb` (`by_exercise`), `test/models/dashboard_test.rb` (month totals; day states by plan, moves and the first-log bound), `test/integration/dashboard_flow_test.rb` (the fold and the month page; the states on the calendar and the strip; tooltips; clicking a missed day opens the right date and the first exercise logs it there; the split page shows only the plan).
- **Changed existing assertions:** only `dashboard_flow_test.rb:164`, with the owner's OK (section 5).
- **In headless Chrome at 390 px** on a test-environment server with a throwaway user, removed afterwards: the open and folded calendar, the month page, every day state on the calendar and the strip, and a click on a missed day (it opened "Pull, Tuesday, November 3"). A long exercise name broke a row onto three lines; fixed (`white-space: nowrap` on the right side) and looked at again.
- Measured how far each calendar number sits from its circle's centre: 0.13 px sideways, 0.25 px up or down (with and without `tabular-nums`).
- **Not verified:** a real phone; a real mouse (headless Chrome reports no hover, so the halo was checked with its rule forced on); old weeks of real data.

## 8. Every file changed (28 including this doc)

**Models and helpers**
- `app/models/day_states.rb` (new): planned / missed / extra per day, and the plan's workout on a date.
- `app/models/dashboard.rb`: month methods, `calendar_states`, `week_states`, public `day_states`; `calendar_logs` loads exercises.
- `app/models/workout_log.rb`: `logged?`.
- `app/models/workout_summary.rb`: `by_exercise`, `heaviest`, `workouts` counts logged workouts.
- `app/helpers/calendar_helper.rb` (new): `day_title`.
- `app/helpers/application_helper.rb`: Dashboard tab lit on the month page.

**Controller and routes**
- `app/controllers/pages_controller.rb`: `month` action.
- `config/routes.rb`: `GET /dashboard/month`.

**Views**
- `app/views/pages/_calendar.html.erb`: fold, "Month" link, states, tooltips, missed link.
- `app/views/pages/month.html.erb` (new): the month page.
- `app/views/pages/_summary_tiles.html.erb` (new): totals tiles shared with "This week".
- `app/views/pages/_week_overview.html.erb`: uses the tiles; an empty log reads Rest.
- `app/views/pages/dashboard.html.erb`, `app/views/pages/today.html.erb`: pass states to the calendar and the strip.
- `app/views/splits/_week.html.erb`: optional `states`, tooltips.

**Styles**
- `app/assets/stylesheets/pages/_dashboard_calendar.scss`: day states, fold button, hover halo, missed link.
- `app/assets/stylesheets/pages/_dashboard_month.scss` (new): month page rows.
- `app/assets/stylesheets/pages/_split_week.scss`: missed, extra, hover halo.
- `app/assets/stylesheets/config/_colors.scss`: `$extra-ring`, `$hover-halo`.
- `app/assets/stylesheets/application.scss`: imports the month styles.

**Tests**
- `test/integration/dashboard_flow_test.rb`, `test/models/dashboard_test.rb`, `test/models/workout_log_test.rb`, `test/models/workout_summary_test.rb`.

**Docs**
- `CLAUDE.md`: code map.
- `doc/Features/Features.md`: the two Calendar features moved to "Features added (DONE)".
- `doc/Issues/Issues.md`: the first "Calendar and week" issue moved to resolved; three potential issues added.
- `doc/calendar-month-and-missed-days.md` (new): this file.

`db/seeds/data.yml` was dumped and came out unchanged (1 user, 3 splits, 6 workouts, 48 sets already in the file), so it is not part of the commit.

## 9. Known gaps

- Missed days follow today's plan even for old weeks; a week trained under an earlier split can show wrong states.
- Recent workouts, "Last time" and "Move a workout" still count a workout with nothing in it.
- The "numbers slightly off centre" issue is still open: not reproducible, waiting for which day and device.
- Hover and taps not tried on a real mouse or phone.
- A missed day can be any distance back in the month; nothing limits it.
- Added to "Potential issues" under "Home page": the first three. Items moved: Features.md (2 bullets, Calendar), Issues.md (1 bullet, "Calendar and week showed a missed day as done").
- The `~/.claude/settings.json` change (default model `opusplan`) is outside the repository.
