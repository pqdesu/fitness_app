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
- **Cardio:** a cardio exercise (Cardio group) logs rows of incline, speed and time instead of sets, and its time counts in every total.
- **Cardio on a rest day:** a Cardio button beside Start workout opens a Cardio-only workout of today.

Earlier sessions also moved "user deletes own exercises" to DONE.

State: `bin/rails test` gives 141 runs and 0 failures. `bundle exec rubocop` reports no offenses and `bundle exec brakeman` no warnings. The UI was checked in headless Chrome at 390 px on a copy of the development database (`fitness_app_preview`), never on a real phone. Pull request: pqdesu/fitness_app#25. Features 7 and 8 (cardio) were built on a branch of their own, `cardio-exercises`, started from this one because they change the same exercise page, set table and picker, and pushed here as a fast-forward at the owner's request.

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
| `d0915a5` | Finalize | This doc, the Features.md and Issues.md updates. |
| `f92d62e` | Feature 7, cardio as an exercise | A Cardio group in the catalogue; rows of incline, speed and time (`CardioEntry`) in place of sets; the cardio time in every total. Built on `cardio-exercises`. |
| `3a7f444` | Feature 8, a Cardio button on a rest day | The Today box's Cardio button and a Cardio-only workout (`WorkoutLog::CARDIO`). Built on `cardio-exercises`. |
| this commit | Docs for features 7 and 8 | This doc, Features.md, Issues.md and the CLAUDE.md code map. |

## 3. Starting point

- A lift's equipment was "free weights" or "machine" with a typed brand. There was no bodyweight, no equipment catalogue and no unilateral mark.
- Exercises had no note for the day, and sets had no tags.
- The lists showed every exercise at once. Logged workouts and split days were long open cards, and edit and delete were separate icons.
- The order of exercises was the order they were added (`order(:id)`), and nothing could be reordered.
- There was no rest timer. The workout timer (Start, Pause/Resume, Stop) existed.
- Every exercise was a lift, logged as sets of weight and reps. On a rest day the Today box offered only the split's workouts and the other fixed workouts (Push, Pull, Legs…).
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

### Cardio as an exercise (`f92d62e`)

- **Before:** every exercise had equipment and was logged as sets of weight and reps.
- **Catalogue:** `Cardio` joins `Exercise::MUSCLE_GROUPS`, and `Exercise#cardio?` is `muscle_group == "Cardio"` (no new column on exercises). The picker groups it under its own heading and the new-exercise pills offer it, with no other change. A CSS `:has()` rule in `components/_choices.scss` hides the equipment pills and Unilateral while the Cardio pill is picked. `db/seeds.rb` adds Treadmill, Stationary bike, Stair climber and Elliptical to the starter catalogue.
- **Data:** migration `20261123100000_create_cardio_entries.rb`, a new table only (safe for `master`, which shares the development database): `workout_log_exercise_id`, `entry_number` (unique per exercise, like `set_number`), `incline` and `speed` (decimal 4,1), `duration_seconds`.
- **Models:**
  - `CardioEntry` numbers itself, needs a time above 0 and below a day, and takes incline (a decline is negative) and speed when the machine has them. The error calls the time "Time" (`config/locales/en.yml`).
  - `WorkoutLogExercise has_many :cardio_entries`; `#cardio?` is its exercise's, or having rows, so it stays cardio when the exercise is deleted. `WorkoutExercise#cardio?` comes from its exercise. On both, `equipment_label` is "Cardio", so every subtitle says so.
  - `User has_many :cardio_entries` through the logged exercises; rows are only found through it. `WorkoutLog.with_sets` also loads them.
  - `WorkoutSummary` counts an exercise with sets or rows and adds `cardio_seconds`. `Dashboard#today_lifts` counts cardio too.
- **Controller:** `CardioEntriesController` (create, update, destroy), the counterpart of `WorkoutSetsController`. From a planned exercise a row goes through `WorkoutExercise#entry_on!`, so the first row logs the workout; a refused row leaves nothing behind, nor on a day still to come. From a logged workout it goes into that entry. Minutes and seconds become `duration_seconds`. Routes: `POST .../cardio_entries` under `workout_exercises` and `workout_log_exercises`, and `PATCH`/`DELETE /cardio_entries/:id`.
- **Views:**
  - `cardio_entries/_table`, `_entry` and `_form`. A row is "# · Incline · Speed · Time" ("12:30", `cardio_time`); its ⋯ menu edits it in the same row (`row_edit_controller.js`, ✓ and × in place of the menu) or deletes it. Add is pre-filled from the last row.
  - `workout_exercises/show` and the cards of `workout_logs/show` switch to them for cardio, with no rest timer, rest alert, set tags or Equipment card. A cardio entry's Edit (`workout_log_exercises/edit`) keeps only its note.
  - Totals: `sets_and_time`, `summary_counts` and `entry_done` (`lifts_helper.rb`) write "1 exercise · 30 min", "2 exercises · 3 sets · 30 min" and the chips ("30 min", "No time yet") on Today, the week overview (a Cardio tile when there is any), Recent workouts, History, `pages/_lifts` and the workout day.
- **Seed data:** `lib/seed_data/cardio.rb` (`SeedData::Cardio`, included by the dumper and the loader) writes and reads an exercise's `cardio` rows, only when it has some, so the entries already in the file stay as they are.

### Cardio button on a rest day (`3a7f444`)

- **Before:** a rest day offered the split's workouts and the other fixed workouts, all lifting.
- **Model:** `WorkoutLog::CARDIO` ("Cardio") and `WorkoutLog::WORKOUTS` (the split's workouts plus Cardio), which the workout validation and `workout_logs#new`/`#create` accept. `WorkoutDay::NAMES` is unchanged: Cardio is never a day of a split. A Cardio workout has no workout day, so it does not count against "one workout per split per day".
- **Picker:** `ExercisePicker#picker_scope` is what can be listed and picked, only cardio when the controller's `cardio_workout?` says so (`WorkoutLogsController` for a Cardio workout, `WorkoutLogExercisesController` for adding to a Cardio log). Ids posted from elsewhere are left out on the server, and a new exercise created there is cardio. `shared/_exercise_picker` takes `cardio:`: its create form asks only the name (a hidden muscle group), with "Rowing machine" as the example. A picker with a single group opens it.
- **Today box:** on a rest day a Cardio button (outlined, running icon) beside Start workout, "Continue cardio" once today's Cardio workout exists; "Logged today · Cardio, no time yet" before its first time. The rest day's buttons stay side by side and move under the title together when there is no room (`.today-header:has(.today-actions)` wraps).
- **Cardio workout page:** `workout_logs/new` leaves out "Not in your split" and the split wording; the flash after starting says "Add your incline, speed and time."

### CLAUDE.md (`ab07105`)

- Code-map lines for the equipment catalogue, bodyweight, set tags, the exercise note, folds and ⋯ menus, `Positioned`, drag and drop, the workout day's two cards and the rest timer.

## 5. Decisions

Each decision is the owner's, made in the session, unless marked otherwise.

- **Feature 2, admin delete in the picker modal:** dropped. It stays in Features.md.
- **Cardio (features 7 and 8, 2026-11-23):**
  - Built on `cardio-exercises` from this branch, not from `master`, because #25 was not merged and changes the same code; pushed here at the owner's request.
  - Cardio is a group of the catalogue (a muscle-group pill), not a separate area, so it is picked and planned like any exercise. The starter catalogue gets four cardio machines.
  - A cardio exercise is rows of incline %, speed km/h and time in minutes and seconds, like sets; only the time is required (a bike has no incline); rows are edited and deleted.
  - Cardio counts as an exercise, never as sets or weight, and its time shows where the sets do.
  - The Cardio button sits beside Start workout in the Today box on a rest day, and opens a Cardio-only workout: its picker lists only cardio, one created there is cardio, and the button reopens it the same day.
  - CLAUDE.md rules this bends, raised with the owner: "Equipment is chosen per lift" and "Sets (weight, then reps)" do not apply to cardio, which is not a lift; "a workout's name comes from a fixed list" now has Cardio for logged workouts only.
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
- **Cardio:** a cardio exercise's page and its card log rows of incline, speed and time (Add, then ⋯ to edit or delete), and the totals show its time. On a rest day, Today's Cardio button opens today's Cardio workout.
- **Admin:** `/admin/equipment` and `/admin/tags`, linked from the user menu and the Account page.
- **Account:** "Tag the first set of each exercise as a warm-up".

To try it:

```bash
bin/rails db:migrate
bin/rails server
```

Sign in as `admin@example.com` / `admin123456` (development seed).

## 7. Tests and verification

- **Results:** `bin/rails test` gives 141 runs, 2027 assertions, 0 failures. rubocop reports no offenses, and brakeman 0 warnings.
- **New test files:**
  - `test/integration/rest_timer_flow_test.rb` (8 tests);
  - `reorder_flow_test.rb` (9 tests, including the two-card drops);
  - `equipment_flow_test.rb`, `set_tags_flow_test.rb`;
  - `test/models/equipped_test.rb`;
  - `test/integration/cardio_flow_test.rb` (9 tests: the Cardio group and pill, a cardio exercise's page and first row, a refused row, rows on a logged workout and nobody else's, the totals, the Cardio button, the Cardio-only workout and its picker);
  - added cases in `seed_data_test.rb` (rest and cardio round trips), `workout_summary_test.rb`, `exercises_flow_test.rb`, `splits_flow_test.rb`, `logging_flow_test.rb`, `dashboard_flow_test.rb`.
- **By hand:** headless Chrome at 390 px with touch, on `fitness_app_preview`. Covered:
  - rest timer: Start, Stop and Add set; both rest boxes and their chain with a paused workout timer; "~min" on an earlier day; the Edit pickers; a note saved after an edit;
  - drags in and out of the two cards, Cancel, a refused drop, reordering, a day to come;
  - the note rings;
  - cardio: the picker's Cardio group and pill, adding and editing rows on a planned exercise and a logged workout, the totals, and the rest-day Cardio button with a temporary rest-day split.
  - Preview data was put back after each run. During the cardio checks a review sub-agent created a Cardio workout on the preview despite being told not to; it was found and removed.
- **Impeccable critique** (design review plus browser measurements) of the rest timer, the two cards, the cardio rows and the Cardio button, with the fixes applied. For cardio: 44 px edit fields and 8 px between ✓ and ×, the exercise's name instead of "row", Min not required, units kept on one line, the Cardio group opened when it is the only one, the two rest-day buttons side by side, and "Continue cardio".
- **Not verified:**
  - any real phone, including the iPhone wheel and real touch drags;
  - long drags with edge auto-scroll;
  - dark mode;
  - JavaScript under a test runner (there are no system tests).

## 8. Every file changed (115)

**Docs and config (9)**

- `CLAUDE.md`: code-map lines for this branch's pieces, cardio included.
- `doc/exercise-page-features.md`: this doc.
- `doc/Features/Features.md`: eleven features moved to DONE.
- `doc/Issues/Issues.md`: potential issues from this branch.
- `config/importmap.rb`: pins SortableJS.
- `config/routes.rb`: move, rest, cardio rows, admin equipment and tags routes.
- `config/locales/en.yml`: a cardio row's time is called "Time".
- `vendor/javascript/sortablejs.js`: SortableJS 1.15.7.
- `db/seeds.rb`: seeds the equipment catalogue, starter tags and four cardio exercises.

**Database (9)**

- `db/migrate/20261121100000_add_equipment_catalogue.rb`: equipment items, detailed equipment, unilateral.
- `db/migrate/20261121120000_create_set_tags.rb`: set tags and their join table.
- `db/migrate/20261122090000_add_auto_warm_up_to_users.rb`: the warm-up setting.
- `db/migrate/20261122120000_add_position_to_exercise_lists.rb`: `position` on planned and logged exercises.
- `db/migrate/20261122150000_add_rest_timer.rb`: the rest timer columns.
- `db/migrate/20261123100000_create_cardio_entries.rb`: cardio rows.
- `db/schema.rb`: the schema after these migrations.
- `db/seeds/data.yml`: the catalogue, tags, setting and the owner's workouts up to 2026-11-22.
- `lib/seed_data/catalogue.rb`: the starter equipment catalogue.

**Seed code (4)**

- `lib/seed_data/dumper.rb`: writes equipment, tags, positions, rests and cardio rows.
- `lib/seed_data/loader.rb`: reads them.
- `lib/seed_data/cardio.rb`: cardio rows in the file.
- `lib/seed_data/merge.rb`: matches the new lists (tags, equipment).

**Models (17)**

- `app/models/concerns/equipped.rb`: detailed equipment, shared by lifts and exercises.
- `app/models/concerns/lift.rb`: uses `Equipped`.
- `app/models/concerns/positioned.rb`: `move!(to)`.
- `app/models/cardio_entry.rb`: a cardio row.
- `app/models/dashboard.rb`: today's lifts count cardio.
- `app/models/equipment_item.rb`: the catalogue.
- `app/models/exercise.rb`: unilateral, starting equipment, the Cardio group.
- `app/models/set_tag.rb`: a tag.
- `app/models/workout_set_tag.rb`: a set's tag.
- `app/models/user.rb`: cardio rows through the logged exercises.
- `app/models/workout_day.rb`: exercises ordered by position.
- `app/models/workout_exercise.rb`: `Positioned`, cardio.
- `app/models/workout_log.rb`: entries ordered by position, the Cardio workout.
- `app/models/workout_log_exercise.rb`: `Positioned`, the rest timer, cardio rows.
- `app/models/workout_set.rb`: tags, bodyweight weights, rest.
- `app/models/workout_summary.rb`: counts, cardio time.
- `app/helpers/lifts_helper.rb`: weight helpers, bodyweight wording, sets and cardio time lines.

**Controllers and helpers (14)**

- `app/controllers/admin/equipment_items_controller.rb`: admin equipment catalogue.
- `app/controllers/admin/set_tags_controller.rb`: admin set tags.
- `app/controllers/cardio_entries_controller.rb`: cardio rows.
- `app/controllers/rest_timers_controller.rb`: Start rest, Stop, No rest.
- `app/controllers/concerns/exercise_picker.rb`: starting equipment for a new exercise; only cardio in a Cardio workout.
- `app/controllers/exercises_controller.rb`: equipment and unilateral fields; the folded list.
- `app/controllers/users/registrations_controller.rb`: the warm-up setting.
- `app/controllers/workout_days_controller.rb`: the two lists.
- `app/controllers/workout_exercises_controller.rb`: move; the note's entry; cardio rows.
- `app/controllers/workout_log_exercises_controller.rb`: move, drop place, return to the workout day; only cardio in a Cardio log.
- `app/controllers/workout_logs_controller.rb`: ordered entries, the Cardio workout.
- `app/controllers/workout_sets_controller.rb`: tags, rest taken or typed.
- `app/helpers/actions_menu_helper.rb`: ⋯ menus.
- `app/helpers/application_helper.rb`: `rest_text`, `time_parts` counts, `cardio_time`.

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
- `app/assets/stylesheets/components/_choices.scss`: equipment pills, hidden for Cardio.
- `app/assets/stylesheets/components/_exercise_picker.scss`: folded muscle groups.
- `app/assets/stylesheets/components/_list_toggle.scss`: Show/Hide toggles.
- `app/assets/stylesheets/components/_lists.scss`: drag handle, ghost, workout day cards.
- `app/assets/stylesheets/pages/_dashboard_today.scss`: Today counts and folds, the rest day's buttons.
- `app/assets/stylesheets/pages/_dashboard_week.scss`: week overview counts.
- `app/assets/stylesheets/pages/_splits_cards.scss`: folded day cards.
- `app/assets/stylesheets/pages/_workout_log.scss`: set tags, note ring, rest timer and picker, cardio rows.

**Views (33)**

- `app/views/admin/equipment_items/_form.html.erb`, `edit.html.erb`, `index.html.erb`: equipment admin (3).
- `app/views/admin/set_tags/_form.html.erb`, `edit.html.erb`, `index.html.erb`: tags admin (3).
- `app/views/cardio_entries/_entry.html.erb`, `_form.html.erb`, `_table.html.erb`: cardio rows (3).
- `app/views/devise/registrations/edit.html.erb`: the warm-up setting, admin links.
- `app/views/exercises/_form.html.erb`: equipment and unilateral.
- `app/views/exercises/index.html.erb`: folded by muscle group, ⋯ menus.
- `app/views/pages/_lifts.html.erb`: folds, order, cardio time.
- `app/views/pages/_recent_workout.html.erb`: folds, order, cardio time.
- `app/views/pages/_today_box.html.erb`: counts, cardio time, the Cardio button.
- `app/views/pages/_week_overview.html.erb`: counts, the Cardio tile.
- `app/views/shared/_choices.html.erb`: pill ids that can be tapped, folding.
- `app/views/shared/_equipment_fields.html.erb`: detailed equipment.
- `app/views/shared/_exercise_picker.html.erb`: folded muscle groups, the Cardio workout's picker.
- `app/views/shared/_list_toggle.html.erb`: the shared toggle.
- `app/views/shared/_navbar.html.erb`: admin links.
- `app/views/splits/show.html.erb`: folded day cards, draggable plan.
- `app/views/workout_days/_planned_exercise.html.erb`: a planned row, cardio time.
- `app/views/workout_days/show.html.erb`: counts, two cards, cardio time.
- `app/views/workout_exercises/show.html.erb`: note, rest timer, rest alert, cardio rows.
- `app/views/workout_log_exercises/edit.html.erb`: no equipment for cardio.
- `app/views/workout_logs/index.html.erb`: cardio time in History.
- `app/views/workout_logs/new.html.erb`: the Cardio workout page.
- `app/views/workout_logs/show.html.erb`: folded draggable cards, rest timer, cardio rows.
- `app/views/workout_sets/_form.html.erb`: tags, ±, "~min", rest marker.
- `app/views/workout_sets/_rest_alert.html.erb`: the rest box.
- `app/views/workout_sets/_rest_timer.html.erb`: Start rest, Stop.
- `app/views/workout_sets/_set.html.erb`: tags, rest line, rest picker, ⋯ menu.

**Tests (12)**

- `test/integration/cardio_flow_test.rb`: cardio exercises and the Cardio button.
- `test/integration/dashboard_flow_test.rb`: counts, no "Hide exercises".
- `test/integration/equipment_flow_test.rb`: equipment catalogue and pills.
- `test/integration/exercises_flow_test.rb`: folded list, unilateral.
- `test/integration/logging_flow_test.rb`: bodyweight, notes, order.
- `test/integration/reorder_flow_test.rb`: reorder and the two cards.
- `test/integration/rest_timer_flow_test.rb`: the rest timer.
- `test/integration/set_tags_flow_test.rb`: set tags and the warm-up setting.
- `test/integration/splits_flow_test.rb`: folded day cards.
- `test/lib/seed_data_test.rb`: catalogue, tags, rests and cardio round trip.
- `test/models/equipped_test.rb`: equipment labels.
- `test/models/workout_summary_test.rb`: counts.

The groups add up to 115 files, the same as `git diff master...HEAD --stat` with this doc.

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
- **Cardio:**
  - a Cardio exercise edited from `master` fails its muscle-group check (the shared development database);
  - an empty Cardio workout reads "0 sets" in Recent workouts and History, while Today says "no time yet";
  - a cardio machine just added to a logged workout starts folded, one more tap before typing;
  - the week overview's Cardio tile appears only with cardio, on a row of its own.
- **Not done:** feature 2 (dropped by the owner).
