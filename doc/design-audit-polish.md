# design-audit-polish

## 1. Summary

This branch fixes the design audit's remaining items, the 31 minor (P2) and 14 polish (P3) ones in `doc/design-audit/README.md`, with the owner's choices. It also covers five requests the owner made while reviewing it:

- the back button had to return to the right page after an edit;
- Recent workouts' tag for another split was too quiet;
- History needed the same tag;
- the Calves muscle group was to be removed, with its exercises moved to Legs;
- the seed file had to be updated.

The P1 fixes went in through PR 34 (`audit-major-fixes`), which is merged. This branch starts from it, so it shows only the new work.

State:
- `bin/rails test` gives 194 runs, 2,459 assertions, 0 failures, 0 errors.
- Rubocop is clean (58 files) and brakeman has no warnings.
- Every changed page was checked in headless Chrome at 390 px. Home, the workout day, the exercise page, logged workouts, History, Month, Splits and Account were also checked at 320 px and at 200% text, with no sideways scroll.
- No real phone was used.

## 2. Timeline

1. **"Now move to fix the other issues found by the audit, before that tell me the other issues"** (2026-11-26). I listed the 31 P2 and 14 P3 items and marked the 9 that change behaviour. The owner:
   - chose all four groups of changes: layout moves, flash and calendar, data shown, installable app;
   - chose to finalize the P1 branch first (it became PR 34).
2. **"Yes, plan them."** Planned in plan mode. The owner:
   - approved the four wording groups that change pinned test texts: dates, error messages, "Still to do" with the Recent chip, and less repetition;
   - chose a 16 px base with an 8-step type scale.

   The work ran in three Sonnet parts, one after another: A (tokens, type, colour, spacing, motion), B (views, wording, layout moves) and C (data, installable app, icons). I reviewed each and checked it in the browser.
3. **The browser review found problems, which I fixed.** Three pages scrolled sideways (a 99,999.125 kg top-weight tile, and a long machine brand in a details line). The "kg" sat raised above the number's baseline. Weights crowded the reps. The app icons had white corners. Home and Month overflowed at 200% text.
4. **"After saving an edit of a past workout when I press the back button the page does not change… Make sure the back button goes back to the dashboard even after an edit, deletion or addition."** Fixed in `back_trail.js`, and redirects to a workout now keep `?from=dashboard`.
5. **"Is there any other issues I need to tackle?" / "so the issues from the audit are all done?"** I answered, and nothing changed.
6. **"Open a server for me", then "use my real development database instead."** I ran port 3001 from the worktree, first on the audit copy, then on `fitness_app_development`.
7. **"When I change the splits the other split workout days still show up with only a small pill tag… make the tags more in your face."** Recent workouts' tag for another split is now solid indigo with the Splits icon.
8. **"Yes, History too."** History uses the same tag. That uncovered a clipped long chip on phones, which I fixed.
9. **"Remove Calves muscle group option, remove it everywhere. And the already logged exercises with that muscle group change it to legs."** Calves is removed and a data migration moves its exercises to Legs.
10. **"Finalize this branch and don't forget the seed file."** This doc, the seed dump, and the pull request.

## 3. Starting point

After PR 34 the app worked well on a phone, but the audit's smaller problems remained:

- **Type:** 21 font sizes in the CSS, with four within 1 px of each other, and a faux bold because Inter 700 was never loaded.
- **Colour:**
  - indigo on set numbers, note arrows and "Not set";
  - two greys for secondary text;
  - Bootstrap's grey tag pills;
  - a calendar "extra" ring at 2.6:1, and no legend on a phone.
- **Spacing:**
  - 40 px gaps next to 16 px ones;
  - four row paddings;
  - seven corner radii;
  - cards with both a border and a shadow.
- **Motion:**
  - Bootstrap's 350 ms folds, and modals dropping in from 50 px above;
  - 500 ms flash cards with a countdown bar;
  - blurs;
  - the default blue Turbo bar.
- **Wording:**
  - "November 09, 2026";
  - "Reps completed can't be blank";
  - "From this day, not in this workout" against "Still to do" for the same thing;
  - Rails' "Create Split" button labels;
  - placeholders that looked like typed values.
- **Layout:**
  - "Delete workout" in every workout's header;
  - the full Equipment form open during a workout;
  - the flash card covering the back arrow;
  - admin pages without a title or back arrow;
  - repeated counts and dates.
- **Data shown:**
  - "Last time" could be an empty workout;
  - History and Recent read "0 exercises · 0 sets";
  - nothing showed last time's sets on the exercise page.
- **Other:**
  - "1234.125 kg" with no separator, and numbers wrapping mid-number;
  - not installable (the `public/` icons were 0-byte files);
  - Font Awesome shipping all 1,962 icons for the 33 used;
  - every tab titled "FitnessApp";
  - 32 decorative icons read aloud by screen readers.

## 4. Changes

### Type, colour, spacing, motion (Part A)

- **Type scale:**
  - New `config/_type.scss`: `$fs-label .75rem`, `$fs-meta .8125rem`, `$fs-small .875rem`, `$fs-body 1rem`, `$fs-title 1.125rem`, `$fs-num 1.375rem`, `$fs-h1 1.75rem` and `$fs-clock 2.25rem`, plus `$ease-out: cubic-bezier(.23,1,.32,1)`.
  - `$font-size-base` went from `.9375rem` to `$fs-body` (16 px).
  - Every `font-size` in `components/` and `pages/` maps onto a step. The exceptions are the 11 px bottom-nav label, the landing clamp, the timer clock and the `em` icon sizes.
  - The layout loads `Inter:wght@400;500;600;700`.
  - h1 tracking is `-.025em` and card h2 `-.01em`.
- **Set numbers:**
  - `.set-value` uses the headline font at `$fs-num`, weight 600.
  - `format_weight` wraps "kg" in `span.unit` (not when `plain:`).
  - The weight column is right-aligned with tabular figures, and the reps column has 1.5 rem before it.
  - `.set-value` is `inline-block; line-height: 2.75rem`, so the number and "kg" share a baseline. The flex version had centred them apart.
  - `.order-badge` has no fill and is `$muted`.
- **Colour:**
  - `$body-secondary-color`, `$input-placeholder-color` and `$secondary` are all `$muted`, so `.text-muted` is one grey.
  - `$orange` and `$notice` are deleted; `$info` is blue and `$warning` is red (both unused).
  - Tag pills are `btn-outline-primary .tag-pill`: white and grey when unticked, indigo-soft when ticked. The ± button is `btn-light`.
  - `.note-save` looks light and grey through `--bs-btn-*` variables. It keeps the `btn-primary` class because a test pins it.
  - `.choice-current` is muted when it reads "Not set" (`is-unset`, toggled by `choice_fold_controller.js`).
  - The active split ring is `0 0 0 1.5px rgba($blue,.5)`.
- **Spacing:**
  - Cards are 16 px apart (`row g-3`), with no margin under the calendar card.
  - Rows are `.875rem 1.25rem`.
  - One label style: `$form-label-*` at `$fs-meta`, weight 600, `$muted`.
  - Radii are 10 px for controls, 16 px for cards, and pills.
  - Cards have a border of `rgba($shadow,.08)` and no shadow.
  - `text-wrap: balance` on headings and `pretty` on paragraphs.
  - `.card-header` and Month rows wrap. That was added after the 200% text check.
- **Motion:**
  - `$transition-collapse: height .22s $ease-out`, with chevrons on the same curve.
  - `$modal-fade-transform: scale(.96)` and `$modal-transition: transform .2s $ease-out`.
  - Flash cards come in over .32 s and leave over .2 s. There is no countdown bar, and `flash_controller.js` waits 250 ms before removing a card.
  - SortableJS animates over 200 ms with the curve, and `.just-moved` lasts 1.2 s.
  - The navbar and modal blurs are gone.
  - `.turbo-progress-bar` is 2 px and indigo.
  - The back link and bottom nav press in at `scale(.96)`.
- **Targets and overflow:**
  - These are now 44 px: `.link-quiet` ("Month", "Change", "History"), the calendar toggle, `.btn-close`, and calendar days of 2.75 rem.
  - `.entry-meta` wraps, the `nowrap`s that caused overflow are gone, and `.set-field` can shrink to `min-width: 0` on phones.
- **Small items:**
  - The 13 `.eyebrow` labels are removed; "This week" is an `h3.h6`.
  - `abbr[title]` has no underline.
  - Cards holding a table have `overflow: hidden`, so their corners stay round.
  - The last `.exercise-group` has no border.
  - `.choices .btn` is `$fs-small`.

### Views, wording, layout moves (Part B)

- **Calendar legend:** a `.calendar-legend` line (planned, missed, extra, today) inside `#calendar-body`. `$extra-ring` is `#6E76EA`.
- **"Delete workout":** it is a `btn-link text-danger` at the bottom of a logged workout (`form.delete-workout`), with the same confirm and `from:` parameter.
- **Equipment:** on the exercise page it is one `button.choice-summary` row ("Equipment · Machine · Bull") that opens `#equipment-form`. `shared/_equipment_fields` is unchanged.
- **Admin pages:**
  - `PAGE_TITLES` has Equipment and Set tags.
  - Their index pages have `back_to edit_user_registration_path`. Users keeps no back arrow, because `accounts_flow_test` pins that.
  - The Account tab is active on `admin/*`.
- **Less repetition:**
  - The workout day's counts moved from the page header to the "In this workout" card header ("· 2 exercises · 3 sets").
  - The exercise page's card shows the date only when it isn't today (`short_date`).
  - The Note card's day label is gone.
- **Flash:** on phones (below 768 px) it sits at the bottom, above the tab bar, using a `--flash-shift` keyframe. Desktop is unchanged. "Set 1 added" stays, because a test pins it.
- **Submitting:**
  - `form[aria-busy=true] .btn` is at `.6` opacity with `cursor: progress`.
  - `data-turbo-submits-with` is on Add set ("Adding…") and the Save buttons.
- **Alerts:**
  - The paused-timer alert swaps its icon to stop when you're leaving.
  - Rest alert verbs: "Save rest and add" / "Add without rest", and on leaving "Stop timer" / "Stay here".
- **Account:** the email field is no longer autofocused.
- **Errors:**
  - `en.yml` attribute names: Reps, Weight, Workout, Date, Name.
  - `Exercise#name` uniqueness says "is already in your exercises".
  - `errors_of` gives the first message per attribute.
- **Placeholders:** "e.g. …" examples, and "kg" / "reps" in the add-set fields.
- **Wording:** the logged workout's "From this day, not in this workout" is now "Still to do".
- **Titles:** `<title>` comes from `document_title`, which is `content_for(:title)` (an exercise, a workout day, a workout) and otherwise `PAGE_TITLES`. The top bar keeps `page_title`.
- **Buttons:** "Create split" / "Save split", "Add workout day" / "Save", "Create exercise" / "Save exercise".
- **Separators:** `sets_and_time`, `summary_counts` and the logged-exercise meta go through `time_parts`. Each part is now an `inline-block`, so a part longer than the line (a long machine brand) wraps inside itself instead of widening the page; it used to be `nowrap`.
- **Dates:** `short_date` ("Wed 25 Nov", plus the year when it isn't this one) is used in History, Recent, the logged workout, new workout, Edit timer, the exercise card and admin users.
- **Recent chip:** no chip for the active split's workouts (`active_split:` local).
- **Icons:** `aria-hidden="true"` on every decorative `<i>`, and in `exercise_picker_button`.

### Data, installable app, icons (Part C)

- **Big numbers:** `weight_text` is `number_with_delimiter(weight_number(w))`, so it reads "1,234.125" and keeps the sign. `format_weight` uses it; fields keep `weight_number`. The top-weight tile shows a value over 7 characters smaller, breaking after the comma (`<wbr>`).
- **Empty workouts:**
  - `WorkoutLog.with_entries` finds workouts with a set or a cardio row.
  - `Dashboard#last_log` skips the others.
  - History and Recent read "Timer only" or "Nothing logged" (`empty_log_label`) instead of "0 exercises · 0 sets". They still list those workouts, because pagination and timer tests pin that.
- **Last time on the exercise page:**
  - `WorkoutLogExercise.previous_for(user, exercise_id, before:)`.
  - The `.last-time` line reads "Last time · Wed 18 Nov: 130×5 · 230×9 · 230×9", with at most 6 sets and then "…". It doesn't appear for cardio or when there's no earlier session.
- **Installable app:**
  - `app/views/pwa/manifest.json.erb`, with the route `get "manifest" => "rails/pwa#manifest", defaults: { format: :json }`.
  - Layout tags: manifest, `theme-color`, the two `apple-mobile-web-app-*` tags, an SVG icon and the apple-touch-icon.
  - CSP: `manifest_src :self`.
  - Icons: `public/icon.svg`, plus `icon-180.png`, `icon-192.png`, `icon-512.png` and `icon-maskable-512.png`, rendered with headless Chrome. The 192 and 512 have transparent corners. The 180 (iPhone) and the maskable one are full-bleed. The apple-touch-icons are copies of the 180.
  - The 0-byte `favicon.ico` is removed.
- **Font Awesome:**
  - `$fa-used-icons` (33 names) with an `@each`, in place of `@import "font-awesome/icons"`.
  - `$fa-font-display: swap`.
  - The compiled CSS went from 338 KB to 280 KB.
  - `test/lib/icons_test.rb` fails if an icon is used but not listed, or listed but unused.

### Back button after an edit (owner, 2026-11-27)

- **Before:** "Save details", Add set, cardio rows, the rest timer and the exercise's Edit page redirected to `workout_log_path(log)` without `?from=dashboard`. `back_trail.js` stored the workout twice (with and without it), so the first Back led to the same page. A Delete afterwards then went to History, not Home.
- **After:**
  - `back_trail.js#samePage`: two addresses that differ only by `from=` or `date=` are one page. `record` keeps the first address, and `takePreviousPage` skips them.
  - `ApplicationController#workout_log_page(log, **)` adds `from: "dashboard"` when the request or its referer has it. It replaces `workout_log_path` in those redirects (`workout_sets`, `workout_log_exercises`, `cardio_entries`, `workout_logs#update`, `rest_timers`).
  - The Edit page's link, form, Cancel and back arrow carry `from`.

### The other-split tag (owner, 2026-11-28)

- `LiftsHelper#split_chip(split, active_split)`: a plain `.chip` for the active split. For any other split it's a `.chip.chip-split` (solid indigo, white text, `fa-layer-group`, aria-label "From another split: …"), and the title stays the split's name. It's used by Recent workouts and History (`@active_split` in `WorkoutLogsController#index`).
- History's phone cell `.history-summary` is `width: 100%; max-width: 0`, so a long chip ends in "…" inside the card instead of growing the cell past it.

### Calves removed (owner, 2026-11-28)

- `Exercise::MUSCLE_GROUPS` no longer has Calves.
- The migration `20261128100000_move_calves_to_legs.rb` runs `UPDATE exercises SET muscle_group = 'Legs' WHERE muscle_group = 'Calves'`. Its `down` does nothing, because which Legs exercises were Calves isn't kept.
- It ran on `fitness_app_development`: "Calf raise" was the only one.
- `db/seeds.rb` (starter catalogue) and `lib/tasks/mock.rake` put Calf raise under Legs.
- `db/schema.rb`'s version moved.

### Docs

- `CLAUDE.md`:
  - type scale and motion;
  - flash position;
  - legend and `short_date`;
  - the "Last time" rules;
  - icons list and manifest;
  - Delete at the bottom and the Equipment fold;
  - the back-trail rule and `workout_log_page`;
  - the Recent and History split tag.
- `doc/design-audit/README.md`: the P2 and P3 status.

## 5. Decisions

- **Test-pinned texts:** I changed only the groups the owner approved:
  - `dashboard_flow_test` (dates, counts, the chip);
  - `cardio_flow_test` (counts);
  - `navigation_flow_test` (dates, through `short_date`, so they don't depend on the year);
  - `logging_flow_test` (errors, "Still to do").

  The long-split-name test got an extra active split ("Main") so its split isn't the active one. That follows the approved chip rule, and its assertions are unchanged.
- **Kept because tests pin them:** the "Set 1 added" flash, the note arrow's `btn-primary` class, no back arrow on Users, and listing empty workouts in History.
- **Timer card margin:** `.timer-card` keeps its `margin-bottom`, because the following `.row` cancels its own gutter. Removing the margin would leave 0 px.
- **Home refresh:** Home uses `turbo_refreshes_with method: :replace` (from the P1 branch), and that is unchanged here.
- **Back trail and `date=`:** it ignores `date=` too, because an exercise page's saves can come back with the date added. History's `?date=` list is only reached from Home, so Back still goes Home (see Known gaps).
- **Referer, not a parameter:** `workout_log_page` reads the referer, because the workout page's forms post without `from`. Adding `from` to every form was the alternative, rejected as larger.
- **No service worker:** home-screen install doesn't need one, and offline wasn't asked for.
- **"Unminified Popper and SortableJS":** a false audit finding. Both are already minified, so nothing changed.
- **Calves data:** I used a plain SQL update in a migration (so every machine gets it on `db:migrate`) rather than a one-off console change.

## 6. How it works now

```bash
bin/rails db:migrate        # Calves -> Legs (data only)
bin/rails test
bin/rails server -p 3001    # from this branch
```

- **Home:**
  - 16 px text, short dates, a calendar legend.
  - "Last time" skips empty workouts.
  - Recent workouts mark another split with a solid indigo tag.
  - Messages appear at the bottom on a phone.
- **Exercise page:**
  - Large set numbers with a quiet "kg".
  - "Last time · …" above Add set.
  - Equipment folded to one row.
- **Logged workout:** "Still to do", Delete at the bottom, and Back that returns Home after any save.
- **History:** "Timer only" or "Nothing logged" for empty workouts, and the other-split tag.
- **Muscle groups:** Chest, Back, Shoulders, Biceps, Triceps, Legs, Core and Cardio.
- **Install:** add `/` to the home screen. The manifest is at `/manifest`.

## 7. Tests and verification

- **Results:** `bin/rails test` gives 194 runs, 2,459 assertions, 0 failures, 0 errors. `test/lib/seed_data_test.rb` passes. Rubocop: 58 files, no offenses. Brakeman: no warnings.
- **New tests:**
  - `test/integration/design_polish_flow_test.rb` (11): legend, Delete at the bottom, the Equipment fold, admin pages, titles, counts, day label, labels and placeholders, separators, the duplicate name message, the error text.
  - `test/integration/polish_data_flow_test.rb`: empty-workout labels, "Last time", manifest and layout tags.
  - `test/helpers/application_helper_test.rb` (`short_date`).
  - `test/helpers/lifts_helper_test.rb` (delimiter, sign, plain fields).
  - `test/models/last_time_test.rb`.
  - `test/models/exercise_test.rb` (Calves refused).
  - `test/lib/icons_test.rb`.
  - Additions in `navigation_flow_test.rb` (Back keeps `?from=dashboard` through saves) and `dashboard_flow_test.rb` (the other-split tag in Recent and History).
- **In the browser** (headless Chrome over CDP):
  - every main page at 390 px and 320 px, plus 200% text, with no sideways scroll and no blank icons;
  - the picker groups and the forms without Calves;
  - `/manifest` and all five icons load;
  - the flash sits above the tab bar;
  - real-click flows: Home → workout → Save details, Add set, Edit page save, and Delete after an edit, each returning Home; workout day → exercise → Add set → Back to the workout day.
- **Not verified:**
  - a real phone (touch, safe areas, home-screen install, the icons there);
  - a screen reader;
  - the admin and form pages at 320 px and 200% text;
  - the owner's own browser (the WSL Chrome check failed in an earlier session).
- **Seed data:** `db/seeds/data.yml` changed Calf raise from Calves to Legs, and the admin's active split to `UL` (the owner's current one). Nothing was removed: 2 users, 3 splits, 6 workouts, 48 sets.

## 8. Every file changed (123)

**Styles (29):**
- `application.scss`: type import, `$fa-font-display`, the Font Awesome subset.
- `config/_type.scss` (new): type steps and `$ease-out`.
- `config/_bootstrap_variables.scss`: base size, greys, radii, card border, labels, close button, motion.
- `config/_colors.scss`: dead tokens removed, `$extra-ring`.
- `components/_bottom_nav`, `_cards`, `_choices`, `_confirm`, `_exercise_picker`, `_flash`, `_layout`, `_list_toggle`, `_lists`, `_navbar`, `_row_link`, `_tables`, `_timer`: type scale, radii, motion, targets, the split chip, wrapping.
- `pages/_auth`, `_dashboard_calendar`, `_dashboard_month`, `_dashboard_moves`, `_dashboard_recent`, `_dashboard_rest_day`, `_dashboard_today`, `_dashboard_week`, `_landing`, `_split_week`, `_splits_cards`, `_workout_log`: type scale, legend, tiles, set table, History cell.

**Controllers (7):**
- `application_controller.rb`: `errors_of` one per field, `workout_log_page`.
- `cardio_entries_controller.rb`, `rest_timers_controller.rb`, `workout_sets_controller.rb`, `workout_log_exercises_controller.rb`, `workout_logs_controller.rb`: redirects keep `from`; History's active split.
- `workout_exercises_controller.rb`: `@previous` for "Last time".

**Helpers (2):**
- `application_helper.rb`: `short_date`, `document_title`, admin titles, picker icon.
- `lifts_helper.rb`: `weight_text`, `span.unit`, `sets_and_time_parts`, `empty_log_label`, `split_chip`.

**JavaScript (6):**
- `back_trail.js`: `samePage`.
- `choice_fold_controller.js`: `is-unset`.
- `flash_controller.js`: no countdown bar, 250 ms wait.
- `rest_alert_controller.js`: verbs.
- `sortable_controller.js`: duration and curve.
- `timer_alert_controller.js`: stop icon when leaving.

**Models (4):**
- `dashboard.rb`: `last_log` skips empty workouts.
- `exercise.rb`: no Calves; the name message.
- `workout_log.rb`: `with_entries`.
- `workout_log_exercise.rb`: `with_entries`, `previous_for`.

**Views (44):**
- Admin `equipment_items` and `set_tags` (`_form`, `edit`, `index`), and `users/index`: titles, back arrow, eyebrows, dates, placeholders.
- `cardio_entries/_form`, `devise/registrations/edit`, `exercises/_form`, `exercises/index`.
- `layouts/application`: fonts, titles, manifest tags.
- `pages/_calendar`, `_recent_workout`, `_summary_tiles`, `_today_box`, `_week_moves`, `_week_overview`, `dashboard`, `month`.
- `pwa/manifest.json.erb` (new).
- `shared/_bottom_nav`, `_choices`, `_equipment_fields`, `_exercise_picker`, `_flashes`, `_navbar`, `_pagination`.
- `splits/_empty`, `_form`, `index`, `show`.
- `workout_days/_form`, `_planned_exercise`, `show`.
- `workout_exercises/show`, `workout_log_exercises/edit`.
- `workout_logs/_timer_alert`, `index`, `new`, `show`.
- `workout_sets/_form`, `_set`, and `workout_timers/edit`.

These carry the wording, layout moves, `aria-hidden` icons, dates, "Last time", the Equipment fold, Delete at the bottom, `from` on the Edit page and the split tag.

**Config (3):**
- `initializers/content_security_policy.rb`: `manifest_src`.
- `locales/en.yml`: attribute names.
- `routes.rb`: `/manifest`.

**Database and seeds (5):**
- `db/migrate/20261128100000_move_calves_to_legs.rb` (new).
- `db/schema.rb`: version.
- `db/seeds.rb`: Calf raise under Legs.
- `db/seeds/data.yml`: Calf raise under Legs, active split.
- `lib/tasks/mock.rake`: Calf raise under Legs.

**Public assets (8):**
- `icon.svg`, `icon-180.png`, `icon-192.png`, `icon-512.png`, `icon-maskable-512.png` (new).
- `apple-touch-icon.png`, `apple-touch-icon-precomposed.png` (real images now).
- `favicon.ico` (removed).

**Tests (11):**
- New: `test/helpers/application_helper_test.rb`, `test/helpers/lifts_helper_test.rb`, `test/integration/design_polish_flow_test.rb`, `test/integration/polish_data_flow_test.rb`, `test/lib/icons_test.rb`, `test/models/exercise_test.rb`, `test/models/last_time_test.rb`.
- Changed: `cardio_flow_test.rb`, `dashboard_flow_test.rb`, `logging_flow_test.rb`, `navigation_flow_test.rb` (approved wording, plus new checks).

**Docs (4):**
- `CLAUDE.md`, `doc/design-audit/README.md`.
- `doc/Issues/Issues.md`: potential issues added.
- `doc/design-audit-polish.md` (this file).

## 9. Known gaps

- **Not tried on a real phone:** touch, safe areas, home-screen install and the icons there. There's no service worker, so nothing works offline.
- **Back trail:** History's `?date=` list and History count as one page for Back, as does one workout day opened for two dates in a row.
- **Referer:** `?from=dashboard` after a save relies on the referer. Without one, Delete returns to History.
- **Calves:** the move is irreversible. Until this is merged, `master` still offers Calves.
- **"Last time":** it doesn't show for a plan row whose exercise was deleted.
- **Top weight:** a value of 10,000 kg or more shows smaller and breaks after its comma.
- **Not checked at 320 px or 200% text:** the admin and form pages.
- **Kept on purpose:** "Move a workout" still counts an empty workout as trained, so the existing potential issue "A workout with nothing in it still shows in some places" stays open, partly fixed. The add-set jump on a dateless address also stays ("Saving a set or a note can still jump to the top").
- **Desktop History:** the Sets column reads "0 · 45 min 50 s" for a cardio-only workout. That's the same on `master`, and it's left as it is.
- **Issues.md:** no item moved to resolved. The open calendar issue (numbers off centre) wasn't checked against the owner's screenshot.
- **Potential issues added:**
  - A very heavy top weight is shown smaller and broken after its comma (Home page).
  - "Last time" needs the exercise to still exist (Exercise page).
  - The back button counts addresses that differ only by from= or date= as one page (General).
  - "Back to Home" after an edit relies on the browser's referer (General).
  - Calves moved to Legs for good; master still offers Calves until merged (General).
  - The installable app not tried on a phone (General).
  - An icon missing from the Font Awesome list shows blank (General).
  - Larger text everywhere checked only on the main pages (General).
- **Features.md:** no open feature matched, so it's unchanged.
