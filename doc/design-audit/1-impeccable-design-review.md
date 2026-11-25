# Impeccable critique, Assessment A (design review)

Method: design review only (Assessment A). The detector (`impeccable detect`) was not run or read; Assessment B covers it.

- App: `http://127.0.0.1:3001`, database `fitness_app_design_audit`, today Wednesday 2026-11-25. The repo was only read, never edited.
- Evidence: every screenshot in `.../scratchpad/shots/png/` (63 shots: phone first, then desktop), plus 30 of my own in `.../scratchpad/shots/impeccable-a/`. I drove those with headless Chrome over CDP on port 9341, using scripts in `.../scratchpad/impeccable-a-scripts/`.
- Measured: computed styles, WCAG contrast ratios (computed, not guessed), and where the Add set button sits before and after a set is added.
- Data I added to the audit database:
  - Sets 4 and 5 of Hip thrust today.
  - A paused and then resumed timer on today's Lower.
  - An exercise with a long name in today's workout: "Single-arm cable rear delt fly with rope attachment (slow eccentric)".
  - Another reviewer seems to have added a 99999.125 kg set and a Full Body workout today. Those show in my later shots.

Long folders are written as `.../scratchpad`. In full that is `/tmp/claude-1000/-home-pedro-code-pqdesu-fitness-app--claude-worktrees-opus-plan-session-e72fa6/d91907ca-cfc9-418e-acc7-1a8504a66bda/scratchpad`.

---

## 1. Design specificity verdict

**Verdict: this is a careful, well-engineered Bootstrap app, not a gym logger with its own visual identity.** If you swap the dumbbell logo for a different icon, it could be a task tracker or a CRM. The care is real but invisible:

- 44px touch targets everywhere.
- The paused-timer and rest alerts, a "breathing" Running pill and tabular numbers.
- Comments in the SCSS that give the reason for every value.

The visual layer is the category default:

- Inter and Plus Jakarta Sans.
- An indigo `#4F46E5` primary.
- 16px-radius cards with a hairline border and a 2%-opacity shadow.
- Lowercase muted eyebrows above every heading.
- Uppercase tracked group labels in the picker.
- Bootstrap's outline-secondary pills.

**What is authored for the gym:**

- The Add set form comes pre-filled with the last set, so repeating a set is one tap.
- The workout timer card: status pill, a 32px tabular clock, and a full-width Pause / Stop row on the phone.
- The week strip of seven circles, and the calendar with planned, missed and extra states.
- 16px fields, so an iPhone does not zoom into them.
- "Weight then reps" everywhere.

**What fights the gym moment:**

- The set table spends about 70% of each set's height on controls (a Tag pill, a full-width note field and a blue arrow). Those controls get used maybe once in twenty sets.
- The number the lifter cares about (the weight, `60 kg`) is set at body size, 15px Inter 400. It is the same size as "Add a note".
- The rest clock, the thing read "at arm's length from the bench" (the code's own comment, `_workout_log.scss:99`), is 22px and sits inline next to the word "Rest".

**Missed opportunities for product character:**

- Numbers as heroes: the weight × reps of the set just done, the rest countdown, and the session total.
- A visible "last time" for this exercise on the exercise page.
- One strong accent kept for the single action of each screen. Today indigo goes on everything: four blue note arrows, Add set, the chips, links, calendar fills and the Change and Month links.

**Surfaces are not separated.** Bootstrap 5.3 derives `$card-bg` and `$input-bg` from `$body-bg`, which the app sets to `$light-gray` (`config/_bootstrap_variables.scss:7`). So every card, input and modal is `#F6F7F9`, the same as the page (computed: `.card` and `.form-control` background are `rgb(246,247,249)`). The flash file's comment says "white cards like the rest of the app" (`components/_flash.scss:1`), so the intent was white. Only `.btn-light`, the choice rows and the bottom bar are white. The result:

- White buttons float on grey cards.
- The card and page read as one flat grey plane, separated only by a 1.14:1 hairline.

This one variable is the biggest single visual fix in the app.

---

## 2. Heuristic scores (Nielsen, 0 to 4)

| # | Heuristic | Score | Key issue |
|---|-----------|-------|-----------|
| 1 | Visibility of system status | 3 | Good: flash notices with a countdown bar, timer pills (Running, Paused, Finished), a live clock, "Set 4 added." The calendar calls Nov 20 "Upper missed", while History and Recent list that same Upper (0 exercises, 0 sets) as a workout. Fields show a green "valid" tick on pages nobody has submitted. |
| 2 | Match with the real world | 3 | Mostly gym language: Weight, Reps, Rest, Warm-up, Drop set. Leaks: "Rest ~min", "Reps completed can't be blank and Reps completed is not a number", "Day must be one of the listed workouts" (the field is "Workout"), "Deleted" (meaning the split), "Create Workout day". |
| 3 | User control and freedom | 3 | One back arrow, Cancel on forms, Esc and Cancel on set edits, confirms before deletes. There is no undo after a confirmed delete. "Delete workout" is a primary-position red button on every logged workout. |
| 4 | Consistency and standards | 2 | The same workout has two pages with different words and controls (`workout_days/11` vs `workout_logs/7`). Labels come in two systems, pills in three. Page headers lay out three ways. Admin Equipment and Set tags have no tab and no title ("FitnessApp"). Button labels: "Create Split" and "Update Workout day" next to "Save". |
| 5 | Error prevention | 3 | Last set pre-filled, numeric keypads, confirms. On the other side: a red × beside every catalogue row in the picker, right next to the checkbox you tap; a valid-green field after a failed login; an example placeholder ("Bench press") that looks like a value. |
| 6 | Recognition rather than recall | 2 | The picker has no search: you must know which muscle group holds "Hip thrust" and open that fold. The exercise page does not show last session's sets for that exercise. The calendar has no legend, so you must remember what filled, dotted and light ring mean. |
| 7 | Flexibility and efficiency | 2 | Pre-fill is a real accelerator. But: Start rest is a separate tap after every set, a confirm on every set while the rest runs, Add set drifts under the tab bar after each set, and changing a preference (automatic timer, warm-up tag) needs your current password. |
| 8 | Aesthetic and minimalist design | 2 | Each logged set is 171 to 197px tall, mostly a Tag pill and a note field (measured). Workout rows carry three or four trailing controls, squeezing names to a single word per line. The Equipment card sits on every exercise page during the workout. |
| 9 | Error recovery | 2 | Simple forms show red inline errors with an icon (good). The set form shows errors in a flash, with column names and duplicated. Devise hints are in lowercase ("leave it blank if you don't want to change it"). The workout-day error names the wrong field. |
| 10 | Help and documentation | 3 | Short inline help where it matters ("Legs and Lower are the same workout under two names", "For this week only…", empty states that teach the next step, calendar tooltips). There is no help page, which is fine for this scope. |
| **Total** | | **25/40** | **Acceptable** (20 to 27): significant improvements needed before the app is pleasant at the gym. |

---

## 3. System inventory and inconsistencies

### 3.1 Type

**Families:** Inter (body), Plus Jakarta Sans (headings, brand, clocks, stat numbers), Font Awesome 6 (solid and regular). They are loaded by `layouts/application.html.erb:12`.

**Faux bold.** Inter is loaded at **400, 500 and 600 only**, and Jakarta at 600, 700 and 800. Computed `document.fonts` shows exactly Inter 400/500/600 and Plus Jakarta Sans 700. Every Inter 700 is a browser-synthesised bold:

- `.exercise-group` (`_list_toggle.scss:51`)
- `.calendar-head` (`_dashboard_calendar.scss:34`)
- `.calendar-day.is-planned`, `.is-missed`, `.is-extra`, `.is-today` (`:60-66`)
- `.week-overview-name` (`_dashboard_week.scss:50`)
- `.picker-group` (`_exercise_picker.scss:9`)
- `.sign-toggle` (`_workout_log.scss:76`)
- `.rest-clock` (`_workout_log.scss:100`)
- every `<strong>` and `<b>` (for example "Signed in as **admin@example.com**", the rest clock, the timer's paused figure)

Fix: add `;700` to the Inter family in the font URL, or change these to 600.

**Base size.** `$font-size-base: .9375rem` (15px, `_bootstrap_variables.scss:8`). Inputs are 16px. Body text is below the 16px floor that `typeset.md` gives for ordinary web body text, and this is a phone read at arm's length.

Every font-size declared in the app's SCSS (rem at 16px):

| px | Where |
|----|-------|
| 11.0 | `.bottom-nav-item` `.6875rem` (`_bottom_nav.scss:21`) |
| 11.2 | `.chip-day` `.7rem` (`_timer.scss:139`); bottom-nav `.user-initial` `.7rem` (`_bottom_nav.scss:55`) |
| 12.0 | `.picker-group`, `.calendar-head`, `.timer-status`, `.week-label`, `.week-summary dt` and `small`, `.move-days small`, `.app-table th`, chevrons (`.75rem`) |
| 12.48 | `.chip`, `.inline-form .form-label`, `.inline-form .choices-field legend` (`.78rem`) |
| 12.8 | `.eyebrow`, `.order-badge`, `.user-initial`, `.history-counts`, `.recent-counts`, `.today-last`, `.week-moves-note`, `.today-moved`, `.set-rest-row`, badges (`.8rem` and `.8em`) |
| 13.0 | `.timer-meta` `.8125rem` |
| 13.6 | `.link-quiet`, `.toggle-days`, `.lift-sets`, `.btn i` (`.85rem` and `.85em`) |
| 14.0 | `.calendar-day`, `.recent-notes`, `.rest-picker` (`.875rem`) |
| 14.4 | `.flash-text`, `.confirm-detail`, `.lift-pill`, `.auth-card a`, `.brand-mark` (`.9rem`) |
| 15.0 | body |
| 16.0 | inputs, `.actions-toggle`, `.back-link`, `.auth h2` |
| 16.8 | `.card h2` `1.05rem` (`_cards.scss:5`) |
| 17.6 | `.confirm-title` `1.1rem`, `.hero p` |
| 18.0 | `.navbar-page-title` `1.125rem` |
| 18.4 | `.modal-title`, `.bottom-nav-icon`, `.confirm-icon` (`1.15rem`) |
| 20.0 | `.today-title`, `.week-summary dd` (`1.25rem`) |
| 22.0 | `.rest-clock` `1.375rem` |
| 24.0 | `.auth-card h1` `1.5rem` |
| 25.6 | `.empty-state > i` `1.6rem` |
| 28.0 | `.page-header h1` `1.75rem` |
| 32.0 | `.timer-clock` `2rem` |

**There are 21 sizes, with three clusters that cannot carry different jobs:**

- **12.0 / 12.48 / 12.8 / 13.0** (four sizes within 1px). Table heads, chips, form labels, eyebrows and timer meta all differ by fractions of a pixel. Collapse them to one 12px "label" role and one 13px "meta" role.
- **13.6 / 14.0 / 14.4.** Collapse to 14px.
- **16.8 / 17.6 / 18.0 / 18.4.** Card h2, confirm title, top-bar title and modal title. Collapse to 18px.

**Proposed fixed scale** (ratio about 1.2, per `operate.md`), with nine roles:

| px | Role |
|----|------|
| 12 | label, caps |
| 13 | meta |
| 14 | small |
| 16 | body (raise from 15) |
| 18 | card title |
| 22 | numeric |
| 28 | page title |
| 36 | rest and timer clock |
| 48 | the live rest clock while resting |

**Weights in use:** 400, 500 (10 declarations), 600 (26), 700 (14), 800 (3, Jakarta only), plus Bootstrap `fw-semibold` ×5 and `fw-normal` ×3, and `$headings-font-weight: 700`, `$btn-font-weight: 600`. Five weights is fine; the faux 700 is not.

**Headings:** 31 `h1`, 34 `h2`, 3 `h3` in views. The `h1` is always 28px with -0.02em tracking (computed -0.56px), with two exceptions:

- Devise pages: 24px (`_auth.scss:8`)
- Account: 28px inside a card, so the page has its h1 *inside* a card with a 2rem card padding. That is the only page laid out this way.

**Label systems (inconsistent).**

- simple_form labels are 15px, weight 400, near-black. Computed: "Name", "Muscle group", "Date", "Notes", "Email".
- inline-form labels are 12.48px, weight 600, `$muted`. Computed: "Weight kg", "Reps", "Exercise name", "Equipment", "Kind" (`_tables.scss:25-30`).

The same "Equipment" label is 15/400/dark on `exercises/new` (`phone--exercise-new-0`) and 12.5/600/muted on the exercise page (`phone--today-exercise-hip-thrust-1`). The same fold row "Free weight" is dark 16px on `exercises/new` and muted 600 13px on `workout_log_exercises/edit`.

**Placeholders.** The placeholder colour computes to `rgba(28,32,36,.75)`, the same as `.text-muted` text. Example placeholders therefore read as real values:

- "Bench press" (picker, `exercises/new`)
- "Push / Pull / Legs" (`splits/new`)
- "Dumbbell" (`admin/equipment`)
- "Warm-up" (`admin/tags`)
- "Add a note" ×N
- "How did it go?"

See `phone--split-new`, `phone--today-workout-lower--picker`, `phone--admin-equipment-0`.

**Two muted greys.** Bootstrap 5.3's `.text-muted` uses `--bs-secondary-color` = `rgba(body, .75)` (computed). `$text-muted: $muted` (`_bootstrap_variables.scss:22`) is therefore dead. Custom CSS uses `$muted #646B78`, while 49 `text-muted` uses in views get `#5C5F64`-ish. Set `$secondary-color: $muted` (5.3 name) or `--bs-secondary-color`.

**Numerals.** `tabular-nums` is applied in tables, the calendar, the timer, the week summary and `.top-set` (good). It is not applied to the set weight cell when it is a `span` outside `.app-table` (it inherits there, fine), and not to `.month-list` numbers (`_dashboard_month.scss`) or `.history-counts`.

### 3.2 Spacing

Values in use: `.125, .1875, .2em, .25, .3, .375, .4, .5, .625, .7 (pointer:coarse btn-sm), .75, .875, 1, 1.125, 1.25, 1.5, 1.75, 2, 2.5, 3, 3.25, 4rem`. That is 22 values.

Off any 4px grid: `.1875` (3px), `.3rem` (4.8px, `_dashboard_recent.scss:72`), `.4rem` (6.4px, `.order-badge` padding `_lists.scss:50`, `.week-overview-days li` `_dashboard_week.scss:41`, `.chip-day` `_timer.scss:138`), `.7rem` (11.2px, `_layout.scss:90`). Also `.375 / .625 / .875 / 1.125`: 6, 10, 14 and 18px are a 2px scale mixed with a 4px one.

**List row vertical padding: four values for the same "row in a card" job.**

| Padding | Where |
|---------|-------|
| `.875rem` | `.list-rows li` (`_lists.scss:12`), `.recent-toggle` (`_dashboard_recent.scss:16`) |
| `.75rem` | `.exercise-group` (`_list_toggle.scss:49`), `td` (`_tables.scss:14`), `.rest-start-days li` (`_dashboard_moves.scss:38`) |
| `.625rem` | `.month-list li` (`_dashboard_month.scss:12`), `.picker-row` (`_exercise_picker.scss:21`), `th` (`_tables.scss:7`) |
| `.4rem` | `.week-overview-days li` (`_dashboard_week.scss:41`) |

**Card body padding: five values.**

| Padding | Where |
|---------|-------|
| `1rem 1.25rem` | Bootstrap default with `$card-spacer-x: 1.25rem`; `.timer-body` (`_timer.scss:11`) |
| `1.125rem 1.25rem .5rem` | `.today-header` (`_dashboard_today.scss:8`) |
| `2rem` | `.auth-card .card-body` (`_auth.scss:6`) |
| `2.5rem 1.5rem` | `.empty-state`, and `1.5rem` for `.compact` (`_empty_state.scss:3,10`). The horizontal 1.5rem breaks the 1.25rem card gutter. |
| `1.5rem 1.25rem 1.25rem` | confirm modal (`_confirm.scss:19`) |

**Uneven gaps between cards.** `.calendar-card { margin-bottom: 1rem }` (`_dashboard_calendar.scss:2`) stacks with `.card + .card { margin-top: 1rem }` (`_cards.scss:7`). That gives 2rem (about 40px measured) above Recent workouts and above Totals, against 16px between every other pair of cards. See `phone--home-1` and `phone--month-0`. `.timer-card { margin-bottom: 1rem }` (`_timer.scss:4`) does the same before the first card under it.

**Inner right edges are not aligned in the set table.** On a phone the last cell's padding is `.75rem` (`_workout_log.scss:62`), so the note field and its blue arrow end 8px further right than the header date, the ⋯ and the Add set button, which sit on the card's 1.25rem gutter. See `phone--today-exercise-hip-thrust-0`, right edge x=365 vs 357 CSS px.

**Big gap after the drag handle.** In workout rows the handle is 44px wide with a -14px margin, then a 16px gap, so the name starts about 54px from the handle's glyph. That wastes about 30px of a 342px row on the narrowest column. See `phone--today-workout-lower-0`.

### 3.3 Colour

Tokens: `config/_colors.scss` (good discipline: every colour named by role, AA notes in comments).

**Hard-coded and leaked values:**

- `#fff` at `_lists.scss:87`, and the literal `white` at 13 places (`_bottom_nav.scss:10`, `_confirm.scss:13`, `_layout.scss:53,80`, `_choices.scss:38`, `_dashboard_recent.scss:54`, `_split_week.scss:28,51,59,64`, `_dashboard_calendar.scss:60,67,74,79,85`, `_navbar.scss:2,61`, `_flash.scss:29`). These should become a `$surface` token, and that token is exactly what the cards are missing.
- **Bootstrap's own grey `#6C757D` leaks** through `btn-outline-secondary`, used on the tag pills, the Tag toggle and the ± sign (`workout_sets/_set.html.erb:22,62,73`, `_form.html.erb:139,170`). It is not in the palette. Text contrast is 4.37:1 on the page, which fails AA at 13px.
- **Valid green.** simple_form uses `valid_class: 'is-valid'` (`config/initializers/simple_form_bootstrap.rb:44,59,69,…`), so `$success` teal `#12A594` paints borders, ticks and labels. That includes "Remember me" after a *failed* login (`impeccable-a/err-signin.png`): 2.87:1 as text, and the wrong message.
- **Unused tokens:** `$orange` / `$warning`, `$notice` / `$info`. `$notice #3E63DD` is a second blue close to `$blue #4F46E5`.

**Contrast (computed on page `#F6F7F9`):**

| Pair | Ratio | Verdict |
|------|-------|---------|
| Checkbox and radio border `#E6E8EC` (`$line`) | 1.14:1 | **Fails 3:1** (1.4.11). Picker checkboxes, Remember me, Unilateral, "Add to the shared catalogue", account settings, Move modal radios. |
| Input border `#D5D9E0` with input bg = page bg | 1.32:1 | **Fails 3:1**. The field edge is the only thing that marks a field. |
| Focus ring `rgba(79,70,229,.25)` (Bootstrap box-shadow) | 1.46:1 | **Fails 3:1** for a focus indicator. See `impeccable-a/focus-row1.png`. |
| `$extra-ring #8C93F0` (off-plan day ring) | 2.60:1 (2.46 on this week's tint) | Fails 3:1. It is the only thing that marks an extra workout. |
| Outline-secondary `#6C757D` text | 4.37:1 | Fails 4.5 at 13px. |
| Valid green `#12A594` text | 2.87:1 | Fails. |
| `$muted` on page / on `$primary-soft` | 5.00 / 4.74 | Pass. |
| Done chip, rest chip, chip, blue on page, white on blue | 5.52 / 5.31 / 8.34 / 5.87 / 6.29 | Pass. |

**Colour dosage.** Indigo marks every one of these at once:

- the primary CTA, links, the active tab, chip-tag, order badges, `badge-soft`
- calendar fills, the week fills, the active split ring
- the pen icons, the choice-current values ("Not set" in blue)
- the note-save arrows, one per set

On the exercise page with 3 sets there are **five solid indigo blocks** (three note arrows, one exercise-note arrow, Add set) competing for the thumb. Add set should be the only solid indigo on that screen.

### 3.4 Radii

| Radius | Where |
|--------|-------|
| `.25rem` | focus, `.toggle-days` |
| `.5rem` | `sm`, `.nav-link`, `.order-badge` |
| `.625rem` | base, `.brand-mark` |
| `.75rem` | `.choice-summary` (`_choices.scss:37`), `.sortable-drag`, bottom-nav focus. **Not a token.** |
| `.875rem` | `lg` |
| `1rem` | cards, flash, `xl` |
| `1.5rem` | confirm, `xxl` |
| `999px` | pills |
| `50%` | circles |

Nine steps where five would do: 8 / 12 / 16 / 24 / pill. The choice rows (`.75rem`) sit next to fields (`.625rem`) and buttons (`.625rem`) on the same form, with a visibly different radius (`phone--today-exercise-hip-thrust-1`: "Type of machine" row vs the "Bull" field).

**History and Users tables:** the card's top corners render square because the `thead` background is not clipped. `.app-table` sits in a `.card` without `overflow: hidden`. See `phone--history-0` (y about 357) and `phone--admin-users`. Fix: `.card > .table-responsive:first-child, .card > .app-table:first-child { border-top-left-radius: inherit; border-top-right-radius: inherit; overflow: hidden }`, or `overflow: hidden` on those cards.

### 3.5 Shadows

| Shadow | Where |
|--------|-------|
| `0 1px 2px rgba($shadow,.04)` | cards (`_cards.scss:3`), back link |
| `0 6px 20px rgba($blue,.12)` | card-link hover |
| `0 10px 30px .14, 0 2px 6px .06` | flash |
| `0 20px 50px .25` | confirm |
| `0 .75rem 1.75rem .18` | drag copy |
| `0 0 0 2px $blue` | active split ring |

These are five unscaled elevations, which is acceptable, but the card shadow at 4% is invisible. With cards the same colour as the page, the cards have no depth at all.

### 3.6 Borders

`$line #E6E8EC` (1.14:1) on cards, rows, the table, the nav and the toggles. `$line-strong #D5D9E0` on fields. The active split card uses a 2px ring plus a border, which reads as a 3px blue frame, the heaviest border in the app. It is also on an empty-state "Active split" card for a user with no splits (`phone--empty--home-0`).

### 3.7 Icons

Font Awesome 6 Free, solid, with two regular icons mixed in (`fa-regular fa-clock` in History, `fa-regular fa-note-sticky`). Sizes:

- inherit
- `.85em` inside buttons (`_layout.scss:75`)
- `1rem` (actions)
- `1.15rem` (bottom nav)
- `1.6rem` (empty states)
- `.75rem` (chevrons)

**Pen icons that are not ⋯ menus.** The pen in workout-day rows is an admin-only "rename catalogue exercise" (`workout_days/_planned_exercise.html.erb:13-16`). Placed there, it reads as "edit this exercise in my workout" on a page where everything else is about the workout (`phone--today-workout-lower-0`). The History pen means "edit timer". The same glyph does two different jobs.

**Icon accessibility:** `<i class="fa-solid fa-plus">` in Add set has no `aria-hidden` (`workout_sets/_form.html.erb:161`). Neither do the chevron and pen in `_planned_exercise.html.erb:15,17`, nor the brand mark (`shared/_navbar.html.erb:25`).

### 3.8 Buttons

Variants in views:

| Variant | Count |
|---------|-------|
| `btn-light` | 44 |
| `btn-sm` | 40 |
| `btn-primary` | 32 |
| `btn-link` | 6 |
| `btn-outline-secondary` | 5 |
| `btn-outline-primary` | 3 |
| `btn-outline-danger` | 3 |
| `btn-lg` | 2 |
| `btn-danger` | 1 |

There are three visual languages for "pill-ish choice":

1. **Choices** (`shared/_choices`): indigo outline, 44px, `.625rem` radius rectangles (muscle group, equipment, Kind).
2. **Tag pills:** `btn-outline-secondary rounded-pill`, Bootstrap grey.
3. **Chips:** soft-fill, 999px (display only).

Tags and choices are the same interaction (tap to toggle) but look unrelated. The Tag toggle's focus state is a *filled dark grey pill* (`focus-row2.png`, panels 2 and 3), which looks exactly like a selected tag.

Primary labels mix Rails defaults ("Create Split", "Update Split", "Create Workout day", "Update Workout day", "Update Exercise") with plain verbs ("Save", "Add", "Add set", "Update" on Account). Make them sentence case and specific: "Create split", "Save split", "Add workout day", "Save exercise".

### 3.9 Cards and rows

The **workout row pattern** (`workout_days/_planned_exercise.html.erb`) is: handle (44px), name and meta link, sets chip, pen (admin) or × (extra), and a bordered chevron button. That is five elements. The name link and the chevron button go to the same URL (`:6` and `:17`), so the chevron is a duplicate target.

The **logged-exercise card** (`workout_logs/show`) is: handle, name, meta and top set, a grey sets chip (not the green one), ⋯, and a bordered chevron fold button. The two pages show the same object with different chips (green "3 sets" vs grey "3 sets"), a different action (pen vs ⋯) and a different chevron meaning (right = open vs down = fold).

**Fold toggles as bordered white 44px boxes** (split days, logged exercises) carry more visual weight than the card title. A bare chevron in a 44px hit area would do.

---

## 4. Page-by-page findings

### Home (`phone--home-0/1/2`, `phone--home--expanded`, `desktop--home`)

- **Eyebrow "Today" above an h1 that is the date** (`pages/dashboard.html.erb:10`). `craft-floor.md` bans eyebrows outright. The top bar already says "Home", and the h1 says the date. Drop the eyebrow everywhere (12 views, listed in §3.1), or fold it into the h1 ("Today, Wednesday 25 Nov").
- **The "Exercises" button sits under the date**, before the Today box (`dashboard.html.erb:14`). On a phone it is the first tappable thing in the content and has nothing to do with today. Move it into the Account tab or the History page, or make the catalogue a fifth tab.
- **The Today box:**
  - "Lower day" (18px) with Continue at top right, 44px tall, `btn-primary` default width (`phone--home-0`).
  - Continue is the single most important action of the whole app and is a small button at the top right, out of thumb reach. Make it full width (`d-grid`) under the summary, 52px tall, 17px/600.
  - "5 sets" is an underlined link in the middle of a muted sentence. It is the only underlined link in the app (other links are bare blue), so it looks like a different control.
- **"Last time · Saturday, November 21 · 0 exercises · 0 sets · Lower in U/R/L/U/L".** "Last time" points to an empty workout whose timer was started (7:57 to 7:58 AM, 2 s). It tells the lifter nothing and hides the real last Lower, Nov 18, with 7 exercises and 19 sets. A log with no sets should not count as "last time" for lifts.
- **Active split card:**
  - The 3px indigo frame is the strongest element on the page, stronger than the Today box. The active split is context, not the action. Reduce it to the standard card, with a "U/R/L/U/L · Active" header.
  - "Move a workout" is right-aligned on its own row, leaving a 200px empty strip.
  - The ↔ icon is FA `arrows-left-right` at text size.
- **Week strip:** "S" Sunday has a light ring (extra) but no label under it. Off-plan days show no workout name, so you can't tell what was done. Labels are 12px/600.
- **"This week" tiles:**
  - "Top weight 110 kg" uses an 800-weight Jakarta number with a 12px muted "kg". That is fine, but with a large value it wraps mid-number ("99999." / "125 kg", `impeccable-a/long-row.png` panel 2). Add `white-space: nowrap` on `dd` and `font-size: clamp()`, or let the tile span two columns.
  - "Cardio 45 min 50 s" sits on its own row, breaking the four-across grid.
- **Calendar (`phone--home-1`):**
  - Four visual states (filled, dotted, light ring, ring around today), plus the current-week tint, plus greyed other-month days. There is **no legend**; meaning lives in `title` tooltips, which touch screens never show.
  - The light ring is 2.6:1.
  - Days are 36px circles (known gap, below 44px).
  - A missed day is a link (good), but a dotted circle does not read as tappable.
  - Fix: add a one-line legend under the grid (four mini swatches, 12px: "Planned · Missed (tap to log) · Extra · Today"), and raise `$extra-ring` to at least `#6E76EA` (3.4:1).
- **Recent workouts:** each row shows the name, the date in "November 25, 2026" format (no weekday), sets, and a chip on its own line. On a phone the chip row makes each item 100px tall, and five items about 500px. The split chip "U/R/L/U/L" is repeated on every row: show it only when it differs from the active split.
- **Gap rhythm:** 40px above Recent workouts vs 16px elsewhere (§3.2).
- **Desktop (`desktop--home`):** the calendar takes the left column, so reading order starts with the calendar, not today. The Today box is in the right column with a 28px-tall Continue button (no coarse pointer). Swap them: Today plus Active split on the left (primary), calendar on the right.

### Move a workout modal (`phone--home--move-modal`)

- Full-screen on a phone, with a footer CTA in the thumb zone (good).
- The radio circles are almost invisible (1.14:1).
- "WHICH WORKOUT" and "MOVE TO" are uppercase tracked labels, a third label style.
- Day buttons: "Today / Lower", "Thu / Free", "Fri / Upper", "Sat / Lower". It is unclear whether the second line is what is there now or what will be there. Use "Thu · empty" / "Fri · has Upper".
- The modal is grey (`#F6F7F9`) because of the card/modal-bg issue, while the confirm modal is white. Two modal colours.

### Today's workout (`phone--today-workout-lower-0/1`, `desktop--today-workout-lower`, `impeccable-a/timer-row.png`)

- **Header:** h1 "Lower", then "Today · Wednesday, November 25", then a bold "2 exercises · 5 sets" line. The "Plan" button (white, 44px) is vertically centred on the three lines, so it floats beside the date, not the title. What "Plan" does is unclear. It goes to the split page; call it "Edit plan" or move it into a ⋯ menu.
- **Timer card:** the best-designed component. Pill, clock, Pause and Stop full-width row. Notes:
  - Stop is an `outline-danger`, the same weight as Pause. Fine, since it is confirmed.
  - "Started 10:28 PM · paused 4 s" is 13px muted.
  - Paused state (`timer-row` panel 2): a "Paused" amber pill, an amber "for 0:00:02" (`rest-text`, 600), and the clock dimmed to `$muted`. Clear.
  - The clock is `0:46:31` with an hours digit. For a gym session that is fine.
- **"In this workout · 2" with "+ Add exercise"** (primary) in the header. Good placement for discoverability, but it is a top-of-card button. On a long workout it scrolls away; a duplicate full-width "Add exercise" at the end of the list (as `workout_logs/show` has) would help.
- **Rows are squeezed** by the trailing controls: the green "3 sets" chip, the pen (admin) and a 44px bordered chevron. The meta "Machine · Bull · Legs" wraps to three lines ("Machine ·" / "Bull · Legs"). On the Legs day (`phone--workout-day-today-legs-0`) "Machine · Bull · Added to this workout" wraps to five lines, about 18 characters per line. The long-name test (`impeccable-a/long-row.png` panel 1) wraps one word per line over seven lines.
- Fix:
  - Drop the chevron button (the whole row is already the link `row-link`, `_planned_exercise.html.erb:6`). Show a 12px `fa-chevron-right` in `$muted` as an affordance at the end of the row.
  - Move the sets chip under the name, on the meta line.
  - Move the admin pen into a ⋯ or the exercise page.
  - Reduce the handle's gap (margin-right 0, gap .25rem).
- **"No sets"** is plain muted text in a row that elsewhere has a chip. Use a neutral chip, "0 sets", for rhythm.
- **The red × on "Added to this workout" rows** sits 40px from the chevron and 90px from the sets chip. A red destructive glyph inline in a list you tap to open things is a slip hazard, even with the confirm. Put it into ⋯ with "Remove from workout".
- **"Still to do · 5":** same row pattern, without the chip. Good. Dragging a to-do row in is clever but undiscoverable; the 44px grip is the only hint, with `title` only.
- **"Everything planned is in this workout."** is shown as a card with a single centred line. Fine.
- **Picker (`phone--today-workout-lower--picker`, `impeccable-a/picker-group-open`):**
  - **No search field.** Nine groups are folded by default, and you must know which group holds the exercise.
  - The groups are **UPPERCASE 12px/700 tracked letters**, which read as section labels, not as rows you can open.
  - In an open group (panel 1 of `timer-row.png`), the row checkbox has a 1.14:1 border, so the rows look like plain text.
  - An admin sees a red × at the end of every row, five in a column.
  - "Create your own" asks for name and muscle group. "Other" is preselected and filled indigo, so the most prominent element in the form is a default nobody chose.
  - Fix: a sticky search input at the top of the modal body. It filters across groups and shows matches flat; typing a name that does not exist offers "Create 'xyz'". Show the groups as 16px/600 sentence-case rows with a count chip (like `exercises/index`). Move the admin × into the exercise's edit page or a long-press ⋯.

### Exercise page (today, `phone--today-exercise-hip-thrust-0/1/2`, `--expanded`, `--actions-menu`, `desktop--today-exercise-hip-thrust`, `impeccable-a/rest-running`, `after-add-set-flash`, `after-add-with-date`)

This is the peak screen of the app. Findings in the order of the thumb's path:

1. **Each logged set is 171 to 197px tall** (measured tbody heights 171, 197, 196). Of that, the numbers row is about 50px. The rest is the rest line (about 22px), a 44px Tag pill on its own line, and a 44px note field with a blue 44px arrow. With 3 sets, Add set starts at y=933 on an 844px screen (measured), so the first view of a resumed exercise **does not show the Add set button**. Fix:
   - Make each set one 48px row: `#`, weight, reps, tag chips inline, ⋯.
   - Move "Add a note" and "Tag" into the ⋯ menu ("Add note", "Tag…").
   - Show a note only when one exists (as a 13px muted line under the row).
   - Set height then drops to 48px, or 70px with a note, and 5 sets fit above the fold with the form.
2. **The Add set button drifts down after each set.** When the page is opened from the workout (URL with `?date=`), scroll is preserved but the new 196px set is inserted above the form. Add set moved from y=632 to y=771, under the tab bar that starts at 784 (measured, `after-add-with-date.png`). Opened without `?date=` (a bookmark, or the shoot script), the redirect URL differs and the page **jumps to the top** with Add set at y=1301 (`after-second-add.png`). Fix:
   - Put the Add set form *above* the list of today's sets (newest first), directly under the card header. It then never moves.
   - Or make the form `position: sticky; bottom: calc(3.75rem + env(safe-area-inset-bottom))` in the card footer on phones.
   - The redirect to `back` in `WorkoutSetsController#create` should keep the URL the page was opened with.
3. **The weight is the hero and is set like body text.** "60 kg" and "12" are 15px/400. Make the weight and reps 20px/600 Jakarta with tabular numbers, and keep "kg" 13px muted. The set number badge (12.8px indigo on soft indigo, 26px) is a third indigo element per row; make it a plain muted `1` in 13px.
4. **Rest timer:**
   - "Start rest" is a separate `btn-light` above the form, so every set costs Add set, then Start rest.
   - While it runs the clock is 22px inline with "Rest", with a Stop button (`rest-running.png`).
   - Pressing Add set while it runs opens a modal, "Your rest timer is running: No rest / Save rest" (`rest-alert-on-add.png`). That is a third tap on the most common path (you rested, now you log the set).
   - Recommendation (a question for the owner, since it changes behaviour):
     - Save the rest by default without asking.
     - Start the rest automatically when a set is added (an account setting, as `auto_warm_up` already is).
     - Show the running rest as a large 36 to 48px clock in a sticky strip above Add set.
   - The clock reads "0:00:04". For a rest under an hour show "0:04".
5. **The form:** "Weight kg" and "Reps" labels are 12.48px muted 600, and the inputs are pre-filled (great). Below the fields:
   - Tag pills "Assisted / Drop set / Warm-up" are Bootstrap grey outline pills, 44px tall, a full row.
   - On an earlier day there is a "Rest ~min" select with "–" options "~1…~30" (`phone--exercise-page-0`). The "~" in the label and the options is jargon. Use "Rest (min)" with options "1 … 30".
   - The weight placeholder "–" on an empty weight makes it look disabled.
6. **Two flashes cover the top bar.** "Set 4 added." sits over the back arrow and the title for 5 s after every set (`after-add-set-flash.png`, `focus-row2` panel 4). At the gym you add a set and often want to go back right after; the back button is under the toast. Fix: on phones place notices at the bottom, above the tab bar (`bottom: calc(3.75rem + .75rem + env(safe-area-inset-bottom))`). Or, for "Set N added." only, skip the toast: the new row already lights up with `.just-moved`, so give the new set that highlight instead.
7. **The Note card** (exercise note for today) is a second note concept on the same screen as per-set notes, with the same placeholder style and arrow. "Note / Today" header. Fine on desktop, where it is in the side column; on a phone it is one more card between the sets and the equipment.
8. **The Equipment card on every exercise page:**
   - A full form (choices, two fold rows "Type of machine: Not set", "Machine: Not set", "Machine brand", and a "Save equipment" button).
   - This is set-up, not logging. On a phone it is 600px of the page.
   - Fold it behind a single row "Equipment · Machine · Bull ›" that opens the form.
   - "Not set" in indigo `choice-current` looks like a link or a value, not an empty state. Use muted.
9. **The ⋯ menu** (`--actions-menu`) is a 176px-wide dropdown with Edit (pen) and Delete (red ×), 44px items (good). It covers the next set's Tag and note.
10. **Expanded tag state** (`--expanded`): the tag choices open as a second row of grey pills under "Tag", so the set grows to about 290px.
11. **The weight/reps alignment:** the "Weight" column header sits at x=155 and the values at x=155 (good). The "Reps" column is wide (about 140px) because the actions column is narrow, so the reps sit 210px from the right edge with empty space after.
12. **Desktop:** the sets table and form are in the left 2/3, Note and Equipment on the right (good). The tag pills there are Bootstrap `sm` (about 26px tall, fine for a mouse).

### Exercise to do, no sets (`phone--today-exercise-todo-rdl`)

- "No sets yet today. Add your first set below." The empty state is centred 15px muted and points to the form underneath. Good.
- The form is pre-filled with "120 / 8" from last time (good). There is **no label** saying where 120 comes from. Add a 13px muted line, "Last time (Wed 18 Nov): 120 kg × 8, 110 × 8, 100 × 10", above the fields. That is the single most useful number in a gym logger, and it is missing from this page.

### Logged workout (today: `phone--today-log-0/1`; past: `phone--log-show-upper`, `--expanded`, `phone--log-show-lower`, `-restday`, `-cardio`, `desktop--log-show-upper`)

- **"Delete workout"** is a red outline button in the page header. It sits beside the title when there is room (`log-show-upper`), and on its own row under the date when a badge is present (`log-show-restday`, `log-show-cardio`). It is the most prominent action on a page about *viewing* the workout. Move it to the bottom of the Details card as a `btn-link text-danger`, or into a header ⋯.
- **Exercise cards:**
  - The name column is about 110px wide (handle, chip, ⋯, chevron box), so "Seated / Lateral Raise", "Upper back / row" and "Incline / dumbbell / press" wrap to two or three lines at 20px.
  - The meta "Free weights ·" ends with a dangling "·" at the end of the line, then "Top 14 kg × 8 reps" (`phone--log-show-upper-0`). `time_parts` keeps separators with their part for times; the equipment line needs the same `nowrap` treatment, or drop the trailing separator when the top set wraps.
- **Sets chip** is grey here, green on the workout day. Pick one meaning: green = done today.
- **"From this day, not in this workout"** (today's log) lists the plan's exercises with an "Add" `btn-light` per row. The workout day page shows the same thing as "Still to do · 5" with drag and open. Same data, two names, two controls (§3.9). Name it "Still to do" on both pages.
- **"+ Add exercise"** is a full-width `btn-light` between the exercises and Details (on the workout day it is a primary in the card header).
- **Details card:**
  - Date and Notes use simple_form labels (15/400), while the exercise forms use inline labels.
  - The date input is the browser default "11/25/2026" (US) while the page shows "November 25, 2026".
  - "Save details" is a full-width `btn-light`.
- **Cardio:**
  - The table header uses "#" where lifts use "Set".
  - Time "0:05" and "45:45" sit in the table, but the chip says "45 min 50 s". Two formats on one card.
  - The values are "5 %" and "10 km/h" with a space before %.
  - The form labels "Incline %", "Speed km/h", "Min", "Sec" and the "+ Add" button are fine.
- **Rest-day log:** "Rest day, trained anyway" chip (amber). The copy is friendly. The amber is the same as "Paused", so two meanings share one colour.

### Past and future workout days (`phone--past-workout-upper-mon`, `phone--workout-day-past-push`, `phone--workout-day-future-upper`)

- **Past:** "In this workout · 0" with "Drag an exercise here, or open one and add a set." (good teaching). But on a phone, dragging between cards is a hidden gesture.
- **Future (Friday):** a single "Exercises" card, "No exercises planned for Upper." There is no hint that sets will open on Friday, and no "Train it today instead" route. Move is on Home only. At minimum say "Sets open on Friday, Nov 27."
- **Active tab differs:** today's workout shows Home active, while past and future workout days show Splits active (`application_helper.rb:92-102`). One page type, two tabs.

### Splits (`phone--splits`, `phone--empty--splits`, `phone--split-show-0/1`, `--picker`, `desktop--split-show`)

- **Index:**
  - The eyebrow "Programs" plus the h1 "Your splits".
  - The subtitle says "the one your **dashboard** follows" (`splits/index.html.erb:6`). The dashboard is now "Home".
  - "+ New split" sits under the subtitle when there is one, and beside the title when there is not (`phone--empty--splits`). Two header layouts.
  - The empty state has "+ New split" in the header **and** "Create your first split" in the card: two primaries for one action. Drop the header one when empty.
- **Split cards:** "PPL/UL / 5 workout days" with chip pills "Push Pull Legs Upper Lower", then "Set as active" as a white button. The active card gets the 3px ring and an "Active ✓" badge (two signals). The whole card is a link, and "Set as active" sits above it (`split-activate z-index`).
- **Show:**
  - The header puts "Set as active" (primary) and a ⋯ beside h1 "PPL/UL". The button is top-aligned with the eyebrow-less title, so the title sits about 20px lower than the button (`phone--split-show-0`).
  - "Your week" circles: an empty day is a white circle with a light border, a planned day solid indigo. The hint "Tap an empty day to add a workout, then plan its exercises below." is good.
  - Day cards: name and weekday, an "N exercises" chip, ⋯, and a bordered chevron box. The folded state is good. "Legs · Wednesday · Today" opened shows "No exercises planned yet." and a full-width "+ Plan exercises".
- **Picker:** the same as the workout picker, the same issues.

### Split and workout-day forms (`phone--split-new`, `--split-edit`, `--workout-day-new`, `--workout-day-edit`, `impeccable-a/err-row1.png`)

- **Fields are green with a tick on first view:**
  - "Sunday" on `workout_days/new`.
  - Every field on the edit pages: "PPL/UL", "Push", "Monday", "Bench press" on `exercises/edit`, the Email on Account.
  - Green means "validated OK", but nothing was submitted.
  - Fix: `config.input_field_valid_class = nil` and drop `valid_class: 'is-valid'` from the wrappers (`config/initializers/simple_form_bootstrap.rb:44,59,69,83,95,108,118,129,142,161`).
- **Required marker:** "Name *". The `<abbr title="required">*</abbr>` gets Bootstrap's dotted underline and reads as ".:". Fix: `abbr[title] { text-decoration: none; cursor: default }`, or `config.required_by_default = false` and mark optional fields instead.
- **Errors:** red border, a ⓘ icon, and a 13px red message under the field (good).
  - "Day must be one of the listed workouts" sits under a field labelled "Workout". The attribute is `day`; the message should say "Choose a workout."
  - On the same failed submit, "Day of the week" stays green. A green field next to a red one on a failed form reads as "half saved".
- **Buttons:** "Create Split / Cancel" are side by side, left-aligned, auto width. On a phone, make the primary full width (as on the auth pages) and put Cancel as a link under it.
- These pages are 80% empty below the form. That is fine.

### History (`phone--history-0/1`, `--confirm`, `desktop--history`, `phone--empty--history`)

- **A one-column table with a "Workout" `th`** on the phone. The `th` row adds a 44px grey strip that labels nothing. Use a list (`list-rows`) on the phone, or hide the `thead` below `md`.
- **Each item:**
  - The date is the link (indigo 16px/600, "November 25, 2026", no weekday).
  - Then "Lower" and the split chip; "2 exercises · 5 sets"; the clock line with a pen.
  - A bordered "Open" button at the right, a duplicate of the date link.
  - The pen floats in the gap between the text and Open, unrelated to the line it edits.
  - Drop Open (the row is the link), lead with "Lower" as the title (16px/600 dark), and make the date muted meta with the weekday: "Wed 25 Nov · 2 exercises · 5 sets".
- **"Deleted"** (muted) after the Rest day chip means "split deleted". It reads as "this workout is deleted". Use "No split" (the Month page already says "No split").
- **Empty logs are listed:** Nov 20 Upper "0 exercises · 0 sets" and Nov 21 Lower "0 exercises · 0 sets" (timer only). The calendar calls Nov 20 "Upper missed. Add it." History and the calendar disagree.
- **Confirm state:** `phone--history--confirm` shows no confirm box. History has no delete on the row (the state script found no `[data-turbo-confirm]` to open), so that shot is the plain page. Not a defect.
- **Desktop:**
  - The table is good, with columns Date, Workout, Split, Exercises, Sets.
  - The Cardio row shows "0 · 45 min 50 s" in the Sets column.
  - The card's top corners are square (§3.4).

### Edit timer (`phone--timer-edit`)

The shot captured a redirect: "This workout has no timer." (alert, red) over History, because log 1 has no timer. That is not a defect of the page. The page itself was not reachable for this log, and I did not open it for a timed log. **Not verified.**

### Month (`phone--month-0/1/2`, `phone--empty--month`, `desktop--month`)

- **"November 2026" twice:** the h1 and the calendar card header. The eyebrow "Month" makes three labels for one fact. The top bar says "Home".
- **No previous/next month navigation**, so the Month page can only show this month. A ‹ › pair in the card header is the expected control.
- **Totals:** the four-tile grid plus Cardio on its own row (as on Home).
- **Splits and Exercises lists** (`.month-list`): names at 16px/600 left, "6 sets · 230 kg" muted right. Clean. The heaviest weight should say "top 230 kg". "6 sets · 230 kg" can be read as total volume.
- **Rhythm:** 40px gap after the calendar, 16px elsewhere.

### Exercises catalogue (`phone--exercises`, `phone--empty--exercises`, `desktop--exercises`)

- **The eyebrow "Catalogue"** plus h1 "Exercises" plus a 3-line paragraph of 15px muted explanation.
  - The admin copy is "As an admin you can add, edit and delete its exercises. Exercises you keep for yourself are marked "Yours"".
  - The other copy is "managed by an admin…".
  - That is long for a list page; one line is enough: "Shared by everyone. Yours are marked 'Yours'."
- **Group rows** (16px/600 dark, count chip, chevron) are the right pattern, unlike the picker's uppercase labels. Use this same row in the picker.
- **A stray 1px line under the card's bottom edge.** `.exercise-group-list { border-bottom }` on the last group sits outside the rounded corner (`phone--exercises` y about 1517, `phone--empty--exercises` y about 1350). Fix: `.exercise-group-list:last-child, .exercise-group:last-of-type { border-bottom: 0 }`.
- **Bottom nav:** the Home tab is active on Exercises (`application_helper.rb:95`, by design, since it is reached from Home). That still confuses: you are on "Exercises", and the tab says Home.

### Exercise forms (`phone--exercise-new-0/1`, `phone--exercise-edit`, `impeccable-a/err-row2.png`)

- **Muscle group:** 10 choices in a 3-column grid, plus a lone "Cardio" on a fourth row, with "Other" first and preselected. The choices are 44px indigo outlines, and the selected one is solid indigo. Fine, but with 10 options use the folded `choice-summary` pattern already used for "Free weight" ("Muscle group · Other ⌄").
- **Equipment:** "Free weights" wraps to two lines in its third ("Free / weights"), while "Machine" and "Bodyweight" stay on one. The row height then grows to 58px. Use "Free weight" (singular, it fits), or `font-size: .875rem` in `.choices .btn`.
- **Checkboxes:** "Unilateral: one arm or one leg at a time" and "Add to the shared catalogue". The unchecked box is invisible (1.14:1).
- **Errors:** "Name has already been taken" for a duplicate. Clearer: "You already have 'Squat'. Pick it from the list."

### Log exercise edit (`phone--log-exercise-edit`)

- Equipment choices plus a "Free weight: Not set" fold, and a Note textarea with the placeholder "Anything to remember about this exercise today (optional)". Then Save (primary) and Cancel. The h1 is the exercise name.
- Labels here are 12.5px muted (inline-form), while the same "Note" is a card header on the exercise page. A third Note surface.

### Account (`phone--account-0/1`, `phone--empty--account`)

- **The page h1 "Account" is inside a card** (`.auth-card`, because it is a Devise page, `layouts/application.html.erb:25-30`), with a 2rem card padding. The top bar also says "Account". On every other page the h1 is outside the cards.
- **The admin links** "Users", "Equipment" and "Set tags" are white buttons with icons, plus "Log out" in the same row style. Log out is an account action and sits with admin tools, and it wraps alone to the second row. Make them a list (`list-rows`) of navigation rows with chevrons, and put Log out at the bottom as a separate `btn-link text-danger`.
- **Preferences need your current password.** "Start the workout timer automatically" and "Tag the first set of each exercise as a warm-up" are checkboxes in the Devise registration form, which requires "Current password *" (`phone--account-1`). Changing a gym preference should not need a password. Move preferences to their own small form (`PATCH /settings`) that saves on toggle.
- **Devise hints** "leave it blank if you don't want to change it" and "we need your current password to confirm your changes" are lowercase and unpunctuated, unlike the rest of the app. Rewrite them in sentence case.
- **"Cancel my account"** with explanatory copy, then a blue "Back" link at the bottom, which duplicates the tab bar.
- The checkbox borders are invisible here too.

### Admin: Users, Equipment, Set tags (`phone--admin-users`, `phone--admin-equipment-0/1/2`, `phone--admin-tags`)

- **The top bar says "FitnessApp"** on Equipment and Set tags (no `PAGE_TITLES` entry), and "Users" on Users. There is no back arrow on any of them, though they are sub-pages of Account. On Equipment and Set tags no tab is active (`bottom_nav.html.erb:7` covers only `users/registrations` and `admin/users`).
- **Users:**
  - A table with an "Email" header.
  - The row "notadmin@example.com": "Make admin" wraps to two lines, and the red "Delete" button touches the card's right edge (x=749 of 755 at 2x, so 3px from the border).
  - The actions should stack under the email on a phone, or go into a ⋯ menu (the app's own pattern).
- **Equipment and Set tags:**
  - An "Add equipment" card (Name, "Kind" choices, a small "Add" primary), then one card per kind with ⋯ rows. Consistent with each other.
  - Placeholders "Dumbbell" and "Warm-up" read as values (they are the names of items already in the list below, which makes it worse).
  - Equipment is 2349 CSS px long on the phone, with one row per item at 78px each. The rows could be 48px.

### Logged out (`phone--loggedout--signin`, `--signup`, `--password-new`, `impeccable-a/err-signin`)

- **"Log in" and "Sign up" appear twice:** in the top bar (link and primary button) and in the card (primary button and link). On a phone the top-bar "Sign up" primary competes with the form's "Log in" primary.
- **After a wrong password:** the error is a red flash (good, it stays until closed), but the email field and the "Remember me" label turn **green with a tick** (`err-signin.png`).
- The auth h1 is 24px; the app h1 is 28px.
- The bottom links "Sign up / Forgot your password?" are 14.4px with no spacing between them. Fine.

### Flash and confirm (`impeccable-a/after-add-set-flash`, `rest-alert-on-add`, `timer-row` panel 3)

- **Flash card:** white, 16px radius, a soft shadow, an icon in a tinted circle, and a 3px countdown bar. Polished. On a phone it covers the top bar (see the exercise page, item 6).
- **Error flash for the set form:** "Set not added: Reps completed can't be blank and Reps completed is not a number." That is technical and says the same thing twice. Use field-level messages, or a custom message: "Type the reps."
- **Confirm and alert boxes:** a white 24px-radius card, an icon in a tinted circle, a bold title, a muted detail, and two equal buttons. Consistent across delete, paused-timer and rest-timer. The paused-timer alert is indigo; the delete confirm is red. Good.

---

## 5. Priority issues

Counts: **P0: 0 · P1: 8 · P2: 17 · P3: 14**

Nothing blocks completing a task (no P0). Every flow I drove works end to end.

### P1 (major)

**P1-1. The Add set button is below the fold and drifts after every set.**

- What: each set row is 171 to 197px tall (Tag pill and note field always shown). With 3 sets the form starts at y=933 on an 844px phone. After each set it moves about 140 to 200px down, under the tab bar (y=632 to 771, tab bar at 784). Opened without `?date=`, the page jumps to the top (Add set at y=1301).
- Why it matters: this is the core action, repeated 15 to 25 times a session, mid-rest, one-handed.
- Fix:
  1. Compact each set to one row. In `workout_sets/_set.html.erb:55-88`, move Tag and Note into the ⋯ menu (`menu_link "Add note"`, "Tag…") and render the note row only `if set.notes.present? || set.set_tags.any?`. Row height target: 48px.
  2. Render the Add set form *above* the sets (`workout_exercises/show.html.erb:34-50`: move the `card-footer` before the table, and list the sets newest first, or keep them oldest first with the form on top).
  3. In `WorkoutSetsController#create`, redirect to the URL the form came from (`request.referer` when it is the same exercise page) so the morph keeps the scroll.
- Command: `/impeccable layout` (exercise page), then `/impeccable distill`.

**P1-2. Cards, inputs and modals are the page colour (`#F6F7F9`).**

- What: Bootstrap 5.3 takes `$card-bg`, `$input-bg` and the modal background from `$body-bg`. Surfaces separate only by a 1.14:1 hairline, and white `btn-light` buttons float on grey cards.
- Fix: in `config/_bootstrap_variables.scss` add:
  - `$card-bg: $surface; $input-bg: $surface; $modal-content-bg: $surface; $dropdown-bg: $surface; $list-group-bg: $surface;`
  - with `$surface: #FFFFFF` in `_colors.scss`, and replace the 14 literal `white`s with it.
  - Keep `$body-bg: $light-gray`.
  - Raise the card shadow to `0 1px 2px rgba($shadow,.06), 0 1px 1px rgba($shadow,.04)`.
- Command: `/impeccable colorize`, then `/impeccable polish`.

**P1-3. Checkbox and radio borders are invisible (1.14:1), and input borders fail (1.32:1).**

- Where: picker exercise rows (the core "Add exercises" choice), Remember me, Unilateral, "Add to the shared catalogue", account preferences, Move-modal radios.
- Fix:
  - `$form-check-input-border: 1.5px solid #8A919E` (3.2:1 on white). That needs a new token, `$control-border: #8A919E`.
  - `$input-border-color: #B9BFC9` with white inputs (after P1-2), which gives at least 1.9:1 for the field edge. Field identification also comes from the white fill on the grey page.
  - For WCAG 1.4.11, use `#8A919E` for checkboxes and radios.
- Command: `/impeccable colorize` (audit of states).

**P1-4. The exercise picker has no search, and the groups look like labels.**

- What: you must know which muscle group holds the exercise and open its fold. The group rows are 12px uppercase tracked text. In the catalogue page the same groups are 16px/600 rows.
- Fix:
  - Add `<input type="search" placeholder="Search exercises" class="form-control">` sticky at the top of `.modal-body` in `shared/_exercise_picker.html.erb`. A small Stimulus filter hides rows that do not match and opens the groups that have matches.
  - When nothing matches, prefill "Create your own" with the query.
  - Restyle `.picker-group` as `.exercise-group`: `font-size: 1rem; font-weight: 600; text-transform: none; letter-spacing: 0; color: $gray`, with the count chip.
- Command: `/impeccable layout` and `/impeccable clarify`.

**P1-5. Three taps per set while using the rest timer.**

- What: Add set, then a confirm ("Save rest" / "No rest"), then Start rest. The confirm guards the expected path.
- Fix (behaviour change, so ask the owner):
  - Save the measured rest by default without the dialog. Keep the dialog only if the rest is over 10 min (a forgotten timer).
  - Add an account setting, "Start rest after each set", like `auto_warm_up`.
  - While resting, show the clock at 36px (`.rest-clock { font-size: 2.25rem; font-family: $headers-font }`), formatted m:ss.
- Command: `/impeccable distill`.

**P1-6. The workout rows squeeze the exercise name to 18 to 110px.**

- What: the handle gap, the sets chip, the pen or ×, and the bordered chevron leave the name column about 95 to 110px. Names and meta wrap to three to seven lines (`phone--workout-day-today-legs-0`, `impeccable-a/long-row.png`, `phone--log-show-upper-0`).
- Fix (`workout_days/_planned_exercise.html.erb`, `workout_logs/show.html.erb`):
  - Remove the chevron `btn-light` (the row is already the link). Add a trailing `fa-chevron-right` 12px `$muted`, with no box.
  - Put the sets chip on the meta line.
  - Move the admin pen and the red × into a ⋯ (`actions_menu`).
  - `.drag-handle { width: 2.75rem; margin-left: -1rem; margin-right: -.5rem }`.
- Command: `/impeccable layout`.

**P1-7. Fields show a green "valid" state on pages nobody submitted, and after a failed login.**

- What: `is-valid` paints the border, a tick and the label in `$success` teal (2.87:1). It shows on `workout_days/new` (Sunday), every edit form, Account, and the sign-in after a wrong password (`impeccable-a/err-signin.png`).
- Why it matters: false status; on a failed login it says the opposite of what happened.
- Fix: in `config/initializers/simple_form_bootstrap.rb` set `config.input_field_valid_class = nil` and remove `valid_class: 'is-valid'` from all wrapper definitions (lines 44, 59, 69, 83, 95, 108, 118, 129, 142, 161).
- Command: `/impeccable harden`.

**P1-8. Changing a preference needs your current password.**

- What: "Start the workout timer automatically" and "Tag the first set as a warm-up" live in Devise's registration form (`devise/registrations/edit.html.erb`), which requires the current password.
- Fix: a separate preferences card on Account with its own form (`PATCH /settings`, `users.timer_auto_start` and `auto_warm_up`), checkboxes that submit on change (the `auto_submit_controller.js` that already exists), and the "Saved." flash.
- Command: `/impeccable clarify`.

### P2 (minor)

**P2-1. A 21-size type scale with sub-pixel clusters.**

- Fix: define `$fs-label: .75rem; $fs-meta: .8125rem; $fs-small: .875rem; $fs-body: 1rem; $fs-title: 1.125rem; $fs-num: 1.375rem; $fs-h1: 1.75rem; $fs-clock: 2.25rem` in `config/_type.scss`, and map each declaration in §3.1 onto these.
- Set `$font-size-base: 1rem`.
- Command: `/impeccable typeset`.

**P2-2. Inter 700 is synthesised (faux bold).**

- Fix: change the font URL to `Inter:wght@400;500;600;700` (`layouts/application.html.erb:12`), or replace the 14 `font-weight: 700` on Inter elements with 600.
- Command: `/impeccable typeset`.

**P2-3. The logged weight and reps are body-sized.**

- Fix: `.set-table td:nth-child(2), .set-table td:nth-child(3) { font-family: $headers-font; font-size: 1.25rem; font-weight: 600 }`, and the unit `kg` in a `<span class="unit">` at `.8125rem $muted`.
- `.order-badge` becomes plain `$muted` 13px, no fill.
- Command: `/impeccable typeset`.

**P2-4. The focus ring is 1.46:1.**

- Fix: `$focus-ring-opacity: 1; $focus-ring-width: 2px; $focus-ring-color: $blue; $input-btn-focus-box-shadow: 0 0 0 2px $surface, 0 0 0 4px $blue`.
- `btn-outline-secondary:focus-visible` must not fill. Better, replace the tag pills (P2-6).
- Command: `/impeccable harden`.

**P2-5. Indigo on everything; five solid indigo blocks on the exercise page.**

- Fix:
  - Note save arrows become `btn-light` with a `$muted` icon, or are removed (P1-1).
  - `.choice-current` becomes `$muted` when "Not set".
  - Pens become `$muted` and turn `$blue` on hover.
  - The active split ring becomes `1px $blue` plus the "Active" badge.
- Command: `/impeccable quieter`.

**P2-6. Three pill languages; tags use Bootstrap grey `#6C757D` (4.37:1).**

- Fix: tags use the `.choices` look at pill radius. Unchecked: `border: 1px solid $line-strong; color: $gray; background: $surface`. Checked: `$primary-soft` background, `$blue` text and border.
- Drop `btn-outline-secondary` from the views (`workout_sets/_set.html.erb:22,62,73`, `_form.html.erb:139,170`).
- Command: `/impeccable polish`.

**P2-7. "Last time" and History count empty logs.**

- What: "Last time · Nov 21 · 0 exercises · 0 sets"; History lists Nov 20 and Nov 21 as "0 exercises · 0 sets" while the calendar says Nov 20 was missed.
- Fix: the Today box's "last time" skips logs with no sets. History marks a timer-only log "Timer only, no sets", or hides empty logs behind "Show empty".
- Command: `/impeccable clarify`.

**P2-8. The calendar has no legend; the extra ring is 2.6:1.**

- Fix: a legend row under the calendar grid (four 10px swatches plus 12px labels). Change `$extra-ring` to `#6E76EA`.
- Command: `/impeccable clarify`.

**P2-9. The flash covers the top bar's back arrow for 5 s after every set.**

- Fix: on phones, `.flash-stack { top: auto; bottom: calc(3.75rem + .75rem + env(safe-area-inset-bottom)) }` below `md`, with the `flash-in` keyframe moving from `translateY(.375rem)`.
- Command: `/impeccable adapt`.

**P2-10. "Delete workout" in the header of every logged workout.**

- Fix: move it to the end of the page (after Details) as `btn btn-link text-danger`, or put it in a header ⋯.
- Command: `/impeccable layout`.

**P2-11. The same workout on two pages with different words and controls.**

- What: "Still to do" vs "From this day, not in this workout"; green vs grey sets chips; pen vs ⋯; chevron-right vs chevron-down; "Add exercise" primary in the header vs `btn-light` full width.
- Fix: one row component and one vocabulary.
- Command: `/impeccable polish`.

**P2-12. Technical error copy.**

- What:
  - "Set not added: Reps completed can't be blank and Reps completed is not a number."
  - "Day must be one of the listed workouts" (field "Workout")
  - "Name has already been taken"
- Fix: custom model messages (`message:`) and `human_attribute_name` ("Reps"), and one message per field.
- Command: `/impeccable clarify`.

**P2-13. Example placeholders read as values; the "–" placeholder looks disabled.**

- Fix: prefix the examples with "e.g." ("e.g. Bench press"). For the weight use `placeholder="kg"`. `$input-placeholder-color: #8A919E` (3.2:1, acceptable for an example placeholder because a label is always present).
- Command: `/impeccable clarify`.

**P2-14. Uneven gaps between cards (40px after the calendar and timer vs 16px).**

- Fix: remove `margin-bottom` from `.calendar-card` (`_dashboard_calendar.scss:2`) and `.timer-card` (`_timer.scss:4`). Let `.card + .card` own the rhythm, or use a `.stack > * + * { margin-top: 1rem }` wrapper.
- Command: `/impeccable layout`.

**P2-15. The exercise page shows no previous session for this exercise.**

- Fix: one muted line above the form, "Last time Wed 18 Nov: 120×8 · 110×8 · 100×10" (13px, tabular). The data is already loaded for the Today box (`pages/_lifts`).
- Command: `/impeccable clarify`.

**P2-16. Admin sub-pages (Equipment, Set tags) have no title, no back arrow and no active tab; the Users row actions touch the card edge.**

- Fix: add `PAGE_TITLES` entries, `back_to edit_user_registration_path`, include `admin/*` in the Account tab's active check (`_bottom_nav.html.erb:7`), and put Users actions in `actions_menu`.
- Command: `/impeccable polish`.

**P2-17. The Equipment form on every exercise page during a workout.**

- Fix: fold it to one row ("Equipment · Machine · Bull ›") with `shared/_list_toggle`, open on demand.
- Command: `/impeccable distill`.

### P3 (polish)

**P3-1. Eyebrows above headings.** There are 12, which `craft-floor.md` bans.
- Fix: remove the `<p class="eyebrow">` lines (§3.1 list), and delete `.eyebrow` (`_layout.scss:32-40`) after moving "This week"'s use to a 13px/600 subheading.
- Command: `/impeccable quieter`.

**P3-2. Rails button labels.**
- Fix: "Create Split", "Update Split", "Create Workout day", "Update Workout day", "Update Exercise" become "Create split", "Save split", "Add workout day", "Save", "Save exercise". Use `f.button :submit, "…"` in `splits/_form`, `workout_days/_form`, `exercises/_form`.
- Command: `/impeccable clarify`.

**P3-3. The required-field `<abbr>` underline renders as ".:".**
- Fix: `abbr[title] { text-decoration: none }`.

**P3-4. Square top corners on table cards (History, Users).**
- Fix: `.card:has(> .app-table), .card:has(> .table-responsive) { overflow: hidden }`.

**P3-5. A stray bottom line under the Exercises card.**
- Fix: no border on the last `.exercise-group-list`.

**P3-6. Inner right edge 8px off in the set table on a phone.**
- Fix: `.set-table td:last-child, .set-table th:last-child { padding-right: 1.25rem }` in `_workout_log.scss:62`, or make the note cell `padding-right: 1.25rem`.

**P3-7. A dangling "·" at line ends in logged-exercise meta.**
- Fix: wrap each meta part in `.time-part`-style `nowrap` spans (the `time_parts` helper already does this for times).

**P3-8. Dates without a weekday in History and Recent ("November 25, 2026").**
- Fix: `"%a %-d %b"` ("Wed 25 Nov"), with the year only when it is not this year.

**P3-9. Recent workouts repeat the active split chip on every row.**
- Fix: show the chip only when the log's split is not the active split.

**P3-10. The two-muted-greys issue.**
- Fix: `$secondary-color: $muted` (or set `--bs-secondary-color` on `:root`).

**P3-11. Dead tokens `$orange` and `$notice`, and a second blue.**
- Fix: delete them, or map `$info` to `$blue`.

**P3-12. "Free weights" wraps in the three-up choices.**
- Fix: label it "Free weight", or `.choices .btn { font-size: .875rem }`.

**P3-13. The Home "Exercises" button sits above today's workout.**
- Fix: move it below Recent workouts, or into Account.

**P3-14. `<title>` is "FitnessApp" on every page, and there is no `theme-color` meta.**
- Fix: `<title><%= [page_title, "FitnessApp"].compact.join(" · ") %></title>` and `<meta name="theme-color" content="#FFFFFF">`.

---

## 6. Cognitive load

Checklist, scored per key screen (a failed item counts 1):

| Item | Home | Workout day | Exercise page |
|------|------|-------------|---------------|
| Single focus | Fail: Exercises button, Today box, active split frame and calendar compete | Pass | **Fail**: sets, tags, notes, rest, note card and equipment |
| Chunking (≤4 per group) | Pass | Pass | Fail: each set row is a group of 5 controls |
| Grouping | Pass (cards) | Pass | Pass |
| Visual hierarchy | Fail: the active-split frame outweighs Continue | Pass: Add exercise is clear | **Fail**: five solid indigo blocks; Add set is not the strongest |
| One thing at a time | Pass | Pass | Pass |
| Minimal choices (≤4) | Fail: about 12 actions above the calendar | Pass, but rows carry 3 to 4 controls | Fail: per set ⋯, Tag, note and arrow, plus Start rest, Add set and 3 tags |
| Working memory | Pass ("last time" shown) | Pass | **Fail**: last session's sets are not on this page; only the last set is pre-filled, with no source label |
| Progressive disclosure | Pass (folds) | Pass | Fail: tag and note controls always open |
| **Failures** | **3, moderate** | **0 to 1, low** | **6, high (critical)** |

**Working-memory rule at the peak moment:** at the exercise page's decision point (log the next set) the lifter sees, in the first viewport:

- 3 sets × (number row, ⋯, Tag, note, arrow)
- the rest line
- the header and date

That is about 17 interactive targets before Add set is even visible. The target is: the last set, the pre-filled form and Add set, with at most 4 items.

---

## 7. Emotional journey

| Moment | What happens | Feeling | Note |
|--------|--------------|---------|------|
| Open app at the gym | Home: big date and "Lower day · Continue" | Oriented, confident | Continue is small and at the top right, 44px |
| Tap Continue | Workout page: Running timer, "In this workout · 2", "Still to do · 5" | Good: a clear map of the session | Rows are crowded; names wrap |
| Open an exercise | Hip thrust: sets table | **Dip**: three tall blocks of Tag and Add a note, no Add set in view | Must scroll about 300px |
| **Log a set (peak)** | Pre-filled 90 / 8 → Add set → flash "Set 4 added." | **High point**: one tap repeats the set; the flash confirms | The flash covers back; Add set slides under the tab bar; next time must scroll again |
| Rest | Start rest → 22px clock "0:00:04" | Neutral | Small clock; an extra tap |
| Next set while resting | Add set → "Your rest timer is running: No rest / Save rest" | **Friction**: a question for the expected case | Third tap |
| Finish | Back to the workout → Stop → confirm | Satisfied: the Finished pill and the total time | No session summary moment (total sets, top set, vs last time) |
| Later, History | List of dates, "Open" | Flat | Empty logs mixed in; "Deleted" confuses |

**Peak-end:** the peak (adding a set) is genuinely good, thanks to pre-fill and instant confirmation. It is surrounded by scroll and confirm friction. The end (Stop) has no payoff: no "Lower done: 6 exercises, 22 sets, top 110 kg, 1 h 3 min" moment. The data exists (`WorkoutSummary`), and a one-card summary after Stop would close the session warmly. That is a suggestion for the owner to accept or decline, since product rules forbid unrequested features.

---

## 8. Persona red flags

### Project persona: "Pedro mid-set". The owner at the gym.

Profile:

- Between sets with 60 to 90 s of rest, sweaty fingers, one hand (the other on a bottle or towel).
- Glancing at the phone from a bench at arm's length.
- Knows the app well, has no patience for dialogs.

Behaviours: repeats the last set, sometimes +2.5 kg; checks what he lifted last time; starts and ignores the rest timer; leaves the app mid-workout and comes back.

Red flags:

- **Add set is not where the thumb is.** It starts below the fold (y=933), slides under the tab bar after each set (632 to 771), and jumps to the top if the URL lacks `?date=`. That is a scroll on most sets, with sweaty thumbs on a scrolling page next to 44px "Tag" and "note" targets.
- **Three taps per set** with rest tracking (Add set, Save rest, Start rest).
- **Numbers too small to read from the bench:** the weight is 15px/400, the rest clock 22px.
- **No "last time" on the exercise page:** he must remember, or go back to Home and expand "Show exercises".
- **A toast over the back button** for 5 s after every set.
- **The tag pills (Assisted, Drop set, Warm-up) sit right under Add set,** 8px below it, also 44px. A slip toggles a tag on the next set without notice. Tagged state is a subtle grey fill.
- **The red × on extra-exercise rows** next to the open chevron on the workout page. The confirm saves him, but it is a scare.

### Casey (distracted mobile)

- Primary actions sit at the top of the screen on Home (Continue, top right), the workout day ("Add exercise", top right of a card) and Splits ("Set as active", top right). Only the modals put the CTA at the bottom (good).
- Coming back mid-workout works: the timer and sets are server state. Good.
- The 36px calendar circles and the pen in History (a 44px target pulled into the line with negative margins) are fine, but the History pen sits 24px from "Open".

### Jordan (first-timer)

- "Split", "U/R/L/U/L", "Plan", "Still to do", "Rest ~min", "Deleted" and "Rest day, trained anyway" need context. The empty Home says "A split is your training program, made of workout days" (good), but the first-run path is: create a split, add workout days one by one via the week circles, plan exercises, then train. Nothing shows that sequence.
- The calendar states are explained only in tooltips, which never show on touch.
- No icon-only nav (good: tabs have labels).

### Sam (accessibility)

- Checkbox and radio borders are 1.14:1, the focus ring 1.46:1, and the extra-day ring 2.6:1.
- The drag handles are `aria-hidden`. On the workout day there is no keyboard alternative to drag between "Still to do" and "In this workout" (opening the exercise and adding a set works, so it is not blocking). Logged workouts have Move up/down in ⋯ (good).
- The calendar meaning is in `title` only (screen readers may read it; sighted touch users cannot).
- Decorative `<i>` icons without `aria-hidden` in `_form.html.erb:161` and `_planned_exercise.html.erb:15,17`.
- Good: real labels on all inputs (including visually hidden ones), `aria-label`s on icon buttons, `role="timer"`, and `aria-current` on tabs.

### Alex (power user)

- Esc cancels a set edit (good). There are no keyboard shortcuts for Add set (Enter in the reps field submits, fine).
- Batch: "Add selected" in the picker (good).
- The dialogs that guard expected paths (rest, paused timer on every add) will annoy.

---

## 9. Strengths

1. **Pre-filled Add set.** Weight and reps come from the last set, so repeating is one tap, with 16px numeric keypads (`inputmode="decimal"` and `"numeric"`) that do not zoom. This is the single best decision in the UI.
2. **The workout timer component.** A status pill (Running with a breathing dot, Paused in amber, Finished in grey), a 32px tabular clock, exact times, Pause / Resume / Stop full width on a phone, and a reduced-motion fallback. It is clear in every state (`timer-row.png`).
3. **Engineering discipline in the styles:**
   - Every colour named by role, with AA notes.
   - Every value commented with its reason.
   - 44px targets under `(pointer: coarse)` only, so desktop stays compact.
   - Safe-area insets.
   - Fixed-strategy dropdowns.
   - Morph with scroll preserve.
   - Its own confirm dialog instead of `confirm()`.
   - This is a strong foundation to restyle on.
4. **Teaching empty states and inline hints:** "Drag an exercise here, or open one and add a set.", "Tap an empty day to add a workout…", "Legs and Lower are the same workout under two names."
5. **Modals done right on a phone:** full-screen with a sticky footer CTA in the thumb zone (Move a workout, Add exercises).

---

## 10. Questions for the owner

1. Should Add set sit *above* today's sets (it never moves), or stay below with the sets made compact? The first is the bigger win for one-handed use.
2. Can the rest be saved automatically when a set is added while the rest timer runs, without asking? And should the rest start by itself after each set (as a setting, like Warm-up)?
3. Should per-set notes and tags move into the set's ⋯ menu (shown only when used), or must they stay one tap away on every set?
4. Is a plain white card on the grey page what you intended? The code comments say "white cards", but cards currently render grey.
5. Should the exercise page show last session's sets for that exercise (the data is already loaded for Home)?
6. A Stop summary card ("Lower done: 22 sets, top 110 kg, 1 h 3 min") is a new feature. Do you want it, or not?
7. Should workouts with no sets (timer only, or opened and left) appear in History and "Last time"?
8. Is Inter staying (the earlier audit left it to you)? If the type scale is reworked (P2-1), it is the moment to decide; adding Inter 700 is needed either way.

---

What I did not check:

- No real phone. Touch was emulated in headless Chrome 390×844 @2x. Native `title` tooltips cannot be seen headless; I read them from the DOM.
- The Edit timer page for a timed log.
- The rest-day state of the Today box (today is not a rest day).
- The cardio timer running.
- Dark mode: the app has none.
- Screen readers.
