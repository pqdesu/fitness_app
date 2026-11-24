# Cardio timer (`cardio-timer`)

## 1. Summary

The branch builds the note in `doc/Features/cardio-timer-feature.md`:

> Remove the general timer for cardio. And add a timer, same as rest, but this time it is to record the amount of time the person did the cardio. It should also be possible to add manually but also use the timer.

- **Cardio timer:** every cardio exercise has its own timer, where a lift has its rest timer. Start it, Stop it, and the time goes into the Add form.
- **Two ways to log:** on today's workout an idle cardio exercise shows **Start cardio timer** or **Add manually**. Add manually opens the form folded behind it.
- **While it runs:** the form keeps incline and speed. Its button is "Stop and add": it stops the timer and saves a row with the timed duration.
- **No workout timer on a Cardio workout:** the Cardio workout (the rest-day Cardio button) loses the workout timer, its paused-timer alert and the automatic start. Other workouts keep theirs.
- **Open cards:** a Cardio workout opens its first exercise, and a cardio exercise whose timer has started stays open.

State: `bin/rails test` gives 149 runs and 0 failures; `bundle exec rubocop` no offenses; `bundle exec brakeman` no warnings. The flow (Start, Stop, Add) was tried in a real browser on a copy of the development database at **desktop width**; the phone layout (390 px) was not checked, because the browser tool would not shrink the page. The "Add manually" button, the "Stop and add" button and the open first card were covered by tests of the markup and not looked at after they were added.

## 2. Timeline

| Request | What was done |
|---|---|
| "Check the current code and tell me the new features and the new skills the past run used" | Read the history. The last run built cardio exercises and the rest-day Cardio button, and added no skills. The four project skills are `finalize-branch`, `investigate-issues`, `plan-features`, `update-seed-data`. |
| "What about impeccable or ponytail?" | They were installed on 20 Nov in the user's config (not the repo) and are used in the docs of several branches. |
| "Use /opusplan in this session" | A session cannot switch its own model; the owner ran `/model opusplan`. |
| "Plan the timer for cardio" | `plan-features` skill in plan mode (Opus). The owner answered: the cardio timer is on every cardio exercise, and Stop fills the form. After the first plan was rejected: the rest timer is never on a cardio exercise, and the workout timer is removed on the rest-day Cardio workout only. Plan approved. |
| Build | Worktree `.claude/worktrees/cardio-timer`, implemented on Sonnet. Tests, rubocop, brakeman, and a browser check on a copy of the development database. |
| "The exercise box is shortened and not open for the first one. I want to add the incline and speed when the timer runs" | A Cardio workout opens its first exercise (and any with a started timer). The form stays while the timer runs, with "Stop and add". |
| "Either the start cardio or the manual add part... another button" | "Add manually" beside Start; the form is folded until it is tapped. |
| "Finalize this branch" | This doc, the issue list, the seed data, commit and push. |

## 3. Starting point

- A cardio exercise (feature 7) was logged as rows of incline, speed and time, all typed in Min and Sec. It had no timer at all: the rest timer was hidden for cardio.
- The Cardio workout (feature 8) still showed the general workout timer (Start, Pause, Stop) and its paused-timer alert.

## 4. Changes

### 4.1 The timer uses the rest timer's columns (no migration)
- **Before:** `workout_log_exercises.rest_started_at` and `rest_ended_at` held a lift's rest between sets.
- **After:** the same two columns also hold a cardio exercise's timer. A logged exercise is cardio or lifts, never both, so they do not clash. `WorkoutLogExercise` has a comment saying so, and a new reader `timer_seconds` (the stopped time in seconds, or nil). `rest_running?` and `take_rest!` are reused as they are.
- **Why:** nothing new to migrate, so the shared development database is untouched.

### 4.2 Routes and `RestTimersController`
- **Before:** `POST/PATCH/DELETE /workout_log_exercises/:id/rest` (needs a logged exercise).
- **After:** also `POST /workout_exercises/:id/rest` (`workout_exercise_rest_path`). A planned cardio exercise with nothing logged yet starts its timer through the plan, and the controller takes the entry with `WorkoutExercise#entry_on!(logging_date)`, which logs the workout, as a first row would. A date to come is refused by `WorkoutLog`; `create` rescues `RecordInvalid` and redirects back with "Timer not started: ...". The controller includes `LoggingDate`.

### 4.3 `CardioEntriesController#create`
- **After:** if the timer runs, it is stopped first (`rest_ended_at`); the row takes the typed time, or else the timer's (`duration_seconds ||= entry.timer_seconds`); then `take_rest!` clears the timer. All of it is in the existing transaction, so a refused row also leaves the timer as it was.

### 4.4 The timer partial `cardio_entries/_timer`
- New, about 30 lines, modelled on `workout_sets/_rest_timer`. Idle (today, nothing started): **Start cardio timer** and **Add manually** (a Bootstrap collapse button for the form, no JavaScript of its own). Running: the clock (`timer_controller.js`) and Stop, with `data-rest-running` and `data-rest-name="cardio"`. Stopped: "Cardio 0:12 in the form below" and an × to throw it away. Earlier days show nothing, only the form.

### 4.5 The form `cardio_entries/_form`
- Takes `entry`. Folded behind Add manually when the day is today and no timer has started; otherwise open (an earlier day, a running or a stopped timer). While the timer runs it has no Min and Sec, and the button is "Stop and add". A stopped timer's time fills Min and Sec.

### 4.6 Pages
- `workout_exercises/show`: renders the timer above the form; the rest alert is now rendered for cardio too, but only while its timer runs (`if !cardio || @entry&.rest_running?`), so the idle page is as before.
- `workout_logs/show`: a Cardio workout skips the workout timer and its paused-timer alert; each cardio card has the timer and form; a Cardio workout opens its first card, and a cardio card whose timer has started is open.

### 4.7 `rest_alert_controller.js`
- Leaving the page while a timer runs asks "Did you forget to stop your **cardio** timer?" with "Stop cardio" (the name comes from `data-rest-name`, default "rest", so the rest wording is unchanged).

## 5. Decisions

| Decision | Alternative rejected | Why |
|---|---|---|
| Reuse the rest columns | New `timer_*` columns | A migration for the same two values; the shared database. |
| Reuse `RestTimersController` | A new controller | Same Start/Stop/throw-away; only the planned-exercise start is new. |
| Stop fills the form, Add saves (owner) | Stop saves a row at once | The owner chose it: incline and speed can still be given. |
| Typed time wins over the timer's | Timer always wins | Manual correction must be possible. |
| Workout timer removed on the Cardio workout only (owner) | Removed on any page with cardio | The timer belongs to the workout; a treadmill inside a Legs workout keeps its workout's timer. |
| The rest alert shows on a cardio exercise page only while its timer runs | Always | The old test says a cardio page has no rest alert; the idle page keeps that. |
| Start only on today's workout | Any day | Same as the rest and workout timers. |
| Assumption | | "The first one not open" read as the first exercise card being folded in a Cardio workout. |

## 6. How it works now

On a cardio exercise on today's workout: tap **Start cardio timer** (the workout is logged if it was not), the clock counts. Fill in incline and speed if you like, then tap **Stop and add** (saves a row with the timed time) or **Stop** (the time goes into the form, then **Add**). **Add manually** opens the form to type the time. An earlier day only has the form. Try it: `bin/rails server -p 3001` from the worktree or after merging, open any cardio exercise of today's workout.

## 7. Tests and verification

- `bin/rails test`: 149 runs, 0 failures. New tests in `test/integration/cardio_flow_test.rb`: Start logs the workout and runs the timer, Stop and Add keep the time, adding while it runs stops it, a typed time wins and the timer can be thrown away, a day to come is refused and an earlier day has no Start, a Cardio workout has no workout timer while another keeps it, and the first Cardio card is open.
- Three tests written earlier in the session were changed when later requests changed the behaviour (the form shows while the timer runs; the form is folded behind Add manually). Two timing tests were made exact with `freeze_time` after they failed one run in a hundred because `travel` cuts off the fraction of a second; the app code was not at fault.
- `bundle exec rubocop`: no offenses. `bundle exec brakeman`: no warnings.
- Real browser, desktop width, on a copy of the development database (removed after): Start logged the workout and the clock ran; Stop filled 0 min 12 sec; Add saved the row at 0:12.
- **Not verified:** 390 px or a real phone; "Add manually" and "Stop and add" in a browser; the leave-the-page box for cardio; the folded and opened cards in a browser.

## 8. Every file changed (14)

Code
- `app/models/workout_log_exercise.rb`: comment on the two timer columns and `timer_seconds`.
- `app/controllers/rest_timers_controller.rb`: finds the entry through a planned exercise (starts the workout), rescues a refused start.
- `app/controllers/cardio_entries_controller.rb`: Add stops a running timer, takes its time, clears it.
- `config/routes.rb`: `POST /workout_exercises/:id/rest`; comment on the rest route.
- `app/javascript/controllers/rest_alert_controller.js`: names the timer ("cardio" or "rest") in the leave box.

Views
- `app/views/cardio_entries/_timer.html.erb` (new): Start, Add manually, the clock, Stop, the stopped time.
- `app/views/cardio_entries/_form.html.erb`: folded behind Add manually, "Stop and add", fills from a stopped timer.
- `app/views/workout_exercises/show.html.erb`: the timer above the form; the rest alert while it runs.
- `app/views/workout_logs/show.html.erb`: no workout timer on a Cardio workout; timer per cardio card; open first card.

Tests
- `test/integration/cardio_flow_test.rb`: 6 new tests and 3 changed assertions.

Docs and data
- `CLAUDE.md`: a "Cardio timer" line in the code map.
- `doc/Issues/Issues.md`: four potential issues from this branch (section 9).
- `doc/cardio-timer.md` (new): this doc.
- `db/seeds/data.yml`: the dump gained 4 Cardio exercises to the catalogue (Treadmill, Stationary bike, Stair climber, Elliptical) and the owner's Cardio workout of 2026-11-24 (Treadmill, 2 rows). The totals are 1 user, 3 splits, 6 workouts, 48 sets; nothing was removed from the file.

## 9. Known gaps

- Moved or added to `doc/Issues/Issues.md` under "Potential issues": the cardio timer shares the rest timer's columns; not tried on a real phone; a failed manual add folds the form again; a timer left running keeps counting. Nothing was moved to "Issues resolved".
- The existing item "A cardio machine just added starts folded" is only partly helped (the first card of a Cardio workout opens); it was left in place.
- `doc/Features/Features.md` was not changed: the cardio timer is in its own note, `doc/Features/cardio-timer-feature.md`, which was left as the owner wrote it.
