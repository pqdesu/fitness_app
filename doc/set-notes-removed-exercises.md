# set-notes-removed-exercises

## 1. Summary

This branch fixes the two open issues under "Exercises" in `doc/Issues/Issues.md`. Fixing the second one meant separating the plan from the workout.

- **No notes per set.** Every set now has its note field under it, always visible. Leaving the field or pressing Enter saves the note. The exercise page and the logged workout page no longer jump to the top on a save: Turbo morphs the page in place and keeps the scroll.
- **Deleted exercise shows up in workout page.** The workout day page was both the workout and the day's plan, and its "Add exercise" added to the plan. Now:
  - the split page is the plan (each workout day's card plans its exercises)
  - a workout day's page is the workout, and "Add exercise" there adds to that day's workout only
  - removing an exercise from a workout keeps it on the plan if it was planned; one added while training is gone
- The issue list gained a "Potential issues" section, and the `finalize-branch` skill now records a branch's leftover risks there.

**State:**
- `bin/rails test`: 90 runs, 1234 assertions, 0 failures.
- `bundle exec rubocop`: no offenses.
- `bundle exec brakeman`: no warnings.
- The changed pages were checked at phone width (390 px) in the Chrome installed on WSL, driven over the DevTools protocol.

The branch was created as `claude/exercises-issues-investigation-b2cb0e` and renamed `set-notes-removed-exercises` before anything was pushed.

## 2. Timeline

1. **Investigate the two "Exercises" issues** (`investigate-issues` skill, read-only).
   - **Notes:** the set note field existed only in the hidden edit row (`workout_sets/_set`), shown by the pen.
   - **Removed exercise:** "From this day, not in this workout" lists the day's planned exercises that are not in the log. The removed exercise was on the plan.
2. **"Fix both, option a".** Two changes:
   - The note field became always visible and saves on change.
   - Removing an entry from a logged workout also deleted the plan row when that row was created on or after the workout's date and had no other entries.
3. **Owner clarified option a.** "If the exercise is in the plan then keep it. If the exercise wasn't in the plan remove it." That is exactly how removal already worked, so the controller change from step 2 was reverted, and a test now checks both cases.
4. **"Why did Triceps pushdown appear when it was not planned for Lower?"**
   - The dev database showed Triceps pushdown on the Lower day's plan, added on 19 Nov at 23:47 (JST), with no logged entry.
   - The only code that adds a plan row is `WorkoutExercisesController#create`, and the workout day page's "Add exercise" posts there. So training a day silently changed its plan.
   - Two fixes were proposed: a tick box, or clean-up when removing.
5. **"Deep search, then: the split can only be planned on the split page; adding exercises on the workout day must not add to the plan; the split page is only a pre-plan (workouts on the week and their exercises); removing from a workout keeps pre-planned exercises and removes the others. You can change how the app works."** This was implemented (sections 4 and 6).
6. **"Save in memory to always check the site in the Chrome installed on WSL, especially mobile views."** This was saved to the assistant's memory, outside the repo. All checks from then on used WSL Chrome at 390 px.
7. **"I also want the note to not be jumpy when added."** Turbo morph refresh with scroll preserve was turned on for the two pages that have set tables, and the picker forms opt out of it (see Decisions).
8. **"Add this risk as a potential issue, in a new section, and make finalize-branch do that when moving issues or features."** The section was added to `Issues.md`, the skill was edited, and `CLAUDE.md` was given one line about it.
9. **"Finalize it."** This doc, the seed data, the commit, the push and the pull request.

## 3. Starting point

- `workout_sets/_set.html.erb` drew a set as a `<tbody>`:
  - the row of numbers
  - the note as text, only when there was one
  - a hidden row with the note field, Save and Cancel
- The pen (`row_edit_controller.js#edit`) showed that hidden row. There was no other way to write a note.
- Every save redirected back and Turbo rendered the page fresh, scrolled to the top.
- `splits#show` showed only the week of circles. A coloured circle opened `workout_days#show`.
- `workout_days#show` was the only page of a split's day:
  - it listed the plan (`@workout_day.workout_exercises`)
  - its "Add exercise" posted to `WorkoutExercisesController#create`, which runs `workout_day.workout_exercises.create!`, the only place a plan row is made
  - each row's trash deleted the plan row
  - its header had Edit and Delete for the day
- The dashboard's "Start workout" and "Train as extra" opened that same page with `?date=`.
- Sets reach a split's workout only through a plan row (`WorkoutExercise#entry_on!`). So every exercise trained from the day page had to become part of the plan.
- `workout_exercises#show` (the exercise page) had a "Remove" button that deleted the plan row.

## 4. Changes

### 4.1 The set note field is always there (`workout_sets/_set`, `row_edit_controller.js`, `_workout_log.scss`)

**Before:** a note row showed text, and a hidden edit row held the note field with Save and Cancel.

**After:**

```erb
<tr class="set-note">
  <td colspan="4">
    <%= text_field_tag "workout_set[notes]", set.notes, id: "notes_set_#{set.id}", form: form_id, maxlength: 200,
          placeholder: "Add a note", ..., data: { action: "change->row-edit#save" } %>
  </td>
</tr>
<tr class="set-note" hidden data-row-edit-target="field"> ... Save, Cancel ... </tr>
```

```js
// The note field saves on its own when it is changed.
save() {
  this.formTarget.requestSubmit()
}
```

- The note input still belongs to the set's existing PATCH form (`form: form_id`), so saving it is the same `WorkoutSetsController#update` as before. No server change was needed: `notes` was already permitted and normalised.
- `change` fires when the field is left after typing, or on Enter. The form also sends weight and reps, with their saved values.
- The pen now only turns weight and reps into fields. The bar under them holds only Save and Cancel, aligned right. The CSS for the old note-in-the-bar layout was deleted.

### 4.2 No jump when a set or note is saved (layout, `workout_exercises/show`, `workout_logs/show`, `_exercise_picker`)

- The layout's `<head>` gained `<%= yield :head %>`.
- Both pages with set tables start with:
  ```erb
  <% turbo_refreshes_with method: :morph, scroll: :preserve %>
  ```
  When a form redirects back to the same address, Turbo 8 (turbo-rails 2.0.23, already installed) morphs the page instead of replacing it, and keeps the scroll.
- Both forms of the exercise picker got `data: { turbo_action: "advance" }`, which makes them load the next page in full. Without it, on the morphing logged workout page, the picker submitted while open and was morphed away, and Bootstrap kept thinking it was open, so it never opened again. That was seen in the browser check.

### 4.3 The split page is the plan (`splits#show`, `splits/_week`, `workout_exercises#create/destroy`, `workout_days` forms)

`splits/show.html.erb` keeps the week of circles and adds one card per workout day (`id="day-<id>"`). Each card has:
- the workout's name and weekday
- a pen (`workout_days#edit`: workout and weekday) and a trash (delete the day, with a confirm)
- the planned exercises, each with its muscle group and a × that removes it from the plan
- "Plan exercises", which opens that day's own picker

Several pickers on one page needed `shared/_exercise_picker` to take a `key:` local. Every id in the modal becomes `exercise-picker-<key>…`. `exercise_picker_button(css, key:, label:)` opens the matching picker. Pages that pass no key are unchanged.

Other changes:
- `SplitsController` includes `ExercisePicker` and loads the days with `includes(workout_exercises: :exercise)`.
- `splits/_week`: on the split page (no `plan:` local), a coloured circle links to its card (`split_path(split, anchor: "day-<id>")`). On the dashboard (`plan:` passed) it still opens the workout.
- `WorkoutExercisesController#create` (plan an exercise) and `#destroy` (unplan one) redirect to the day's card. Before, they went to the workout day page, or to the exercise page when one exercise was added.
- Messages: "Bench press planned for Push." and "Bench press removed from Push."
- `WorkoutDaysController#create` and `#update`, the edit page's back arrow, and the form's Cancel all return to the day's card on the split page.

### 4.4 The workout day page is the workout (`workout_days#show`, `workout_log_exercises#create/destroy`, routes)

**Route:**
```ruby
resources :workout_days, only: [...] do
  resources :workout_exercises, only: [:create]      # plan (split page)
  resources :workout_log_exercises, only: [:create]  # add to the workout while training
end
```

**`WorkoutDaysController#show`** also works out `@extra_entries`: the entries of that date's session that no planned exercise of the day matches.
```ruby
entries = @workout_exercises.to_h { |planned| [planned.id, log && planned.entry_in(log)] }
@sets_logged = entries.transform_values { |entry| entry&.workout_sets&.size.to_i }
@extra_entries = log ? log.workout_log_exercises.sort_by(&:id) - entries.values : []
```

**`workout_days/show.html.erb`:**
- The header has a "Plan" link to the day's card. Edit and Delete for the day moved to the split page.
- It lists the planned exercises, which open the exercise page as before. They have no remove button, because the workout does not change the plan.
- Then it lists the extra entries, labelled "Added to this workout":
  - each one opens its logged workout at `#entry-<id>`, where its sets are added
  - each has a × to take it out of the workout, which asks first only when it has sets
- "Add exercise" posts to `workout_day_workout_log_exercises_path(day, date:)`. On a workout later this week, there is no picker.
- The back arrow falls back to the dashboard. Before, it fell back to the split.

**`WorkoutLogExercisesController#create`** accepts `workout_day_id`:
```ruby
workout_day = current_user.workout_days.find(params[:workout_day_id])
date = logging_date(workout_day)
workout_log = workout_day.log_on(date) || workout_day.workout_logs.new(date:)
...
WorkoutLogExercise.transaction { workout_log.new_record? ? workout_log.save! : entries.each(&:save!) }
```
- A new session is saved together with its entries, which were built on it. Its existing validations apply: no future date, one session per workout per day, one workout per split per day, rest-day mark.
- A refusal comes back as "Nothing added: …" on the workout day page.

**`#destroy`** returns to the workout day page when called with `workout_day_id` (and `date`). Otherwise it returns to the logged workout, as before. The notice names the exercise.

**`workout_exercises/show.html.erb`** lost its "Remove" button, which deleted the plan row.

### 4.5 Removing an exercise from a workout

No code change: the owner's rule is how `WorkoutLogExercisesController#destroy` already worked. It deletes the entry and its sets; a plan row is untouched.
- A planned exercise is offered again under "From this day, not in this workout".
- One added while training is gone.

A step 2 version that also deleted same-day plan rows was written, then reverted (Timeline 3).

### 4.6 Docs and skill

- **`doc/Issues/Issues.md`:**
  - Both "Exercises" issues moved to "Issues resolved", each with the fix.
  - A new "Potential issues" section sits above "Issues resolved", with one item (section 9).
- **`.claude/skills/finalize-branch/SKILL.md`:** step 3a now also records the risks a branch leaves behind under "Potential issues" whenever items move. Each item starts "From `BRANCH`:". A potential issue the branch fixes moves to resolved. The change doc and the report list the ones added.
- **`CLAUDE.md`:**
  - product rules for plan vs workout, and for removal
  - the "Start workout creates nothing" rule now also says a workout is logged when an exercise is added to it from its page
  - a code-map line for the plan and workout pages
  - one sentence about "Potential issues"
- **`doc/Prompt/project-context.md`:**
  - decision 6 rewritten (the plan is made on the split page)
  - new decision 18 (training never changes the plan)
  - the Split page, Workout day page and Exercise page flows rewritten

## 5. Decisions

- **Note saves on `change`, not on every keystroke.** The owner asked for "saved when the text is added". `change` (leave the field, or Enter) sends one request per note, with no timer code. *Rejected:* saving as you type (debounced). It adds requests and JavaScript for no gain.
- **The note uses the set's existing form.** No new route or action. *Rejected:* a separate notes endpoint.
- **Option a, first reading (same-day plan rows deleted on removal): built, then reverted** at the owner's correction (Timeline 3).
- **Plan vs workout: two pages, one job each.** The owner asked that the plan be made only on the split page and that the workout never change it.
  - The tick box ("Add to Lower's plan") and clean-up-on-remove options were dropped: the owner chose the separation.
  - *Rejected:* a separate "workout" model or table. The existing `WorkoutLog` / `WorkoutLogExercise` already hold "this day's workout". The only new code path is creating the session when the first extra exercise is added.
- **Adding an exercise while training starts the session right away.** The entry needs a log to belong to. This mirrors "a workout not in the split is logged when its first exercise is added". `CLAUDE.md` says so. *Assumption:* the owner accepts a workout appearing in History once an exercise is added, before any set.
- **An extra exercise opens in the logged workout page** (at its entry), which already has the add-set form. *Rejected for now:* an exercise page per log entry, which would be a near copy of `workout_exercises#show`.
- **Plan editing on the split page itself,** one card per day, rather than a separate plan page per day. The owner said "the split page is a pre plan". One picker per day was simpler than a shared picker that would need JavaScript to know which day it was for.
- **No remove button for planned exercises on the workout page.** Removing them from the workout there would only delete sets, and sets can already be deleted one by one. The plan changes only on the split page.
- **Equipment chosen on the exercise page still updates the plan row,** so the next workout starts with the same machine. This was kept unchanged, and the owner was told. *Open:* whether equipment should also stay out of the plan.
- **Split-page circles no longer open the workout.** Training goes through the dashboard: "Start workout", "Train as extra", and the week strip with `plan:`. A non-active split's workout cannot be opened from its split page any more. The owner was told.
- **Morph only on the two set pages, not app-wide.** Morphing everywhere would also morph pages whose Bootstrap modals submit while open. Even on these two pages the picker had to opt out (4.2).
- **`Issues.md` changes made on this branch, not on `master`.** `CLAUDE.md` forbids writing to the main checkout or pushing to `master`, so the section reaches `master` with this pull request.
- **No `Features.md` items moved.** "Also add notes of the exercise and notes for the set" is only partly done: set notes are always visible now, while exercise notes already existed on a logged exercise's edit page. Nothing else in the list was finished.

## 6. How it works now

- **Split page (`/splits/:id`), the plan.**
  - The week of circles: a blank day adds a workout day, and a coloured day scrolls to its card.
  - Each card lists the day's planned exercises. × takes one off the plan, and "Plan exercises" picks from the catalogue or creates one.
  - The pen changes the workout or weekday, and the trash deletes the day.
- **Workout day page (`/workout_days/:id?date=…`), the workout.**
  - Opened from the dashboard.
  - Lists the planned exercises, then "Added to this workout".
  - "Add exercise" adds to that date's workout (starting it), never to the plan.
  - × on an added exercise takes it out, and it is gone.
  - "Plan" goes to the day's card.
- **Exercise page (`/workout_exercises/:id?date=…`).**
  - Sets with an always-visible note field under each.
  - The pen edits weight and reps.
  - Saving keeps the page where it is.
- **Logged workout page (`/workout_logs/:id`).**
  - The same set rows, and the same no-jump saving.
  - × on an exercise removes it from the workout. A planned one is offered again under "From this day, not in this workout"; an extra one is gone.

To try it:
```bash
git fetch origin set-notes-removed-exercises
git switch set-notes-removed-exercises   # in a checkout of your choice
bin/rails server -p 3001
```

## 7. Tests and verification

- **`bin/rails test`:** 90 runs, 1234 assertions, 0 failures, 0 errors.
  - New: "an exercise added while training goes into that workout, never into the plan". It covers:
    - the picker's target
    - the session created on the first add, with the plan unchanged
    - creating an exercise on the spot
    - a duplicate refused
    - the page listing plan then extras, with extras linking to the log
    - the log offering only planned exercises
    - removing an extra from the day page
    - a workout later in the week refusing
  - Rewritten: "planning a day's exercises on the split page…" (was "adding exercises to a day…"). The picker per day, plan redirects, × buttons, no set fields on the plan, and the admin's shared tick box.
  - Changed:
    - the set test checks the always-visible note field, its `change->row-edit#save` action and the morph meta tags
    - the logged workout test checks that a removed planned exercise stays planned and is offered again, and that a removed extra is gone
    - the splits test checks that circles go to the day cards
    - the navigation test has the new back-arrow fallbacks
- **`bundle exec rubocop`:** no offenses. **`bundle exec brakeman`:** no warnings. `bundler-audit` was not run (no gems changed).
- **In the browser** (WSL Google Chrome, headless, 390 × 844, with a throwaway user deleted afterwards):
  - Note saved on change ("Set 1 updated.") and Enter.
  - Edit mode shows weight and reps fields, then the note, then Save and Cancel.
  - No sideways scroll on any checked page (scrollWidth 390).
  - Split page: cards per day, and "Plan exercises" added Barbell row to the plan.
  - Workout day page: "Add exercise" put Squat in the workout only. Afterwards the plan was Bench press and Barbell row, and the log held Squat.
  - Note saved at the bottom of a 10-set exercise page: scroll 794 → 794. On the logged workout page: 1027 → 1027.
  - The picker on the logged workout page added an exercise and opened again afterwards. Before the opt-out, it did not reopen.
- **Not verified:**
  - adding and deleting sets after the morph change (they redirect the same way)
  - the anchor case listed in "Potential issues"
  - a real phone
  - the dashboard page after these changes, beyond the tests

## 8. Every file changed (27)

Code (19):
- `app/assets/stylesheets/pages/_workout_log.scss`: the edit bar holds only Save and Cancel; removed the note-in-bar rules.
- `app/controllers/splits_controller.rb`: includes `ExercisePicker`; loads days with their planned exercises.
- `app/controllers/workout_days_controller.rb`: `show` works out extra entries; create and update return to the day's card.
- `app/controllers/workout_exercises_controller.rb`: plan create and destroy return to the day's card, with new messages; `plan_path`.
- `app/controllers/workout_log_exercises_controller.rb`: add to a workout day's session (creating it); destroy returns to the workout day page when asked.
- `app/helpers/application_helper.rb`: `exercise_picker_button` takes `key:` and `label:`.
- `app/javascript/controllers/row_edit_controller.js`: `save()` for the note field.
- `app/views/layouts/application.html.erb`: `yield :head`.
- `app/views/shared/_exercise_picker.html.erb`: `key:` for unique ids; forms load in full (`turbo_action: advance`).
- `app/views/splits/_week.html.erb`: circles go to day cards on the split page.
- `app/views/splits/show.html.erb`: day cards with planned exercises, ×, edit, delete and pickers.
- `app/views/workout_days/_form.html.erb`: Cancel returns to the day's card.
- `app/views/workout_days/edit.html.erb`: back arrow to the day's card.
- `app/views/workout_days/show.html.erb`: the workout: planned, added, add to workout, "Plan" link.
- `app/views/workout_exercises/show.html.erb`: no "Remove" (plan) button; morph refresh.
- `app/views/workout_logs/show.html.erb`: morph refresh.
- `app/views/workout_sets/_set.html.erb`: always-visible note field that saves on change.
- `config/routes.rb`: `workout_days/:id/workout_log_exercises` (create).
- `.claude/skills/finalize-branch/SKILL.md`: records potential issues.

Tests (3):
- `test/integration/logging_flow_test.rb`: planning on the split page, adding while training, note field, removal rules.
- `test/integration/navigation_flow_test.rb`: back-arrow fallbacks of the workout day and edit pages.
- `test/integration/splits_flow_test.rb`: create returns to the card; circles link to cards.

Docs and data (5):
- `CLAUDE.md`: product rules, code map, potential issues.
- `doc/Issues/Issues.md`: two issues resolved, "Potential issues" section.
- `doc/Prompt/project-context.md`: decisions 6 and 18; page flows.
- `doc/set-notes-removed-exercises.md`: this document.
- `db/seeds/data.yml`: the seed dump (section 10).

## 9. Known gaps

- **Potential issue (added to `Issues.md`):** a save can still jump to the top when it does not come back to the exact same address:
  - an exercise page opened without `?date=` (app links always add it)
  - likely, not verified: a logged workout page opened at `#entry-…`
- **Existing data:** Triceps pushdown is still on Lower's plan (U/R/L/U/L). Remove it with × on the split page.
- **No open-workout link on the split page:** a non-active split's workout can no longer be opened from its split page.
- **Added exercises open in the logged workout page,** not on an exercise page of their own.
- **Equipment changed on the exercise page still changes the plan row** (kept as before; open question for the owner).
- **Adding an exercise while training creates the workout** before any set, so it shows in History and the calendar from then on.

## 10. Lists and seed data

- **`Issues.md` items moved to "Issues resolved"**, under "Exercises":
  - "No notes per set"
  - "Deleted exercise shows up in workout page"
- **Potential issue added:** "Saving a set or a note can still jump to the top" (Exercise page).
- **`Features.md`:** nothing moved (see Decisions).
- **`db/seeds/data.yml`** (`bin/rails seed:dump`):
  - totals: 1 user, 3 splits, 2 workouts, 46 sets
  - new since the last version: Squat planned on Saturday's Lower day of one split
  - no workouts lost, no new emails
  - `test/lib/seed_data_test.rb` passes
