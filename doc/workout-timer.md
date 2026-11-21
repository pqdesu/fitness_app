# Workout timer

Branch `workout-timer`, from `master` at `362fd57` (after pull request 20, `dropdowns-off-screen`).

## 1. Summary

The branch adds a timer to each logged workout. It records when the workout started, when it was paused and resumed, and when it stopped. The workout shows its start and end times, the time recorded, and the time spent paused. The owner can also correct a finish time from History, for a timer left running.

- **Controls:** Start, Pause / Resume, Stop, on a workout day's page and on a logged workout's page.
- **Automatic start:** an Account setting makes opening today's workout start it, with its timer running.
- **Past midnight:** a workout stays on its own day, and each time shows its date as a badge: 11:30 PM `20/11` ~ 1:05 AM `21/11`.
- **Exact times:** times are kept and shown to the second, never rounded.
- **Paused-timer alert:** while the timer is paused, adding an exercise or a set asks whether to keep it paused or resume it. Leaving the workout page asks whether to keep it paused or stop it.
- **Edit timer:** a pen in History opens a page to set when the workout finished, in hours and minutes (seconds 0).
- **Design pass:** a status pill (Running, Paused, Finished), a larger clock, full-width buttons on a phone, and short ease-out motion.

**State:**
- `bin/rails test`: 98 runs, 0 failures. The new file `test/integration/timer_flow_test.rb` has 8 tests.
- `bundle exec rubocop`: no offenses. `bundle exec brakeman`: no warnings. `bundle exec bundler-audit check --update`: no vulnerabilities.
- Every page was checked in headless Chrome at 390 × 844 (phone, touch) and 1280 × 800 (desktop).
- Not tried on a real phone.

The bottom navigation bar (the other "General" feature) is **not** in this branch; it is left for another session.

## 2. Timeline

Each request from the owner, in order, and what was done.

1. **"Use the plan-features skill to add the features on General, one feature by one."**
   - The two General features were planned: the timer and the bottom nav bar.
   - Three choices were asked and answered:
     - Pressing Start before anything is logged logs the workout.
     - The auto/manual choice lives in Account settings.
     - The nav bar gets four pages plus Account. This is not built here.
   - The first timer had Start and Stop, an automatic start on the first set, and times shown in History and Recent workouts.
   - The `plan-features` skill itself was committed on its own branch (`claude/code-implementation-skill-2e78d9`); it is not part of this pull request.
2. **"How was the timer built?"** Explained; no change.
3. **"The workout can start the moment I open it, without an exercise."**
   - With the automatic timer on, opening today's workout now logs it and starts the timer.
   - The open page presses Start itself (`auto_submit_controller.js`). Making the page load write would be a GET that writes, and Turbo prefetches links on hover, so touching a link could start a workout.
   - The owner also asked what happens past midnight. The first timer could not be stopped after midnight; this was fixed with a 12-hour limit on Stop, removed later (step 4).
4. **"Run like a normal timer… past midnight keep it in the same day with a badge… simple, not server-side, not every millisecond."**
   - The 12-hour limit was removed: a timer runs until Stop.
   - Only the start and the end are saved; the page counts the time in between.
   - Past midnight, each time gets its date as a badge.
5. **"Make it stoppable and startable again; sum the stopped times; show the time not recorded."**
   - Added Pause and Resume. Then, from the owner's next messages: "Instead of stopped, make it paused and resume", then "Also keep the stop button".
   - Result: Start → Pause / Resume → Stop.
     - `paused_at` is set while paused.
     - `paused_seconds` adds up each pause.
     - `ended_at` is the final stop.
6. **"Past midnight you can't Resume… Why not??" and "Do not round it."**
   - Resume now works on any day; only a new timer is limited to today.
   - Times are exact to the second: "1 h 24 min 7 s".
   - From the owner's question about counting the pause: while paused, the paused time now counts up on screen.
7. **"If I forget to pause… make an edit timer on the History page; seconds should be 0."**
   - A pen beside each workout's time in History opens "Edit timer".
   - It sets the finish in hours and minutes, with the seconds at 0.
8. **"Add alerts when the timer is paused: leaving the workout page, adding an exercise, adding a set."**
   - Owner's answer to a clarifying question: the alerts are about a **paused** timer; "Links inside the app" count as leaving.
   - Added the paused-timer alert. Then, from the next message ("it should ask if the user wants to keep the timer paused or not"), it was worded as **Keep paused / Resume** and **Keep paused / Stop timer**.
9. **"Use the UI skills (Impeccable, Emil Kowalski) to analyze and adjust the timer design."**
   - Impeccable's polish pass: evidence screenshots at 390 and 1280 px, the detector (no findings), then fixes and a second look.
   - The Emil Kowalski skill is not installed (nothing on disk or in the account), so his motion principles were applied from knowledge.
10. **"Finalize this branch with only the timer feature."** This document.

## 3. Starting point

- A workout (`WorkoutLog`) had a date, notes and its exercises, but no times.
- There was no way to record how long a session took.
- "Start workout" on the dashboard created nothing. A split's workout was logged by its first set, or by adding an exercise from its page.
- The feature request (`doc/Features/Features.md`, General):

  > Add a timer of when workout started and then ended, the timer can be set to start automatically when you start a workout or start when I press the timer start button. Then the data shoould be displayed with the day, show how long it was and from what time to the end time.

## 4. Changes

### 4.1 Data (two migrations, additive)

`db/migrate/20261120120000_add_timer_to_workout_logs.rb`:

```ruby
add_column :workout_logs, :started_at, :datetime
add_column :workout_logs, :ended_at, :datetime
add_column :users, :timer_auto_start, :boolean, default: false, null: false
```

`db/migrate/20261120130000_add_paused_seconds_to_workout_logs.rb`:

```ruby
add_column :workout_logs, :paused_at, :datetime
add_column :workout_logs, :paused_seconds, :integer, default: 0, null: false
```

What each column means:

| Column | Meaning |
|---|---|
| `started_at` | The first start |
| `paused_at` | When the timer was paused; empty while it runs |
| `ended_at` | When it was stopped for good |
| `paused_seconds` | The total time between each Pause and Resume |
| `users.timer_auto_start` | Off by default |

Both migrations only add columns, so `master` keeps working on the shared development database. Both were run on it.

### 4.2 Model: `WorkoutLog`

Before: no timer. After:

- `timer_today?`: only today's workout starts a timer.
- `timer_running?`, `timer_paused?`, and `timer_end` (`ended_at || paused_at`, so a timer paused and never stopped ends at its pause).
- `recorded_seconds`: `(end or now) − start − paused_seconds`, to the second.
- `pause_timer`, `resume_timer` (adds `now − paused_at` to `paused_seconds`), and `stop_timer` (a timer stopped while paused ends at its pause).
- `finish_at("HH:MM")`, for Edit timer:
  - takes the first such clock time after the start, with seconds 0 (a time earlier than the start is the next day);
  - stops a timer still running or paused;
  - returns `nil` for anything that is not a clock time.
- `before_create :start_timer_automatically`: with the account setting on, a workout logged today starts its timer. This covers a set added straight from an exercise page.
- `validate :ends_after_start`: the end needs a start, isn't before it or in the future, and leaves no less time than was paused.

### 4.3 Controller and routes: `WorkoutTimersController`

```ruby
resources :workout_days … do
  resource :timer, only: [:create], controller: "workout_timers"
end
resources :workout_logs … do
  resource :timer, only: [:create, :edit, :update, :destroy], controller: "workout_timers" do
    post :pause
  end
end
```

**`create`: Start or Resume.**
- From a workout day with nothing logged yet, it logs the workout.
- Refused when the timer was stopped.
- A new timer is refused when the workout is not today's; Resume works on any day.
- Pressing it while running changes nothing.

**`pause`** pauses a running timer. **`destroy`** stops a running or paused timer.

**`edit` / `update`:** the History correction, through `finish_at`.

The workout is always found through `current_user`; another user's workout is not found.

`Users::RegistrationsController` permits `timer_auto_start` on the account page.

### 4.4 Views

**`workout_logs/_timer`: the timer box**, at the top of a workout day's page and a logged workout's page.

| State | Pill | Content | Buttons |
|---|---|---|---|
| idle | none | "How long is this workout?" | Start timer |
| running | ● Running | Live clock; "Started 7:25 AM · paused 5 min" | Pause, Stop |
| paused | Paused | Dimmed clock; "for 0:09:57 · since 8:03 AM" (the pause counts up) | Resume, Stop |
| finished | Finished | "11:30 PM `20/11` ~ 1:05 AM `21/11` · **1 h 25 min 12 s** · paused 10 min" | none |

Stop asks first ("Stop the timer? It can't be resumed after.").

**`workout_logs/_timer_alert`: the paused-timer alert.** It is the app's confirm box with the blue icon, and it is rendered whenever the workout has a timer.

**`workout_timers/edit`: the Edit timer page.**
- It shows "Started at 6:02 PM `20/11`" and any paused time.
- **Finished at** is a time field (hours and minutes).
- It has Save and Cancel.

**History (`workout_logs/index`):**
- Each workout with a timer gets a time line under its counts, with a pen that opens Edit timer.
- The pen is a 44 px target, and on a phone it keeps one column on the right.

**Other views:**
- `pages/_recent_workout` (the dashboard): the same time line in each recent workout.
- `devise/registrations/edit`: the "Start the workout timer automatically" setting.
- `workout_days/show`, `workout_logs/show` and `workout_exercises/show`: render the box and the alert, and mark what stays in the workout (`data-stays-in-workout`).
- `workout_sets/_form`: marked so adding a set asks while the timer is paused.

### 4.5 Helpers (`ApplicationHelper`)

- **`workout_time(log)`:** the time line ("6:02 PM ~ 7:15 PM · 1 h 3 min · paused 10 min", or "Started 6:02 PM · paused 5 min" while running).
- **`time_parts`:** keeps each part of that line whole with the "·" after it, so a wrapped line never starts with a separator. The text is unchanged.
- **`duration_text(seconds)`:** "1 h 3 min 10 s", exact, never rounded.
- **`clock_duration(seconds)`:** "0:42:13".
- **`clock_time(time)`** and **`day_badge(time)`:** the badge is `20/11`.
- **`exercise_picker_button`:** now marked with `data-alert-when-paused="add"`.

### 4.6 JavaScript (Stimulus)

- **`timer_controller.js`:** counts up from a saved moment, plus an offset. It is used for the running clock (start − paused) and for the paused counter (pause + earlier pauses). It saves nothing, and it reads the clock once a second, so the time stays right after the phone screen has been locked.
- **`auto_submit_controller.js`:** sends its form once the page is on screen. This is how the automatic timer presses Start. It skips Turbo's cached preview.
- **`timer_alert_controller.js`:** while the timer is paused, it catches clicks on `[data-alert-when-paused="add"]`, submits of those forms, and links that leave the workout. It catches them on `window` in the capture phase, so Turbo, Bootstrap and the back button see nothing yet.
  - It asks, does what was chosen (Resume or Stop through `fetch`, with the CSRF token), then repeats the tap.
  - Closing the box cancels.
  - After Resume from "Add exercise", it reloads the page to show the running timer and reopens the exercise list.

### 4.7 Styles

- **`components/_timer.scss` (new):**
  - the box layout (on a phone the buttons take a full-width row; from `sm` up they sit on the right);
  - the status pill, using the app's existing chip colours: done green for Running, rest amber for Paused, grey for Finished;
  - the Running dot breathing (opacity, 2 s);
  - the clock at 2 rem with tabular numerals, dimmed while paused;
  - the time-line parts and the date badge;
  - the alert icon;
  - a button press (scale .97, 160 ms ease-out).
  - Motion is off under `prefers-reduced-motion`.
- **`components/_confirm.scss`:** the confirm box (shared by the delete confirm and the paused-timer alert) now grows in from 96 % over 200 ms with an ease-out, instead of Bootstrap's 50 px slide-down. It has no motion under reduced motion.
- **`pages/_workout_log.scss`:** the History time line and its pen.
- **`application.scss`:** imports `components/timer`.

### 4.8 Seed data

- `lib/seed_data/dumper.rb` writes `timer_auto_start`, `started_at`, `ended_at`, `paused_at` and `paused_seconds`.
- `lib/seed_data/loader.rb` loads them as they were, bypassing the automatic start, which would otherwise stamp the loading time.
- `db/seeds/data.yml`: see section 7.

### 4.9 Docs

- **`CLAUDE.md`:**
  - new product rules: when a workout is logged, the timer, the alert, Edit timer;
  - code-map notes on the timer box, its controller and routes, the alert, the automatic start, and `workout_time` / `time_parts`.
- **`doc/Prompt/project-context.md`:** decision 19, the workout timer, with the owner's words.
- **`doc/Features/Features.md` and `doc/Issues/Issues.md`:** see section 7.

## 5. Decisions

| Decision | Rejected | Why |
|---|---|---|
| Times on `workout_logs` (four columns) | A table of timer segments | One timer per workout; a paused total gives the recorded time without storing each pause. |
| Start before anything is logged logs the workout | Start only after the first set | The owner's answer. It changes the rule "Start workout creates nothing" (recorded in `CLAUDE.md`). |
| The automatic timer is the open page pressing Start (a POST) | Starting it in the GET of the page | Turbo prefetches links on hover; a GET that writes could log a workout from a touch. |
| The automatic timer's setting is in Account settings | A switch on the timer box | The owner's answer. Devise asks for the current password to save there. |
| The automatic start defaults to off | On | Assumption: nothing changes until the owner opts in. |
| The page counts from the saved start, once a second | A +1 counter, or saving every second | A +1 counter freezes while the phone sleeps; saving every second is what the owner asked not to do. Only Start, Pause, Resume and Stop write. |
| Only today's workout starts; once started it pauses, resumes and stops on any day | Limiting all of them to today; a 12-hour Stop limit | The owner: a workout past midnight must stop and resume, and a timer runs until stopped. |
| Times exact to the second ("1 h 24 min 7 s") | Rounded minutes | The owner: "Do not round it". |
| Pause and Resume, plus Stop | Stop-and-start-again only | The owner asked for both. |
| Stop asks first | No confirm | Stop cannot be undone and sits next to Pause. |
| A paused-and-never-stopped timer ends at its pause | Counting until now | History needs an end; the pause is the last time it ran. |
| Edit timer only changes the finish, in hours and minutes, seconds 0 | Editing the start or the pauses too | Exactly what was asked. |
| A time earlier than the start is the next day | A date field | Only the time is typed, and a workout past midnight is the case it is for. |
| The paused-timer alert reuses the confirm box | A new component | It is the same kind of question; consistent look. |
| Alerts only while paused; opening the workout's own exercises is not leaving | Asking while running too | The owner's answer. |
| Status pill colours from the existing chip tokens | New colours | Keeps the app's look (a polish pass, not a redesign). |
| The finished box shows the time line with the length in bold | A big final clock | The owner's exact text stays, and the tests keep checking it. |

## 6. How it works now

1. **Start:** open today's workout (dashboard "Start workout", or a workout day's page), then press **Start timer**. With **Account settings → Start the workout timer automatically** on, opening the page starts it.
2. **While it runs:** the box shows ● Running and the clock. **Pause** saves the moment it paused.
3. **While paused:** the clock stands still and dims, and "for 0:01:23" counts the pause. **Resume** adds that pause to the paused total. Adding an exercise or a set asks **Keep paused / Resume**, and leaving the workout asks **Keep paused / Stop timer**.
4. **Stop:** saves the end and asks first. The box then shows Finished, with start ~ end, the length recorded, and the time paused.
5. **History:** every workout with a timer shows the same line, with a pen. **Edit timer** sets the finish (for example 7:15 → 19:15:00) and stops a timer left running or paused.

To try it, from this branch:

```bash
bin/rails db:migrate
bin/rails server -p 3011
```

## 7. Tests and verification

**Run:**
- `bin/rails test`: 98 runs, 1361 assertions, 0 failures, 0 errors.
- `bundle exec rubocop`: no offenses.
- `bundle exec brakeman`: no warnings.
- `bundle exec bundler-audit check --update`: no vulnerabilities.
- Impeccable's detector (`impeccable detect`) on the timer views: no findings.

**`test/integration/timer_flow_test.rb` (8 tests) covers:**
- start, pause, resume and stop, with the exact recorded and paused times;
- stopping while paused;
- the automatic start, on, off, and not on a workout the split cannot log today;
- a workout across midnight, with pause, resume and stop, the date badges, and exact seconds;
- only today's workout starting a timer, and another user's workout not found;
- the History correction: seconds at 0, a paused timer, past midnight, and refusals for a bad time, a future time, and less time than was paused;
- the alert's markup on the three pages.

Tests changed during the session only where the owner changed the behaviour (Stop → Pause/Resume/Stop, no rounding, Resume past midnight). No test was edited to hide a failure.

**In the browser** (headless Chrome over DevTools, 390 × 844 with touch, and 1280 × 800, with throwaway users deleted afterwards):
- every box state, History, Edit timer, and the alert;
- Start, Pause, Resume, Stop, and the automatic start;
- every alert answer: Keep paused, Resume (the set was saved and the timer ran), and Stop timer;
- the back arrow and Plan asking;
- an exercise of the workout not asking;
- no sideways scroll on any page.

**Not verified:**
- on a real phone (iOS Safari or Android Chrome);
- sessionStorage in a private window (used to reopen the exercise list after Resume);
- the motion as felt on a device.

**Moved in `doc/Features/Features.md`:** the General timer item ("Add a timer of when workout started and then ended…") went to "Features added (DONE)" → General. The bottom navigation bar item stays where it is. The Exercise page's "Timer for exercise" is a different feature (a timer per exercise) and stays where it is.

**Added to `doc/Issues/Issues.md` → Potential issues:** see section 9.

**`db/seeds/data.yml`:** `bin/rails seed:dump` was run. The file now holds 1 user, 3 splits, 3 workouts and 46 sets.
- It gained the timer fields: `timer_auto_start` on the user, and `paused_seconds` on the existing workouts.
- It gained one workout from the development database: Lower on 2026-11-21 (U/R/L/U/L), with a 2-second timer and no exercises, most likely a quick try of the timer.
- Nothing was removed. `test/lib/seed_data_test.rb` passes.

## 8. Every file changed

**New (12):**
- `app/controllers/workout_timers_controller.rb`: Start/Resume, Pause, Stop, Edit timer.
- `app/views/workout_logs/_timer.html.erb`: the timer box.
- `app/views/workout_logs/_timer_alert.html.erb`: the paused-timer alert.
- `app/views/workout_timers/edit.html.erb`: the Edit timer page.
- `app/javascript/controllers/timer_controller.js`: the counting clock.
- `app/javascript/controllers/auto_submit_controller.js`: the automatic Start.
- `app/javascript/controllers/timer_alert_controller.js`: the paused-timer alert's behaviour.
- `app/assets/stylesheets/components/_timer.scss`: the timer's styles.
- `db/migrate/20261120120000_add_timer_to_workout_logs.rb`: start, end, the automatic setting.
- `db/migrate/20261120130000_add_paused_seconds_to_workout_logs.rb`: the pause and the paused total.
- `test/integration/timer_flow_test.rb`: the timer's tests.
- `doc/workout-timer.md`: this document.

**Changed: app (17):**
- `app/models/workout_log.rb`: timer state, times, `finish_at`, validation, automatic start.
- `app/helpers/application_helper.rb`: the time line helpers; the picker button marked for the alert.
- `app/controllers/workout_days_controller.rb`: `@log` and `@autostart` for the box.
- `app/controllers/workout_exercises_controller.rb`: `@log` for the alert on the exercise page.
- `app/controllers/users/registrations_controller.rb`: permits `timer_auto_start`.
- `app/views/workout_days/show.html.erb`: renders the box and the alert; exercises stay in the workout.
- `app/views/workout_logs/show.html.erb`: the same, and the Add buttons marked.
- `app/views/workout_exercises/show.html.erb`: the alert (for adding a set).
- `app/views/workout_logs/index.html.erb`: the time line and the Edit timer pen.
- `app/views/pages/_recent_workout.html.erb`: the time line on the dashboard.
- `app/views/workout_sets/_form.html.erb`: the add-set form marked for the alert.
- `app/views/devise/registrations/edit.html.erb`: the automatic timer setting.
- `app/assets/stylesheets/application.scss`: imports the timer styles.
- `app/assets/stylesheets/components/_confirm.scss`: the box's ease-out scale-in.
- `app/assets/stylesheets/pages/_workout_log.scss`: the History time line and pen.
- `config/routes.rb`: the timer routes.
- `db/schema.rb`: the new columns.

**Changed: data and docs (7):**
- `lib/seed_data/dumper.rb`: writes the timer fields.
- `lib/seed_data/loader.rb`: loads them as they were.
- `db/seeds/data.yml`: the latest data (from `bin/rails seed:dump`), if it changed.
- `CLAUDE.md`: the timer rules and code map.
- `doc/Prompt/project-context.md`: decision 19.
- `doc/Features/Features.md`: the timer moved to DONE.
- `doc/Issues/Issues.md`: potential issues added.

## 9. Known gaps

- **No real-phone check.** Everything was tried in headless Chrome with phone emulation only.
- **"Start timer" saves an empty workout.** With the automatic timer on, opening today's workout just to look at it logs it, empty, until it is deleted from History.
- **A forgotten timer keeps counting.** A timer left running or paused counts on until it is stopped or corrected from History.
- **Edit timer changes only the finish.** Not the start or the individual pauses, and it cannot set a finish that leaves less time than the paused total.
- **The times on the line show hours and minutes** while the length is to the second, so 11:09 ~ 11:50 can sit next to "30 min 10 s".
- **The alert covers the app's own links.** Not the browser's back button or closing the tab.
- **Reopening the exercise list after Resume uses sessionStorage.** If that is blocked, the list does not reopen (the timer still resumes).
- **The account setting needs the current password,** because of Devise's account page.
