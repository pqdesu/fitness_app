# audit-major-fixes

## 1. Summary

This branch fixes the 12 major (P1) problems the design audit found (`doc/design-audit/README.md`, merged in PR 32), with the owner's choices for the four that change behaviour. It also fixes four things the owner reported while reviewing it on port 3001:

- the weight could not be edited from the exercise's Edit page;
- a set's weight had no direct way in (only ⋯ → Edit);
- moving workouts and exercises jumped to the top, and the back button then needed a second tap;
- the set tables were cramped.

The visual look stays the same; the Readout new look comes later. The remaining P2 and P3 audit items are left for a following branch.

State: `bin/rails test` gives 171 runs, 2,303 assertions, 0 failures, 0 errors. Rubocop is clean (58 files) and brakeman has no warnings. Every change was checked in headless Chrome at 390 px (and at 320 px where things could overflow) against a copy of the development database. Nothing was checked on a real phone: the check in the owner's WSL Chrome failed, because the tab could not take screenshots.

## 2. Timeline

1. **"Please go ahead and do the P1 issues first"** (2026-11-26). Planned in plan mode. The owner chose the recommended option in all four questions:
   - one-row sets, with Tag and Note in the ⋯ menu;
   - the rest saved without asking, unless it is over 10 minutes;
   - a search box in the exercise picker;
   - Preferences that need no password.

   Implemented by three Sonnet sub-agents, one after another, then reviewed and checked in the browser.
2. **"I cannot edit the weight used" on `/workout_logs/8`.** Nothing failed in the set table itself. The only way into a set's edit was ⋯ → Edit, so tapping the weight or the reps now opens it.
3. **"After coming from dashboard and when I move workouts around I jump to the top… the back button does not work the first click after moving a workout."** Moves now return to the exact address they came from, and the workout day and Home pages keep their scroll.
4. **"Still can not edit the weight" (screenshots of the exercise card's ⋯ → Edit page).** That page had no sets on it. It now lists the exercise's sets, and they can be edited there.
5. **"Everything looks too cramped."** The set table now has more space between its parts.
6. **"Finalize P1s first."** This doc, then the pull request. The P2 and P3 items come next on a new branch, with all four of the owner's 🔸 groups (layout moves, flash and calendar, data shown, installable app).

## 3. Starting point

The audit (Impeccable 25/40 and 15/20, plus the Emil Kowalski review) found these 12 P1 problems:

1. Add set was below the fold and moved after every set. A set was three rows: the numbers, a 44 px Tag pill and a note field.
2. On a workout day, exercise names were squeezed to 70 to 110 px by a boxed chevron button, the sets chip and the pencil.
3. Cards, inputs and modals were the page grey (`#F6F7F9`), separated only by a 1.14:1 hairline.
4. Controls were hard to see:
   - checkbox and radio borders were 1.14:1;
   - input borders were 1.32:1;
   - the focus ring was 1.1:1 on `btn-light` and 1.46:1 elsewhere.
5. A long split name made Home 410 px wide on a 390 px phone, and editing a set overflowed at 320 px.
6. simple_form put a green "valid" ✓ on every pre-filled field, even after a wrong password.
7. Hover stuck after a tap on touch screens, there was a blue tap flash, and buttons gave no press feedback.
8. The exercise picker had no search, and its group rows looked like labels.
9. Logging a set while the rest timer ran took three taps (Add set, "Save rest?", Start rest), and the rest clock was 22 px and read `0:00:04`.
10. The confirm box always showed a trash can and a red "Yes", even for "Stop the timer?".
11. "Add selected" in the full-screen picker sat under the iPhone home indicator.
12. Changing a preference (automatic timer, warm-up tag) needed the current password.

## 4. Changes

### Exercise page: one row per set (P1 1)

- **Before**: `workout_sets/_set.html.erb` rendered the numbers, then an always-visible `tr.set-note` with the tag chips, a `btn-outline-secondary` "Tag" pill and a note `input-group` with a blue arrow.
- **After**: the numbers row (#, weight, reps, ⋯) is the set. The ⋯ menu holds Edit, Tag (only when the admin has tags), Add note (or Edit note when there is one) and Delete. Tag and the note item open Bootstrap collapses (`#set-<id>-tags`, `#set-<id>-note`). Under the numbers, only what a set has is shown: its tag chips and its note as text (`p.set-note-text`). Every field still carries `form="edit_set_<id>"`, so saving a note or a tag sends the whole set and keeps its rest.
- **Spacing** (owner's "too cramped"):
  - the numbers row is 3.5 rem with .375 rem padding;
  - the note and tags start under the weight (`calc(80px + 1.25rem)`, 4 rem on a phone), with 1 rem below;
  - the note is .875 rem and muted;
  - the rest line has .75 rem above it;
  - there is one line per set (the `tbody` border; cell borders are off), so there are no double lines.
- **Edit bar**: `flex-wrap: wrap`, so editing a set fits 320 px.
- **Result**: with 8 sets, Add set starts at y = 789 (it was 1,473 with 3 sets).

### Tap the weight or reps to edit (owner)

- `_set.html.erb`: the weight and reps are `span.set-value` with `role="button"`, `tabindex="0"`, an aria-label ("Edit the weight of set 1: 60 kg"), `data-row-edit-focus-param` (the field's id) and `click`/Enter/Space → `row-edit#edit`. They are at least 44 px tall and turn `$primary-soft` on press (and on hover with a mouse).
- `row_edit_controller.js#edit({ params })`: it focuses the field whose id it is given, or the first field as before.

### The exercise's Edit page lists its sets (owner)

- `workout_log_exercises/edit.html.erb`: a "Sets" card (`#entry-sets`) with `workout_sets/table` sits above the equipment and note form, for lifts only (cardio has no sets). The page has `turbo_refreshes_with method: :morph, scroll: :preserve`.
- `WorkoutSetsController#update` and `#destroy`: `redirect_back_or_to page_of(set)`, so a set saved on the Edit page (or the exercise page, or the workout) comes back to that page, and Turbo morphs it in place. `page_of` is the fallback when there is no referer, and the tests use it.

### Moves keep the scroll and the back button (owner)

- `WorkoutLogExercisesController#move` and `#destroy`: `redirect_back_or_to back_after_change`. Before, they redirected to `workout_log_path(log, anchor: "entry-…")`, which dropped `?from=dashboard`. Turbo saw a new address, scrolled, and pushed a history entry. `back_trail.js` then held two copies of the workout, so the first press of the back button went to the same workout.
- `workout_days/show.html.erb`: `turbo_refreshes_with method: :morph, scroll: :preserve` (the logged workout page already had it).
- `pages/dashboard.html.erb`: `turbo_refreshes_with method: :replace, scroll: :preserve`. Move a workout and Back to the plan already redirected back to `/`, but the page jumped to the top.
- **Result**:
  - Workout 8 opened from Home, ⋯ → Move down: the address stays `/workout_logs/8?from=dashboard`, the scroll stays at 705 px, history does not grow, and the first Back goes to Home.
  - Dropping an exercise on the workout day page: the scroll and history stay.
  - Home's Move a workout: the scroll stays at 169 px, and the pop-up opens again afterwards.

### Exercise rows (P1 2)

- `workout_days/_planned_exercise.html.erb` and the added-row block of `workout_days/show.html.erb`:
  - The boxed `btn-light` chevron (a second link to the same page) is removed. The row link now holds `.row-text` (the name, the meta, then the sets chip or "No sets") and a muted `fa-chevron-right.row-chevron`.
  - The admin pencil stays as an icon, now muted (`.row-action`; blue on mouse hover and on focus). The red × on added rows stays.
- `workout_logs/show.html.erb`: the card's fold toggle is `btn-link` (not boxed), and the chip moved under the name.
- `components/_row_link.scss`: `.row-link` is a flex row; `.row-text` uses `overflow-wrap: break-word`.

### Surfaces and contrast (P1 3, 4)

- `config/_colors.scss`: `$surface: #FFFFFF`, and `$control-border: #8A919E` (3.1:1 on white).
- `config/_bootstrap_variables.scss`:
  - `$card-bg`, `$input-bg`, `$modal-content-bg`, `$dropdown-bg`, `$list-group-bg: $surface`;
  - `$table-bg: transparent`;
  - `$input-border-color: #B9BFC9`;
  - `$form-check-input-border: 1.5px solid $control-border`;
  - `$focus-ring-opacity: 1`, `$focus-ring-width: .2rem`.
- `components/_layout.scss`: `.btn:focus-visible { box-shadow: 0 0 0 2px $surface, 0 0 0 4px $blue }`.
- Literal surface `white`s are now `$surface`: the back link, `btn-light`, navbar, bottom nav, choices, confirm, flash, lift pill, calendar and week circles, and `.sortable-drag`. `color: white` on blue stays.

### Nothing scrolls sideways (P1 5)

- `components/_lists.scss` `.chip`: `max-width: 100%; overflow: hidden; text-overflow: ellipsis`.
- `.recent-chips` and `.history-line`: `min-width: 0`.
- `pages/_recent_workout.html.erb` and `workout_logs/index.html.erb`: the split chip carries `title=<full name>`.

### No green ✓ (P1 6)

- `config/initializers/simple_form_bootstrap.rb`: `input_field_valid_class = nil`, and `valid_class: 'is-valid'` is removed from every wrapper. `error_class: 'is-invalid'` stays.

### Touch (P1 7)

- `components/_layout.scss`:
  - `html { -webkit-tap-highlight-color: transparent }`;
  - `a, button, .btn, label, input, select, textarea, summary { touch-action: manipulation }` (`.drag-handle` keeps `none`);
  - `.btn:not(:disabled):active { transform: scale(.97) }` over 160 ms with `cubic-bezier(.23,1,.32,1)`, off with reduced motion;
  - under `@media (hover: none)`, `.btn:where(:not(.active, :active, .show, :disabled)):hover` is reset to its resting colours.
- The per-component copies in `_timer.scss` are removed.
- Every app `:hover` rule is inside `@media (hover: hover) and (pointer: fine)`, with `:focus-visible` kept outside. That covers `_layout`, `_cards` (the translateY lift is removed), `_row_link`, `_lists`, `_navbar`, `_flash`, `_actions_menu`, `_splits_cards`, `_dashboard_recent`, `_dashboard_calendar` and `_split_week`.

### Exercise picker (P1 8, 11)

- New `app/javascript/controllers/picker_filter_controller.js`, on the picker's `.modal-body`. A sticky `input[type=search]` (shown only when the picker has exercises):
  - hides rows whose `.picker-name` does not match;
  - hides groups with no match and opens the matching ones;
  - restores each group's open or closed state when the box is emptied;
  - with no match at all, fills the "Create your own" name (its `name` target, not `#exercise_name`, which repeats on the split page).
- `components/_exercise_picker.scss`:
  - `button.picker-group` is 1 rem, weight 600, not uppercase, 2.75 rem tall;
  - `.picker-delete` is muted, red on hover and focus;
  - safe-area padding on the full-screen phone modal's header and footer.

### Rest timer (P1 9)

- `workout_sets/_form.html.erb`: `data-rest-started` (ISO8601) next to `data-rest-url`.
- `rest_alert_controller.js#submit`: a rest started 600 s ago or less is saved without the box (PATCH, then the set is submitted). Over that, it asks Save rest or No rest as before. The server is unchanged.
- The rest clock:
  - `ApplicationHelper#short_clock` and `timer_controller.js` with `format: "short"` give `m:ss` (and `h:mm:ss` from one hour);
  - they are used in `workout_sets/_rest_timer` and `cardio_entries/_timer`;
  - `.rest-clock` is 2.25 rem in the headings font.

  The workout timer keeps H:MM:SS.

### Confirm box (P1 10)

- `shared/_confirm.html.erb`: the icon has `data-confirm-icon`.
- `confirm_dialog.js`: the message's first word picks the look:
  - Delete: bin, red, "Delete";
  - Remove: ×, red, "Remove";
  - Stop: stop icon, blue, "Stop";
  - anything else: question icon, blue, "Yes".

  `is-neutral` styles the blue ones (`_confirm.scss`).
- `devise/registrations/edit.html.erb`: "Are you sure?" becomes "Delete your account? Your splits and workouts go with it. This cannot be undone."

### Preferences without the password (P1 12)

- `config/routes.rb`: `resource :preferences, only: :update`.
- New `PreferencesController#update`: `current_user.update!(params.expect(user: [:timer_auto_start, :auto_warm_up]))`, then a redirect to the Account page with "Saved.".
- Account page: a Preferences section (a plain `section`, not a nested card, so it gets no extra padding) above the Devise form. Its checkboxes save on change through `row-edit#save`, and a visually hidden submit button is there for keyboards. The two checkboxes are removed from the Devise form. `Users::RegistrationsController#permit_settings` stays, because tests post them there.

### Docs

- `CLAUDE.md`: the code map now describes the set rows, tags, rest timer, picker search, confirm box, Preferences, surfaces and touch rules, the exercise rows, the Edit page sets and the in-place redirects.
- `doc/design-audit/README.md`: a status line under P1.

## 5. Decisions

- **The add-set redirect keeps `?date=`.** The plan made it follow the page's own date. Three tests pin the date (`logging_flow_test.rb:114`, `:218`, `:516`), and in-app links always carry it, so that part of the plan was reverted instead of changing tests. A page opened without the date still jumps once on its first Add set (see Known gaps).
- **The pencil and × stay as icons.** The plan put them in a ⋯ menu, but a menu adds `li` elements inside each row's `li` (`dashboard_flow_test.rb:44` counts rows), and ⋯ is as wide as the pencil. The width comes from removing the boxed chevron and moving the chip instead.
- **The rest is saved in the browser, not the server.** The page already does Stop then Add set for "Save rest", so skipping the box reuses that path, and no server or test change was needed. The alternative was ending a running rest in `take_rest!`.
- **Redirects follow the referer, with the old addresses as the fallback.** This keeps every existing test (they send no referer) and returns to the exact address, query included. Rails' `redirect_back_or_to` refuses other hosts.
- **Home is replaced, not morphed.** Morphing would leave Bootstrap's state for the open Move pop-up pointing at removed elements. Replacing gives a fresh page with the scroll kept.
- **Preferences reuse `row-edit#save`**, which is no new JavaScript. `auto_submit_controller` submits on connect, so it could not be reused.
- **Approved test change**: `set_tags_flow_test.rb:50-51` now finds the Tag item in `.actions-menu` (the owner chose this). One `rest_timer_flow_test.rb` assertion was made stricter (it also checks `data-rest-started`). No other existing assertion was edited.

## 6. How it works now, and how to try it

```bash
bin/rails test
DATABASE_URL=postgres:///fitness_app_design_audit bin/rails server -p 3001   # the audit copy; log in as admin@example.com / auditpass123
```

- **Exercise page**: one row per set. Tap the weight or reps to edit, or use ⋯ → Edit, Tag, Add note or Delete. A short rest saves itself when Add set is pressed.
- **A workout's exercise card, ⋯ → Edit**: the sets (editable), then equipment and note.
- **Workout day**: whole-row links with the sets under the name. Dragging keeps the scroll.
- **Home**: Move a workout keeps the scroll. Workouts opened from Home keep `?from=dashboard` through moves, so Back returns Home in one tap.
- **Exercise picker**: type to filter.
- **Account**: Preferences save on a tick.

## 7. Tests and verification

- **Tests**: `bin/rails test` gives 171 runs, 2,303 assertions, 0 failures, 0 errors (156 before the audit work), and `test/lib/seed_data_test.rb` passes. Rubocop: 58 files, no offenses. Brakeman: no warnings.
- **New tests**:
  - `preferences_flow_test.rb` (new file);
  - set row note, tag and menu items (`set_tags_flow_test.rb`);
  - the rest clock's `m:ss` and `data-rest-started` (`rest_timer_flow_test.rb`);
  - rows with no Open button, the chevron, the pencil and the remove button (`reorder_flow_test.rb`, `exercises_flow_test.rb`);
  - the fold toggle, picker search, tap to edit, and the Edit page's sets (`logging_flow_test.rb`);
  - the long split chip's title, and Home's refresh meta (`dashboard_flow_test.rb`);
  - the confirm icon (`navigation_flow_test.rb`);
  - the account delete confirm (`accounts_flow_test.rb`);
  - redirects in place with a referer, and refusal of a foreign referer (`reorder_flow_test.rb`).
- **Browser** (headless Chrome over CDP, Node 26, 390 px and 320 px, `fitness_app_design_audit`):
  - set rows are 53 to 56 px, and Add set is in reach;
  - no sideways scroll at 320 px on Home, History, workouts, the workout day, Month, Account, or while editing a set;
  - the picker search ("curl" finds the two curls, no match fills "Create your own");
  - Stop confirm (stop icon, blue "Stop");
  - a 5 s rest saved without the box, and the clock showing `0:04`;
  - Preferences ("Saved.");
  - no tap highlight, `touch-action: manipulation`, white surfaces, no `.is-valid`;
  - weight edits with real mouse and keyboard events, on workout 8 and on its Edit page;
  - the move, scroll and back flows listed under "Moves".
- **Not verified**:
  - a real iPhone or Android phone (sticky hover, safe areas, keyboard);
  - the owner's WSL Chrome (the tab could not take screenshots);
  - a screen reader;
  - the JavaScript in tests (rest skip, picker filter, tap to edit, confirm look), which is covered by browser checks only.
- **Seed data**: `bin/rails seed:dump` left `db/seeds/data.yml` unchanged (2 users, 3 splits, 6 workouts, 48 sets).

## 8. Every file changed (57)

**Styles (19)**
- `config/_colors.scss`: `$surface`, `$control-border`.
- `config/_bootstrap_variables.scss`: surface backgrounds, transparent tables, borders, focus ring.
- `components/_layout.scss`: tap highlight, `touch-action`, press scale, focus ring, gated hovers, `$surface`.
- `components/_actions_menu.scss`, `_navbar.scss`, `_flash.scss`, `_choices.scss`, `_bottom_nav.scss`: gated hovers and `$surface`.
- `components/_cards.scss`: hover lift removed, hover gated.
- `components/_confirm.scss`: `$surface`, `.is-neutral` icon.
- `components/_exercise_picker.scss`: search box, group rows, muted ×, safe areas.
- `components/_lists.scss`: chip ellipsis, gated hovers, `$surface` drag ghost.
- `components/_row_link.scss`: flex row link, `.row-text`, `.row-chevron`, `.row-action`.
- `components/_timer.scss`: per-component press rules removed.
- `pages/_dashboard_calendar.scss`, `_split_week.scss`, `_splits_cards.scss`, `_dashboard_recent.scss`: gated hovers, `$surface`, chip `min-width`.
- `pages/_workout_log.scss`: one-row sets, spacing, `.set-value`, note and tag rows, rest clock, edit bar wrap.

**Controllers (3)**
- `preferences_controller.rb` (new): saves the two preferences without a password.
- `workout_log_exercises_controller.rb`: move and remove return to the referer.
- `workout_sets_controller.rb`: set update and delete return to the referer.

**JavaScript (5)**
- `confirm_dialog.js`: icon, colour and verb by the first word.
- `controllers/picker_filter_controller.js` (new): picker search.
- `controllers/rest_alert_controller.js`: skips the box for a rest of 10 minutes or less.
- `controllers/row_edit_controller.js`: focuses the tapped field.
- `controllers/timer_controller.js`: `short` format.

**Helpers (1)**
- `application_helper.rb`: `short_clock`.

**Views (14)**
- `workout_sets/_set.html.erb`: one-row set, ⋯ items, tappable values, note and tags only when present.
- `workout_sets/_form.html.erb`: `data-rest-started`.
- `workout_sets/_rest_timer.html.erb`, `cardio_entries/_timer.html.erb`: short clock.
- `workout_days/_planned_exercise.html.erb`, `workout_days/show.html.erb`: row links, muted pencil, morph refresh.
- `workout_logs/show.html.erb`: unboxed fold toggle, chip under the name.
- `workout_logs/index.html.erb`, `pages/_recent_workout.html.erb`: split chip title.
- `pages/dashboard.html.erb`: replace refresh with scroll kept.
- `workout_log_exercises/edit.html.erb`: the Sets card, morph refresh.
- `shared/_confirm.html.erb`: icon target.
- `shared/_exercise_picker.html.erb`: search box and targets.
- `devise/registrations/edit.html.erb`: Preferences section, account delete wording.

**Config (2)**
- `config/initializers/simple_form_bootstrap.rb`: no valid class.
- `config/routes.rb`: `/preferences`.

**Tests (9)**
- `accounts_flow_test.rb`, `dashboard_flow_test.rb`, `exercises_flow_test.rb`, `logging_flow_test.rb`, `navigation_flow_test.rb`, `reorder_flow_test.rb`, `rest_timer_flow_test.rb`, `set_tags_flow_test.rb`: new tests (plus the one approved and one stricter assertion).
- `preferences_flow_test.rb` (new).

**Docs (4)**
- `CLAUDE.md`: the code map.
- `doc/design-audit/README.md`: P1 status.
- `doc/Issues/Issues.md`: one item resolved, five potential issues added.
- `doc/audit-major-fixes.md`: this file.

## 9. Known gaps

- **Add set on an exercise page opened without `?date=`** still jumps once, because the redirect adds the date. This is the existing potential issue "Saving a set or a note can still jump to the top", now only true for Add set and the exercise note. It is left in place.
- **Referer**: the in-place redirects need the browser's referer. Without one, the old behaviour comes back.
- **Folds close on Home**: Home is replaced after a move, so opened folds close.
- **Untested JavaScript**: the rest skip, picker filter, tap to edit and confirm look are not covered by tests (the browser only).
- **No real phone or screen reader** was used.
- **Issues.md**:
  - "Long exercise names on a workout day" moved to Issues resolved;
  - potential issues added: "A set's note and tags are one menu away", "The rest is saved without asking up to 10 minutes", "Moving or saving comes back by the browser's referer" (Exercise page), "Folded boxes close after a move" (Home page), and "Touch and phone fixes not tried on a phone" (General).
- **Features.md**: no open feature matched this branch, so it is unchanged.
- **Next**: the P2 and P3 audit items, on a new branch.
