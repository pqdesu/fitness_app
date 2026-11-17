# Context prompt: home page work (branch `home-page-overview`)

Paste this into a new session to continue the work. It records the whole conversation of 2026-11-16 and 2026-11-17: what was asked, what was decided, and what changed in the code. Read `CLAUDE.md` and `doc/Prompt/project-context.md` first; this file only covers this branch.

## State of the branch

- Branch: `home-page-overview` (renamed from `claude/home-page-implementation-895811` before the first push, because the repo wants plain names without digits or a `claude/` prefix).
- Pushed to GitHub. **No pull request is open and nothing is merged.** The owner wants to keep working on it and does not want it merged yet.
- Not finalized: there is no change doc at `doc/home-page-overview.md` yet. The `finalize-branch` skill writes it when the owner asks.
- Tests: `bin/rails test` gives 59 runs, 0 failures. `bundle exec rubocop` reports no offenses.
- The layout was checked in a real browser at 393px wide (iPhone 16), and at 430px and 440px for the first round of changes. No sideways scroll.

## To run it on another machine or user

```bash
git fetch origin
git switch home-page-overview
bin/setup
bin/rails db:migrate      # this branch adds one column: workout_logs.rest_day
bin/rails server
```

The migration `20261117100000_add_rest_day_to_workout_logs.rb` only adds a boolean column with a default of false. `master` code ignores it, so it is safe on a database that `master` also uses.

## What the owner asked for, in order

All requests come from `doc/Features/Features.md` (Home page section) and `doc/Issues/Issues.md` (Home page section).

1. Add a weekly overview under the week of the split, and remove the Splits, Workouts logged and Sets recorded boxes.
2. On Recent workouts, make the whole block clickable, not only the name.
3. Make it work on iPhone 16 and later.
4. Make Recent workouts a dropdown: a summary first, more detail when opened.
5. Do the same for the Active split: expand to show the weekdays.
6. A Today box with today's workout, and a quick button to start the workout.
7. Issue: deleting a workout opened from the home page went to History instead of back to the home page.
8. Issue: no button to start a workout on a rest day. When recorded, it must show it was a rest day the user trained on, without changing the split.
9. Let the `finalize-branch` skill edit `Features.md` and `Issues.md`, and nothing else.

## Decisions taken

- **Keep the counts in the controller.** `@splits_count`, `@logs_count` and `@sets_count` stay in `PagesController#home` although the boxes are gone. The owner said they might be used again.
- **Request 2 was replaced by request 4.** The whole row was first a link (`stretched-link`). A dropdown row has to expand on tap, so the row is now the toggle. The owner's answer: exercises are pills inside the opened row, and "Open workout" is the only link out.
- **Active split summary.** The owner wants: sets done, top weight of a set, and number of exercises. It is this week's totals (Sunday to Saturday). The weekday rows are behind a "Show days" toggle.
- **Recent workout detail.** Heaviest set per exercise; tapping an exercise shows the rest of its sets.
- **"Start workout" creates no log.** The owner chose this over creating an empty log. A log is still only created when the first set is added (`WorkoutExercise#entry_on!`). "Start workout" only opens the workout day. A day that is started and abandoned leaves nothing in the calendar or History.
- **Exercises in the week summary count distinct exercise names**, and only exercises with at least one set. This was my choice; the owner has not confirmed it.
- **Rest day is stored, not computed.** `workout_logs.rest_day` is set when the log is created and never recalculated, so editing the split later does not rewrite history. Logs made before the column existed are not marked.
- **No new JavaScript.** All dropdowns use Bootstrap's collapse (`data-bs-toggle="collapse"`), which the app already loads.

## How the home page works now

- **Left column:** the month calendar only. The three totals boxes are gone.
- **Active split card:** split name, "Change" link, the week circles, then "This week": Workouts, Exercises, Sets, Top weight. "Show days" opens one row per day: workout name and set count, linked to that workout, or to `/workout_logs?date=…` when the day has several. Unlogged days show "Rest", or "–" for days still ahead. The toggle reads "Hide days" when open.
- **Today box, planned day:** "Start workout" until sets exist, then "Continue". Once sets exist the line reads "Logged today · N exercises · N sets · top N kg". Both buttons open the workout day.
- **Today box, rest day:** "Rest day" with a primary "Start workout" button. It opens a panel with one pill per workout of the active split (for example "Upper Mon"); each opens that workout day. Workouts logged today are listed with a "Rest day" chip.
- **Recent workouts:** each row is a dropdown. Closed: name, date, set count, "Rest day" chip if it applies, split name, chevron. Open: exercise and set counts, one pill per exercise with its heaviest set (tap to list every set in order), the notes, and "Open workout".
- **Rest day chip:** shown on the workout page ("Rest day, trained anyway"), in History, in Recent workouts and in the Today box.
- **Deleting a workout:** opened from the dashboard (`?from=dashboard`), it returns to the dashboard. From anywhere else it returns to History.

## Files changed

New:

- `app/models/workout_summary.rb`: plain Ruby class. Totals over loaded logs: `workouts`, `exercises`, `sets`, `top_weight`, `sets_in(log)`. Needs logs loaded with `includes(workout_log_exercises: :workout_sets)`.
- `app/views/pages/_week_overview.html.erb`: the "This week" summary and the collapsible day rows.
- `app/views/pages/_recent_workout.html.erb`: one recent workout as a dropdown with exercise pills.
- `db/migrate/20261117100000_add_rest_day_to_workout_logs.rb`: adds `workout_logs.rest_day`.
- `test/models/workout_summary_test.rb`: three tests for the summary.
- `doc/Prompt/home-page-overview-context.md`: this file.

Changed:

- `app/controllers/pages_controller.rb`: loads `@week_dates`, `@week_logs` (with exercises and sets), `@week_summary`, `@today_summary`. The old counts are kept.
- `app/controllers/workout_logs_controller.rb`: `destroy` redirects to the dashboard when `params[:from] == "dashboard"`.
- `app/models/workout_log.rb`: `mark_rest_day` before validation on create. True when the log's own split plans nothing on that weekday.
- `app/views/pages/home.html.erb`: totals boxes removed, weekly overview rendered, Today box buttons and rest-day panel, recent list rendered from the partial.
- `app/views/workout_logs/show.html.erb`: the Delete button passes `from`; rest day chip in the header.
- `app/views/workout_logs/index.html.erb`: rest day chip in the Workout column.
- `app/assets/stylesheets/components/_app.scss`: `.chip-rest`, and at the end of the file `.week-overview`, `.week-summary`, `.toggle-days`, `.week-overview-days`, `.today-start`, `.recent-*`, `.lift-pill`, `.lift-sets`. Touch targets are at least 44px.
- `db/schema.rb`: the new column.
- `test/integration/workout_flow_test.rb`: new tests for the weekly summary, the recent dropdown, delete from the dashboard, and the rest-day workout. The existing dashboard test now expects "Start workout".
- `test/models/workout_log_test.rb`: rest day is marked, and stays after the split changes.
- `.claude/skills/finalize-branch/SKILL.md`: new step 3a. Finalizing may move finished items in `doc/Features/Features.md` and `doc/Issues/Issues.md`, and may edit no other existing file.
- `doc/Features/Features.md`, `doc/Issues/Issues.md`: the owner's latest lists, copied from the main folder so this branch carries them. In `Issues.md`, "Deleting workout" and "No add workout on rest day button" are under "Issues resolved (DONE)".

## Still open

Home page issues in `doc/Issues/Issues.md`, not started:

- **Only split workouts are selectable on a rest day.** The owner wants to either pick a split day or create a new one.
- **Days on the split names and repetitive workout names.** Show only the workout name without the day, and when the same workout is planned on other days (Lower on Wednesday and Saturday), offer to move one of them, as an info pop-up. For all splits. This one needs clarifying with the owner before building.

Other open items, outside this branch's scope so far: "Exercise name edit" (muscle group should be a dropdown), and the General, Calendar and Exercise page features in `Features.md`.

Not done on purpose:

- `Features.md` still lists the finished Home page features in the open section. Moving them to "Features added (DONE)" is left for the finalize step.
- `doc/Prompt/project-context.md` is not updated for this branch.
- No pull request.

## Working rules the owner repeated in this conversation

- Explain the plan before implementing a new feature, and wait for the go-ahead.
- Use the browser only to look at the pages. Do not click anything that changes data.
- Never merge, never open a pull request unless asked, never pull or merge in the owner's main folder.
- Do not remove this worktree or finalize until the owner asks.
