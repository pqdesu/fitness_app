# Fitness app

A simple workout tracker in Ruby on Rails. The owner's own description of the core use: "I go to the gym, log my workouts and what I did for the day, and then that's it."

The full project context (product brief, every decision, data model, page flows, current state, open issues) is in [doc/Prompt/project-context.md](doc/Prompt/project-context.md). Read it before making product or design choices.

## Product rules

- Top priority is a very intuitive, simple, user-friendly UI: few taps and little typing to log a set on a phone at the gym.
- Plain POST and GET: record entries, read them back. Do not add features beyond what is asked.
- Keep the planning layer (splits, workout days, planned exercises), the shared exercise catalogue and the admin role. Do not propose removing them.
- Users pick an exercise from the catalogue or create their own; only an admin changes the shared catalogue.
- An admin is a normal user with two extras: managing the shared catalogue, and managing users (make or unmake an admin, delete a user). An admin can also create private exercises; one goes to the catalogue only when they tick "Add to the shared catalogue".
- Equipment is chosen per lift: free weights, or a machine whose brand the user types.
- A workout day lists only exercises. Sets (weight, then reps) are added when the user opens an exercise.
- There is one logged workout per workout per day. Sets added from any split join it, and Legs and Lower count as the same workout.
- A split has one logged workout per day. A second workout on the same day only comes from another split.
- An exercise is on a workout day once and in a logged workout once.
- A workout can be moved to another day for the current week only (today to Saturday). The split's plan is never changed by a move, and the next week follows the plan again. Moving onto a day that has a workout swaps the two.
- Sets added from a workout day go to the date that workout falls on this week (its weekday, or the one it was moved to). Wednesday's workout opened on Thursday fills in Wednesday; a workout later this week takes no sets yet. "Start workout" and "Train as extra" open it on today.
- "Start workout" creates nothing. A split's workout is logged when its first set is added; a workout that is not in the split is logged when its first exercise is added.
- A workout trained on a day its split has nothing on that week is a rest day workout. It is marked when logged (`workout_logs.rest_day`) and the mark is never recalculated.
- Weights keep three decimals (1.125 kg).

## How to work in this repo

- Work in a git worktree under `.claude/worktrees/<branch>`, on a branch named for the work (`git worktree add .claude/worktrees/<branch> -b <branch> master`). The owner asked for this on 2026-11-16, replacing the earlier "no worktrees" rule. Leave the main checkout alone: it is the owner's.
- A server started from the main folder serves the main folder's branch, not the worktree. To let the owner see the work before merging, run a server from the worktree on another port and say which, or give them the command to check the branch out. Do not finalize work unprompted.
- The worktree and the main folder share one development database. Say so before running a migration that drops or renames something `master` still reads.
- Ruby 3.3.13 (through rbenv) and PostgreSQL are installed natively on the owner's machine. Run the tests, the server and migrations directly (`bin/rails test`), not in Docker. If either is missing, tell the owner instead of skipping the tests.
- Look at changed pages in a real browser at phone width before calling UI work done. The tests do not run the JavaScript or show the layout.
- When asked to finalize, finish or wrap up a branch, use the `finalize-branch` skill (in `.claude/skills/`). It writes a detailed change doc to `doc/<branch>.md`, pushes, and opens a pull request.
- Never merge a pull request, enable auto-merge, or run `git pull` / `git merge` for the owner. Give them the commands instead; they decide what goes into `master` and what comes into their folder.
- Branch names are a few plain lowercase words joined by dashes, with no digits and no `claude/` prefix.
- Before committing or pushing a branch, update the base data with the `update-seed-data` skill (`.claude/skills/`), so `db/seeds/data.yml` carries the latest data and keeps the old. `finalize-branch` does this as one of its steps.
- Change docs must be very detailed: every step, decision, file changed, the reason, and how it works now.
- Open and resolved issues are tracked in [doc/Issues/Issues.md](doc/Issues/Issues.md). When an issue is fixed, move it under "Issues Resolved".
- When asked to read, investigate or explain issues from `Issues.md` (usually one section, on `master`), use the `investigate-issues` skill (`.claude/skills/`). It traces each issue to its cause and explains it without changing anything, then asks before fixing.

## Stack and commands

Ruby 3.3.13, Rails 8.1, PostgreSQL, Devise 5, Bootstrap 5 with SCSS (Dart Sass through dartsass-sprockets), Hotwire (Turbo and Stimulus) through importmap, simple_form, Minitest.

```bash
bin/setup                 # gems and database
bin/rails db:seed         # admin user, starter catalogue, then db/seeds/data.yml (idempotent, only adds)
bin/rails seed:dump       # merges the dev database's real data into db/seeds/data.yml (keeps the old)
bin/rails server
bin/rails test
bundle exec rubocop       # linter; must report no offenses
bundle exec brakeman      # security scan of the code; must report no warnings
bundle exec bundler-audit check --update  # known vulnerabilities in the gems
bin/rails mock:last_week  # logs last week's sessions for every split, as mock data
bin/rails mock:clear      # deletes the mock workouts and the plans the mock task added
```

`.github/workflows/ci.yml` runs the tests, rubocop, brakeman and bundler-audit on every push.

`MAILER_SENDER` sets the address password-reset emails come from.

## Code map

- Program: `Split` has many `WorkoutDay` (one per weekday, name from a fixed list) has many `WorkoutExercise`.
- Record: `WorkoutLog` (belongs to the user, survives split deletion) has many `WorkoutLogExercise` has many `WorkoutSet`.
- `Lift` concern (`app/models/concerns/lift.rb`) is shared by planned and logged exercises: name copy, equipment, machine brand.
- `Exercise` without a user is in the shared catalogue; with a user it is that user's own. A name is unique within the catalogue and within one user's own exercises.
- `WorkoutDayMove` (workout day, `week_start`, weekday) is a workout on another weekday for one week. `Split#week_plan(date)` is the one place that answers what is on which day that week (the plan with that week's moves); the dashboard, the Today box and the rest day mark read it. `Split#move_for_week!` writes moves and swaps; creating a workout day or changing a weekday clears the split's moves.
- `WeekMovesController` (`POST` and `DELETE /splits/:id/week_move`) moves a workout for this week and goes back to the plan. The Splits pages show the plan; only the dashboard passes `plan:` to `splits/_week`.
- `WorkoutSummary` (plain Ruby, `app/models/workout_summary.rb`) totals loaded logs: workouts, exercises, sets, top weight. It needs logs loaded with `includes(workout_log_exercises: :workout_sets)`.
- `LoggingDate` (controller concern) gives the date a workout day's pages log on: `?date=`, which those pages pass along, or else `WorkoutDay#date_in_week_of(today)`. A future date shows no add-set form, and `WorkoutLog` refuses it.
- `WorkoutExercise#entry_on!(date)` is the one way sets of a split's workout reach a log: it finds or creates the user's session of that workout on that date, and the entry of that exercise in it.
- `ExercisePicker` (controller concern) reads the "Add exercises" modal and decides whether a new exercise is private or shared. `Paginated` (controller concern) with `shared/_pagination` pages History, the catalogue and the users list.
- `Admin::UsersController` (`/admin/users`) is the admin's users page, linked from the user menu.
- A set is a `<tbody>` of its own in a set table (`workout_sets/_set`): the row of numbers, then its note, or the note field with Save and Cancel while editing (`row_edit_controller.js`).
- The dashboard calendar (`pages/_calendar`) rings only the days a workout was logged on. A ringed day links to that workout, or to `/workout_logs?date=YYYY-MM-DD` when the day has several.
- The dashboard's Today box (`pages/home`, `pages/_lifts`) shows today's sets once there are any, with "last time" as a link; before that it shows last time's heaviest sets. Its button is "Start workout", then "Continue".
- On a rest day the Today box opens a panel: one pill per workout name of the split, each with a pop-up (`pages/_rest_day_start`) to move it to today or train it as an extra, and pills for the fixed workouts the split does not have, which open `workout_logs#new`.
- The active split card has "This week" (`pages/_week_overview`), "Move a workout" (`pages/_move_workout`) and "Back to the plan". Recent workouts are dropdowns (`pages/_recent_workout`). All of these use Bootstrap collapse and modals, with no JavaScript of their own.
- Deleting a workout opened with `?from=dashboard` returns to the dashboard, otherwise to History.
- An admin renames an exercise from a workout day: the pencil opens `exercises#edit` with `workout_day_id`, which is where saving or cancelling returns.
- The muscle group of an exercise is chosen from `Exercise::MUSCLE_GROUPS` (or left empty, "Other"); it is never typed.
- Sub-pages declare their back button with `<% back_to path %>` at the top of the view; the layout draws it as a round arrow. It returns to the page visited before (`back_trail.js` keeps each tab's pages in sessionStorage, `back_controller.js` follows it), skipping form pages (`body[data-back-skip]` on new, edit, create, update) and a record deleted from its own page. `path`, the parent page, is only the fallback when the tab has no earlier page.
- Flash messages (`shared/_flashes`, `flash_controller.js`) are cards at the top of the screen. A notice fades out after 5 seconds, waiting while it is pointed at or focused; an alert stays until its × is pressed. Every `data-turbo-confirm` opens the app's own box (`shared/_confirm`, `confirm_dialog.js`, through `Turbo.config.forms.confirm`), never the browser's `confirm()`.
- Dates follow the browser's time zone, sent in a cookie by `app/javascript/time_zone.js` and remembered in `users.time_zone` for sessions that have not reported one yet.
- `Dashboard` (plain Ruby, `app/models/dashboard.rb`) answers everything the home page shows for a user on a date; `PagesController#home` only builds it. It also keeps `logs_count` and `sets_count`, which no box shows now (the owner asked to keep them).
- A controller finds a record through its owner: `current_user.workout_exercises`, `.workout_log_exercises` and `.workout_sets` (`has_many through` on `User`). `WorkoutLog.session_of(workout, date)` is the one lookup of a session; `WorkoutDay#log_on(date)` uses it. `Split#rest_day?(date)` is the one rest day check.
- Controllers read form fields with `params.expect(model: [:field])` (Rails 8), and models tidy text with `normalizes` rather than a `before_validation`. Rubocop enforces the hash shorthand (`where(date:)`).
- The "once only" rules also have unique indexes; `ApplicationController` rescues `RecordNotUnique` (a double tap) with a message. `from_dashboard?` and `errors_of(record)` are there too, for controllers and views.
- Accounts: Devise `:lockable` (10 wrong passwords, 15 minutes), passwords of 8 or more characters, `paranoid`. The only admin cannot delete their account (`User#last_admin?`, `Users::RegistrationsController`).
- The content security policy is in `config/initializers/content_security_policy.rb`. A new outside host (fonts, scripts, images) must be added there or the browser blocks it. Do not add inline `style=` attributes or inline scripts.
- The add-set form and the set table are `workout_sets/_form` and `workout_sets/_table`, used by the exercise page and the logged workout page.
- Styles: `components/` for what pages share, `pages/` for one page; `application.scss` lists them in one order.
- `db/seeds/data.yml` is the base data (users, splits, logged workouts), matched by email, name, weekday and date, never by id. `lib/seed_data/` writes it (`Dumper`, `Merge`: the file only grows) and loads it (`Loader`: creates what is missing, changes nothing that exists). Mock workouts are never written.
- Integration tests are in `test/integration/*_flow_test.rb`, one file per area, on the shared `FlowTest` setup in `test/test_helper.rb`; the dashboard object by `test/models/dashboard_test.rb`; the mock task by `test/tasks/mock_task_test.rb`.
