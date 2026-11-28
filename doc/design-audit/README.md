# Design audit: the whole app (2026-11-25)

Four reviews of every page, at phone width (390 px, and 320 px for overflow) and desktop width (1280 px), on a copy of the development database. Nothing in the app's code or the development database was changed.

| Review | Skill | Result | Full report |
|---|---|---|---|
| Design review: hierarchy, type, spacing, colour, copy, page by page | Impeccable (critique) | **25/40, Acceptable** (P0 0 · P1 8 · P2 17 · P3 14) | [1-impeccable-design-review.md](1-impeccable-design-review.md) |
| Technical audit: detector, contrast, touch targets, a11y, performance, theming | Impeccable (audit) | **15/20, Good** (P0 0 · P1 3 · P2 12 · P3 7) | [2-impeccable-technical-audit.md](2-impeccable-technical-audit.md) |
| Polish, motion, mobile feel, worst-case data | Emil Kowalski (emil-design-eng, review-animations, mobile-native, break-ui) | No P0, 8 P1, 13 P2, 24 P3. All 29 animations reviewed one by one | [3-emil-polish-review.md](3-emil-polish-review.md) |
| New look: minimalist, futuristic, simple | taste-skill (design-taste-frontend + minimalist-ui) | Concept "Readout", light and dark | [new-look/readout-concept.html](new-look/readout-concept.html), [new-look/DIRECTION.md](new-look/DIRECTION.md) |

Screenshots of every page as it is today are in [evidence/scratchpad/shots/png/](evidence/scratchpad/shots/png/); every other file the reviewers made (their screenshots, scripts, detector JSON and measurements) is under [evidence/scratchpad/](evidence/scratchpad/). The precise handover for the next agent is [HANDOVER-PROMPT.md](HANDOVER-PROMPT.md).

## Verdict

The app is carefully built. Inputs are 16 px so iOS doesn't zoom, touch targets are 44 px, every number field has `inputmode`, safe areas are handled, the clocks use tabular figures, reduced motion is respected, every text colour passes AA, and the colour tokens are named by role. The detector found no "AI template" patterns: no gradient text, glows, nested cards or buzzwords.

What keeps it from looking professional and minimalist comes down to four things, which all three reviewers found independently:

1. **Too much on each item.** A logged set is three rows: the numbers, a 44 px "Tag" pill, and a note field with a blue arrow. An exercise row has a drag grip, a sets chip, a pencil and a second chevron button, which leaves the name about 70 to 110 px. With real data, names wrap one word per line or break mid-word ("Stationar/y bike"), and an exercise page with 14 sets is 3,500 px tall.
2. **Bootstrap defaults leak through the design.** Cards, inputs and modals are the same grey as the page, separated only by a 1.14:1 hairline. Checkbox borders are 1.14:1, the focus ring is 1.1 to 1.46:1, `.text-muted` is a second grey, and simple_form paints a green ✓ on every pre-filled field, even after a wrong password.
3. **Indigo is on everything.** `#4F46E5` marks primary buttons, pens, note arrows, set numbers, unset choices, the active split ring and the calendar, so nothing stands out as the next thing to press. The number a lifter actually reads (`60 kg`) is 15 px regular text.
4. **Built for mouse, not thumb.** Hover effects aren't limited to mouse devices, so a tag pill you untick still looks ticked. Android shows its blue tap flash everywhere except the tab bar. Only the timer, the back arrow and the tab bar react when pressed. Motion is Bootstrap's defaults: 350 ms folds, modals that drop in from 50 px above, and 500 ms flash cards.

## Priority issues (merged and ranked)

Most of these were found by more than one reviewer. Tags: **A** = Impeccable design review, **B** = Impeccable technical audit, **E** = Emil.

### P1: major (fix before anything else)

**Status (2026-11-26): all 12 fixed on the branch `audit-major-fixes`**, with the owner's choices: one-row sets with Tag and Note in the ⋯ menu, the rest saved without asking up to 10 minutes, a search box in the picker, and Preferences without the password. Two changes from the suggestions below, because existing tests pin the current behaviour:
- **Item 1:** the add-set redirect still carries `?date=`. An exercise page opened without a date still jumps to the top after its first set, but every in-app link carries the date, and the one-row sets fixed the drift under the tab bar. Add set now starts at y = 789 with 8 sets, against 1,473 with 3 sets before.
- **Item 2:** the admin pencil and the × stay as icons (muted), not in a ⋯ menu. A ⋯ menu is as wide as the pencil, and its list items would sit inside the row's list item.

1. **The Add set button is below the fold and moves after every set** (A, B, E). Each set row is 171 to 197 px. With 3 sets, the weight field starts at y = 933 to 1,473 on an 844 px phone, and after each set it slides under the tab bar. Opened without `?date=`, the page jumps back to the top.
   - Fix: one 48 px row per set. Note and Tag go into the set's ⋯ menu, and a note shows as text only when there is one (`workout_sets/_set.html.erb:55-88`).
   - Fix: put the add-set form above the sets, or keep it pinned at the bottom.
   - Fix: redirect back to the page the form came from, so the page keeps its scroll.
   - This is the action you repeat 15 to 25 times a workout, one-handed, so it matters most.
2. **Exercise names squeezed to 70 to 110 px** (A, B, E). In `workout_days/_planned_exercise.html.erb:4-17` and `workout_logs/show.html.erb:55-71`:
   - Remove the boxed chevron button, since the row is already a link; leave a plain 12 px muted chevron.
   - Put the sets chip on the meta line.
   - Move the admin pen and × into ⋯.
3. **Surfaces are the page colour** (A, B). Add a `$surface: #FFFFFF` token and set `$card-bg`, `$input-bg`, `$modal-content-bg`, `$dropdown-bg` and `$list-group-bg` to it in `config/_bootstrap_variables.scss`. The 14 literal `white`s become the token.
4. **Controls you can't see** (A, B; WCAG 1.4.11).
   - Checkbox and radio borders are 1.14:1, including the picker's exercise checkboxes. Fix: `$form-check-input-border: 1.5px solid #8A919E`.
   - Input borders are 1.32:1. Fix: `$input-border-color: #B9BFC9` on white fields.
   - The focus ring is 1.1:1 on `btn-light` (44 uses) and 1.46:1 elsewhere. Fix: `$focus-ring-opacity: 1`, plus a 2 px ring with a 2 px white gap.
5. **Long names push the page sideways** (B, E; WCAG 1.4.10).
   - The split-name chip in Recent workouts is `white-space: nowrap` (`components/_lists.scss:36`). A 58-character name makes Home 410 px wide on a 390 px phone, and 377 px wide at 320 px. Fix: `max-width: 100%; overflow: hidden; text-overflow: ellipsis`.
   - Editing a set at 320 px overflows by 67 px, because the rest, Save and Cancel bar doesn't wrap (`_set.html.erb:93-113`).
6. **Green "valid" ✓ on fields nobody submitted** (A, B). It shows on every edit form and on Account, and after a wrong password it marks the email field as correct. Fix: remove `valid_class: 'is-valid'` from `config/initializers/simple_form_bootstrap.rb` (10 wrappers) and set `input_field_valid_class = nil`.
7. **Sticky hover and no press feedback on touch** (E, B).
   - Limit every hover to mouse devices with `@media (hover: hover) and (pointer: fine)`, including Bootstrap's button hovers.
   - Add `-webkit-tap-highlight-color: transparent` and `touch-action: manipulation`.
   - Give every button an `:active` press of `scale(.97)` over 160 ms with `cubic-bezier(.23,1,.32,1)`.
8. **The exercise picker has no search** (A, E). Its muscle groups are 12 px uppercase labels that don't look tappable, and an admin sees a red × beside every row.
   - Add a search field fixed at the top of the picker that filters as you type and opens the groups that match. When nothing matches, it fills "Create your own" with what you typed.
   - Style the groups like the catalogue page: 16 px, weight 600, not uppercase.
9. **Three taps per set when you use the rest timer** (A). The sequence is Add set, then "Save rest?", then Start rest. This one changes behaviour, so it's your call.
   - Save the measured rest without asking, and ask only when the rest is over 10 min (a forgotten timer).
   - Optionally add a setting, "Start rest after each set".
   - Show the rest clock at 36 px as m:ss, not `0:00:04` at 22 px.
10. **The confirm box always shows a trash can and says "Yes"**, even for "Stop the timer?" (E; `shared/_confirm.html.erb:5`, `confirm_dialog.js:24`). Fix: take the icon and the verb from the action ("Stop", "Delete").
11. **The full-screen picker's "Add selected" sits under the iPhone home indicator** (E). Fix: give the modal footer `padding-bottom: calc(1rem + env(safe-area-inset-bottom))`.
12. **Changing a preference asks for your current password** (A). The automatic timer and warm-up options live in Devise's account form. Fix: a separate Preferences card that saves when you tick a box, using the existing `auto_submit_controller.js`.

### P2: minor (next pass)

**Status (2026-11-27): the P2 and P3 items are done on the branch `design-audit-polish`**, with the owner's choices:
- all four added changes: Delete at the bottom, the Equipment fold, the flash at the bottom on phones and the calendar legend, "Last time" for empty workouts and per exercise, and the installable app;
- the approved wording changes: short dates, plain error messages, "Still to do" on both pages, the Recent chip only for other splits, and less repetition;
- a 16px base with one type scale.

What was done differently:
- **Note arrow:** it keeps its button class (a test pins it) but looks light and grey.
- **Users page:** it keeps no back arrow (a test pins it).
- **Flash after Add set:** it stays (a test pins "Set 1 added"), now at the bottom on phones.
- **Rows on admin and table cards:** only the padding and wrap changed.
- **Import map:** the "unminified Popper and SortableJS" item was a false alarm (both are minified), so nothing changed there.

- **Type**:
  - The SCSS declares 21 font sizes, four of them within 1 px (12, 12.48, 12.8 and 13 px). Fix: an 8-step scale of `.75 / .8125 / .875 / 1 / 1.125 / 1.375 / 1.75 / 2.25rem` (A).
  - Inter weight 700 is never loaded, so 14 selectors and every `<strong>` get a browser-faked bold. Fix: load the 700 weight, or use 600 (A).
  - Logged weight and reps should be 20 px, weight 600, with a small muted `kg` (A).
- **Colour**:
  - Keep indigo for the one primary action per screen. Make pens, note arrows, set numbers and unset choices muted (A, E).
  - Use one grey for secondary text: `$secondary-color: $muted` (A, B).
  - Tags use Bootstrap's grey `#6C757D` and a third pill style; give them the `.choices` look (A).
- **Motion** (E):
  - Use one curve, `$ease-out: cubic-bezier(.23,1,.32,1)`.
  - Folds go to 220 ms (Bootstrap uses 350 ms `ease`).
  - Modals scale in from `.96` over 200 ms instead of dropping 50 px over 300 ms.
  - Flash cards take 320 ms in and 200 ms out (now 500 ms each way, with `ease-in-out` out).
  - Drag and drop takes 200 ms with the curve set.
  - Remove the card hover lift, the backdrop blur and the flash countdown bar.
  - Make Turbo's progress bar indigo, not its default blue `#0076ff`.
- **Spacing**:
  - The gap after the calendar and the timer card is 40 px, against 16 px everywhere else (`_dashboard_calendar.scss:2`, `_timer.scss:4`).
  - List rows use four different vertical paddings, labels come in two styles and toggle pills in three (A).
- **The flash card covers the back arrow for 5 s after every set** (A). On a phone, move it to the bottom, above the tab bar. Once the new set row lights up, the flash after Add set isn't needed at all (E).
- **Numbers**: 99,999.125 kg wraps in the middle of the number on Home and the Month page, and there's no thousands separator. Right-align weights in set tables with tabular figures (E).
- **Empty workouts count as "last time"** (A). "Last time · Nov 21 · 0 exercises · 0 sets", while the calendar says Nov 20 was missed.
- **The calendar has no legend on a phone** (A, E). Its tooltips never show on touch, and the "extra" ring is 2.6:1 and looks like "today".
- **The same workout uses different words on two pages** (A). "Still to do" vs "From this day, not in this workout", green vs grey sets chips, pen vs ⋯, chevron-right vs chevron-down. Use one row component and one set of words.
- **"Delete workout" sits in the header of every logged workout** (A). Move it to the end of the page.
- **Technical error messages** (A): "Reps completed can't be blank and Reps completed is not a number". Use one plain message per field.
- **The exercise page doesn't show last time's sets** (A). One muted line would do: "Last time Wed 18 Nov: 120×8 · 110×8 · 100×10".
- **The Equipment form is fully open on every exercise page during a workout** (A). Fold it to one row: "Equipment · Machine · Bull ›".
- **Admin pages** (A): Equipment and Set tags have no title, no back arrow and no active tab, and the Users row actions touch the card edge.
- **Not installable** (E):
  - There is no `theme-color` and no manifest, so the app can't open full screen from the home screen.
  - Every page is titled just "FitnessApp" (B).
- **Font Awesome** (B): it uses `font-display: block` and a 158 KB font, and the CSS carries 1,962 icon rules for the 26 icons used.
- **Account tab opens the keyboard every time** (B).
- **Text at 200% zoom overflows 5 pages** (B).

### P3: polish

There are 45 small items across the three reports, each with its exact value. The highlights:

- Remove the 12 uppercase "eyebrow" labels.
- Change Rails' button labels ("Update Split") to plain ones ("Save split").
- Use three radii instead of seven (10 for controls, 16 for cards and sheets, round for chips).
- Make borders semi-transparent (`rgba(#101828,.08)`), and use a border or a shadow on cards, not both.
- Balance heading wrap with `text-wrap: balance`.
- Make the active split ring thinner.
- Show dates with the weekday ("Wed 25 Nov").
- Show the split chip in Recent workouts only when it isn't the active split.
- Delete the dead tokens `$orange` and `$notice`.
- Remove the obsolete `shrink-to-fit=no`.

## The new look: "Readout"

Open [new-look/readout-concept.html](new-look/readout-concept.html) in a browser. It shows five phone screens with your real data: Home, today's workout with the timer running, the Hip thrust page while logging, History, and the Add exercises picker. It has light and dark themes and the full design system.

- **Idea:** the phone as a gym instrument. Surfaces are graphite and off-white, separated by 1 px lines instead of shadows. Every number (weight, reps, clock, stats, dates) is set in **Geist Mono**, like a display. Everything else is set in **Geist**.
- **One signal colour, orange** (`#FF5A1F` light, `#FF6A2B` dark). It marks only what is live (running timer, today) and the one button to press next (Start or Continue, Add set, Add exercise, Add selected). Everything else is monochrome.
- **Dark mode** follows the phone's setting through Bootstrap 5.3 colour modes, with no toggle and no JavaScript.
- **Big readouts:**
  - the workout clock is 56 px mono
  - weights and reps are 22 px mono
  - the add-set fields are 56 px tall, with `kg` inside the field
- **Fewer boxes:** rows are whole links, rest between sets is a dotted line, and the calendar keeps its four day states with a legend.
- **Every function and every text stays.** Only three things move:
  - the Exercises button goes into the top bar
  - the Today button becomes full width
  - boxed row buttons become whole-row links
- [DIRECTION.md](new-look/DIRECTION.md) has every token as SCSS, ready for `config/_fonts.scss`, `_colors.scss` and `_bootstrap_variables.scss`. It also has a table of what changes per component and a 9-step migration order. It keeps the security policy (Google Fonts are already allowed, and there are no inline styles) and adds no JavaScript libraries.

## Suggested order

1. **The P1 fixes, which hold whatever the look** (most of them are layout and Bootstrap variables). Start with the exercise page (one row per set, Add set in reach), the exercise rows, surfaces and control contrast, overflow, and the green ✓. Then touch feedback and the picker search. These are in `/impeccable layout`, `colorize`, `harden` and `distill`.
2. **Decide on Readout.** If you take it, do steps 1 and 2 of its migration together. On its own, step 1 turns every indigo accent orange, including links and calendar fills, which step 2 makes ink. Do the motion and type P2s inside it rather than on the current look.
3. **The P2 and P3 polish pass**, then run `/impeccable audit` and `critique` again to measure the change.

## How this was done

- **Server:** the app ran from this worktree on port 3001 against `fitness_app_design_audit`, a copy of `fitness_app_development`, with the password `auditpass123` set only in the copy.
- **Test data:** to have today's workout to look at, the copy got a workout logged today (Lower, with Hip thrust and Squat sets and the timer started). The reviewers also added worst-case data there: long names, 14 sets, 17 exercises, 99,999.125 kg and a 3-hour timer.
- **Screenshots:** headless Chrome over CDP, 63 base captures plus about 100 more from the reviewers.
- **Impeccable detector:** ran on 13 pages at 390×844 and 3 at 1280×800 while logged in. It found 1 real layout bug (`text-overflow`), 1 false positive (`pulsing-dot`, the real running-timer dot), and `overused-font` (Inter and Plus Jakarta Sans).
- **Not checked:** a real iPhone or Android phone (sticky hover, safe areas and the keyboard were emulated), a screen reader, the touch drag gesture, and the production CSS size. The Readout SCSS was not compiled against the app.
