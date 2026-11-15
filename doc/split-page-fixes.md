# Split page fixes

Record of the work done on 2026-11-16 on the branch `split-page-fixes` (created as `claude/split-page-issues-2225da` and renamed before it was pushed).

---

## 1. Summary

- Fixes the seven "Split Page" issues listed in `doc/Issues/Issues.md`.
- A workout day of a split now shows only its program. Adding one exercise opens it, an exercise can be removed from its row, sets show weight before reps, and a recorded set can be corrected in place.
- A new rake task logs last week's sessions for every split, as mock data.
- **Checked:** `bin/rails test` passes: 39 runs, 390 assertions, 0 failures. A server started from this branch boots and serves the new Stimulus controller.
- **Not checked:** nobody clicked through the changed pages in a browser during this work. The in-place set editing in particular is JavaScript that the tests only cover on the server side.

---

## 2. Timeline

| Step | Request | What happened |
|---|---|---|
| 1 | "Read doc/Issues/Issues.md and fix the issues for Split Page" | Read the issues and the code behind them, made the changes described below, updated the tests, ran the suite, ran the mock data task on the development database, and moved the Split Page section to "Issues Resolved". |
| 2 | "These issues were not fixed" (issues 2 to 6) | The fixes were in place. The server on `localhost:3000` was running from the main folder on `master`, and the changes were uncommitted in this worktree. Issue 7 had looked fixed because both checkouts share the development database. Started a second server from the worktree on `localhost:3001` so the fixes could be seen. No code changed. |
| 3 | "Yes, finalize" | Renamed the branch, re-ran the tests, wrote this doc, committed, pushed and opened the pull request. |

---

## 3. Starting point

The seven issues, as written by the user:

1. Each split should not have the exercises recorded. It should only be a page of the splits programmed.
2. When adding an exercise go to the page of said exercise so I can already add the reps and weight I did for the exercise.
3. Have a quick button on the exercise box to delete the exercise if I add the wrong exercise.
4. Remove the today form "N reps today" and just have "N reps".
5. Change the position of reps - weight to be weight - reps.
6. Add a function to edit the number on the already registered reps or weight; need to be able to edit it if I make a mistake but don't want to delete the whole exercise.
7. Also create mock data with exercises for each split already recorded from last week, to compare and see how the app handles it.

How the app behaved before:

- The workout day page (`workout_days/show`) had two columns: the exercises of the day, and a "Logged workouts" list of past sessions.
- Adding exercises from the "Add exercises" modal always returned to the day page.
- An exercise could only be removed from its own page ("Remove" in the header).
- A row with sets recorded today showed a chip reading "N sets today".
- Set tables and "Add set" forms were ordered Set, Reps, Weight.
- A recorded set could be deleted but not changed. `workout_sets` had only `create` and `destroy`.
- `db/seeds.rb` created the admin and the catalogue; there was no way to generate logged workouts.

---

## 4. Changes

### 4.1 The day page shows only the program (issue 1)

`app/views/workout_days/show.html.erb` lost its right-hand "Logged workouts" column, and the exercises card now takes the full width. `WorkoutDaysController#show` no longer loads `@logs`.

Logged sessions are still reachable from History and from the dashboard.

### 4.2 Adding one exercise opens it (issue 2)

`WorkoutExercisesController#create`:

```ruby
# before
WorkoutExercise.transaction do
  exercises.each { |exercise| workout_day.workout_exercises.create!(exercise: exercise) }
end
redirect_to workout_day, notice: "..."

# after
added = WorkoutExercise.transaction do
  exercises.map { |exercise| workout_day.workout_exercises.create!(exercise: exercise) }
end
redirect_to (added.one? ? added.first : workout_day), notice: "..."
```

One exercise added (ticked in the catalogue or created on the spot) redirects to that exercise's page, where the "Add set" form is. Several exercises ticked at once go back to the day.

### 4.3 Quick remove on the exercise row (issue 3)

Each row of the day's exercise list has a trash button that sends `DELETE /workout_exercises/:id`. It removes immediately. It carries a `turbo_confirm` only when sets were already recorded on that exercise today, because then the removal unlinks recorded sets from the plan (they stay in the history).

### 4.4 "N sets" (issue 4)

The chip on the row reads "2 sets" instead of "2 sets today".

### 4.5 Weight before reps (issue 5)

On the exercise page (`workout_exercises/show`) and the logged workout page (`workout_logs/show`), the table header is now Set, Weight, Reps, and the "Add set" form has the weight field first. The dashboard already showed "weight × reps".

### 4.6 Editing a recorded set (issue 6)

- Route: `resources :workout_sets, only: [:update, :destroy]`.
- `WorkoutSetsController#update` changes `reps_completed` and `weight_used` only (not the set number), scoped to the signed-in user's own sets, then redirects back with "Set N updated." or "Set not updated: ...". A blank weight saves as bodyweight, as when adding a set.
- The lookup and the fallback path shared with `destroy` moved into two private methods, `own_set` and `entry_path`.
- New partial `app/views/workout_sets/_set.html.erb` renders one set row and is used by both set tables. Each row has a pen button and the delete button. The pen hides the values and shows two number fields with Save and Cancel.
- New Stimulus controller `app/javascript/controllers/row_edit_controller.js` does the switching. Cancel (or Esc) resets the fields to the saved values.
- The inputs sit in the weight and reps cells while the `<form>` sits in the actions cell; they are tied together with the HTML `form="edit_set_<id>"` attribute, because a form cannot wrap table cells.
- Three style rules added in `_app.scss` (`.set-table td`, `.set-field`, `.set-actions`).

### 4.7 Mock data (issue 7)

New file `lib/tasks/mock.rake`:

```bash
bin/rails mock:last_week                  # every user
bin/rails mock:last_week EMAIL=me@x.com   # one user
bin/rails mock:clear                      # deletes the workouts it logged
```

For every workout day that has a weekday, in every split, it logs a session on that weekday of last week (Sunday to Saturday): one entry per planned exercise, three sets each, same weight, reps dropping by one per set. Weights and reps come from a fixed table per exercise, so the result is the same on every run. A day that has no exercises first receives a typical plan for its workout (Push, Pull, Legs/Lower, Upper, Anterior, Posterior, Full Body) from the shared catalogue; a missing catalogue exercise is created. The logs carry the note "Mock data", which is what `mock:clear` deletes. A day already logged on that date is skipped, so the task can be run again.

It was run once on the development database and logged 13 workouts dated 2026-11-09 to 2026-11-14 for the three existing splits (PPL/UL, UL, U/R/L/U/L). A second run skipped all 13.

### 4.8 Issues file

The "Split Page" section of `doc/Issues/Issues.md` moved under "Issues Resolved".

---

## 5. Decisions

| Decision | Alternative rejected | Why |
|---|---|---|
| Issue 1 means the "Logged workouts" list on the day page. **Assumption.** | Also removing the set-count chip from the rows. | Issue 4 asks for that chip to stay, reworded. The logged list was the only other recorded data on the page. |
| Issue 4: the chip says "N sets". **Assumption.** | "N reps", the literal wording of the issue. | The number counts sets. Labelling it reps would be wrong. |
| Several exercises added at once return to the day. | Opening the first of them. | With several there is no single "said exercise" to open. |
| The quick remove confirms only when sets were recorded today. | Always confirming; never confirming. | The request is for a quick button for a mistaken add, which has no sets. With sets, a slip would unlink them from the plan. |
| Sets are edited in place in the table row. | A separate edit page per set. | Correcting one number should not leave the page. |
| Editing changes weight and reps, not the set number. | Permitting `set_number` as `create` does. | Set numbers are unique per exercise; renumbering was not asked for and can collide. |
| Mock data is a rake task. | Putting it in `db/seeds.rb`. | Seeds run on setup, including production; mock workouts should only exist when asked for. |
| The mock task fills empty days with a plan. | Logging only days that already have exercises. | Most days in the development database had none, so most splits would have had nothing recorded to compare. |
| The second server was started on port 3001. | Switching the main folder to this branch. | The main folder is the user's; nothing is changed there. |

---

## 6. How it works now

Flow on a split: open a split, tap a coloured day, and the day page lists its exercises. "Add exercise" opens the modal; adding one exercise lands on that exercise's page. There, "Today" lists the sets (Set, Weight, Reps), each with a pen to correct it and a trash to delete it, and the form below adds the next set, pre-filled from the last one. Back on the day, each row shows "N sets" once something is recorded and has a trash button to drop the exercise from the day.

The data model is unchanged: no migration. One route was added (`PATCH /workout_sets/:id`).

To try it from this branch:

```bash
bin/rails server
bin/rails mock:last_week
```

---

## 7. Tests and verification

Run: `bin/rails test`, twice (after the changes and again before committing): 39 runs, 390 assertions, 0 failures, 0 errors, 0 skips.

`test/integration/workout_flow_test.rb` was extended to cover:

- one added exercise redirects to its page; several redirect to the day
- the day page has the remove button on a row and no "Logged workouts" heading
- the remove form carries a confirmation once sets exist
- the chip reads "2 sets"
- the table header is Set, Weight, Reps, and the weight field comes before the reps field
- each set row has its edit form and two linked inputs
- `PATCH /workout_sets/:id` updates weight and reps, redirects back, and rejects blank reps without changing the set

Also checked: `mock:last_week` ran on the development database (13 logged, then 13 skipped); the server from this branch answered `/up` with 200 and served `row_edit_controller.js`.

Not verified:

- the pages were not opened in a browser, so layout, the pen/Save/Cancel behaviour and the Esc key are untested by hand
- `mock:clear` was not run
- the mock task has no automated test

---

## 8. Every file changed

14 files.

Controllers and routes
- `app/controllers/workout_days_controller.rb`: no longer loads the day's logged workouts.
- `app/controllers/workout_exercises_controller.rb`: one added exercise redirects to its page.
- `app/controllers/workout_sets_controller.rb`: new `update`; shared lookup and fallback path extracted.
- `config/routes.rb`: `workout_sets` gains `update`.

Views
- `app/views/workout_days/show.html.erb`: program only, "N sets" chip, remove button on each row.
- `app/views/workout_exercises/show.html.erb`: weight before reps; rows rendered by the shared partial.
- `app/views/workout_logs/show.html.erb`: weight before reps; rows rendered by the shared partial.
- `app/views/workout_sets/_set.html.erb` (new): one set row with in-place editing.

JavaScript and styles
- `app/javascript/controllers/row_edit_controller.js` (new): switches a row between showing and editing.
- `app/assets/stylesheets/components/_app.scss`: styles for the editable set row.

Tasks
- `lib/tasks/mock.rake` (new): `mock:last_week` and `mock:clear`.

Tests
- `test/integration/workout_flow_test.rb`: assertions for the points in section 7.

Docs
- `doc/Issues/Issues.md`: Split Page section moved to "Issues Resolved".
- `doc/split-page-fixes.md` (new): this file.

---

## 9. Known gaps

- No browser check of the new UI (see section 7).
- Two of the seven issues were read with an assumption (issues 1 and 4, section 5). If the reading is wrong, the change is small to adjust.
- `mock:last_week` added planned exercises to the days that had none in the development database. `mock:clear` removes the mock workouts but leaves those planned exercises.
- With several splits, the mock data holds more than one session of the same workout on the same date (for example three "Upper" sessions on Monday), one per split.
- `redirect_back` after editing or deleting a set relies on the browser's referer; without it the user lands on the logged workout page instead of the exercise page.
- The development database is shared between the main folder and worktrees, so the mock workouts are visible on `master` too, before this branch is merged.
