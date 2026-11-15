# Fitness App: model fixes and first UI

Record of the work done on 2026-11-15: what the codebase looked like, what was changed, why each decision was taken, how the app works now, and what is still open.

Everything described here is in one commit, `e64ee12` "Add first UI for planning and recording workouts" (49 files), on the branch `first-ui`.

---

## Contents

1. [Summary](#1-summary)
2. [Timeline of the work](#2-timeline-of-the-work)
3. [Starting point: what the review found](#3-starting-point-what-the-review-found)
4. [Part A: fixes to how exercises are recorded](#4-part-a-fixes-to-how-exercises-are-recorded)
5. [Part B: the first UI](#5-part-b-the-first-ui)
6. [Part C: the admin user](#6-part-c-the-admin-user)
7. [How the app works now](#7-how-the-app-works-now)
8. [Tests and verification](#8-tests-and-verification)
9. [Every file changed](#9-every-file-changed)
10. [Git and workspace history](#10-git-and-workspace-history)
11. [Decisions at a glance](#11-decisions-at-a-glance)
12. [Known gaps and things not done](#12-known-gaps-and-things-not-done)

---

## 1. Summary

- **Before:** a Rails 7.1 template with Devise login and eight models. No pages for workouts, no seed data, no real tests. The models had five problems in the part that records exercises.
- **After:** the five problems are fixed, the database enforces the important rules, and there is a working UI to plan a split, plan a workout day, start a workout and log every set. There is an admin account and a starter exercise catalogue.
- **Checked:** 17 automated tests pass (97 assertions). The server boots and the stylesheet compiles.
- **Not checked:** nobody has looked at the pages in a real browser yet during this work, so layout and visual polish are untested.

---

## 2. Timeline of the work

| Step | Request | What happened |
|---|---|---|
| 1 | "Check the whole code base and how it is working now" | Read every model, migration, controller, view and config file. Booted the server, ran the autoload check and the tests, and ran a rolled-back smoke test of the model chain. Reported eight problems. No files changed. |
| 2 | Fix five of the reported problems, focused on how exercises are recorded | Changed seven models, added one migration, added 11 model tests. Ran the migration on the development database. |
| 3 | Why were the changes under `.claude`? | Explained that the session had been started in a git worktree (a second checkout of the same repo). No files changed. |
| 4 | Wanted to test with `rails s` before merging | Explained how to run the server from the worktree. No files changed. |
| 5 | Build a simple, modern UI for the current functionality, without changing functionality, and create an admin user | Added routes, seven controllers, the views, a new stylesheet, an `admin` column, seeds, and six integration tests. Ran the second migration and the seeds on the development database. |
| 6 | Save the changes on a branch named `first-ui` | Created the branch and committed everything as one commit. |
| 7 | Push `first-ui` to GitHub | Pushed and set upstream tracking. |
| 8 | Remove the worktree under `.claude` | Confirmed it was clean and pushed, then removed it. |
| 9 | This document | Written for the `doc/` folder. |

---

## 3. Starting point: what the review found

### Stack

- Ruby 3.3.5, Rails 7.1, PostgreSQL
- Devise for authentication
- Bootstrap 5.3, `font-awesome-sass`, `simple_form`, Sass via `sassc-rails`
- Hotwire (Turbo and Stimulus) through importmap
- Based on the Le Wagon Rails template (navbar, fonts, colours, flash partial)

### What existed

- **Routes:** Devise user routes, `root` (`pages#home`), and the `/up` health check.
- **Controllers:** `ApplicationController` (requires login everywhere) and `PagesController#home` (public, placeholder text).
- **Models:** `User`, `Split`, `WorkoutDay`, `Exercise`, `WorkoutExercise`, `WorkoutLog`, `WorkoutLogExercise`, `WorkoutSet`.
- **Database:** all nine migrations applied; every table empty in development.
- **Tests:** eight model test files, all empty stubs. Running the suite gave 0 runs, 0 assertions.
- **Seeds:** empty.

### What was run during the review

| Check | Result |
|---|---|
| `bin/rails zeitwerk:check` | Passed |
| `bin/rails db:migrate:status` | All migrations `up` |
| Server on a spare port | `/`, `/users/sign_in`, `/users/sign_up` returned 200; `/users/edit` redirected to login |
| `bin/rails test` | 0 runs |
| Model chain smoke test (test database, rolled back) | Creating user → split → day → exercise → log → set worked; destroying the user cascaded cleanly |
| `bundle exec rubocop` | Failed: `.rubocop.yml` exists but rubocop is not in the Gemfile |

### The eight problems reported

1. Deleting an exercise that is in use raised `ActiveRecord::InvalidForeignKey`.
2. Numbers were not validated (`sets: -1, reps: 0` was accepted).
3. Constraints existed only in Rails: columns were nullable and set numbers had no unique index.
4. A log had no direct route to its owner; `User` had no `workout_logs`.
5. `WorkoutLogExercise` could link a log to an exercise planned for a different day.
6. Template leftovers: Le Wagon navbar and logo, dead links, Devise mailer sender still `please-change-me…`.
7. README describes things that do not exist (SQLite/MySQL, Vue.js, rest timer, progress monitoring).
8. `decimal` columns (`target_weight`, `weight_used`) have no precision or scale.

Problems 1 to 5 were fixed in Part A. Problem 6 was partly addressed in Part B (the navbar). Problems 7 and 8 and the mailer sender are still open (see [section 12](#12-known-gaps-and-things-not-done)).

---

## 4. Part A: fixes to how exercises are recorded

### 4.1 Deleting an exercise that is in use

**Before** (`app/models/exercise.rb`):

```ruby
has_many :workout_exercises
has_many :workout_days, through: :workout_exercises
has_many :workout_log_exercises
```

Calling `exercise.destroy` on an exercise that appeared in any plan hit the database foreign key and raised an exception, which in a controller would be a 500 error.

**After:**

```ruby
has_many :workout_exercises, dependent: :restrict_with_error
has_many :workout_days, through: :workout_exercises
has_many :workout_log_exercises, through: :workout_exercises
```

**Decision: block the delete instead of cascading.**
`dependent: :restrict_with_error` makes `destroy` return `false` and put a message in `exercise.errors[:base]`. The alternative, `dependent: :destroy`, would delete every user's planned exercise for it and, through those, every logged set. The catalogue is shared by all users, so one delete would silently erase other people's training history. Blocking is the safe default; the UI shows the message.

**Extra fix found on the way.** `has_many :workout_log_exercises` was broken: the `workout_log_exercises` table has no `exercise_id` column, so calling the association would have raised an SQL error. It now goes `through: :workout_exercises`, which is the real path. This was not in the original list of five.

### 4.2 Number validation

**`WorkoutExercise`** (the plan):

```ruby
validates :sets, :reps, presence: true,
                        numericality: { only_integer: true, greater_than: 0 }
validates :target_weight, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
```

**`WorkoutSet`** (what was actually done):

```ruby
validates :set_number, presence: true,
                       numericality: { only_integer: true, greater_than: 0 },
                       uniqueness: { scope: :workout_log_exercise_id }
validates :reps_completed, presence: true,
                           numericality: { only_integer: true, greater_than_or_equal_to: 0 }
validates :weight_used, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
```

**`WorkoutDay`:**

```ruby
validates :order_index, presence: true, numericality: { only_integer: true }
```

**Decisions:**

| Field | Rule | Reason |
|---|---|---|
| Planned `sets`, `reps` | Integer, greater than 0 | A plan of zero or negative sets is meaningless. |
| `set_number` | Integer, greater than 0 | Sets are counted from 1. |
| `reps_completed` | Integer, 0 or more | Zero is allowed on purpose: a failed attempt is still a set worth recording. |
| `target_weight`, `weight_used` | 0 or more, may be blank | Blank means bodyweight (pull-ups, planks). Negative weight is rejected. |
| `order_index` | Integer | Only used for ordering; no range was imposed. |

### 4.3 Database constraints

New migration `db/migrate/20261115120000_add_database_constraints_to_workout_tables.rb`:

```ruby
change_column_null :exercises, :name, false
change_column_null :splits, :name, false
change_column_null :workout_days, :day, false
change_column_null :workout_days, :order_index, false
change_column_null :workout_exercises, :sets, false
change_column_null :workout_exercises, :reps, false
change_column_null :workout_logs, :date, false
change_column_null :workout_sets, :set_number, false
change_column_null :workout_sets, :reps_completed, false

add_index :workout_sets, [:workout_log_exercise_id, :set_number], unique: true
```

**Why:** Rails validations can be skipped (`save(validate: false)`, `update_column`, bulk inserts, the console) and the uniqueness validation has a race: two requests can both check "is set 1 taken?", both see no, and both insert. The database is the only place that can guarantee these rules.

**Why these columns:** each one already had a presence validation in its model, so the database now matches what the models already claimed. Optional columns (`muscle_group`, `equipment`, `target_weight`, `weight_used`, `notes`) were left nullable.

**Safety:** all tables were empty in development, so the migration could not fail on existing rows. If another database has rows with nulls in these columns or duplicate set numbers, the migration will fail there and the data must be cleaned first.

**Not added:** database `CHECK` constraints for the positive-number rules. Those rules live only in the models.

### 4.4 Reaching a user's logs

**Before:** to get one user's logs you had to walk `user.splits` → `workout_days` → `workout_logs` by hand.

**After:**

```ruby
# app/models/user.rb
has_many :splits, dependent: :destroy
has_many :workout_days, through: :splits
has_many :workout_logs, through: :workout_days

# app/models/workout_day.rb
has_one :user, through: :split

# app/models/workout_log.rb
has_one :user, through: :workout_day
```

So `current_user.workout_logs`, `current_user.workout_days`, `workout_log.user` and `workout_day.user` all work.

**Decision: `through` associations, not a `user_id` column on `workout_logs`.**
A column would be a second copy of information that already exists (log → day → split → user) and could drift out of sync. The `through` version has a single source of truth and needs no migration. The cost is a three-table join on those queries, which is irrelevant at this size. If logs ever need to outlive their split or day, a direct column would be worth revisiting.

**Consequence to know:** these nested `through` associations are read-only. You can query and `find` through them, but you cannot `current_user.workout_logs.create`. New logs are created through the day: `workout_day.workout_logs.create`.

### 4.5 Logged exercise must match the log's day

`WorkoutLogExercise` belongs to both a `WorkoutLog` and a `WorkoutExercise`. Each of those belongs to a `WorkoutDay`, and nothing forced the two days to be the same, so a "Push" log could contain an exercise planned for "Pull".

**After** (`app/models/workout_log_exercise.rb`):

```ruby
validate :workout_exercise_belongs_to_logged_day

private

def workout_exercise_belongs_to_logged_day
  return if workout_log.nil? || workout_exercise.nil?
  return if workout_exercise.workout_day_id == workout_log.workout_day_id

  errors.add(:workout_exercise, "must belong to the same workout day as the log")
end
```

**Decision: validate, do not restructure.** The redundancy could be removed by redesigning the tables, but that would change the data model you wrote. A validation closes the hole and leaves the structure alone. The nil checks let the existing `belongs_to` presence errors report missing associations.

**Not added:** a rule that an exercise appears only once per log.

---

## 5. Part B: the first UI

The brief was: simple, fairly modern, based only on what the app can already do, and no change to functionality.

### 5.1 Routes

`config/routes.rb`:

```ruby
devise_for :users
root to: "pages#home"

resources :exercises, except: [:show]

resources :splits do
  resources :workout_days, only: [:new, :create]
end
resources :workout_days, only: [:show, :edit, :update, :destroy] do
  resources :workout_exercises, only: [:create]
  resources :workout_logs, only: [:create]
end
resources :workout_exercises, only: [:edit, :update, :destroy]

resources :workout_logs, only: [:index, :show, :update, :destroy] do
  resources :workout_log_exercises, only: [:create]
end
resources :workout_log_exercises, only: [:destroy] do
  resources :workout_sets, only: [:create]
end
resources :workout_sets, only: [:destroy]

get "up" => "rails/health#show", as: :rails_health_check
```

**Decision: shallow nesting.** A record is created under its parent (so the parent is known from the URL) and afterwards addressed by its own id (`/workout_days/5`, not `/splits/2/workout_days/5`). This keeps URLs short and avoids four-level paths for sets.

| URL | Purpose |
|---|---|
| `GET /` | Landing page (signed out) or dashboard (signed in) |
| `GET /splits`, `/splits/new`, `/splits/:id`, `/splits/:id/edit` | List, create, view, rename a split |
| `GET /splits/:split_id/workout_days/new` | Add a day to a split |
| `GET /workout_days/:id`, `/workout_days/:id/edit` | A day's plan and its logged workouts |
| `POST /workout_days/:id/workout_exercises` | Add a planned exercise |
| `GET /workout_exercises/:id/edit` | Edit a planned exercise |
| `POST /workout_days/:id/workout_logs` | Start a workout |
| `GET /workout_logs`, `/workout_logs/:id` | History, and one workout |
| `PATCH /workout_logs/:id` | Save date and notes |
| `POST /workout_logs/:id/workout_log_exercises` | Add a planned exercise to a workout |
| `DELETE /workout_log_exercises/:id` | Remove an exercise from a workout |
| `POST /workout_log_exercises/:id/workout_sets` | Log a set |
| `DELETE /workout_sets/:id` | Delete a set |
| `GET /exercises`, `/exercises/new`, `/exercises/:id/edit` | Catalogue (changes are admin only) |

### 5.2 Controllers

| Controller | Actions | Notes |
|---|---|---|
| `ApplicationController` | – | Still requires login everywhere. Gained a private `require_admin!`. |
| `PagesController` | `home` | Public. When signed in, loads the user's splits, last five logs, and counts. |
| `ExercisesController` | `index`, `new`, `create`, `edit`, `update`, `destroy` | `index` for everyone; the rest admin only. `destroy` shows the model's error when the exercise is in use. |
| `SplitsController` | all seven | Scoped to `current_user.splits`. |
| `WorkoutDaysController` | `new`, `create`, `show`, `edit`, `update`, `destroy` | `new` pre-fills `order_index` with the next position. |
| `WorkoutExercisesController` | `create`, `edit`, `update`, `destroy` | `create` is the inline form on the day page. |
| `WorkoutLogsController` | `index`, `show`, `create`, `update`, `destroy` | `create` starts a workout (see below). |
| `WorkoutLogExercisesController` | `create`, `destroy` | Add or remove an exercise within a workout. |
| `WorkoutSetsController` | `create`, `destroy` | Log or delete a set. |

**Decision: every lookup is scoped to the signed-in user.**
Records are found through the user, never by bare id:

```ruby
current_user.splits.find(params[:id])
current_user.workout_days.find(params[:id])
current_user.workout_logs.find(params[:id])

WorkoutExercise.joins(workout_day: :split)
               .where(splits: { user_id: current_user.id }).find(params[:id])
```

Guessing another user's id gives `ActiveRecord::RecordNotFound`, which Rails turns into a 404. This is the reason section 4.4 mattered. The only unscoped model is `Exercise`, because the catalogue is shared.

**Decision: starting a workout creates the log and its entries together.**
`WorkoutLogsController#create` makes a log dated today and, in the same transaction, one `WorkoutLogExercise` for each exercise planned for that day. Without this you would have to add each exercise by hand before logging a set. No model behaviour changed; it is the controller using the existing models. If any record is invalid the whole thing rolls back and you are returned to the day with a message.

**Decision: two styles of error handling.**

- *Full-page forms* (split, workout day, exercise, edit planned exercise) re-render the form with status 422 and show field errors next to the inputs.
- *Inline forms* (add planned exercise, log set, save details) redirect back with the validation messages in a flash alert, for example "Set not logged: Set number has already been taken." Re-rendering a whole page that contains many small forms would have needed far more code for no gain at this stage.

**Decision: browser validation is off, on purpose.**
`simple_form` is configured with `browser_validations = false`, and the inline number fields have no `min` attribute. You can therefore type `-1` and submit it, and see the server reject it. That is what makes the model fixes testable by hand.

**Strong parameters.** Each controller permits only its own fields. `admin` is never permitted anywhere.

### 5.3 Pages

| Page | File | What it shows |
|---|---|---|
| Landing | `pages/home.html.erb` | Headline, "Create an account" and "Log in". |
| Dashboard | `pages/home.html.erb` | Three tiles (splits, workouts logged, sets recorded), your splits with their days as links, the last five workouts. |
| Splits | `splits/index.html.erb` | One card per split with its days. |
| Split | `splits/show.html.erb` | One card per day in `order_index` order, listing planned exercises as "name, sets × reps". Add day, rename, delete. |
| Split form | `splits/_form`, `new`, `edit` | Name. |
| Day form | `workout_days/_form`, `new`, `edit` | Name and position. |
| Workout day | `workout_days/show.html.erb` | Planned exercises table, inline "add exercise" form, list of logged workouts, **Start workout**, edit, delete. |
| Edit planned exercise | `workout_exercises/edit.html.erb` | Sets, reps, target weight. |
| Workout | `workout_logs/show.html.erb` | One card per exercise: the plan, a "2 / 3 sets" chip (turns green when the plan is met), the sets logged, and a form to log the next set. A side card for date and notes. A list of planned exercises that are not in this workout, each with an Add button. |
| History | `workout_logs/index.html.erb` | Table of all workouts: date, day, split, exercises, sets. |
| Exercises | `exercises/index.html.erb` | Catalogue table: name, muscle group, equipment, how many plans use it. Admin sees New, Edit, Delete. |
| Exercise form | `exercises/_form`, `new`, `edit` | Name, muscle group, equipment. |

**Small conveniences in the set form:** the set number is pre-filled with the next number, reps with the planned reps, and weight with the last set's weight (or the target weight for the first set). They are only defaults; any value can be typed.

**Empty states.** Every list has a message and a next action when there is nothing in it yet.

**Destructive actions** (delete split, day, workout, remove exercise) ask for confirmation through Turbo and say what else will be deleted.

### 5.4 Layout and navigation

- `layouts/application.html.erb` now wraps content in `<main class="container app-main">`. Devise pages are automatically placed inside a narrow card, so the Devise views themselves were not edited.
- `shared/_navbar.html.erb` was rewritten. Signed in: Dashboard, Splits, History, Exercises, and a user menu with the email, an "Admin" badge when relevant, account settings and log out. Signed out: Log in and Sign up. The Le Wagon logo, placeholder avatar and dead links are gone.
- `ApplicationHelper` gained `nav_link_to` (marks the current section) and `format_weight`.

### 5.5 Styling

**Decision: stay on the stack already installed.** Bootstrap 5, Font Awesome and Sass were already in the Gemfile, so the look comes from overriding Bootstrap variables plus one new stylesheet. No gem, JavaScript library or build step was added.

| File | Change |
|---|---|
| `config/_fonts.scss` | Inter for body text, Plus Jakarta Sans for headings (Google Fonts). Replaces Work Sans and Nunito. |
| `config/_colors.scss` | Indigo primary `#4F46E5`, near-black text, light grey page, plus `$muted`, `$line`, `$primary-soft`. The template's variable names (`$blue`, `$gray`, …) were kept so nothing else broke. |
| `config/_bootstrap_variables.scss` | Larger corner radius, lighter borders, bolder buttons and headings, slightly smaller base font. |
| `components/_navbar.scss` | Sticky white bar, brand mark, active link pill, user chip. |
| `components/_app.scss` | New. Page headers, cards, stat tiles, row lists, chips, tables, inline forms, empty states, landing hero, Devise card. |
| `components/_index.scss` | Imports the new `app` file. |

**Decision: weights are labelled "kg".** The database stores no unit. This is an assumption; it lives in `ApplicationHelper#format_weight` and three form labels ("Target kg", "Weight kg", "Target weight (kg)").

---

## 6. Part C: the admin user

The app had no concept of an admin, so "create an admin user" needed a definition.

### What was added

**Migration** `db/migrate/20261115130000_add_admin_to_users.rb`:

```ruby
add_column :users, :admin, :boolean, default: false, null: false
```

**Seed** (`db/seeds.rb`):

```ruby
admin_email = ENV.fetch("ADMIN_EMAIL", "admin@example.com")
admin_password = ENV.fetch("ADMIN_PASSWORD") do
  raise "Set ADMIN_PASSWORD to seed the admin user" if Rails.env.production?
  "admin123456"
end

admin = User.find_or_initialize_by(email: admin_email)
admin.password = admin_password if admin.new_record?
admin.admin = true
admin.save!
```

### Login for development

- Email: `admin@example.com`
- Password: `admin123456`

### Decisions

| Decision | Reason |
|---|---|
| A boolean column, not a roles gem | One role is all that is needed now. |
| Admin controls only the exercise catalogue | It is the one thing shared between all users, so it is the one thing that needs an owner. Everything else already belongs to a user. |
| Regular users can browse the catalogue but not change it | Otherwise any account could rename or delete exercises that other people's plans depend on. |
| Admin cannot be self-assigned | Devise's sign-up does not permit the `admin` parameter, and no controller permits it. A test covers this. |
| Credentials overridable by environment variables | The defaults are for local use only. In production the seed refuses to run without `ADMIN_PASSWORD`. |
| Seed is idempotent | Running it again does not duplicate anything and does not reset an existing admin's password. |

**Note:** this is the one place where behaviour was added beyond pure UI, because the request required it. An admin is otherwise a normal user with their own splits and logs. There is no admin panel and no page to promote another user; that is done in the console (`user.update(admin: true)`).

### Starter catalogue

The seed also creates 14 exercises with `find_or_create_by!(name:)`: Bench press, Incline dumbbell press, Overhead press, Lateral raise, Triceps pushdown, Pull-up, Barbell row, Lat pulldown, Barbell curl, Squat, Romanian deadlift, Leg press, Calf raise, Plank. Each has a muscle group and equipment. Without them a new install would have an empty catalogue and nothing to plan with.

---

## 7. How the app works now

### Data model

```
User ──< Split ──< WorkoutDay ──< WorkoutExercise >── Exercise (shared catalogue)
                        │                 │
                        └──< WorkoutLog   │
                                  │       │
                                  └──< WorkoutLogExercise ──< WorkoutSet
```

| Model | Meaning | Key rules |
|---|---|---|
| `User` | Account (Devise). `admin` flag. | Has splits; reaches days and logs through them. |
| `Split` | A training program. | Needs a name. Deleting it deletes its days. |
| `WorkoutDay` | One day of a split, e.g. "Push". | Needs a name and an integer position. Deleting it deletes its plan and logs. |
| `Exercise` | Catalogue entry shared by everyone. | Needs a name. Cannot be deleted while any plan uses it. |
| `WorkoutExercise` | An exercise planned for a day. | Sets and reps are positive integers; target weight optional, not negative. |
| `WorkoutLog` | One performed workout of a day. | Needs a date. |
| `WorkoutLogExercise` | An exercise within that workout. | Its planned exercise must belong to the same day as the log. |
| `WorkoutSet` | One set actually done. | Set number positive and unique within its exercise entry; reps 0 or more; weight optional, not negative. |

### Deletion behaviour

| Deleting… | Also deletes | Blocked when |
|---|---|---|
| User | Splits and everything under them | – |
| Split | Days, plans, logs, sets | – |
| Workout day | Its planned exercises and its logs (and their sets) | – |
| Planned exercise | Its entries in logs, and their sets | – |
| Workout log | Its entries and sets | – |
| Logged exercise entry | Its sets | – |
| Catalogue exercise | Nothing | Any plan uses it |

### Typical flow in the browser

1. Log in.
2. **Splits → New split**, give it a name.
3. **Add workout day**, e.g. "Push", position 1.
4. On the day page, pick an exercise, enter sets, reps and target weight, press **Add**. Repeat.
5. Press **Start workout**. A log for today opens with a card per planned exercise.
6. For each set, adjust reps and weight and press **Log set**.
7. Optionally change the date or add notes under **Details**.
8. Find it later under **History**, on the day page, or on the dashboard.

### Things to try to see the fixes

| Try | Expected |
|---|---|
| Add a planned exercise with sets `-1` | "Exercise not added: Sets must be greater than 0." |
| Log set number 1 twice for one exercise | "Set not logged: Set number has already been taken." |
| Log a set with reps `0` and no weight | Accepted; shown as "Bodyweight". |
| As admin, delete an exercise used in a plan | Refused, with the reason. |
| As admin, delete an unused exercise | Deleted. |
| As a non-admin, open `/exercises/new` | Redirected with "Only an admin can manage the exercise catalogue." |
| Open another user's `/splits/:id` | 404. |

### Running it

```bash
bin/rails db:migrate
bin/rails db:seed
bin/rails server
```

On the machine where this work was done, both migrations and the seed have already been run against `fitness_app_development`.

---

## 8. Tests and verification

### Result

`bin/rails test`: **17 runs, 97 assertions, 0 failures, 0 errors.**

### Model tests: `test/models/workout_recording_test.rb` (11)

1. An exercise in use cannot be destroyed.
2. An unused exercise can be destroyed.
3. An exercise reaches its logged entries through workout exercises.
4. Planned sets and reps must be positive integers (and target weight not negative).
5. Target weight is optional.
6. Recorded set values must be valid.
7. A set may record zero reps and no weight.
8. Set number is unique per logged exercise, in Rails and in the database (saves with `validate: false` and expects `RecordNotUnique`).
9. Required columns are not null in the database (expects `NotNullViolation`).
10. A user reaches their own logs only.
11. A log cannot record an exercise planned for a different day.

### Integration tests: `test/integration/workout_flow_test.rb` (6)

1. Signed-out visitors see the landing page and are redirected to login elsewhere.
2. Devise pages render (login, sign-up, forgot password, account settings).
3. The whole flow: create split → day → invalid then valid planned exercise → edit it → start workout → log a set → duplicate set rejected → save notes → every page renders → remove and re-add a logged exercise → delete a set, the log, the plan, the day, the split.
4. A user gets 404 on another user's split, day, planned exercise and log, and cannot post sets or start workouts on them.
5. Only admins manage the catalogue: a regular user is blocked from new, create and delete; an admin can create, edit, is refused when deleting an exercise in use, and can delete an unused one.
6. Signing up with `admin: true` in the parameters does not create an admin.

Because test 3 requests every page, every view template is rendered at least once by the suite.

### Other checks

| Check | Result |
|---|---|
| Both migrations | Applied; `db/schema.rb` regenerated |
| `bin/rails db:seed` | "Admin user: admin@example.com", "Exercises in catalogue: 14" |
| Server on a spare port, signed out | `/`, `/users/sign_in`, `/users/sign_up` returned 200; `/splits` redirected to login |
| Compiled stylesheet | Served with status 200 |

### What was not verified

- **No visual check.** The pages were never viewed in a browser during this work. The suite proves they render without errors and contain the expected elements, not that they look right, that the mobile menu and dropdown open, or that spacing is good.
- **No signed-in check against the running server.** An attempt to log in over HTTP from the command line was blocked by the session's permission rules, so signed-in pages were verified only through the integration tests.
- **A test detail that rests on an assumption.** In the "another user's records" test, the user is signed in again before each request. Without that, the request after a 404 was redirected to login. I attributed this to how Devise's test helper stores the login (a request that ends in an exception does not save the test session) and not to the app. That explanation was not confirmed against a real browser session; if you are ever logged out after hitting a 404 in the browser, this is where to look.
- **Rubocop** was not run; it is not installed in the bundle.

---

## 9. Every file changed

49 files in commit `e64ee12`. This document is a 50th file, added afterwards.

### Models (7 modified)

| File | Change |
|---|---|
| `app/models/exercise.rb` | `restrict_with_error` on `workout_exercises`; `workout_log_exercises` now `through`. |
| `app/models/user.rb` | Added `workout_days` and `workout_logs` through associations. |
| `app/models/workout_day.rb` | Added `has_one :user`; `order_index` must be an integer. |
| `app/models/workout_exercise.rb` | Numeric validations on `sets`, `reps`, `target_weight`. |
| `app/models/workout_log.rb` | Added `has_one :user`. |
| `app/models/workout_log_exercise.rb` | Validation that the planned exercise matches the log's day. |
| `app/models/workout_set.rb` | Numeric validations on `set_number`, `reps_completed`, `weight_used`. |

### Database (2 added, 2 modified)

| File | Change |
|---|---|
| `db/migrate/20261115120000_add_database_constraints_to_workout_tables.rb` | New. Nine `NOT NULL` changes and one unique index. |
| `db/migrate/20261115130000_add_admin_to_users.rb` | New. `users.admin` boolean. |
| `db/schema.rb` | Regenerated by the two migrations. |
| `db/seeds.rb` | Admin user and 14 exercises. |

### Routes, controllers, helper (7 added, 4 modified)

| File | Change |
|---|---|
| `config/routes.rb` | All resource routes; removed template comments. |
| `app/controllers/application_controller.rb` | Added `require_admin!`. |
| `app/controllers/pages_controller.rb` | `home` loads dashboard data when signed in. |
| `app/controllers/exercises_controller.rb` | New. |
| `app/controllers/splits_controller.rb` | New. |
| `app/controllers/workout_days_controller.rb` | New. |
| `app/controllers/workout_exercises_controller.rb` | New. |
| `app/controllers/workout_logs_controller.rb` | New. |
| `app/controllers/workout_log_exercises_controller.rb` | New. |
| `app/controllers/workout_sets_controller.rb` | New. |
| `app/helpers/application_helper.rb` | `format_weight`, `nav_link_to`. |

### Views (16 added, 3 modified)

| File | Change |
|---|---|
| `app/views/layouts/application.html.erb` | `<main>` container; Devise pages wrapped in a card. |
| `app/views/shared/_navbar.html.erb` | Rewritten. |
| `app/views/pages/home.html.erb` | Landing page and dashboard. |
| `app/views/exercises/` | `index`, `new`, `edit`, `_form` (new). |
| `app/views/splits/` | `index`, `show`, `new`, `edit`, `_form` (new). |
| `app/views/workout_days/` | `show`, `new`, `edit`, `_form` (new). |
| `app/views/workout_exercises/` | `edit` (new). |
| `app/views/workout_logs/` | `index`, `show` (new). |

### Stylesheets (1 added, 5 modified)

| File | Change |
|---|---|
| `app/assets/stylesheets/components/_app.scss` | New. Main UI styles. |
| `app/assets/stylesheets/components/_index.scss` | Imports `app`. |
| `app/assets/stylesheets/components/_navbar.scss` | Replaced Le Wagon navbar styles. |
| `app/assets/stylesheets/config/_bootstrap_variables.scss` | New overrides. |
| `app/assets/stylesheets/config/_colors.scss` | New palette. |
| `app/assets/stylesheets/config/_fonts.scss` | New fonts. |

### Tests (2 added)

| File | Change |
|---|---|
| `test/models/workout_recording_test.rb` | New. 11 tests. |
| `test/integration/workout_flow_test.rb` | New. 6 tests. |

### Not touched

Devise views and initializer, `Gemfile`, JavaScript, mailers, `README.md`, the existing migrations, and the eight empty model test stubs.

---

## 10. Git and workspace history

- The session was started by the desktop app inside a **git worktree** at `.claude/worktrees/codebase-review-d62b2e`, on the branch `claude/codebase-review-d62b2e`. A worktree is a second checkout of the same repository; it shares history with the main folder but has its own files and branch. That is why the edits did not appear in the main folder at first.
- The worktree and the main folder used the **same development database**, so the migrations and seeds applied to the one database you use.
- The work was committed as one commit, `e64ee12`, on a new branch **`first-ui`**, and pushed to `origin/first-ui` on GitHub.
- Before the worktree was removed, local `master` in the main folder was already at `e64ee12` (a fast-forward merge of `first-ui`, done outside this session) and was one commit ahead of `origin/master`.
- The worktree was then removed on request, after confirming it had no uncommitted changes and was fully pushed.
- The branch `claude/codebase-review-d62b2e` was left in place. It points at the old `d415c01` and has no commits of its own, so `git branch -d claude/codebase-review-d62b2e` removes it safely.
- An empty, untracked `.claude` folder may remain in the project root.
- No pull request was opened.

**Working agreement from here on:** changes are made on a normal branch in the main folder that you create, not in a worktree.

---

## 11. Decisions at a glance

| # | Decision | Alternative rejected | Why |
|---|---|---|---|
| 1 | Block deleting an exercise that is in use | Cascade delete | Would erase other users' plans and history. |
| 2 | `reps_completed` may be 0 | Require at least 1 | A failed attempt is still a set. |
| 3 | Weights optional | Require a weight | Bodyweight exercises. |
| 4 | `NOT NULL` and a unique index in the database | Rails validations only | Validations can be skipped and uniqueness has a race. |
| 5 | Reach logs with `through` associations | `user_id` column on logs | No duplicated ownership to keep in sync. |
| 6 | Validate the day match on logged exercises | Redesign the tables | Closes the hole without changing your structure. |
| 7 | Shallow nested routes | Fully nested routes | Short URLs. |
| 8 | Scope every lookup to the current user | Find by id | Other users' records must not be reachable. |
| 9 | Starting a workout pre-creates an entry per planned exercise | Add each by hand | Otherwise logging a set takes several extra steps. |
| 10 | Inline forms report errors by flash; full forms re-render | Re-render everything | Much less code for the same information. |
| 11 | Leave browser validation off | Add `min` attributes | Lets you see the server-side validation work. |
| 12 | Style with the Bootstrap and Sass already installed | Add a UI library | No new dependencies. |
| 13 | `admin` boolean, limited to the catalogue | Roles gem, admin panel | Smallest thing that satisfies "an admin user". |
| 14 | Seed credentials from environment variables with dev defaults | Hard-coded only | Safe to run in production. |
| 15 | Label weights "kg" | No unit | A number without a unit is ambiguous. This is an assumption. |
| 16 | One commit for everything | Separate commits for fixes and UI | It was requested as "save the changes"; splitting it later is possible but was not asked for. |

---

## 12. Known gaps and things not done

### From the original review, still open

- **Decimal precision.** `target_weight` and `weight_used` are bare `decimal` columns.
- **Devise mailer sender** is still `please-change-me-at-config-initializers-devise@example.com`.
- **README** still lists SQLite/MySQL, Vue.js, a rest timer and progress monitoring.
- **Rubocop** has a config file but is not in the Gemfile.
- **Empty test stubs.** The eight generated model test files are still empty.
- **Deprecation warning** about `Rails.application.secrets` appears when the app boots. Its source was not investigated.

### Limits of the new UI

- **Not viewed in a browser** (see [section 8](#8-tests-and-verification)).
- **Sets cannot be edited**, only deleted and logged again.
- **Notes on a logged exercise and on a set** exist in the database but have no input in the UI. Only the workout's own notes can be edited.
- **A workout always starts dated today**; the date can be changed afterwards under Details.
- **Nothing prevents the same exercise being added twice** to one day's plan, or two workouts for the same day and date.
- **No way to reorder days** other than editing each one's position number.
- **No pagination** on History or the catalogue.
- **No admin screen for users.** Promoting someone is done in the console.
- **Regular users cannot add exercises.** If the catalogue lacks one, an admin must add it.
- **No progress charts, rest timer or summaries.** The UI covers only what the models could already do.
- **Positive-number rules are not in the database**, only in the models.
- **`app/javascript/controllers/hello_controller.js`** from the template is still present and unused.

### Before deploying anywhere

- Set `ADMIN_EMAIL` and `ADMIN_PASSWORD`; do not use the development defaults.
- Check that existing data satisfies the new `NOT NULL` and unique rules before migrating a database that already has rows.
