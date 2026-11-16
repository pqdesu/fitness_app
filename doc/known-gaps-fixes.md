# Known gaps fixes

Record of the work done on 2026-11-16 on the branch `known-gaps-fixes` (from `master` at `bd88bdd`), in the worktree `.claude/worktrees/known-gaps-fixes`.

---

## 1. Summary

- Fixes the "Known gaps" that `doc/Prompt/project-context.md` listed, plus two things the owner specified while asking: an admin can keep private exercises, and weights keep three decimals.
- Adds an admin page for users, pagination, notes on sets and logged exercises, a saved time zone, a linter that runs, a test for the mock task, and a new README.
- Does **not** touch the dashboard calendar. The two open Calendar issues in `doc/Issues/Issues.md` are still open, as the owner asked.
- **Checked:** `bin/rails test`: 48 runs, 541 assertions, 0 failures, 0 errors. `bundle exec rubocop`: 31 files, no offenses. `bin/rails zeitwerk:check`: good. The changed pages were opened and driven in headless Chromium at 390px (phone) and 1280px (desktop), with no browser errors.
- **Not checked:** a real phone, Safari or Firefox; the `down` of the two migrations; the migrations against the owner's own development database (this machine has no PostgreSQL, see section 7).

---

## 2. Timeline

| Step | Request | What happened |
|---|---|---|
| 1 | "Read CLAUDE.md ... also read the md files on doc" | Read `CLAUDE.md` and the eight Markdown files in `doc/`. Summarised the app, its history and what was open. No changes. |
| 2 | "Please work in a worktree like the other times. Also explain to me the known gaps more" | Said a worktree would be used from the next piece of work, pointed out that `CLAUDE.md` said the opposite, and explained each known gap. No changes. |
| 3 | "Please fix all the known gaps and update CLAUDE.md. DO NOT CHANGE the calendar yet." With two specifications: an admin can create catalogue exercises and also private ones, and manages users; `weight_used` keeps at least three decimals. "When you fix this create a worktree and a branch with the proper name of the fix." | Created the worktree and the branch `known-gaps-fixes`. Found the machine had no Ruby or PostgreSQL and set up two Docker containers to run the tests. Made every change in section 4, updated the tests, ran Rubocop for the first time, drove the app in a headless browser, fixed a phone layout bug that the browser showed, and updated `CLAUDE.md` and `doc/Prompt/project-context.md`. |
| 4 | "Is this bug fixed?" (the phone set-editing bug) | Confirmed: fixed and seen in the rerun screenshot at 390px; checked in Chromium only. No changes. |
| 5 | "Finalize it" | Reran tests and Rubocop, wrote this doc, committed, pushed, opened the pull request, removed the worktree. |

---

## 3. Starting point

The gaps as `project-context.md` listed them:

1. No browser check of any UI.
2. The first page of a new browser session renders in UTC and reloads once; without JavaScript or cookies the app stays in UTC.
3. Today's log is found per workout day, so the same workout from two splits on one date creates two logs.
4. `mock:clear` leaves the planned exercises the mock task added; the mock task has no test.
5. After editing or deleting a set, the redirect relies on the browser's referer.
6. The same exercise can be added twice to a day's plan or to a logged workout.
7. Equipment changed on a day's exercise does not update an entry already created for today.
8. An admin cannot create a private exercise.
9. Notes on a logged exercise and on a set have no input.
10. No pagination on History or the catalogue; no admin screen for users.
11. `README.md` is out of date.
12. Devise's mailer sender is a placeholder; Rubocop is configured but not installed; `weight_used` is a bare `decimal`.

The owner's two specifications:

> Admin can create catalogue exercises but it can also create private exercises. Only difference of the admin is to create catalogue exercises and other admin stuff like delete user, manage stuff etc

> change to be at least 3 more decimals like 1.111 kg

---

## 4. Changes

### 4.1 One logged workout per workout per day (gap 3)

Before, `WorkoutSetsController#create` looked for today's log through the workout day:

```ruby
workout_log = planned.workout_day.workout_logs.where(date: Date.current).order(:id).first_or_create!
workout_log.workout_log_exercises.where(workout_exercise: planned).order(:id).first_or_create!
```

Two splits with an "Upper" day therefore made two logs on the same date.

After, the lookup lives on the model and goes through the user and the workout name:

```ruby
# app/models/workout_exercise.rb
def log_on(date)
  workout_day.split.user.workout_logs.of_workout(workout_day.day).where(date: date).order(:id).first
end

def entry_on!(date)
  log = log_on(date) || workout_day.workout_logs.create!(date: date)
  entry_in(log) || log.workout_log_exercises.create!(workout_exercise: self)
end

def entry_in(log)
  entries = log.workout_log_exercises
  matching = entries.where(workout_exercise_id: id)
  matching = matching.or(entries.where(exercise_id: exercise_id)) if exercise_id
  matching.min_by { |entry| [entry.workout_exercise_id == id ? 0 : 1, entry.id] }
end
```

- `of_workout` already treats Legs and Lower as one workout, so they share a session too.
- `entry_in` finds the entry started from this plan row, or else the entry of the same exercise (started from the other split's plan, or added by hand). So Squat from split A and Squat from split B are one entry with sets 1, 2, 3.
- The controller now calls `planned.entry_on!(Date.current)`. The exercise page (`workout_exercises#show`) uses `entry_on`, and the day page counts today's sets through `log_on` and `entry_in`, so both splits' pages show the same sets.
- `WorkoutLog` gained a validation, `only_session_of_workout_that_day`, run on create and when the date or workout changes: "Date already has a Push workout logged". It stops the Details form from moving a workout onto a date that already has one.
- `WorkoutLogExercise`'s rule "the planned exercise must belong to the log's day" became `workout_exercise_fits_the_log`: the log's own day, or the same workout in another split of the same user. Without this the second split's plan rows could not link to the shared log.

### 4.2 An exercise once per day and once per logged workout (gap 6)

- `WorkoutExercise` validates `not_already_on_day` and `WorkoutLogExercise` validates `not_already_in_log`, both `on: :create`, with the messages "Bench press is already on this day" and "Bench press is already in this workout".
- `WorkoutExercisesController#create` leaves out exercises already on the day and answers "Nothing added: already on this day." when none is left.
- `ExercisePicker#find_or_build_exercise`: a typed name that matches an exercise the user can already pick (ignoring case and extra spaces) uses that exercise instead of creating a twin.
- `Exercise` validates its name as unique within the catalogue and within one user's own exercises, ignoring case, and squishes the name.
- On a logged workout, "From this day, not in this workout" no longer offers an exercise that is already in the workout by any route (`planned.entry_in(@workout_log)`).

### 4.3 Equipment follows today's entry (gap 7)

`WorkoutExercisesController#update` now also updates today's entry:

```ruby
if @workout_exercise.update(equipment_params)
  @workout_exercise.entry_on(Date.current)&.update(equipment_params)
```

Earlier workouts keep the equipment they were logged with.

### 4.4 Returning to the right page after editing or deleting a set (gap 5)

Before: `redirect_back fallback_location: ...`, which depends on the `Referer` header.

After: the set partial takes an optional `workout_exercise` local and puts its id in the form URL (`workout_set_path(set, workout_exercise_id: ...)`). `WorkoutSetsController#page_of` redirects to that exercise page when the id is one of the signed-in user's own planned exercises, and otherwise to the logged workout. Someone else's id is ignored.

### 4.5 Notes on a set and on a logged exercise (gap 9)

- **Set:** pressing the pen now also shows a "Note (optional)" field. A saved note is shown under the set's numbers. `WorkoutSetsController#update` permits `notes`; the model squishes it and stores blank as nil.
- **Logged exercise:** its edit page (the pen on a logged workout) has a "Note" text area next to the equipment; the note is shown under the exercise name on the logged workout. `WorkoutLogExercisesController` permits `notes`.

### 4.6 The set row, and the phone bug the browser found

To hold the note, a set is now a `<tbody data-controller="row-edit">` of its own with up to three rows: the numbers; the note (when there is one); and, hidden until editing, the note field with Save and Cancel.

The first browser run showed that on a 390px screen the weight and reps fields were squeezed so narrow that "81.125" read as "8" and reps as an empty box. Save and Cancel sat in the same row as the fields and took their room. This was already the case on `master`; no test could show it.

Fix: Save and Cancel moved to the row with the note field (`.set-edit-bar`), and `.set-field` got `width: 100%; min-width: 4.75rem`. The empty `<form>` stays in the actions cell; fields and the Save button belong to it through their `form` attribute. `row_edit_controller.js` now tracks `this.editing` itself instead of reading the form's `hidden` attribute.

### 4.7 Admin: private exercises (gap 8, owner's specification)

- `ExercisePicker#shared_exercise_requested?` is true only for an admin who sent `exercise[shared]=1`. Everything else creates the exercise as the current user's own. A regular user sending the parameter is ignored.
- The "Add exercises" modal shows an admin a checkbox "Add to the shared catalogue", unticked.
- `/exercises/new` (still admin-only) has the same checkbox, ticked, with the hint "Unticked, the exercise is only yours."
- `ExercisesController#set_exercise`: an admin now manages the shared catalogue and their own exercises (`Exercise.visible_to(current_user)`); before it was the shared ones only. The index shows Edit and Delete accordingly and marks the admin's own as "Yours".

### 4.8 Admin: users page (gap 10, owner's specification)

- Route: `namespace :admin { resources :users, only: [:index, :update, :destroy] }`.
- `Admin::UsersController`: lists accounts (30 per page) with their number of logged workouts; `update` sets or clears `admin`; `destroy` deletes the user and, through the existing `dependent: :destroy` associations, their splits, logged workouts and own exercises.
- An admin's own row has no buttons, and `set_user` refuses requests on the admin's own id, so there is always one admin left.
- Linked as "Users" in the user menu, for admins only. On a phone the Joined and Workouts columns are hidden so the buttons stay on screen.
- `ApplicationController#require_admin!` now redirects to the dashboard with "Only an admin can do that." `ExercisesController` keeps its own message through `require_catalogue_admin!`.

### 4.9 Weights keep three decimals (gap 12, owner's specification)

Migration `20261116140000_give_weights_three_decimals.rb`:

```ruby
change_column :workout_sets, :weight_used, :decimal, precision: 8, scale: 3
```

- `WorkoutSet` also validates `less_than: 100_000`, the column's limit.
- New helper `weight_number` (three decimals, trailing zeros stripped) is used by `format_weight` and by every weight field's pre-filled value, so 80 shows as "80 kg", 32.5 as "32.5 kg" and 1.125 as "1.125 kg".

### 4.10 Pagination (gap 10)

New concern `Paginated` (`paginate(scope, per:)`, sets `@page` and `@page_count`, clamps out-of-range pages) and partial `shared/_pagination` (Previous, "Page 2 of 5", Next; nothing when there is one page). Used by History (20 per page), the catalogue (30) and the users page (30). No gem was added.

### 4.11 Saved time zone (gap 2)

Migration `20261116150000_add_time_zone_to_users.rb` adds `users.time_zone`. `ApplicationController#browser_time_zone` saves the cookie's zone on the user when it is a known zone and differs, and falls back to the saved zone when the cookie is missing or unknown. A new browser session, or a browser without JavaScript, now starts in the user's zone and does not need the reload.

### 4.12 Mock task (gap 4)

- `mock:last_week` skips a day when the user already has a session of that workout on that date, in line with 4.1. Two splits with Upper on Monday give one Upper session.
- When the task fills an empty day with a plan, the session's note is "Mock data · plan added". `mock:clear` deletes the mock workouts and then the planned exercises linked from those sessions, except any the user has since recorded real sets on.
- New `test/tasks/mock_task_test.rb` covers both tasks.

### 4.13 Housekeeping (gaps 11 and 12)

- `README.md` rewritten to describe the app as it is.
- `config/initializers/devise.rb`: `mailer_sender` is `ENV.fetch("MAILER_SENDER", "FitnessApp <no-reply@example.com>")`.
- `Gemfile`: `rubocop` added to the development and test group. Adding it pulled `json` 3.1.0 into the bundle, which broke asset compilation (`execjs`: "unknown keyword: create_additions") and `rack-test` ("unknown keyword: quirks_mode"), so `json` is pinned `"< 3"` (resolved to 2.21.2).
- `.rubocop.yml`: the first run reported 44 offenses, mostly style. The config was matched to the code's existing style (see section 5); the remaining 10 small offenses were corrected in the code (spaces inside `%i[ ]` and `[ :home ]`, anonymous block forwarding in `ApplicationController`, nested `module Admin`).

### 4.14 Docs

`CLAUDE.md` and `doc/Prompt/project-context.md` updated: worktrees are the way to work again, the admin rule, the new product rules, the Docker fallback, the browser check, the new code map entries, and a rewritten "Known gaps" list.

---

## 5. Decisions

| Decision | Alternative rejected | Why |
|---|---|---|
| One session per workout per day, shared by splits. **Assumption:** the owner asked for the gap to be fixed, not for this rule. | A unique database index; leaving two logs and only merging the display. | It is the reading that matches "what I did for the day". An index cannot express Legs = Lower. |
| The same exercise from two splits shares one entry. | One entry per plan row. | Otherwise the shared log would hold Squat twice, which 4.2 forbids. |
| Existing doubled logs and exercises are not merged. | A data migration. | Merging rewrites history and the only known doubles are mock data. The new validations run on create only, so old rows stay editable. |
| A typed name that already exists uses the existing exercise. | Refusing with an error. | Fewer taps: the user gets what they meant. |
| An admin's exercise is private by default in the modal, shared by default on the catalogue's "New exercise" page. **Assumption** for the defaults. | One default for both. | The modal is used at the gym for one's own training; the catalogue page exists to manage the catalogue. |
| Sharing is chosen at creation only. | A switch on the edit form. | Making a shared exercise private would pull it out from under other users' plans. |
| Admin users page: make or unmake an admin, delete. Nothing else. | Editing emails, resetting passwords, viewing a user's data. | "delete user, manage stuff" names only these; the product rule is not to add features beyond what is asked. |
| An admin cannot act on their own account there. | Counting admins before each change. | Simpler, and guarantees one admin remains. |
| `decimal(8, 3)`. | More decimals. | The owner's example is 1.111. Eight digits allow 99,999.999. |
| A set's note is added through the pen, not in the "Add set" form. | A third field in "Add set". | "Add set" stays weight, reps, one tap. |
| Hand-written pagination. | The `pagy` or `kaminari` gem. | Twelve lines; no new dependency. |
| The time zone is saved on the user. | A setting the user picks. | Needs no input, and still follows travel through the cookie. |
| Mock plans are marked through the session's note. | A `mock` column on `workout_exercises`. | No schema change for a development-only task. |
| Rubocop's config relaxed to the existing style: `Style/SymbolArray` off, `Layout/EndAlignment` to `variable`, line length 130, method and block length and perceived complexity off. | Rewriting about 40 lines across the app to the defaults. | A linter that passes is the goal; restyling working code adds risk and noise to the diff. |
| `json` pinned below 3. | Leaving Rubocop out; putting it in a group of its own. | Bundler loads every group's versions, so the pin is the only fix that keeps Rubocop. |
| Tests and server run in Docker. | Skipping verification on a machine without Ruby. | The work had to be tested. Nothing was installed on the machine itself. |
| `require_admin!` got a general message; exercises keep theirs. | One message for both. | "manage the exercise catalogue" is wrong on the users page; the old message is asserted by existing behaviour. |

---

## 6. How it works now

Data model (changes only):

```
users          + time_zone (string)
workout_sets   ~ weight_used decimal(8, 3)
```

New rules:

- One `WorkoutLog` per user, workout (Legs = Lower) and date.
- One `WorkoutExercise` per exercise and day; one `WorkoutLogExercise` per exercise and log.
- `Exercise` name unique in the catalogue and among one user's own.
- A `WorkoutLogExercise` may link to a plan row of the log's day or of the same workout in another of the user's splits.

Flows:

- **Logging:** open a day, open an exercise, "Add set". The first set of the day creates the workout; sets from another split with the same workout join it.
- **Correcting a set:** pen, change weight or reps, optionally type a note, Save (or Esc / Cancel).
- **Admin:** user menu, "Users". "New exercise" on the Exercises page, or "Create your own" in the modal, with the shared-catalogue checkbox.

To try it:

```bash
bin/rails db:migrate
bin/rails server
```

New routes: `GET /admin/users`, `PATCH /admin/users/:id`, `DELETE /admin/users/:id`. `?page=N` on `/workout_logs`, `/exercises` and `/admin/users`.

---

## 7. Tests and verification

**Environment.** The machine had no Ruby and no PostgreSQL. Tests ran in Docker: a `postgres:16-alpine` container and a `ruby:3.3.5` container (with `libpq-dev` and `nodejs` installed) with the worktree mounted, as the host user, with `DATABASE_URL` pointing at the Postgres container. The databases there were created fresh from the migrations; the owner's own development database was never touched.

**Automated.** Run after the changes and again before committing:

- `bin/rails test`: 48 runs, 541 assertions, 0 failures, 0 errors, 0 skips (was 39 runs, 390 assertions on `master`).
- `bundle exec rubocop`: 31 files inspected, no offenses.
- `bin/rails zeitwerk:check`: "All is good!"

New or extended tests:

- `test/models/workout_recording_test.rb`: cross-split plan rows on a log; exercise once per day and per log, with old doubles still editable; one session per workout per day, shared entry, date move refused; three-decimal weights; exercise name uniqueness.
- `test/models/workout_day_test.rb`: adjusted to the one-session rule.
- `test/integration/workout_flow_test.rb`: duplicates refused on a day and in a log; typed name reuse; admin private and shared creation in the modal and on the form; a regular user cannot share; set editing with note, three decimals and the explicit return page; equipment following today's entry; the same workout from two splits; pagination; the admin users page, including deleting a user with data; saved time zone.
- `test/tasks/mock_task_test.rb`: `mock:last_week` and `mock:clear`.

**Browser.** A development server ran from the worktree in the container, seeded, with one split and mock data. A Playwright script (headless Chromium, time zone America/Sao_Paulo) ran at 390×844 and 1280×900: sign in, dashboard, split, day, the add-exercise modal, an exercise page, add a set of 81.125 kg, pen, Esc (values reset), pen, type a note, Save, switch equipment to Machine and back (brand field shown and hidden), delete the set, then History, a logged workout, Exercises, New exercise and Users. Screenshots were looked at. Result: no JavaScript errors, the page was rendered in the browser's zone, and the phone layout bug of section 4.6 was found, fixed and seen fixed in the rerun.

**Not verified:**

- Any browser other than Chromium, and any real phone.
- The `down` direction of the two migrations.
- The migrations on a database that already has data. Both are additive (a new nullable column; a precision change that keeps existing values, rounding any with more than three decimals).
- Password-reset emails with the new sender.

---

## 8. Every file changed

47 files: 39 modified, 8 added (7 code and test files, and this doc).

Models
- `app/models/exercise.rb`: name squished and unique per catalogue and per owner.
- `app/models/workout_exercise.rb`: `log_on`, `entry_on`, `entry_on!`, `entry_in`; once per day.
- `app/models/workout_log.rb`: one session per workout per day.
- `app/models/workout_log_exercise.rb`: plan row may come from the same workout in another split; once per log; note normalised.
- `app/models/workout_set.rb`: weight below 100,000; note normalised.

Controllers
- `app/controllers/admin/users_controller.rb` (new): the users page.
- `app/controllers/application_controller.rb`: saved time zone; general admin message.
- `app/controllers/concerns/exercise_picker.rb`: name reuse; private unless an admin shares.
- `app/controllers/concerns/paginated.rb` (new): pagination.
- `app/controllers/exercises_controller.rb`: shared or private on create; admin manages own too; paginated.
- `app/controllers/pages_controller.rb`: spacing only (Rubocop).
- `app/controllers/workout_days_controller.rb`: today's set counts from the shared session.
- `app/controllers/workout_exercises_controller.rb`: no doubles; equipment follows today's entry; uses `entry_on`.
- `app/controllers/workout_log_exercises_controller.rb`: permits the note.
- `app/controllers/workout_logs_controller.rb`: paginated; unlogged list without doubles.
- `app/controllers/workout_sets_controller.rb`: `entry_on!`; note; explicit return page.

Views, helper, JavaScript, styles
- `app/helpers/application_helper.rb`: `weight_number`, three decimals.
- `app/views/admin/users/index.html.erb` (new): the users table.
- `app/views/exercises/_form.html.erb`: shared-catalogue checkbox.
- `app/views/exercises/index.html.erb`: admin text, actions on own exercises, pagination.
- `app/views/shared/_exercise_picker.html.erb`: shared-catalogue checkbox for admins.
- `app/views/shared/_navbar.html.erb`: "Users" link for admins.
- `app/views/shared/_pagination.html.erb` (new): page links.
- `app/views/workout_exercises/show.html.erb`: passes the exercise to the set rows; weight value.
- `app/views/workout_log_exercises/edit.html.erb`: note field.
- `app/views/workout_logs/index.html.erb`: pagination.
- `app/views/workout_logs/show.html.erb`: entry note; weight value; set rows.
- `app/views/workout_sets/_set.html.erb`: a `<tbody>` per set, note, edit bar.
- `app/javascript/controllers/row_edit_controller.js`: tracks editing itself.
- `app/assets/stylesheets/components/_app.scss`: set fields and edit bar, note rows, pagination bar.

Database, routes, config
- `db/migrate/20261116140000_give_weights_three_decimals.rb` (new).
- `db/migrate/20261116150000_add_time_zone_to_users.rb` (new).
- `db/schema.rb`: result of both.
- `config/routes.rb`: `admin/users`.
- `config/initializers/devise.rb`: `MAILER_SENDER`.
- `Gemfile`, `Gemfile.lock`: `rubocop`, `json < 3`, and Rubocop's dependencies.
- `.rubocop.yml`: matched to the code's style.

Tasks and tests
- `lib/tasks/mock.rake`: one session per workout per day; `clear` removes added plans.
- `test/tasks/mock_task_test.rb` (new).
- `test/integration/workout_flow_test.rb`, `test/models/workout_recording_test.rb`, `test/models/workout_day_test.rb`.

Docs
- `README.md`: rewritten.
- `CLAUDE.md`: working rules, product rules, commands, code map.
- `doc/Prompt/project-context.md`: decisions, working rules, data model, pages, known gaps.
- `doc/known-gaps-fixes.md` (new): this file.

---

## 9. Known gaps

- **Calendar issues are open,** on purpose: highlight only days with a logged workout, and make a highlighted day open that workout.
- **Old data is not merged.** Logs or exercises doubled before this branch stay. With two logs of a workout on one date, new sets go to the older one.
- **`mock:clear` does not remove plans added by the old mock task,** which left no mark. Run on a database that still has old mock data, it deletes the workouts and leaves those planned exercises.
- **Time zone on a user's very first visit** still renders in UTC and reloads once; a browser that has never run the script stays in UTC.
- **Deleting the last set of the day leaves an empty workout** ("0 sets") in History until it is deleted by hand.
- **History and the users table scroll sideways on a phone** when their columns do not fit.
- **Rubocop has no length or complexity limits** after the config change.
- **Positive-number rules and the new uniqueness rules are in the models only,** not in the database.
- **Two migrations must be run** on the owner's development database (`bin/rails db:migrate`). Both are safe for `master`.
- **Verified in Chromium only** (section 7).
