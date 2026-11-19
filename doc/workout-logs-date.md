# Sets logged on the workout's own day

Branch `workout-logs-date`. The app created it as `claude/workout-logs-date-issue-3e0c03`, and it was renamed before anything was pushed. It starts from `master` at `702232e`.

## 1. Summary

This branch fixes the main part of the issue under **Exercises** in `doc/Issues/Issues.md`: "Future workout logs have present days logged".

Before, a set added from a workout day's exercise page was always saved under **today's date**, whichever day the workout was planned for. Two things went wrong because of it:

- Friday's curl, added on Wednesday, was saved as Wednesday.
- Wednesday's Lower, logged the next day, was saved as Thursday and marked as a rest day workout.

Now a workout day's pages save sets to **the date that workout falls on this week**:

- **Earlier this week:** opening Wednesday's Lower on Thursday fills in Wednesday.
- **Later this week:** opening Friday's Upper on Wednesday shows that the workout is on Friday, and there is no Add set form. The server also refuses a set for a date to come.
- **Today:** the dashboard's "Start workout" and "Train as extra" open the workout on today's date, as before.
- **Past midnight:** the pages carry the date they were opened on. A set added at 00:30 from a workout started at 23:00 stays on the day it was started.

The owner's Lower workout in the development database was moved from Thursday 19 Nov to Wednesday 18 Nov, and `db/seeds/data.yml` was corrected to match.

State:

- All 89 tests pass, with two new tests.
- Rubocop reports no offenses, and Brakeman reports no warnings.
- The changed pages were checked in headless Chrome at 390 px (phone width), and at desktop width.

## 2. Timeline

1. **"Investigate the issue under Exercises – Future workout logs have present days logged … the main issue is the one in the past … I want this issue to be fixed."**
   - I traced the cause with the `investigate-issues` skill (section 3). The owner had already asked for the fix, so I went on to fix it.
   - I renamed the branch to `workout-logs-date`. The repo's rule is plain words, with no digits and no `claude/` prefix.
   - I added `LoggingDate` and `WorkoutDay#date_in_week_of`, passed the date through the workout day, exercise, set and dashboard pages, and updated and added tests.
   - I moved the owner's Lower log (id 27) from 2026-11-19 to 2026-11-18, with `rest_day: false`.
   - I corrected the same workout in `db/seeds/data.yml`. I also removed the curl workout that had been wrongly saved on 18 Nov, which the owner had already deleted from the database (section 5).
   - I ran a server from the worktree on port 3001 and checked the pages in the Chrome extension. That window stayed at desktop width.
2. **"Use the chrome installed in WSL to inspect mobile layouts."**
   - The chrome-devtools MCP server did not connect in this session.
   - I drove the WSL Chrome (`/usr/bin/google-chrome`, headless) over the DevTools protocol, with a small Node script (`node --experimental-websocket`) kept in the session's scratchpad, not in the repo.
   - The script signed in a temporary user (`browser-check@example.test`, with a generated password) and took screenshots at 390 × 844. The user was deleted afterwards.
   - The screenshots showed the long date on the workout day page pushing Edit and Delete onto their own line. The date is now the dashboard's shorter style ("Wednesday, November 18"; "Today · Thursday, November 19").
3. **The owner asked me to add a plugin marketplace and install a plugin** (`/plugin marketplace add …`, `/plugin install …`).
   - Those are built-in Claude Code commands that install third-party code, so I gave the owner the commands to run themselves. Nothing in the repo changed.
4. **"Use my skill to re seed the database."**
   - I ran the `update-seed-data` skill: `seed:dump`, the diff, the seed test, and a round trip through a scratch database. The file came back identical.
5. **"Finalize it."** This doc, the issue list, the commit, the push and the pull request.

## 3. Starting point

The chain that saved the sets:

- `WorkoutDaysController#show` counted "sets today" from `session_of(@workout_day.day, Date.current)`.
- `WorkoutExercisesController#show` showed `@workout_exercise.entry_on(Date.current)`, under a card headed **Today**.
- `WorkoutSetsController#create` saved every set from a planned exercise with `planned.entry_on!(Date.current)`.
- `WorkoutExercise#entry_on!(date)` finds or creates the user's session of that workout on that date. `WorkoutLog#mark_rest_day` then marks it as a rest day when the split has nothing on that date.

No page knew which date a workout day stood for. The workout day page only showed its weekday name ("Wednesday"), and every link from it was a plain `workout_exercise_path(we)`.

That made all of these happen:

- **Future workout:** opening Friday's Upper on Wednesday and adding a curl created an Upper session dated Wednesday. That broke the rule "a split has one workout a day", alongside Wednesday's own workout.
- **Past workout:** opening Wednesday's Lower on Thursday created a Lower session dated Thursday. Thursday is a rest day in the owner's split, so it was marked `rest_day: true`. That is the data the owner reported: log 27, Lower, dated 2026-11-19, rest day.
- **Midnight:** a workout started at 23:00 and continued at 00:30 was split across two sessions on two dates.

`WorkoutLog` already refused dates in the future (`date_in_range`), but the date passed in was always today, so that check never came into play.

## 4. Changes

### `WorkoutDay#date_in_week_of(date)` (new)

```ruby
def date_in_week_of(date)
  date.beginning_of_week(:sunday) + (split.week_plan(date).key(self) || weekday)
end
```

This gives the date of the workout in the Sunday-to-Saturday week of `date`. It reads `Split#week_plan`, so a workout moved for this week (`WorkoutDayMove`) counts on the day it was moved to. If the plan does not list the day, it falls back to the planned weekday.

### `LoggingDate` controller concern (new, `app/controllers/concerns/logging_date.rb`)

```ruby
def logging_date(workout_day)
  date = text_param(:date)
  (Date.iso8601(date) if date.present?) || workout_day.date_in_week_of(Date.current)
rescue Date::Error
  workout_day.date_in_week_of(Date.current)
end
```

This is the one place that decides which date a workout day's pages log on:

- the `?date=` the page was opened with, which the pages pass along;
- otherwise, the workout's date this week.

A value that is not a date falls back to the workout's date this week. `logging_date_label(date)` ("Today" or the weekday name) is a helper for the exercise page heading.

The concern is included in `WorkoutDaysController`, `WorkoutExercisesController` and `WorkoutSetsController`.

### Controllers

- **`WorkoutDaysController#show`:** sets `@date`. It counts the sets of that date's session (`@sets_today` was renamed `@sets_logged`).
- **`WorkoutExercisesController#show`:** sets `@date` and shows `entry_on(@date)`.
- **`WorkoutExercisesController#create`:** the "Add exercises" modal now keeps the date in its redirect.
- **`WorkoutExercisesController#update`** (equipment): updates that date's entry, which before was today's. It redirects with the date.
- **`WorkoutExercisesController#destroy`:** redirects to the day page with the date.
- **`WorkoutSetsController#create`:** before, the set went to today:

  ```ruby
  entry = planned.entry_on!(Date.current)
  ```

  Now it goes to the page's date:

  ```ruby
  date = logging_date(planned.workout_day)
  back = workout_exercise_path(planned, date:)
  entry = planned.entry_on!(date)
  ```

  For a date to come, `WorkoutLog`'s existing check raises `RecordInvalid`. The existing `rescue` turns that into the message "Set not added: Date can't be in the future." and nothing is saved.
- **`WorkoutSetsController#page_of`** (edit and delete of a set from the exercise page): returns with the date.

### Views

- **`workout_days/show`:**
  - The subtitle shows the date the sets go to, "Wednesday, November 18", or "Today · Thursday, November 19". Before, it was the weekday only.
  - Every link to an exercise, the remove buttons and the picker's form URL carry `date: @date`.
- **`workout_exercises/show`:**
  - The card heading is "Today" or the weekday, with the long date.
  - For a date to come, it shows "Upper is on Friday this week. Add sets on that day." with no form.
  - The empty state says "No sets yet on Wednesday" for a past day.
  - The back arrow, Remove, the equipment form, the set table and the set form all carry the date.
- **`workout_sets/_form`:** a `date` local. When given, the form posts to `…/workout_sets?date=…`.
- **`workout_sets/_table` and `workout_sets/_set`:** pass `date` on, so editing or deleting a set returns to the same date.
- **`pages/home`:** "Start workout" / "Continue" opens `workout_day_path(today_workout, date: today)`.
- **`pages/_rest_day_start`:** "Train as extra" opens `workout_day_path(day, date: today)`, so a workout trained on a rest day is still logged today and marked as a rest day workout.
- **`workout_logs/show`:** the back arrow returns to the workout day on the log's own date.

### Tests

- **New, `logging_flow_test.rb`:** "a workout day logs on its date this week: an earlier day fills that day in, a day to come takes no sets". On Thursday 2026-11-19 it checks:
  - Wednesday's Lower shows Wednesday and saves sets on Wednesday, not as a rest day, with or without `?date=`.
  - Friday's Upper shows no form, and a posted set is refused.
  - The plan can still get exercises ahead of time.
  - A bad `?date=` falls back to the workout's date.
  - At 00:30 on Friday, a set from Wednesday's page still goes to Wednesday.
- **New, `workout_day_test.rb`:** `date_in_week_of` for different days of a week, the next week, and a workout moved for one week.
- **Updated:** tests that logged through a day on Monday (`weekday: 1`) without fixing the clock now use `Date.current.wday`, because their date is now the workout's date this week. Expected links and redirects now include `date=`. The two tests that train a second workout of the split today post with `date: Date.current`, as the pages opened from "Train as extra" do.

### Data

- **Development database:** `WorkoutLog` 27 (Lower, admin) changed from 2026-11-19, rest day, to 2026-11-18, not a rest day. Its 7 exercises and 19 sets are unchanged.
- **`db/seeds/data.yml`:**
  - That workout moved from `2026-11-19` to `2026-11-18`, with `rest_day: false`.
  - The `2026-11-18` Upper workout (one Barbell curl set) was removed. It was the curl wrongly saved on Wednesday, and the owner had already deleted it from the database.

### `CLAUDE.md`

- One product rule: sets go to the workout's date this week; a later day takes none; "Start workout" and "Train as extra" open today.
- One code map line: `LoggingDate` and `WorkoutDay#date_in_week_of`.

## 5. Decisions

- **The date comes from the week's plan, not from a date picker.** The owner's top rule is few taps. Opening the workout from the week strip already says which day it is, so the right date needs no extra input.
  - Rejected: a date field on the set form, because it adds typing to every set.
  - Rejected: a "log for yesterday" toggle, a new feature beyond what was asked.
  - A workout logged on the wrong day can still be corrected with the Date field in the logged workout's Details.
- **The date travels in the URL (`?date=`), and every link and form passes it on.** That makes the date fixed for as long as a page is open. A workout started before midnight keeps its date after midnight.
  - Rejected: recomputing the date on each request from "today". That would have split a late workout across two days again.
  - Rejected: storing the date in the session, because two tabs could disagree.
- **"Start workout" and "Train as extra" pass today explicitly.** "Train as extra" means "train this today, as a rest day workout". Without the date, it would have filled in the workout's planned day.
  - Rejected: guessing from whether the planned day was already logged, which is harder to explain on screen.
- **A future workout shows the page, without the form.** The plan can still be edited (add or remove exercises, change equipment), which the owner needs ahead of the day.
  - Rejected: hiding the day or the exercise link. That would also have blocked planning.
  - The server refusal reuses `WorkoutLog#date_in_range`, which already existed, rather than a new check.
- **The week runs Sunday to Saturday,** as everywhere else in the app (`WorkoutDayMove.week_start_of`, the week strip).
  - Consequence: on a Sunday, Saturday's workout is next Saturday, so a forgotten Saturday is not filled in from the workout day page (section 9).
- **The midnight part of the issue** is covered by the date in the URL for workouts of a split. The owner's idea of a "logged past midnight" tag was not built, because the session now simply stays on its day.
- **The data fix also cleared the rest day mark.** The rule is that the mark is never recalculated. Here, though, it was only set because of the bug: Wednesday is a Lower day in the split. So it was set to `false` together with the date.
- **The seed file was edited by hand,** which the `update-seed-data` skill normally keeps for removals the owner asks for. The owner asked for the Wednesday data to be fixed.
  - The removed curl workout had to go: it and the moved Lower workout would both be on 18 Nov in the same split, and `db:seed` would have stopped with "A second workout that day has to come from another split".
  - The later dump and round trip confirm that the file matches the database.
- **Browser check without the extension window.** The Chrome extension's window did not resize to phone width, and the chrome-devtools MCP server did not connect.
  - I drove the WSL Chrome headless over the DevTools protocol instead, emulating a 390 × 844 phone at 2× pixel density.
  - I signed in a temporary user with a generated password, rather than the owner's admin account. It was deleted afterwards.

## 6. How it works now

1. **From the dashboard week strip or the Splits page,** opening a workout day uses `logging_date`. With no `?date=`, that is `date_in_week_of(today)`:
   - Lower on Wednesday, opened on Thursday 19 Nov → 18 Nov.
   - Upper on Friday → 20 Nov.
2. **The day page** shows that date under the workout name. The "N sets" chip counts that date's session. Every exercise link carries `?date=2026-11-18`.
3. **The exercise page's card** is headed "Wednesday", with "November 18, 2026" beside it:
   - Adding a set posts to `/workout_exercises/:id/workout_sets?date=2026-11-18`.
   - `entry_on!` finds or creates the Lower session of 18 Nov, and the set joins it.
   - The rest day mark is worked out for 18 Nov, so it is false on a planned day.
4. **On a date to come,** the exercise page shows "Upper is on Friday this week. Add sets on that day." A set sent anyway is refused with "Set not added: Date can't be in the future."
5. **The Today box** ("Start workout" / "Continue") and the rest day pop-up ("Train as extra") open the day with `?date=` set to today.
6. **Moves:** a workout moved to another day this week (`WorkoutDayMove`) counts on its new day, because `date_in_week_of` reads `Split#week_plan`.

To try it:

```bash
bin/rails server -p 3001
```

Open a workout day of the active split whose weekday was earlier this week, then a later one.

## 7. Tests and verification

- `bin/rails test`: 89 runs, 1188 assertions, 0 failures, 0 errors.
- `bundle exec rubocop`: 40 files, no offenses.
- `bundle exec brakeman`: no warnings.
- Seed data:
  - `bin/rails seed:dump` reported 1 user, 3 splits, 2 workouts and 46 sets.
  - `bin/rails test test/lib/seed_data_test.rb` passed.
  - The file was loaded into a scratch database (`fitness_app_seed_check`) and dumped again, and came out identical. The scratch database was dropped afterwards.
- Browser, at 390 px (headless WSL Chrome):
  - Lower day page (past date), Squat page with two sets and a note, Upper exercise page (future, no form), Upper day page with `?date=` today, the dashboard (rest day) and the Lower logged workout page.
  - Every page was 390 px wide, with no sideways scroll.
  - Adding a set from Wednesday's page in the browser saved it on 2026-11-18.
- Not verified:
  - On a real phone.
  - In the browser, the midnight case (covered by a test with a fixed clock) and a workout moved for the week (covered by a model test).

## 8. Every file changed (22)

Code:

- `app/controllers/concerns/logging_date.rb`: new; the date a workout day's pages log on, and the "Today"/weekday label.
- `app/controllers/workout_days_controller.rb`: counts the sets of the page's date.
- `app/controllers/workout_exercises_controller.rb`: shows, updates equipment for, and redirects on the page's date.
- `app/controllers/workout_sets_controller.rb`: saves sets on the page's date and returns there.
- `app/models/workout_day.rb`: `date_in_week_of`.

Views:

- `app/views/pages/_rest_day_start.html.erb`: "Train as extra" opens on today.
- `app/views/pages/home.html.erb`: "Start workout" / "Continue" opens on today.
- `app/views/workout_days/show.html.erb`: shows the date; links carry it.
- `app/views/workout_exercises/show.html.erb`: heading by date; no form on a date to come; links and forms carry the date.
- `app/views/workout_logs/show.html.erb`: back arrow to the day on the log's date.
- `app/views/workout_sets/_form.html.erb`: posts with the date.
- `app/views/workout_sets/_set.html.erb`: edit and delete return on the date.
- `app/views/workout_sets/_table.html.erb`: passes the date to each set.

Tests:

- `test/integration/logging_flow_test.rb`: new date test; others use today's weekday and expect `date=`.
- `test/integration/dashboard_flow_test.rb`: links carry today's date; back arrow carries the log's date.
- `test/integration/navigation_flow_test.rb`: back targets carry the date.
- `test/integration/week_moves_flow_test.rb`: "Train as extra" carries today; its set posts with today.
- `test/models/workout_day_test.rb`: new `date_in_week_of` test.

Data and docs:

- `db/seeds/data.yml`: Lower workout moved to 2026-11-18; the wrongly saved curl workout removed.
- `CLAUDE.md`: the product rule and the code map line.
- `doc/Issues/Issues.md`: the fixed part of the issue moved to resolved.
- `doc/workout-logs-date.md`: this doc.

## 9. Known gaps

- **The second bullet under the same issue heading is not done:** "the note field always present on each set". It is a separate request and stays open in `Issues.md`.
- **The "logged past midnight" tag** the owner suggested was not built. A late session now stays on its start day instead, as long as the page that started it is used. A workout first opened after midnight from the week strip goes to the workout's planned date this week. If the workout is planned on today, it goes to today.
- **On a Sunday, a forgotten Saturday** cannot be filled in from the workout day page, because Saturday is then next week's. Workaround: log it, then change the date in the logged workout's Details.
- **Workouts not in the split** (`workout_logs#new` / `create`) are still always logged today. That is intended: they have no planned day.
- **Bookmarks:** a URL with an old `?date=` opens that date. A past date still accepts sets, which is the point of the fix; a future date is refused.
- **The Chrome extension window** could not be set to phone width in this setup. Use the headless WSL Chrome, or fix the chrome-devtools MCP server (`npx -y chrome-devtools-mcp@latest --headless --isolated`, which closed its connection in this session).
