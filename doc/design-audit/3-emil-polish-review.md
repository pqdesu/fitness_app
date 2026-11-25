# Emil-style review: interaction polish, motion, mobile feel and worst-case data

Lens: emil-design-eng (main), review-animations + STANDARDS, mobile-native, break-ui (report only), remove-animations / find-animation-opportunities (read-only), apple-design (touch feel).
Repo read only. Paths are relative to the worktree `/home/pedro/code/pqdesu/fitness_app/.claude/worktrees/opus-plan-session-e72fa6`.
Screenshots: the brief's set in `.../scratchpad/shots/png/`, plus mine in `.../scratchpad/shots/emil/` (all 390 CSS px at 2x unless named `wc320-*`, `vp320-*` (320 px) or `wcdesk-*` (1280 px)).

## Overall verdict

The app is careful: 16px inputs, 44px targets, `inputmode` on every number, `viewport-fit=cover` with insets on the navbar and tab bar, tabular-nums on the clocks and tables, a confirm box with a strong ease-out curve, reduced-motion handled for the motion it adds. That part is better than most.

What keeps it from feeling professional and minimalist is mostly three things:
1. **Too much chrome per item.** Each set is three rows (numbers, a 44px "Tag" pill, a full note input with a blue arrow button). Each exercise row has a drag grip, a status chip, a pencil and a separate chevron button. With real data (long names, 14 sets, 17 exercises) that chrome pushes content into a 70px column, words break mid-word, and the page grows to 3,500 to 6,600 px.
2. **Hover and press states are not built for touch.** Ungated `:hover` everywhere (Bootstrap's and the app's), a blue Android tap flash everywhere except the tab bar, and almost no `:active` press feedback outside the timer card, back arrow and tab bar.
3. **Motion is Bootstrap's defaults.** 350ms `ease` collapses, a 300ms modal that drops 50px from above, 500ms flash cards with an `ease-in-out` exit, a 150ms SortableJS slide with no curve. None of it is wrong enough to block; all of it is slower and softer than the confirm box, which is the one piece tuned properly.

---

## P0: blocking

None. Nothing loses data or becomes unreachable at 390 px with realistic data. (Two overflows below come close: P1-1 and P1-2.)

---

## P1: major

### P1-1. A long split name widens the Home page past the phone (horizontal overflow)
- **Where:** `app/assets/stylesheets/components/_lists.scss:36` (`.chip { white-space: nowrap }`), used for the split name chip in Recent workouts (`pages/_recent_workout`) and History (`app/views/workout_logs/index.html.erb:48`).
- **Seen:** `wc-home.png`, `vp-home-recent.png`: the layout viewport becomes 410 px on a 390 px phone (the shot came out 410 wide), so the whole page can be panned sideways. `wc-history.png`: the chip "Push/Pull/Legs + Upper/Lower hybrid (winter cut, 12 we…" is cut off by the table edge with no ellipsis.
- **Data:** split name of 58 characters (limit is 60, `app/models/split.rb:6`).
- **Why:** a nowrap chip with no `max-width` is an unbreakable string.
- **Fix:**
  ```scss
  .chip { max-width: 100%; overflow: hidden; text-overflow: ellipsis; vertical-align: middle; }
  ```
  and add `title="<%= split.name %>"` on the split chip so the full name is reachable. The split name is secondary metadata here: truncate at the end.

### P1-2. Editing a set on a 320 px phone overflows the page by 67 px
- **Where:** `app/views/workout_sets/_set.html.erb:93-113` (the edit bar: Rest select, "min", select, "s", Save, Cancel on one flex row), `app/assets/stylesheets/pages/_workout_log.scss:11,104`.
- **Seen:** `vp320-exercise-editing.png`: the layout viewport jumps to 387 px; Cancel hangs over the card edge, and the card header no longer reaches the right edge. 390 px is fine.
- **Fix:** let the edit bar wrap, with the rest picker on its own line:
  ```scss
  .set-edit-bar { flex-wrap: wrap; row-gap: .5rem; }
  .rest-picker { flex: 1 1 100%; }
  ```
  On 360+ phones it stays on one line in practice; on 320 it wraps instead of overflowing.

### P1-3. Exercise rows squeeze the name into a ~70 px column; words break mid-word
- **Where:** `app/views/workout_days/_planned_exercise.html.erb:4-17` (grip, `.row-link`, status chip, pencil, chevron button) and the logged workout card header `app/views/workout_logs/show.html.erb:55-71` (grip, title, chip, ⋯, chevron). Bootstrap's `.card { word-wrap: break-word }` plus `.row-link { min-width: 0 }` (`components/_row_link.scss:6`) lets the browser break inside words.
- **Seen:** `wc-workout-day.png` and `vp-workout-day-longname.png`: the 74-character name takes 8 lines and the brand 7 more; "Stationar / y bike" breaks mid-word with ordinary catalogue data (no worst case needed). `wc-log-show.png`: the same, and the 300-character exercise note runs 20 lines in that column. `wc320-workout-day.png` is worse.
- **Why:** the trailing controls (chip 70px + pencil 44px + chevron button 44px + gaps 48px) take about 55% of the row. Two of them repeat what the row already does: the whole row is a link to the exercise (`row-link`), and the chevron button links to the same URL (`_planned_exercise.html.erb:17`).
- **Fix (subtract, do not add):**
  1. Remove the chevron button on `_planned_exercise.html.erb:17` (the row is the link; add a 12px muted `fa-chevron-right` inside `.row-link`'s end instead, `aria-hidden`).
  2. Move the admin pencil into the row's ⋯ menu (`actions_menu`), as the logged workout already does.
  3. Put the status ("3 sets", "No sets") under the name in the meta line instead of as a right-hand chip, or keep it right but `flex-shrink: 0` and drop "No sets" (absence already says it).
  4. On `.row-title`: `overflow-wrap: break-word; hyphens: auto;` (not `anywhere`), and on the meta line `display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden;` so a long brand never runs 7 lines.
  Result: the name gets ~270 px instead of ~70 px.

### P1-4. A set is three rows of chrome; notes are unreadable in a one-line input
- **Where:** `app/views/workout_sets/_set.html.erb:55-87`: every set renders a "Tag" pill button (44px tall on touch, `_layout.scss:90`) and a full-width note input with a primary blue submit button.
- **Seen:** `phone--today-exercise-hip-thrust.png` (3 sets ≈ 1,000 px), `wc-exercise-page.png` (14 sets = 3,534 px), `vp-exercise-top.png`: the 158-character note shows "Left knee felt off on the last two reps" and the rest is hidden inside a single-line `<input>`; there is no way to read it without tapping into the field and scrolling text.
- **Why (Emil):** at the gym the set row is the most-seen surface in the app. Fourteen blue arrow buttons and fourteen outlined pills are noise; the data (weight × reps) is the smallest thing on screen.
- **Fix:**
  - Show the note as text when it exists (`<p class="set-note-text">`, `font-size: .875rem; color: $muted; overflow-wrap: break-word`), and put "Note" and "Tag" as items in the set's existing ⋯ menu. Editing a note opens the row-edit state that already exists (`row_edit_controller.js`).
  - Tag chips stay as they are (they are data); the "Tag" button goes into the ⋯ menu.
  - If the owner wants the note field always there, at least make it a `<textarea rows="1">` with `field-sizing: content` (Chrome 123+, Safari 18.4+; falls back to one line) and a quiet ghost submit (`btn-link`, muted arrow) instead of `btn-primary`.
  Expected effect: a set becomes one 48px row (two with a note), 14 sets ≈ 700 px instead of 3,500.

### P1-5. Sticky hover on touch: a tag pill you untick still looks ticked
- **Where:** Bootstrap `.btn-outline-secondary:hover` (filled grey, white text) used for the tag pills (`workout_sets/_form.html.erb:55`, `_set.html.erb:73`) and `.btn-outline-primary:hover` for the choice pills (`components/_choices.scss`). Bootstrap's hover rules are not gated.
- **Why:** on a phone the first tap applies `:hover` and leaves it there. Ticking a tag fills it (checked), unticking it leaves it filled (hover), so the pill lies about its state until the user taps elsewhere. Same for "Free weights / Machine / Bodyweight".
- **Fix:** turn Bootstrap's hover off on touch, once, after `@import "bootstrap"`:
  ```scss
  @media (hover: none) {
    .btn:hover { color: var(--bs-btn-color); background-color: var(--bs-btn-bg); border-color: var(--bs-btn-border-color); }
    .btn-check:checked + .btn:hover { color: var(--bs-btn-active-color); background-color: var(--bs-btn-active-bg); border-color: var(--bs-btn-active-border-color); }
  }
  ```
  and gate the app's own hovers (list in P2-1).

### P1-6. No press feedback on almost anything; Android paints a blue tap flash instead
- **Where:** `-webkit-tap-highlight-color: transparent` exists only on `.bottom-nav-item` (`components/_bottom_nav.scss:25`). Computed on `<html>`: `rgba(51,181,229,.4)` (the default flash). `:active` scale exists only on `.back-link` (`_layout.scss:60`), `.bottom-nav-item` (`_bottom_nav.scss:28`) and `.timer-card .btn` (`_timer.scss:118-123`). Every other button (Add set, Continue, Add exercise, Save, ⋯, pills, chevrons, row links) only changes colour on `:active`, on Bootstrap's 150ms `ease-in-out`.
- **Why:** feedback must land on pointer-down (apple-design §1). The timer card shows the pattern is already known; it is just not global.
- **Fix** (one block, `components/_layout.scss`):
  ```scss
  html { -webkit-tap-highlight-color: transparent; }
  .btn, .bottom-nav-item, .back-link, .lift-pill, .recent-toggle, .choice-summary, .row-link {
    touch-action: manipulation;
    transition: color .15s ease, background-color .15s ease, border-color .15s ease, box-shadow .15s ease,
                transform .16s cubic-bezier(.23, 1, .32, 1);
  }
  .btn:active, .lift-pill:active, .choice-summary:active { transform: scale(.97); }
  .row-link:active, .recent-toggle:active { background: rgba($blue, .04); } // rows: tint, not scale
  @media (prefers-reduced-motion: reduce) { .btn:active, .lift-pill:active, .choice-summary:active { transform: none; } }
  ```
  Then delete the timer-specific copy (`_timer.scss:116-128`). Do not scale `.btn-check + .btn` pills inside a grid by more than .97.

### P1-7. The confirm box always shows a trash can, even for "Stop the timer?"
- **Where:** `app/views/shared/_confirm.html.erb:5` (fixed `fa-trash-can`), `app/javascript/confirm_dialog.js:24` (button says "Yes" for anything not Delete/Remove).
- **Seen:** `wc-workout-day--confirm.png`: "Stop the timer? It can't be resumed after." with a red trash icon and a red "Yes".
- **Why:** the icon is the first thing read; a bin says "something gets deleted". "Yes" is the weakest possible verb.
- **Fix:** let the message carry the verb and icon: in `confirm_dialog.js`, map the first word (`Delete|Remove` → trash, `Stop` → `fa-stop`, else `fa-circle-question`) and use that word as the button label ("Stop", "Delete", "Remove"); only fall back to "Yes" when the first word is not a verb. Swap the icon class on `[data-confirm-icon]`.

### P1-8. Full-screen picker modal: footer button sits in the home-indicator zone
- **Where:** `app/views/shared/_exercise_picker.html.erb:12` (`modal-fullscreen-sm-down`), no safe-area padding on `.modal-footer`.
- **Seen:** `phone--today-workout-lower--picker.png`: "Add selected" is flush with the bottom edge. With `viewport-fit=cover` (layout line 5) an iPhone draws the home indicator over it when Safari's toolbar is collapsed, and always in standalone.
- **Fix:**
  ```scss
  .modal-fullscreen-sm-down .modal-footer { padding-bottom: calc(.75rem + env(safe-area-inset-bottom, 0px)); }
  .modal-fullscreen-sm-down .modal-header { padding-top: calc(1rem + env(safe-area-inset-top, 0px)); }
  .modal-body { overscroll-behavior: contain; } // the page behind does not scroll when the list ends
  ```
  Needs a real iPhone to confirm.

---

## P2: minor

### P2-1. Ungated hover rules (sticky on touch)
| Before | After | Why |
| --- | --- | --- |
| `a.card-link:hover { border-color; box-shadow 0 6px 20px; transform: translateY(-1px) }` (`components/_cards.scss:33-39`) | Inside `@media (hover: hover) and (pointer: fine)`, and drop the lift and shadow: `border-color: rgba($blue,.4)` only, `transition: border-color .15s ease` | A tapped split card stays lifted and blue-shadowed on a phone; lift-on-hover is decoration on a tens/day surface |
| `div.card-link:hover` (`pages/_splits_cards.scss:15-18`) | Same gate | Sticky blue border |
| `.week-day:hover .week-circle { border-color: $blue }` (`pages/_split_week.scss:48`) | Move into the existing `@media (hover: hover)` on line 49, and make it `(hover: hover) and (pointer: fine)` | The halo is gated, the border is not: tapping a grey day leaves it blue-ringed |
| `.has-workout:hover { background: $blue; color: white }` (`pages/_dashboard_calendar.scss:74,85`) | Gate `:hover` (keep `:focus-visible` ungated) | Fills the day blue on tap, before navigation |
| `.recent-toggle:hover { background: $primary-soft }` (`pages/_dashboard_recent.scss:22`) | Gate | Row stays tinted after it is opened and closed |
| `button.lift-pill:hover`, `a.chip:hover`, `a.row-title:hover`, `.row-link:hover .row-title`, `.eyebrow a:hover`, `.back-link:hover`, `.btn-light:hover`, `.flash-close:hover`, `.actions-toggle:hover`, `.nav-link:hover` | One gate per file: `@media (hover: hover) and (pointer: fine) { … }` | The back arrow in particular stays tinted indigo after a tap, then Turbo restores the page from cache with it still tinted |
| `.calendar-day` halo `@media (hover: hover)` (`_dashboard_calendar.scss:55`) | `(hover: hover) and (pointer: fine)` | Some Android phones report `hover: hover` with a coarse pointer |

### P2-2. Bootstrap collapse: 350ms `ease`, used on every fold
- **Where:** Bootstrap default `$transition-collapse: height .35s ease`, used by fold cards, list toggles, the calendar, Recent workouts, tag lists, choice folds.
- **Why:** over the 300ms budget, a weak curve, and these folds are opened tens of times per session.
- **Fix:** in `config/_bootstrap_variables.scss`: `$transition-collapse: height .22s cubic-bezier(.23, 1, .32, 1);` (height animation of an accordion is the documented exception to "compositor-only"). Bootstrap's reduced-motion already sets it to none (verified: `.collapsing` computes `transition: none` under reduce).
- The chevrons (`_list_toggle.scss:22,43,58`, `_dashboard_calendar.scss:15`, `_dashboard_recent.scss:23,59`, `_choices.scss:42`) rotate in `.2s ease`: make them `transform .22s cubic-bezier(.23,1,.32,1)` so the arrow lands with the panel. Define once: `$ease-out: cubic-bezier(.23, 1, .32, 1); $dur-fold: .22s;` in `config/` and reuse (today the confirm box and timer each hard-code the curve).

### P2-3. Modals drop 50px from above in 300ms
- **Where:** Bootstrap default `$modal-fade-transform: translate(0, -50px)`, `$modal-transition: transform .3s ease-out`; used by the picker, Move a workout, rest-day pop-ups, timer alerts. The confirm box already overrides it well (`components/_confirm.scss:59-62`).
- **Fix:** centred dialogs match the confirm box: `$modal-fade-transform: scale(.96); $modal-transition: transform .2s cubic-bezier(.23, 1, .32, 1);` (then delete the confirm-specific override, it becomes the default). The full-screen picker on a phone should rise as a sheet: 
  ```scss
  @include media-breakpoint-down(sm) {
    .modal.fade .modal-fullscreen-sm-down { transform: translateY(1.5rem); transition: transform .3s cubic-bezier(.32, .72, 0, 1); }
    .modal.show .modal-fullscreen-sm-down { transform: none; }
  }
  ```
- `.modal-backdrop.show { backdrop-filter: blur(2px) }` (`_confirm.scss:71`): a full-viewport blur is the most expensive thing in the app on an older phone and adds little at 2px over a .45 tint. Remove it.

### P2-4. Flash cards: 500ms in, 500ms `ease-in-out` out, keyframes
- **Where:** `components/_flash.scss:34,36,95-101`; `flash_controller.js:53` waits 600ms.
- **Fix:**
  | Before | After | Why |
  | --- | --- | --- |
  | `animation: flash-in .5s ease-out` | `animation: flash-in .32s cubic-bezier(.23,1,.32,1)` | Toast budget is ~400ms; this one carries a status the user is waiting for |
  | `&.is-leaving { animation: flash-out .5s ease-in-out forwards }` | `animation: flash-out .2s ease-out forwards` | Exit faster than enter; ease-in-out delays the start |
  | `translateY(-.375rem)` | `translateY(-.75rem)` (from above, the edge it lives on) | 6px reads as a fade with a wobble, not a drop from the top |
  | `setTimeout(remove, 600)` | `setTimeout(remove, 250)` | Keep in step with the shorter exit |
  | Reduced motion: `animation: none` | Keep a 150ms opacity fade (`@keyframes flash-fade { from { opacity: 0 } }`) | Reduced motion means gentler, not none |
- `.flash-timer` (3px bar, `_flash.scss:78-89`): decorative on a 5s notice that already pauses on hover/focus. For minimalism, delete it (the controller's pause logic stays).
- **Placement:** `wc-exercise-page--flash.png` shows the card covering the back arrow for 5 seconds (`.flash-stack top: .75rem` over the sticky navbar). Either start the stack under the navbar on phones (`top: calc(4rem + env(safe-area-inset-top))`) or keep it but shorten notices to 3s; the back button is the most-tapped control after a save.

### P2-5. Drag and drop: 150ms with the default curve, no "picked up" state
- **Where:** `app/javascript/controllers/sortable_controller.js:18`, `components/_lists.scss:82-91`.
- **Fix:** `animation: 200, easing: "cubic-bezier(0.23, 1, 0.32, 1)"` (siblings make room in an ease-out). Add `.sortable-chosen .drag-handle { color: $blue }` so the grip reacts on press before the drag starts (pointer-down feedback). The lifted copy (`.sortable-drag` shadow `0 .75rem 1.75rem rgba($shadow,.18)`) is right; add `transform: scale(1.02)` to it for the "lifted" read. `delayOnTouchOnly` is not needed: the handle already owns the gesture (`touch-action: none`, `_lists.scss:77`), which is correct.
- `.just-moved` (`_lists.scss:61-62`): 1.6s background fade. Keep (it has a purpose: the eye follows the row), shorten to 1.2s `ease-out`. It is a colour fade, so it is fine under reduced motion.

### P2-6. No theme-color, no manifest: the app cannot feel installed
- **Where:** `app/views/layouts/application.html.erb:3-14`. Probed: no `meta[name=theme-color]`, no `link[rel=manifest]`, no `apple-mobile-web-app-*`. `public/apple-touch-icon.png` exists (iOS finds it by path).
- **Why:** used at the gym every day from the home screen, this app is the textbook case for standalone mode: no URL bar, the bottom tab bar where the thumb is, and the navbar colour in the status bar.
- **Fix:**
  ```html
  <meta name="theme-color" content="#ffffff">
  <meta name="apple-mobile-web-app-capable" content="yes">
  <meta name="apple-mobile-web-app-status-bar-style" content="default">
  <link rel="manifest" href="/manifest.json">
  ```
  Rails 8 ships `app/views/pwa/manifest.json.erb` and the route (`get "manifest" => "rails/pwa#manifest"`); enable it with `display: "standalone"`, `theme_color: "#ffffff"`, `background_color: "#F6F7F9"`. Also drop `shrink-to-fit=no` from the viewport (iOS 9 only). The app has no dark mode, so one theme-color is enough.

### P2-7. Turbo's progress bar is the wrong blue
- Probed `.turbo-progress-bar` computes `rgb(0,118,255)` (Turbo's default), not the app's indigo `#4F46E5`.
- **Fix:** `.turbo-progress-bar { height: 2px; background: $blue; }`.

### P2-8. Numbers break mid-figure and have no separators
- **Seen:** `wc-home.png` / `vp-home-week.png`: "Top weight 99999. / 125 kg" wraps inside the number (`pages/_dashboard_week.scss:19-27`, a quarter of a 4-column grid); same in `wc-month.png` totals. `vp-exercise-top.png`: "1234.125 kg", "99999.125 kg" with no thousands separator.
- **Data:** weight 99999.125 is accepted by the model (`workout_set.rb:23`, < 100,000).
- **Fix:** `.week-summary dd { white-space: nowrap; }` and let the figure shrink instead: `font-size: clamp(1rem, 5vw, 1.25rem)`. Format weights with `number_with_delimiter` / `number_with_precision(strip_insignificant_zeros: true, delimiter: ",")` in `format_weight` so it reads "1,234.125 kg". Never truncate numbers.

### P2-9. The Tag pill and the tag chips sit on one line at two heights
- **Seen:** `vp-exercise-top.png`: chips "Assisted / Drop set / Warm-up" are 22px tall, the "Tag" button beside them is 44px (coarse-pointer `btn-sm` padding, `_layout.scss:90`), an outlined grey pill. The row looks misaligned and the button is the loudest thing on it.
- **Fix:** if it stays (see P1-4), make it a chip-height ghost: `.set-tag-toggle { min-width: 0; padding: .125rem .625rem; border-style: dashed; border-color: $line-strong; }` with a 44px hit area through `::before { content:""; position:absolute; inset:-11px 0; }`.

### P2-10. Paused-timer and rest alerts, confirm: button verbs and icons
- Covered for the confirm box in P1-7. The paused-timer alert (`workout_logs/_timer_alert`) uses the blue icon well (`_timer.scss:145-148`). Keep.

### P2-11. Disabled state during Turbo submits
- Turbo disables the submitter while the request runs; Bootstrap then paints it at `opacity: .65`. On a fast LAN that is a one-frame grey flash on every Add set, which reads as a glitch, not a state. On a slow gym connection there is no other sign.
- **Fix:** `form[aria-busy="true"] .btn:disabled { opacity: 1; cursor: progress; }` (Turbo sets `aria-busy` on the form) plus the themed progress bar (P2-7) for anything over 500ms. Optional, nice: `data-turbo-submits-with="Adding…"` on Add set only. (Moderate confidence on Turbo's exact disable timing; verify in DevTools with network throttling.)

### P2-12. The workout day page header and the exercise page repeat counts and dates
- `phone--today-workout-lower.png`: "Today · Wednesday, November 25 / 2 exercises · 5 sets" under the title, then "In this workout · 2". `wc-workout-day.png`: "1 exercise · 14 sets" above a list headed "In this workout · 17": the two counts disagree in meaning (exercises with sets vs exercises in the workout). Drop the header count line; the card heading carries it.
- `phone--today-exercise-hip-thrust.png`: "Today / November 25, 2026" card header on a page reached from today's workout. Drop the date (the back trail already says where you are) or keep "Today" only.

### P2-13. Picker modal: nine outlined blue pills and no search
- `phone--today-workout-lower--picker.png`: the muscle-group pills are 9 blue outlined buttons with a filled one; this is the loudest block in the app. Make unselected pills neutral (`btn-light`, `$chip-text`), only the checked one blue. A search field at the top of the list (filtering rows client-side, `type="search" enterkeyhint="search"`) would cut taps more than any motion change; flagging, not proposing as motion.

---

## P3: polish

| # | Before | After | Why |
| --- | --- | --- | --- |
| 1 | `.back-link:active { transform: scale(.94) }` with no `transform` in its `transition` (`_layout.scss:57,60`) | add `transform .16s cubic-bezier(.23,1,.32,1)`; scale `.96` | It snaps in and out; it should give and release |
| 2 | `.bottom-nav-item { transition: color .15s, transform .1s }`, `:active scale(.94)` (`_bottom_nav.scss:26,28`) | `transform .12s cubic-bezier(.23,1,.32,1)`, `scale(.96)`; add `-webkit-touch-callout: none; user-select: none` | Tab bar is tapped 100+ times a day: subtle and fast; long-press should not open the link callout |
| 3 | No active indicator motion on the tab bar | Leave it instant | 100+/day navigation: no animation, correct as is |
| 4 | `.timer-status::before` breathing dot, `2s ease-in-out infinite`, opacity (`_timer.scss:53`) | Keep; it is state indication, opacity only, and reduced motion stops it (`:126`) | Passes the gate |
| 5 | `.timer-clock` font-variant-numeric: tabular-nums (`_timer.scss:71`), `.rest-clock` (`_workout_log.scss:100`) | Keep; also add `tabular-nums` to `.timer-meta` (paused time counts up in it, `.timer-paused` has it but "Started" line does not) and `.history-counts` | No jitter while counting |
| 6 | Set table numbers left-aligned (`td` computes `text-align: start`) | Right-align Weight with `tabular-nums`, header too: `.set-table td:nth-child(2), th:nth-child(2) { text-align: end; padding-right: 1.5rem }` | 0.5 kg, 35 kg and 1,234.125 kg line up on the decimal side |
| 7 | `.order-badge` set numbers in indigo on indigo-soft (`_lists.scss:45-56`) | Plain muted numerals, no badge: `color: $muted; font-weight: 600; background: none` | Set numbers are an index, not a status; one less tinted shape per row |
| 8 | Borders `$line: #E6E8EC` opaque everywhere (`config/_colors.scss:14`) | `rgba(#101828, .08)` | A semi-transparent border reads the same on white cards, the `#F6F7F9` page, the tinted current-week row and `.just-moved` |
| 9 | Radii: 8 (inputs sm), 10 (btn, input), 12 (choice-summary, sortable-drag), 14 (lg), 16 (card, flash), 24 (confirm), pill | 3 steps: 10 controls, 16 cards and sheets, pill only for chips/status | Fewer radii read as one system |
| 10 | Card shadow `0 1px 2px rgba(.04)` + 1px border (`_cards.scss:3`) | Keep one of them: border only on the gray page, or shadow `0 0 0 1px rgba(16,24,40,.06), 0 1px 2px rgba(16,24,40,.04)` and no border | Border + shadow doubles the edge |
| 11 | Active split card: `border-color: $blue; box-shadow: 0 0 0 2px $blue` (`_splits_cards.scss:6-9`), and on Home the same 2px indigo ring (`phone--home.png`) | `box-shadow: 0 0 0 1.5px rgba($blue,.5)` or just the "Active" badge | The thick ring is the loudest frame on Home and the split list |
| 12 | `h1` no `text-wrap` (computed `wrap`) | `h1, h2, .row-title { text-wrap: balance } p, .entry-note { text-wrap: pretty }` | The 74-char exercise title breaks "…with rope and / a pause at the top" unevenly (`vp-exercise-top.png`) |
| 13 | `.picker-group` uppercase `.04em` (`_exercise_picker.scss:10`) | `.06em` and `font-size: .7rem` | Uppercase at 12px wants a touch more tracking |
| 14 | `.page-header h1 { letter-spacing: -.02em }` at 28px | `-.025em` at 28px, and `-.01em` on h2 1.05rem | Plus Jakarta tightens well at display sizes |
| 15 | Icons in buttons at `.85em` with `margin-right: .25rem` (`_layout.scss:75`) | `.875em`, `margin-right: .375rem`, `vertical-align: -.0625em` | Font Awesome solid glyphs sit high next to Inter caps |
| 16 | The pencil (`fa-pen`, solid, blue) per row (`_planned_exercise.html.erb:15`) | Move to ⋯ (P1-3); if kept, muted colour | Blue is for the primary action |
| 17 | `.calendar-day` `title` tooltip only | Fine on desktop; on touch the dotted/filled states need the legend: one muted line under the calendar | Native `title` never shows on a phone |
| 18 | Viewport `shrink-to-fit=no` | Remove | Obsolete (iOS 9) |
| 19 | `html` `overscroll-behavior: auto` | Keep on the page (pull-to-refresh is useful in a document app); `contain` on `.modal-body` and `.dropdown-menu` | Stops the page scrolling behind a list that ended |
| 20 | Dropdown (⋯ menu) opens with no motion (`ActionsMenuHelper#actions_menu`, Popper fixed) | Keep instant | Tens/day; an animated menu here would only slow the edit |
| 21 | `.week-circle` `transition: border-color .15s, background-color .15s, outline-color .15s` (`_split_week.scss:34`) | `.15s ease` explicitly; fine | Hover/colour → `ease` |
| 22 | `transition: background .15s` on `.recent-toggle` (`_dashboard_recent.scss:20`) | `background-color .15s ease` | Name the property |
| 23 | Empty states (`components/_empty_state.scss`) | Fine: muted icon `$icon-faint`, short copy. No skeletons needed: pages are server-rendered | — |
| 24 | `.flash-close`, ⋯, pencil: 44px targets | Keep | Correct |

---

## Motion inventory (every transition, animation and keyframes)

| # | Where | What | Property | Duration / easing | Verdict |
| --- | --- | --- | --- | --- | --- |
| 1 | `_layout.scss:57` `.back-link` | hover/focus tint | color, bg, border | .15s ease | Gate hover; add transform (P3-1) |
| 2 | `_layout.scss:60` `.back-link:active` | press | transform scale(.94) | none (snaps) | Retune: .16s strong ease-out, .96 |
| 3 | `_bottom_nav.scss:26,28` | tab press | color, transform | .15s / .1s ease | Retune to .12s strong ease-out, .96 |
| 4 | `_bottom_nav.scss:53` | active pill bg | background-color | .15s ease | Keep (or remove: tab changes are page loads, it never animates in practice) |
| 5 | `_cards.scss:33` `a.card-link` | hover lift | border, box-shadow, transform | .15s ease | Remove lift and shadow, gate (P2-1) |
| 6 | `_splits_cards.scss:16` `div.card-link` | hover border | border, shadow | .15s | Gate |
| 7 | `_flash.scss:34` | flash in | opacity + translateY (keyframes) | .5s ease-out | Retune .32s strong ease-out (P2-4) |
| 8 | `_flash.scss:36` | flash out | opacity + translateY | .5s ease-in-out | Retune .2s ease-out |
| 9 | `_flash.scss:88` | 5s countdown bar | transform scaleX | 5s linear | Remove (decoration) or keep; linear is right for progress |
| 10 | `_confirm.scss:59-62` | confirm box in/out | transform scale(.96) | .2s cubic-bezier(.23,1,.32,1) | The model to copy; make it the Bootstrap default |
| 11 | `_confirm.scss:71` | backdrop blur | backdrop-filter | (Bootstrap fade .15s linear) | Remove the blur |
| 12 | `_timer.scss:53` | live dot | opacity keyframes | 2s ease-in-out infinite | Keep (state), reduced-motion handled |
| 13 | `_timer.scss:118-123` | timer buttons press | transform scale(.97) | .16s strong ease-out | Correct; make global (P1-6) |
| 14 | `_lists.scss:61` `.just-moved` | moved-row highlight | background-color keyframes | 1.6s ease-out | Keep, 1.2s |
| 15 | `_list_toggle.scss:22,43,58` | chevron rotate | transform | .2s ease | Retune .22s strong ease-out |
| 16 | `_dashboard_calendar.scss:15` | chevron | transform | .2s ease | Same |
| 17 | `_dashboard_calendar.scss:54` | day halo | outline-color | .15s ease | Keep, gate `pointer: fine` |
| 18 | `_dashboard_calendar.scss:72` | logged day fill on hover | background, color | .15s ease | Gate hover |
| 19 | `_dashboard_recent.scss:20,23,59` | row tint, chevrons | background, transform | .15s / .2s | Gate hover; chevrons retune |
| 20 | `_choices.scss:42` | chevron | transform | .2s | Retune |
| 21 | `_split_week.scss:34` | week circle | border, bg, outline | .15s | Keep, gate the border hover |
| 22 | Bootstrap `.collapsing` | every fold | height | .35s ease | Retune .22s strong ease-out (P2-2) |
| 23 | Bootstrap `.modal.fade .modal-dialog` | every modal | transform translateY(-50px) | .3s ease-out | Retune scale(.96) .2s; picker as sheet (P2-3) |
| 24 | Bootstrap `.fade` | modal/backdrop opacity | opacity | .15s linear | Keep |
| 25 | Bootstrap `.btn` | colour states | color, bg, border, shadow | .15s ease-in-out | Add transform; `ease` for colour |
| 26 | Bootstrap `.form-control` | focus ring | border, box-shadow | .15s ease-in-out | Keep |
| 27 | `sortable_controller.js:18` | siblings make room | transform (SortableJS) | 150ms, no easing set | 200ms strong ease-out (P2-5) |
| 28 | `flash_controller.js:53` | removal wait | setTimeout 600 | — | 250 with the shorter exit |
| 29 | `timer_controller.js:12` | clock tick | textContent, 1s interval | — | Not motion; fine. Note `setInterval(1000)` drifts and can skip a second when the tab is throttled: align to the next whole second with `setTimeout(tick, 1000 - (Date.now() % 1000))` |

Prefers-reduced-motion: handled for flash, confirm box, timer dot and button press, and by Bootstrap for collapse, modal and fade (verified: `.collapsing` and `.modal-dialog` compute `transition: none` under reduce). Missing: card lift (`_cards.scss:38`) and back/tab-bar scale; both become moot with P1-6 and P2-1.

### What to remove (remove-animations gate)
1. Card hover lift and shadow growth (`_cards.scss:35-39`): tens/day, decoration, sticky on touch.
2. Backdrop blur (`_confirm.scss:71`): cost with no purpose.
3. The flash countdown bar (`_flash.scss:78-92`): decoration; the pause-on-hover logic is the useful part.

### Where motion would genuinely help (find-animation-opportunities, few on purpose)
| # | Location | Today | Purpose | Frequency | Suggested motion |
| --- | --- | --- | --- | --- | --- |
| 1 | New set row after Add set (`workout_sets/_set`, page morph) | The row appears with no sign it is new; the flash says "Set 4 added" at the top of the screen, far from the thumb | Feedback, preventing a jarring change | Tens per workout | Reuse `.just-moved`: give the new set's `tbody` the class via `flash[:moved]`-style id, a 600ms `background-color` fade from `$primary-soft` (colour only, no slide). Then the "Set n added" notice can go: the row itself confirms it |
| 2 | Timer Start → Running (`workout_logs/_timer`) | The card swaps state on reload | State indication | Once per workout | `@starting-style` on `.is-running .timer-status`: `opacity: 0; transform: scale(.96)` → settled, `transition: opacity .2s ease-out, transform .2s cubic-bezier(.23,1,.32,1)` |
| 3 | Rest timer Start/Stop (`workout_sets/_rest_timer`) | Swap | State indication | Tens per workout | Nothing beyond the global press scale: frequency too high |
| 4 | Full-screen picker on phone | Drops from above | Spatial consistency | Few per workout | Rise 1.5rem with the drawer curve (P2-3) |

Rejected: animating the ⋯ menu, tab bar changes, calendar month fold beyond the collapse retune, chips, counts ticking up, the week strip. All are frequent or functional.

---

## Mobile-native checklist

| Item | State | Evidence | Action |
| --- | --- | --- | --- |
| viewport meta | `width=device-width, initial-scale=1, shrink-to-fit=no, viewport-fit=cover` | layout:5 | Drop `shrink-to-fit=no`; consider `interactive-widget=resizes-content` so Android's keyboard does not cover Add set |
| Zoom allowed | Yes (no `maximum-scale`) | layout:5 | Good |
| Input font ≥ 16px | Yes, all `.form-control`/`.form-select` incl. `-sm` compute 16px | `_bootstrap_variables.scss:12-13`, probed | Good |
| inputmode | `decimal` on weights/incline/speed, `numeric` on reps/minutes/seconds | `_form.html.erb:26,31,37`, `_set.html.erb:24,30,38`, cardio forms | Good. Add `enterkeyhint="done"` on reps and `enterkeyhint="send"` on notes |
| 100vh vs dvh | No `vh` anywhere | grep | Good |
| Safe areas | Navbar top, tab bar bottom, body left/right, back arrow, flash top | `_navbar.scss:5`, `_bottom_nav.scss:8-9`, `_layout.scss:4-7,67-68`, `_flash.scss:6` | Missing on full-screen modal header/footer (P1-8) |
| Tap highlight | Only the tab bar | `_bottom_nav.scss:25` | Global (P1-6) |
| touch-action | `none` on drag handles only; buttons `auto` | `_lists.scss:77`, probed | `manipulation` on controls (P1-6) |
| user-select | Bootstrap `.btn` none; drag handle none; links-as-controls (tab bar, row links) selectable | probed | Add to `.bottom-nav-item` (P3-2) |
| Sticky hover | Many ungated (P1-5, P2-1) | — | Gate |
| overscroll | `auto` | probed | `contain` in modal bodies (P1-8) |
| theme-color | Missing | probed | Add (P2-6) |
| Manifest / standalone | Missing | probed | Add (P2-6) |
| Real device | Not tested | — | Sticky hover, tap flash, safe areas and the keyboard over Add set need an iPhone and an Android phone |

---

## Worst-case data (break-ui, report only)

Created through the running app on port 3001 (requests from the logged-in page, plus two `rails runner` updates on the audit database only: timer backdated 3 h 4 min with 12 min 34 s paused, one set given a 3 h 2 min rest and all three tags, and the long logged exercise linked to its plan row so the exercise page shows its sets).

| Field | Limit (source) | Worst case used |
| --- | --- | --- |
| Exercise name | 80 (`exercise.rb:29`) | "Single-arm cable rear delt fly, kneeling, with rope and a pause at the top" (74) |
| Machine brand | 60 (`equipped.rb:19`) | "Hammer Strength by Life Fitness, Plate-Loaded Iso-Lateral" (57) |
| Split name | 60 (`split.rb:6`) | "Push/Pull/Legs + Upper/Lower hybrid (winter cut, 12 weeks)" (58) |
| Weight | ±100,000 (`workout_set.rb:23`) | 1234.125, 99999.125, 0.5, empty |
| Reps | none found | 999, 1 |
| Set note | 200 (`workout_set.rb:32`) | 158-char sentence |
| Logged exercise note | 500 | 300-char paragraph |
| Sets on one exercise | none | 14 |
| Exercises in a workout | none | 17 (incl. 4 cardio) |
| Timer | — | running 2 h 52 min, paused 12 min 34 s; rest 3 h 2 min 5 s |
| Flash message | none | "Barbell curl, Barbell row, … and Upper back row added to this workout." (16 names) |

| # | Severity | Field | What happens | Screenshot | Fix |
| --- | --- | --- | --- | --- | --- |
| 1 | Broken | split name chip | Home page 410 px wide on a 390 phone; History chip clipped with no ellipsis | `wc-home.png`, `vp-home-recent.png`, `wc-history.png` | P1-1 |
| 2 | Broken | set edit bar at 320 px | Page widens to 387 px | `vp320-exercise-editing.png` | P1-2 |
| 3 | Ugly | exercise name + brand in rows | 8 + 7 lines in a 70 px column; "Stationar/y bike" breaks mid-word even with catalogue data | `wc-workout-day.png`, `vp-workout-day-longname.png`, `wc-log-show.png`, `wc320-workout-day.png` | P1-3 |
| 4 | Broken (content unreadable) | set note | 158-char note hidden in a one-line input | `vp-exercise-top.png` | P1-4 |
| 5 | Ugly | logged exercise note | 20-line column in the card header | `wc-log-show.png` | P1-3; clamp to 2 lines with "more" in the open card |
| 6 | Ugly | top weight 99999.125 | "99999. / 125 kg" wraps inside the figure | `wc-home.png`, `wc-month.png` | P2-8 |
| 7 | Ugly | weights ≥ 1000 | "1234.125 kg" with no separator | `vp-exercise-top.png` | P2-8 |
| 8 | Ugly | 14 sets | Exercise page 3,534 px tall; 14 blue arrow buttons | `wc-exercise-page.png` | P1-4 |
| 9 | Ugly | 17 exercises | Workout page 6,000 px; log page 6,642 px | `wc-workout-day.png`, `wc-log-show.png`, `wc-log-show--expanded.png` | P1-3 (rows shrink to ~64 px each) |
| 10 | Fragile | header counts | "1 exercise · 14 sets" above "In this workout · 17" | `vp-workout-day-longname.png` | P2-12 |
| 11 | Fragile | rest picker | 3 h rest makes the minutes select list 0-182 | `vp320-exercise-editing.png` | Cap display at 30 + "longer" or show the value as text |
| 12 | Fine | long exercise name as page title | Wraps on 3 lines, readable; balance would help | `vp-exercise-top.png` | P3-12 |
| 13 | Fine | long split name on Splits and Month | Wraps cleanly in the card title and the month list | `wc-splits.png`, `wc-month.png` | — |
| 14 | Fine | long flash message | `overflow-wrap: anywhere` on `.flash-text`, card grows | (seen in the seed responses; the flash card wraps) | — |
| 15 | Fine | 3-hour timer | "2:52:20" and "paused 12 min 34 s" fit; clock is tabular | `wc-workout-day.png` | — |
| 16 | Fine | 1 rep, 0.5 kg | Render fine | `wc-exercise-page.png` | — |
| 17 | Fine | 999 reps, 1234.125 kg in the set row | Fits at 390 and 320 | `vp-exercise-top.png`, `wc320-exercise-page.png` | Right-align (P3-6) |

Not checked: RTL, dark mode (the app has neither), 200% browser zoom, non-Latin names.

---

## The 10 changes that would make it feel professional and minimalist

1. **One row per set.** Note as text when present; Note and Tag move into the set's ⋯ menu (P1-4). Biggest single cut in visual noise and page length.
2. **One tap target per exercise row.** Drop the duplicate chevron button and the inline pencil; the row is the link (P1-3). Names get 4x the width and stop breaking mid-word.
3. **Global press feedback and no tap flash:** `-webkit-tap-highlight-color: transparent`, `touch-action: manipulation`, `:active { scale(.97) }` at 160ms `cubic-bezier(.23,1,.32,1)` on every button (P1-6).
4. **Gate every hover** behind `(hover: hover) and (pointer: fine)`, including Bootstrap's button hovers, so ticked/unticked pills tell the truth (P1-5, P2-1).
5. **One motion vocabulary:** `$ease-out: cubic-bezier(.23,1,.32,1)`; folds 220ms, modals `scale(.96)` 200ms, flash in 320ms / out 200ms, Sortable 200ms; delete the card lift and the backdrop blur (P2-2 to P2-5).
6. **Quiet the blue.** Blue for the one primary action per screen; muted for pencils, set numbers, note arrows, unselected pills; a lighter ring on the active split (P2-13, P3-7, P3-11, P3-16).
7. **Truncate metadata, never numbers:** ellipsis on chips with `max-width: 100%`, clamp meta lines to 2, `nowrap` + separators on weights (P1-1, P2-8).
8. **Make it installable:** theme-color, manifest with `display: standalone`, safe-area padding on full-screen modals (P2-6, P1-8).
9. **Right verbs in the confirm box:** icon and button from the message ("Stop", "Delete"), never a bin on a non-delete and never a bare "Yes" (P1-7).
10. **Cut repeated information:** header counts that restate the card, the "Today / date" header on the exercise page, the flash after Add set once the new row lights up (P2-12, motion opportunity 1).
