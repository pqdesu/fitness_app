# Exercise page features (`exercise-page-features`)

## 1. Summary

The branch builds the "Exercise page" items of `doc/Features/Features.md`:

- **Counts:** exercise and set counts on a workout day, in the week overview and on Today.
- **Folds and menus:** folding lists, with edit and delete in ⋯ menus.
- **Bodyweight:** a third kind of equipment.
- **Equipment catalogue:** an admin keeps it; each lift picks detailed equipment; an exercise can be unilateral.
- **Notes:** a note on an exercise for the day.
- **Set tags:** an admin keeps them, with a warm-up setting.
- **Reordering:** exercises can be reordered by drag and drop, and a workout day's page has two cards you drag between.
- **Rest timer:** a timer between sets.

Earlier sessions also moved "user deletes own exercises" to DONE.

State: `bin/rails test` gives 131 runs and 0 failures. `bundle exec rubocop` reports no offenses and `bundle exec brakeman` no warnings. The UI was checked in headless Chrome at 390 px on a copy of the development database (`fitness_app_preview`), never on a real phone. Pull request: pqdesu/fitness_app#25.

Two changes made during this work were split out to branches of their own, at the owner's request, because they are not exercise page features:

- `back-to-plan-keeps-trained` (pqdesu/fitness_app#26) is the "Back to the plan" calendar fix. It was committed here as `2efbe8e` and reverted by `729ae94`. The finalize rules forbid a force push, so the branch history keeps both.
- `opusplan-model-rule` (pqdesu/fitness_app#27) is the CLAUDE.md rule to run sessions on `opusplan`. It was never committed here.

## 2. Timeline

The branch was built over several sessions, each feature committed on its own after the owner's go.

| Commit | Request | What was done |
|---|---|---|
| `6683d58` | Feature 13, "users delete their own exercises" | It already worked on the Exercises page. Moved to DONE. |
| `68c1c1e` | Feature 5, counts | "9 exercises · 27 sets" on a workout day's page, per day in the week overview, and on Today's "Last time" line (all from `WorkoutSummary`). |
| `d111d1e` | Lists of exercises should fold | A shared "Show … / Hide …" toggle (`shared/_list_toggle`). Today's lifts and recent workouts start closed. The "Add exercises" pop-up and the Exercises page fold by muscle group. |
| `ddf9c33` | Feature 10, logged workout cards | Cards load folded behind a down arrow. Edit and delete sit in ⋯ menus (`ActionsMenuHelper`) everywhere; delete is an ×. `fold_controller.js` keeps a card open across a Turbo morph. |
| `1d88f53` | Feature 11, split page | Day cards fold, with today's open. A week circle or `#day-<id>` opens its day. The splits list stays unfolded (owner's choice). |
| `da3c996` | Feature 9, bodyweight | A third equipment kind, with a ± button for weight added or taken off (`sign_controller.js`). |
| `911e04e`, `9a629c5` | Feature 1, detailed equipment | Admin equipment catalogue (`/admin/equipment`), detailed pills per lift, starting equipment on exercise creation, unilateral mark. Pills whose names had a space could not be tapped; fixed, and the name lists fold (`choice_fold_controller.js`). |
| `0a93649` | Feature 3, notes | A Note card on the exercise page for that day's logged exercise, shown once it has a set. Set notes already existed. |
| `42cbfd9`, `fb5334a` | Feature 4, set tags | Admin set tags (`/admin/tags`), pills on Add set, a Tag button on each set. Account setting to tick Warm-up on each exercise's first set. |
| `f791a0d` | Notes save with a button | A blue → button inside each note field. |
| `9e7a409` | Seed data | The equipment catalogue, the set tags and the setting went into `db/seeds/data.yml`. |
| `4c3351b`, `06528f0`, `ce77c31` | Feature 6, reorder | `Positioned#move!`. Drag and drop with SortableJS on the split page and on a logged workout (Move up / Move down stay in the ⋯ menu). On a workout day's page, "In this workout" comes first and is draggable, then "Still to do". |
| `cee0ce9` | Feature 12, rest timer | Start rest and Stop. The rest is saved on the next set, typed in minutes ("~3 min") on earlier days, and editable in a set's Edit. Alerts before Add set or leaving while a rest runs. |
| `267649a` | While testing: tell done from to-do; the note highlight looked off | The workout day became two cards you drag exercises between. The focus ring wraps a note's box and its arrow. |
| `2efbe8e`, then `729ae94` | "Back to the plan" left a trained workout on the calendar | Fixed, then moved to its own branch. See section 1. |
| `ab07105` | Hand-off asked for it | CLAUDE.md code-map lines for the new pieces. |
| this commit | Finalize | This doc, the Features.md and Issues.md updates. |

## 3. Starting point

- A lift's equipment was "free weights" or "machine" with a typed brand. There was no bodyweight, no equipment catalogue and no unilateral mark.
- Exercises had no note for the day, and sets had no tags.
- The lists showed every exercise at once. Logged workouts and split days were long open cards, and edit and delete were separate icons.
- The order of exercises was the order they were added (`order(:id)`), and nothing could be reordered.
- There was no rest timer. The workout timer (Start, Pause/Resume, Stop) existed.
- A workout day's page listed the plan first, then the exercises added while training.

## 4. Changes

### Counts (`68c1c1e`)

- `WorkoutSummary` counts an exercise once it has a set.
- `workout_days/show` shows `day-counts` under the date.
- `pages/_week_overview` shows "N exercises · N sets" per day, and `pages/_today_box` adds counts to "Last time".
- `time_parts` keeps each count whole, so no line starts with "·".

### Folds and ⋯ menus (`d111d1e`, `ddf9c33`, `1d88f53`)

- **Before:** every list was open; edit and delete were loose icons.
- **After:**
  - `shared/_list_toggle` (Bootstrap collapse) folds lists, styled in `components/_list_toggle.scss`.
  - `fold_controller.js` keeps a card's open state across a Turbo morph and opens the card the address names.
  - `ActionsMenuHelper` (`actions_menu`, `menu_link`, `menu_button`, `menu_delete`) draws every ⋯ menu, styled in `components/_actions_menu.scss`.
- **Why:** shorter pages on a phone, and one place for edit and delete.

### Bodyweight (`da3c996`)

- `bodyweight` is an equipment kind. A set's weight may then be below zero (assisted) and is shown "Bodyweight ± 10 kg" ("BW" on a phone).
- `LiftsHelper` holds the weight helpers.
- Added bodyweight never counts as a top weight.

### Equipment catalogue and unilateral (`911e04e`, `9a629c5`)

- `EquipmentItem` (migration `20261121100000_add_equipment_catalogue.rb`) holds free weights, machines and machine types. `Admin::EquipmentItemsController` serves it at `/admin/equipment`.
- The `Equipped` concern, shared by `Lift` and `Exercise`, stores the chosen names as text, so a label survives an item's deletion.
- `shared/_equipment_fields` and `shared/_choices` draw the pills, and `choice_fold_controller.js` folds each list to its current choice. A `<select>` was rejected because it opened past the screen bottom.
- `Exercise` gains `unilateral` and the equipment its lifts start with.
- `lib/seed_data/catalogue.rb` seeds the starter catalogue.

### Exercise note (`0a93649`)

- `workout_exercises/show` has a Note card once that day's logged exercise exists. It writes `workout_log_exercises.notes` through `WorkoutLogExercisesController#update` with `workout_exercise_id` and `date`, so the page comes back to itself.

### Set tags and the warm-up setting (`42cbfd9`, `fb5334a`)

- `SetTag` and `WorkoutSetTag` (migration `20261121120000_create_set_tags.rb`). `Admin::SetTagsController` serves them at `/admin/tags`.
- Add set has tag pills, and each set shows chips plus a Tag button whose ticks save at once (`row_edit_controller.js`).
- `users.auto_warm_up` (migration `20261122090000`) pre-ticks Warm-up on an exercise's first set. Pre-ticked rather than added on save, so what is saved is always seen.

### Note save button (`f791a0d`, `267649a`)

- A `.note-save` arrow sits inside each note field.
- `.input-group:has(> .note-save)` draws one focus ring around the box and the arrow, with matching corners on small fields and no second ring.

### Reorder (`4c3351b`, `06528f0`, `ce77c31`, `267649a`)

- **Order on the rows:**
  - `position` (nullable) on `workout_exercises` and `workout_log_exercises` (migration `20261122120000`).
  - The `Positioned` concern's `move!(to)` takes "up", "down" or a place, renumbers the whole list, and ignores a place off the list.
  - The associations order by `position, id`, and every `order(:id)` / `sort_by(&:id)` on those lists is gone.
- **Routes:** `PATCH /workout_exercises/:id/move` and `/workout_log_exercises/:id/move` with `to`.
- **Highlight:** `flash[:moved]` lights the moved row up (`.just-moved`).
- **Drag and drop:**
  - SortableJS 1.15.7 is vendored (`vendor/javascript/sortablejs.js`, `config/importmap.rb`), so there is no CSP change.
  - `sortable_controller.js` submits a hidden Turbo form on drop.
  - The ↑ ↓ arrows were removed (owner's choice).
- **Workout day page (`267649a`):**
  - Two cards: "In this workout · N" with Add exercise, and "Still to do · N".
  - The controller's `group` and `sort` values let the two lists trade items that carry `data-sortable-into-url`. The item is put back at once and the server decides.
  - A to-do row dropped in is created where it was dropped (`WorkoutLogExercisesController#create` with `to`). It asks Keep paused / Resume while the workout timer is paused.
  - A planned row dropped back is removed from the workout (the existing `destroy`); with sets it asks first.
  - An exercise added while training cannot go to "Still to do". A row of the workout with no set says "No sets". A day to come shows only the plan.

### Rest timer (`cee0ce9`)

- **Data:**
  - Migration `20261122150000_add_rest_timer.rb`.
  - `workout_log_exercises.rest_started_at` and `rest_ended_at` hold the timer.
  - `workout_sets.rest_seconds` (nullable) and `rest_approx` (default false) hold the result.
- **Controller:** `RestTimersController` (`POST`/`PATCH`/`DELETE /workout_log_exercises/:id/rest`) starts, stops and throws away a rest. `WorkoutSetsController#create` gives the next set the stopped rest (`WorkoutLogExercise#take_rest!`); a rest typed in wins.
- **Views:**
  - `workout_sets/_rest_timer` draws Start rest, the running clock (`timer_controller.js`) with Stop, and the stopped rest.
  - `workout_sets/_set` shows "Rest 2 min 15 s" or "Rest ~3 min" above a set (`rest_text`), plus the picker in Edit: minutes and seconds for a measured rest, ~minutes otherwise.
  - `workout_sets/_form` adds "Rest ~min" on an earlier day.
- **Alerts:**
  - `workout_sets/_rest_alert` with `rest_alert_controller.js` asks on Add set (Save rest / No rest) and when leaving (Stop rest / Back to page).
  - It is rendered before the paused-timer alert so it asks first, and an answered rest drops its markers, so each box asks once. Without this the two boxes looped and the set was never added; this was found in the browser.
- **Seed data:** `lib/seed_data/dumper.rb` and `loader.rb` carry `rest` and `rest_approx` only for sets that have a rest.

### CLAUDE.md (`ab07105`)

- Code-map lines for the equipment catalogue, bodyweight, set tags, the exercise note, folds and ⋯ menus, `Positioned`, drag and drop, the workout day's two cards and the rest timer.

## 5. Decisions

Each decision is the owner's, made in the session, unless marked otherwise.

- **Feature 2, admin delete in the picker modal:** dropped. It stays in Features.md.
- **Splits list:** stays unfolded.
- **Tag button:** outside the ⋯ menu. Deleting a tag removes it from every set.
- **Exercise note:** only once the exercise has a set that day.
- **Reordering on the split page:** drag only. The arrows were removed, and keyboard and screen-reader users lose that path there. A logged workout keeps Move up / Move down.
- **The workout day page orders that day's workout only, never the plan.** This follows the CLAUDE.md rule that only the split page changes the plan. An existing test (`logging_flow_test.rb:287`) was changed with the owner's OK.
- **Two cards on the workout day:**
  - "Hide exercises" was removed. Two existing tests were changed with the owner's OK, given by approving the plan: `reorder_flow_test.rb`, because to-do rows now have handles, and `dashboard_flow_test.rb`.
  - Dragging a row with sets back asks first.
  - Extras can't go to "Still to do".
- **Rest timer:**
  - Start rest is a button. Stop comes before the next set.
  - Forgetting Stop asks on Add set. There is no 10-minute alert; there is an alert on leaving, whose buttons are "stop the rest" and "back to the page".
  - The first set of an exercise has no rest.
  - Rest typed later is in whole minutes with "~".
  - The rest is editable with native lists (the iPhone wheel).
  - It shows as a line between sets, and the timer is on both the exercise page and the logged workout page.
- **Assumptions:**
  - The rest is measured on the server from saved times, not sent by the browser. Mine: no client value at a trust boundary.
  - The paused-workout box and the rest box chain by render order, not by changing the workout timer's code. Mine: the owner asked that the rest timer not interfere with it.
  - `position` is nullable rather than NOT NULL, because `master` shares the development database and its inserts don't set it.

## 6. How it works now

- **Exercise page** (`/workout_exercises/:id?date=`):
  - the sets of that day, each with its rest line, tags, note and a ⋯ menu (Edit with the rest picker, Delete);
  - on today's workout, Start rest / Stop;
  - Add set with weight (± on bodyweight), reps, tag pills and, on an earlier day, "Rest ~min";
  - the Note card; the Equipment card.
- **Workout day** (`/workout_days/:id`): the counts, the timer, then the two cards to drag between.
- **Logged workout** (`/workout_logs/:id`): folded cards with ⋯ menus, dragged to reorder. Each opens its sets, its rest timer (today) and Add set.
- **Split page:** folded day cards (today's open), with the plan dragged into order.
- **Admin:** `/admin/equipment` and `/admin/tags`, linked from the user menu and the Account page.
- **Account:** "Tag the first set of each exercise as a warm-up".

To try it:

```bash
bin/rails db:migrate
bin/rails server
```

Sign in as `admin@example.com` / `admin123456` (development seed).

## 7. Tests and verification

- **Results:** `bin/rails test` gives 131 runs, 1883 assertions, 0 failures. rubocop reports no offenses, and brakeman 0 warnings.
- **New test files:**
  - `test/integration/rest_timer_flow_test.rb` (8 tests);
  - `reorder_flow_test.rb` (9 tests, including the two-card drops);
  - `equipment_flow_test.rb`, `set_tags_flow_test.rb`;
  - `test/models/equipped_test.rb`;
  - added cases in `seed_data_test.rb` (rest round trip), `workout_summary_test.rb`, `exercises_flow_test.rb`, `splits_flow_test.rb`, `logging_flow_test.rb`, `dashboard_flow_test.rb`.
- **By hand:** headless Chrome at 390 px with touch, on `fitness_app_preview`. Covered:
  - rest timer: Start, Stop and Add set; both rest boxes and their chain with a paused workout timer; "~min" on an earlier day; the Edit pickers; a note saved after an edit;
  - drags in and out of the two cards, Cancel, a refused drop, reordering, a day to come;
  - the note rings.
  - Preview data was put back after each run.
- **Impeccable critique** (design review plus browser measurements) of the rest timer and of the two cards, with the fixes applied.
- **Not verified:**
  - any real phone, including the iPhone wheel and real touch drags;
  - long drags with edge auto-scroll;
  - dark mode;
  - JavaScript under a test runner (there are no system tests).

## 8. Every file changed (101)

**Docs and config (8)**

- `CLAUDE.md`: code-map lines for this branch's pieces.
- `doc/exercise-page-features.md`: this doc.
- `doc/Features/Features.md`: nine features moved to DONE.
- `doc/Issues/Issues.md`: potential issues from this branch.
- `config/importmap.rb`: pins SortableJS.
- `config/routes.rb`: move, rest, admin equipment and tags routes.
- `vendor/javascript/sortablejs.js`: SortableJS 1.15.7.
- `db/seeds.rb`: seeds the equipment catalogue and starter tags.

**Database (8)**

- `db/migrate/20261121100000_add_equipment_catalogue.rb`: equipment items, detailed equipment, unilateral.
- `db/migrate/20261121120000_create_set_tags.rb`: set tags and their join table.
- `db/migrate/20261122090000_add_auto_warm_up_to_users.rb`: the warm-up setting.
- `db/migrate/20261122120000_add_position_to_exercise_lists.rb`: `position` on planned and logged exercises.
- `db/migrate/20261122150000_add_rest_timer.rb`: the rest timer columns.
- `db/schema.rb`: the schema after these migrations.
- `db/seeds/data.yml`: the catalogue, tags, setting and the owner's workouts up to 2026-11-22.
- `lib/seed_data/catalogue.rb`: the starter equipment catalogue.

**Seed code (3)**

- `lib/seed_data/dumper.rb`: writes equipment, tags, positions and rests.
- `lib/seed_data/loader.rb`: reads them.
- `lib/seed_data/merge.rb`: matches the new lists (tags, equipment).

**Models (14)**

- `app/models/concerns/equipped.rb`: detailed equipment, shared by lifts and exercises.
- `app/models/concerns/lift.rb`: uses `Equipped`.
- `app/models/concerns/positioned.rb`: `move!(to)`.
- `app/models/equipment_item.rb`: the catalogue.
- `app/models/exercise.rb`: unilateral, starting equipment.
- `app/models/set_tag.rb`: a tag.
- `app/models/workout_set_tag.rb`: a set's tag.
- `app/models/workout_day.rb`: exercises ordered by position.
- `app/models/workout_exercise.rb`: `Positioned`.
- `app/models/workout_log.rb`: entries ordered by position.
- `app/models/workout_log_exercise.rb`: `Positioned`, the rest timer.
- `app/models/workout_set.rb`: tags, bodyweight weights, rest.
- `app/models/workout_summary.rb`: counts.
- `app/helpers/lifts_helper.rb`: weight helpers, bodyweight wording.

**Controllers and helpers (13)**

- `app/controllers/admin/equipment_items_controller.rb`: admin equipment catalogue.
- `app/controllers/admin/set_tags_controller.rb`: admin set tags.
- `app/controllers/rest_timers_controller.rb`: Start rest, Stop, No rest.
- `app/controllers/concerns/exercise_picker.rb`: starting equipment for a new exercise.
- `app/controllers/exercises_controller.rb`: equipment and unilateral fields; the folded list.
- `app/controllers/users/registrations_controller.rb`: the warm-up setting.
- `app/controllers/workout_days_controller.rb`: the two lists.
- `app/controllers/workout_exercises_controller.rb`: move; the note's entry.
- `app/controllers/workout_log_exercises_controller.rb`: move, drop place, return to the workout day.
- `app/controllers/workout_logs_controller.rb`: ordered entries.
- `app/controllers/workout_sets_controller.rb`: tags, rest taken or typed.
- `app/helpers/actions_menu_helper.rb`: ⋯ menus.
- `app/helpers/application_helper.rb`: `rest_text`, `time_parts` counts.

**JavaScript (8)**

- `app/javascript/controllers/choice_fold_controller.js`: folds the equipment pill lists.
- `app/javascript/controllers/fold_controller.js`: keeps cards open across a morph.
- `app/javascript/controllers/rest_alert_controller.js`: the rest boxes.
- `app/javascript/controllers/reveal_controller.js`: adjusted for the new fields.
- `app/javascript/controllers/row_edit_controller.js`: saves tags and notes.
- `app/javascript/controllers/sign_controller.js`: the ± button.
- `app/javascript/controllers/sortable_controller.js`: drag and drop, and dragging between two lists.
- `app/assets/stylesheets/application.scss`: lists the new style files.

**Styles (9)**

- `app/assets/stylesheets/components/_actions_menu.scss`: ⋯ menus.
- `app/assets/stylesheets/components/_choices.scss`: equipment pills.
- `app/assets/stylesheets/components/_exercise_picker.scss`: folded muscle groups.
- `app/assets/stylesheets/components/_list_toggle.scss`: Show/Hide toggles.
- `app/assets/stylesheets/components/_lists.scss`: drag handle, ghost, workout day cards.
- `app/assets/stylesheets/pages/_dashboard_today.scss`: Today counts and folds.
- `app/assets/stylesheets/pages/_dashboard_week.scss`: week overview counts.
- `app/assets/stylesheets/pages/_splits_cards.scss`: folded day cards.
- `app/assets/stylesheets/pages/_workout_log.scss`: set tags, note ring, rest timer and picker.

**Views (27)**

- `app/views/admin/equipment_items/_form.html.erb`, `edit.html.erb`, `index.html.erb`: equipment admin (3).
- `app/views/admin/set_tags/_form.html.erb`, `edit.html.erb`, `index.html.erb`: tags admin (3).
- `app/views/devise/registrations/edit.html.erb`: the warm-up setting, admin links.
- `app/views/exercises/_form.html.erb`: equipment and unilateral.
- `app/views/exercises/index.html.erb`: folded by muscle group, ⋯ menus.
- `app/views/pages/_lifts.html.erb`: folds, order.
- `app/views/pages/_recent_workout.html.erb`: folds, order.
- `app/views/pages/_today_box.html.erb`: counts.
- `app/views/pages/_week_overview.html.erb`: counts.
- `app/views/shared/_choices.html.erb`: pill ids that can be tapped, folding.
- `app/views/shared/_equipment_fields.html.erb`: detailed equipment.
- `app/views/shared/_exercise_picker.html.erb`: folded muscle groups.
- `app/views/shared/_list_toggle.html.erb`: the shared toggle.
- `app/views/shared/_navbar.html.erb`: admin links.
- `app/views/splits/show.html.erb`: folded day cards, draggable plan.
- `app/views/workout_days/_planned_exercise.html.erb`: a planned row.
- `app/views/workout_days/show.html.erb`: counts, two cards.
- `app/views/workout_exercises/show.html.erb`: note, rest timer, rest alert.
- `app/views/workout_logs/show.html.erb`: folded draggable cards, rest timer.
- `app/views/workout_sets/_form.html.erb`: tags, ±, "~min", rest marker.
- `app/views/workout_sets/_rest_alert.html.erb`: the rest box.
- `app/views/workout_sets/_rest_timer.html.erb`: Start rest, Stop.
- `app/views/workout_sets/_set.html.erb`: tags, rest line, rest picker, ⋯ menu.

**Tests (11)**

- `test/integration/dashboard_flow_test.rb`: counts, no "Hide exercises".
- `test/integration/equipment_flow_test.rb`: equipment catalogue and pills.
- `test/integration/exercises_flow_test.rb`: folded list, unilateral.
- `test/integration/logging_flow_test.rb`: bodyweight, notes, order.
- `test/integration/reorder_flow_test.rb`: reorder and the two cards.
- `test/integration/rest_timer_flow_test.rb`: the rest timer.
- `test/integration/set_tags_flow_test.rb`: set tags and the warm-up setting.
- `test/integration/splits_flow_test.rb`: folded day cards.
- `test/lib/seed_data_test.rb`: catalogue, tags and rests round trip.
- `test/models/equipped_test.rb`: equipment labels.
- `test/models/workout_summary_test.rb`: counts.

The groups add up to 101 files, the same as `git diff master...HEAD --stat` with this doc.

## 9. Known gaps

All of these are recorded under "Potential issues" in `doc/Issues/Issues.md`, each marked "From `exercise-page-features`".

- **Never on a real phone:** nothing on this branch was tried on one, including drag and drop, edge auto-scroll and the iPhone wheel pickers.
- **Drag only:** the plan and the workout day's cards cannot be moved by keyboard or screen reader. On a workout day, a planned exercise leaves the workout only by dragging it back.
- **Bodyweight:** a lift with negative sets switched back to free weights shows "-15.5 kg".
- **Tags:** a second set tag takes another tap.
- **Highlight:** `.just-moved` does not flash twice for the same row.
- **Order:** `position` relies on PostgreSQL sorting NULL last.
- **Rest timer:**
  - an hour digit on the clock;
  - the leave box only catches the app's links;
  - "Save rest" counts the set's own time.
- **Layout:** long exercise names wrap to three lines on a workout day.
- **Exercises page:** it still pages 30 exercises, so a big muscle group can continue on page 2.
- **Not done:** features 7 and 8 (cardio, and a Cardio button on a rest day), and feature 2 (dropped by the owner).
