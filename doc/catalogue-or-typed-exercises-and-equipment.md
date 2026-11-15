# catalogue-or-typed-exercises-and-equipment

Branch: `catalogue-or-typed-exercises-and-equipment` (from `master` at `2aae478`). Written 2026-11-15.

## 1. Summary

This branch brings the app in line with the product prompt (`doc/Prompt/fitness-app-prompt.md`, not in git) and with the "Split creation" section of the issue list (`doc/Issues/Issues.md`, not in git).

- An exercise is picked from the shared catalogue (admin-managed) **or created by the user** as their own exercise.
- Equipment is chosen **per lift**: free weights, or a machine with a typed brand. It is no longer a field on the catalogue exercise.
- A split is a **week, Sunday to Saturday**: one circle per weekday, coloured when it has a workout day.
- A workout day lists **only exercises**. Target sets, reps and weight are gone.
- **Opening an exercise** is where sets are logged: reps, weight, "Add set". Sets go into today's workout automatically.
- Exercises are added through an **"Add exercises" modal**: the catalogue grouped by muscle group, plus a form to create a new exercise.

State: the test suite passes (27 runs, 215 assertions, 0 failures). The UI was **not** checked in a browser, and the development database was **not** migrated by this session (see section 7).

## 2. Timeline

| Request | What was done |
|---|---|
| Read the prompt to understand the purpose | Read it, summarised it. No changes. |
| Review the code and say what must change to follow the prompt | Reviewed schema, routes, models, controllers, views, seeds. Reported the gap: exercises only from an admin catalogue, equipment fixed on the catalogue exercise. Proposed removing the catalogue and admin role. |
| Keep the catalogue, admin-only additions, but also allow typing a name. Do not change code yet; edit the prompt | Rewrote the prompt accordingly. The hook blocks writing to the main folder from a worktree, so it was written in the worktree and the user copied it over (the two copies were identical at finalize time). |
| Create a branch and apply the changes | Created this branch. First round: optional catalogue link, typed names, per-lift equipment, logging unplanned exercises, editing a logged exercise. Tests: 24 passing. |
| Does "existing rows set to Free weights" rename Bench press? | Explained: the name is untouched; only the separate equipment value changed, and the old "Barbell"/"Cable" text is not carried over. No changes. |
| Four "Split creation" edits (exercise list + modal, exercise-only plans with per-set logging, week UI, catalogue grouped by muscle group) | Second round, described in section 4. Tests: 27 passing. |
| Do the other two issues (back buttons, dashboard week)? | User answered "Not yet". Not done. |
| Finalize the branch | First attempt stopped: the GitHub CLI token was invalid. After the user logged in again: tests rerun, this doc, commit, push, pull request, worktree removed. |

## 3. Starting point

```
User → Split → WorkoutDay → WorkoutExercise → Exercise (shared catalogue, admin-only)
                    ↓               ↑
               WorkoutLog → WorkoutLogExercise → WorkoutSet
```

- `workout_exercises.exercise_id` was required: an exercise could only be picked from the catalogue, and only an admin could add to it.
- `exercises.equipment` was one free-text field ("Barbell", "Machine") shared by everyone using that exercise.
- A planned exercise carried `sets`, `reps` and `target_weight`.
- A workout day had a free-text name and an `order_index`; a split showed its days as cards.
- Logging needed "Start workout", which created a log with one entry per planned exercise; a log entry had to point at a planned exercise; each set needed a typed set number.
- Removing a planned exercise deleted every set logged for it.

## 4. Changes

### 4.1 Exercises: shared catalogue plus the user's own

Before: `Exercise` had no owner; only admins created them.
After: `exercises.user_id` (nullable). `NULL` = shared catalogue, managed by admins only. Set = that user's own exercise, visible only to them.

```ruby
scope :shared, -> { where(user_id: nil) }
scope :visible_to, ->(user) { where(user_id: [nil, user.id]) }
```

- The "Add exercises" modal creates an exercise through `ExercisePicker#picked_exercises`: owned by the user, unless the user is an admin, in which case it goes to the shared catalogue.
- `ExercisesController`: `new`/`create` stay admin-only. `edit`/`update`/`destroy` work on the shared catalogue for an admin and on their own exercises for everyone else; anything else is a 404.
- The Exercises page lists the catalogue plus the user's own exercises, marked "Yours".

Reason: the user wanted the catalogue kept for quick selection, admin-only additions, and the freedom to use any exercise; later they asked for the picker to show "the ones he created".

### 4.2 Name and equipment live on each lift (`Lift` concern)

`workout_exercises` and `workout_log_exercises` both gained `name`, `equipment` (`free_weights` | `machine`, default `free_weights`) and `machine_brand`. `exercise_id` is optional on both (`workout_log_exercises` gained the column).

`app/models/concerns/lift.rb`, included by both models:

- the linked exercise decides the name; the name is stored on the row so history survives the exercise being deleted;
- `equipment` must be one of the two values; `machine_brand` is required for a machine and cleared otherwise;
- `equipment_label` gives "Free weights" or "Machine · Brand".

`exercises.equipment` was removed. Renaming an exercise renames linked plan and log rows (`Exercise#rename_linked_lifts`). Deleting an exercise is still refused while it is in a plan; log entries only lose the link.

### 4.3 A split is a week

Before: `workout_days.order_index`, cards per day.
After: `workout_days.weekday` (0 = Sunday … 6 = Saturday, as `Date#wday`), unique per split; `order_index` removed.

- `splits/_week.html.erb` renders seven circles with the weekday initial. A weekday with a workout day is coloured, shows the day's name under it and links to the day; an empty one links to "new workout day" with that weekday preselected.
- The workout day form asks for a name and a day of the week.
- Existing days: one named after a weekday ("Monday") keeps it; the others take the free weekdays in their old order, starting Monday. An eighth day in a split is left without a weekday and listed under "Not on a weekday yet".

### 4.4 A workout day lists only exercises

`workout_exercises.sets`, `reps` and `target_weight` were removed, with their validations, form fields and display.

The day page shows a list of exercises. Empty: an "Add exercise" button. Otherwise the button is in the card header. Each row opens the exercise and shows "n sets today" when there are any.

### 4.5 Opening an exercise and adding sets

New page `GET /workout_exercises/:id`: today's sets, a form with reps and weight and an "Add set" button, and the equipment form.

`POST /workout_exercises/:id/workout_sets`:

```ruby
workout_log = planned.workout_day.workout_logs.where(date: Date.current).order(:id).first_or_create!
workout_log.workout_log_exercises.where(workout_exercise: planned).order(:id).first_or_create!
```

- Today's workout and its entry are created on the first set, inside a transaction that rolls back if the set is invalid, so no empty workout is left behind.
- `WorkoutSet` numbers itself on create (next number for its exercise); the set-number field is gone from the forms.
- The form is pre-filled with the last set (today's, else the most recent one for that exercise).
- "Start workout" (button, route, `WorkoutLogsController#create`) was removed.

### 4.6 "Add exercises" modal

`shared/_exercise_picker.html.erb`, a Bootstrap modal used on the day page and on a logged workout:

- exercises visible to the user, grouped by muscle group (blank group = "Other"), with checkboxes; ones already added are disabled and marked "Added";
- "Create your own": name and muscle group (`Exercise::MUSCLE_GROUPS` plus any group already in use).

Both forms post to the same URL; `ExercisePicker` reads either `exercise_ids[]` or `exercise[name, muscle_group]`.

### 4.7 Logged workouts

- A log entry no longer needs a planned exercise (`workout_exercise_id` nullable). One created from a plan copies the plan's exercise, name and equipment (`WorkoutLogExercise#copy_from_plan`).
- Removing an exercise from a day keeps logged entries (`dependent: :nullify`, was `:destroy`).
- The workout page: entries show their equipment, "Add set" without a set number, an "Add exercise" button opening the modal, and an edit page for an entry's equipment.

## 5. Decisions

| Decision | Alternative rejected | Why |
|---|---|---|
| Keep catalogue and admin role | Remove both (my first proposal) | The user asked to keep them. |
| Store the name on plan and log rows, with an optional link | Derive the name through the link only | Logged history must survive an exercise being deleted or removed from a plan. |
| Equipment is two values plus a brand | Keep "Barbell/Dumbbell/Cable" detail | The prompt names exactly two choices. Offered to the user; not requested. |
| Existing rows become "Free weights" | Map the old "Machine" text to machine | A machine needs a brand and the old data had none. |
| Removing a planned exercise keeps its logged sets | Delete them, as before | Recommended in the review; the user later confirmed it. |
| A logged exercise's equipment can be edited | Remove and re-add | Machines differ by day; the user confirmed it. |
| User-created exercises are private; an admin's go to the catalogue | Every created exercise is shared | Only an admin may add to the catalogue. **Assumption** for the admin half: the user did not say what an admin's modal creation should do. |
| A workout day belongs to one weekday, one per weekday per split | Keep free ordering and show calendar dates | The issue list asks for a Sunday–Saturday week and (Home page item) "what workout from the split it is" today. **Assumption**: "each date" means each weekday. |
| Sets are saved under today's date, created on the first set | Keep "Start workout"; or sets with no date | Fewest taps, and History keeps working. **Assumption**: the user did not say which; flagged to them. |
| Remove "Start workout" | Keep both ways of logging | Two paths to the same thing; flagged to the user. |
| Equipment is set on the exercise page, not in the modal | Ask per exercise in the modal | The modal adds several exercises at once. |
| Select catalogue exercises with checkboxes | One at a time | "Choose the ones…" in the request. |
| Second migration instead of editing the first | One combined migration | The user had already run the first on their development database. |
| Removed `hello_controller.js` | Leave it | Unused Rails sample next to the new controller. |

## 6. How it works now

```
User ─┬→ Split → WorkoutDay (weekday) → WorkoutExercise (name, equipment, brand) ─→ Exercise
      │                ↓                         ↑ optional                          ↑ optional
      │           WorkoutLog (date) → WorkoutLogExercise (name, equipment, brand) → WorkoutSet
      └→ Exercise (user_id set = own; NULL = shared catalogue)
```

Flow: Splits → open a split → tap a weekday circle → name the workout day → "Add exercise" → tick exercises or create one → tap an exercise → enter reps and weight → "Add set". The workout appears in History under today's date.

To run it:

```bash
bin/rails db:migrate
bin/rails db:seed      # optional: admin user and starter catalogue
bin/rails server
```

## 7. Tests and verification

- `bin/rails test`: **27 runs, 215 assertions, 0 failures, 0 errors** (run again at finalize time).
- Both migrations were run against the **test** database only. The second was also rolled back and re-run over sample rows to check the weekday backfill: `Push, Wednesday, Pull, Legs, sunday, A, B, C, D` became `Monday, Wednesday, Tuesday, Thursday, Sunday, Friday, Saturday, none, none`.
- The stylesheet was compiled once to confirm the new rules are valid SCSS.

Not verified:

- **Nothing was looked at in a browser.** The modal opening, the week layout on a phone, and the show/hide of the machine brand field (`reveal_controller.js`) are untested.
- **The development database was not migrated** by this session. It is shared with the main folder, and `master` still reads columns these migrations drop.
- The `down` direction of the first migration was not run.
- No linter was run (`rubocop` is not in the bundle).

## 8. Every file changed (41)

Migrations and schema (3)
- `db/migrate/20261115140000_add_typed_names_and_equipment_to_lifts.rb` — name, equipment, brand on plan and log rows; optional links; drops `exercises.equipment`.
- `db/migrate/20261115150000_schedule_days_and_add_personal_exercises.rb` — `exercises.user_id`, `workout_days.weekday` with backfill, drops targets and `order_index`.
- `db/schema.rb` — result of both.

Models (7)
- `app/models/concerns/lift.rb` — new; shared name and equipment rules.
- `app/models/exercise.rb` — owner, scopes, muscle groups, rename propagation.
- `app/models/user.rb` — `has_many :exercises`.
- `app/models/workout_day.rb` — weekday validation and name.
- `app/models/workout_exercise.rb` — uses `Lift`; targets removed; nullifies log entries.
- `app/models/workout_log_exercise.rb` — uses `Lift`; optional plan link; copies from plan.
- `app/models/workout_set.rb` — numbers itself.

Controllers and routes (9)
- `app/controllers/concerns/exercise_picker.rb` — new; reads the modal's two forms.
- `app/controllers/exercises_controller.rb` — owner-or-admin management.
- `app/controllers/splits_controller.rb` — orders days by weekday.
- `app/controllers/workout_days_controller.rb` — weekday preselect, today's set counts, picker data.
- `app/controllers/workout_exercises_controller.rb` — `show`, create from the picker, equipment update.
- `app/controllers/workout_log_exercises_controller.rb` — create from plan or picker, equipment edit.
- `app/controllers/workout_logs_controller.rb` — "Start workout" removed; picker data.
- `app/controllers/workout_sets_controller.rb` — adds a set to today's workout or to a log entry.
- `config/routes.rb` — exercise page and its sets; log entry edit; removed start-workout route.

Views (15)
- `app/views/shared/_exercise_picker.html.erb` — new; the modal.
- `app/views/shared/_equipment_fields.html.erb` — new; equipment select and brand.
- `app/views/splits/_week.html.erb` — new; the week strip.
- `app/views/splits/show.html.erb` — week instead of cards.
- `app/views/splits/index.html.erb` — sorts days by weekday.
- `app/views/workout_days/_form.html.erb` — name and day of the week.
- `app/views/workout_days/show.html.erb` — exercise list and "Add exercise".
- `app/views/workout_exercises/show.html.erb` — new; today's sets, "Add set", equipment.
- `app/views/workout_exercises/edit.html.erb` — deleted; replaced by the page above.
- `app/views/workout_log_exercises/edit.html.erb` — new; equipment of a logged exercise.
- `app/views/workout_logs/show.html.erb` — no targets, "Add set", modal.
- `app/views/workout_logs/index.html.erb` — empty-state text.
- `app/views/pages/home.html.erb` — sorting and texts.
- `app/views/exercises/_form.html.erb` — equipment field removed.
- `app/views/exercises/index.html.erb` — "Yours" marker, per-row permissions, equipment column removed.

Assets (3)
- `app/assets/stylesheets/components/_app.scss` — week, row link, picker styles.
- `app/javascript/controllers/reveal_controller.js` — new; shows the brand field for a machine.
- `app/javascript/controllers/hello_controller.js` — deleted.

Seeds, tests, doc (4)
- `db/seeds.rb` — catalogue without equipment.
- `test/integration/workout_flow_test.rb` — rewritten for the new flows.
- `test/models/workout_recording_test.rb` — updated and extended.
- `doc/catalogue-or-typed-exercises-and-equipment.md` — this file (force-added: `/doc` is in `.gitignore`).

## 9. Known gaps

- Not browser-tested (section 7).
- **Data loss on migrate, by design:** target sets/reps/weights and the old catalogue equipment text are dropped; all existing lifts become "Free weights".
- A split with more than seven days leaves the extra ones without a weekday until edited.
- Equipment changed on a day's exercise does not update an entry already created for today.
- The same exercise can be added to a logged workout twice (only the day page marks exercises as "Added" reliably for the plan).
- An admin cannot create a private exercise: what they create in the modal is shared.
- Two issues from `Issues.md` are not done, at the user's request: back buttons (General) and the week on the dashboard with today highlighted (Home page).
- `README.md` still describes planned sets/reps and a rest timer.
