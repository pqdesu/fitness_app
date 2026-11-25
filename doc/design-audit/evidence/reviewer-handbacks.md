# Reviewer hand-backs (the final message each reviewer sent when it finished)

Copied as received, without the two-space indent the harness added. These are summaries; the full reports are the source of truth.

## Emil Kowalski review (emil.md)

The Emil-style review is finished. Full report: /tmp/claude-1000/-home-pedro-code-pqdesu-fitness-app--claude-worktrees-opus-plan-session-e72fa6/d91907ca-cfc9-418e-acc7-1a8504a66bda/scratchpad/reports/emil.md
My screenshots are in /tmp/claude-1000/-home-pedro-code-pqdesu-fitness-app--claude-worktrees-opus-plan-session-e72fa6/d91907ca-cfc9-418e-acc7-1a8504a66bda/scratchpad/shots/emil/ (names starting `wc-`, `vp-`, `wc320-`, `wcdesk-`). Nothing blocks use (no P0); there are 8 P1 findings.

Summary:
1. A long split name (58 characters) in a chip that never wraps (`_lists.scss:36`) makes Home 410 px wide on a 390 px phone and is cut off in History (`wc-home.png`, `wc-history.png`).
2. Editing a set on a 320 px phone makes the page 387 px wide, because the rest, Save and Cancel bar doesn't wrap (`_set.html.erb:93-113`, `vp320-exercise-editing.png`).
3. In exercise rows, the trailing chip, pencil and chevron button take about 55% of the width, so names get about 70 px. Words break mid-word: "Stationar/y bike" happens even with catalogue data. The chevron button repeats the row link (`_planned_exercise.html.erb:4-17`, `workout_logs/show.html.erb:55-71`).
4. Each set takes three rows: the numbers, a 44 px "Tag" pill, and a note input with a blue button. 14 sets make the page 3,534 px tall, and a 158-character note is unreadable in a one-line input (`_set.html.erb:55-87`).
5. On a phone, Bootstrap's hover stays after a tap, so a tag pill you untick still looks ticked. Many of the app's own hovers are not limited to mouse devices either: card lift, week circle, calendar fill, back arrow.
6. Android's blue tap flash shows everywhere except the tab bar. Press feedback (`scale(.97)`) exists only on the timer buttons, the back arrow and the tab bar.
7. The confirm box always shows a trash can and says "Yes", even for "Stop the timer?" (`_confirm.html.erb:5`, `confirm_dialog.js:24`).
8. The full-screen exercise picker has no safe-area padding, so on an iPhone the home indicator sits over "Add selected".
9. Motion is mostly Bootstrap defaults: folds take 350 ms with `ease`, modals drop 50 px over 300 ms, flash cards take 500 ms in and 500 ms out (`ease-in-out` on the way out), and drag and drop runs 150 ms with no curve set. Copy the confirm box's settings everywhere (`cubic-bezier(.23,1,.32,1)`, 200 ms, `scale(.96)`). Remove the card hover lift, the backdrop blur and the flash countdown bar.
10. The app has no theme-color tag and no manifest, so it can't run as a home-screen app without browser bars. Turbo's progress bar shows its default blue `#0076ff`, not the app's indigo.
11. 99,999.125 kg wraps inside the number ("99999. / 125") on Home and the Month page, and weights have no thousands separator.
12. Already correct: inputs are 16 px (checked in the browser), every number field has `inputmode`, there are no `vh` units, the navbar and tab bar use safe areas, the clocks use tabular figures, reduced motion is respected, and the breathing dot is justified.
13. The report has a table of all 29 transitions and animations with keep, retune or remove for each, four places where motion would help, a mobile-native checklist, and 17 worst-case results with their screenshots.
14. It ends with the 10 changes with the biggest effect, led by "one row per set" and "one tap target per exercise row".

Data and checks:
- All test data went into the disposable audit database through port 3001: split 4, workout day 14, workout log 8 (17 exercises, 14 sets on entry 21) and plan row 26. Two `rails runner` updates also ran against `fitness_app_design_audit` only: the timer was backdated 3 hours, and one set got a 3-hour rest and all three tags.
- That split is not active, so Home still follows the U/R/L/U/L split. However, its Full Body workout today now appears in Home's Recent workouts, "This week" and the calendar, and in History, so other reviewers will see it.
- Not checked: a real iPhone or Android phone (sticky hover, safe areas, the keyboard), RTL, 200% zoom, non-Latin text.
- My Chrome on port 9343 is stopped. The repo was not edited.

## taste-skill new look (DIRECTION.md, readout-concept.html)

I built "Readout", a standalone concept for the app's new look, checked it in headless Chrome at 1440 and 390 in both themes, and wrote the direction doc. Nothing in the repo was touched. The Chrome on port 9344 is closed.

**The concept in 10 lines**
1. The idea: the phone works like a gym instrument. Surfaces are graphite and bone, separated by 1px lines instead of shadows. Every number (weights, reps, clock, stats, dates) is set in Geist Mono, like a display. Everything else is set in Geist.
2. One colour carries meaning: signal orange (#FF5A1F light, #FF6A2B dark). It marks only what is live (running timer, today) and the one button to press next (Start workout / Continue, Add set, Add exercise, Add selected). Everything else is monochrome. Choices that are settings (muscle group, equipment) are filled in ink, not orange.
3. Dark mode is a true graphite (#0E0F10). In the app it follows the phone's setting through Bootstrap 5.3 colour modes, with no toggle and no JavaScript. The toggle on the concept page is only there to show both themes.
4. Big readouts: the workout clock is 56px mono with dimmed colons, a breathing ring on the live dot, and a thin line under the clock that fills once a minute. Weights and reps are 22px mono, and the add-set fields are 56px tall with the unit inside the field.
5. Fewer boxes: cards have no shadows. Rows are whole links with a quiet chevron, so the boxed "›" and "Open" buttons go. Rest between sets is a dotted line reading "Rest 2 min 5 s". The calendar keeps its four day states: planned is ink fill, missed is a dashed ring, extra is a thin ring with a dot, and today has an orange ring.
6. The five screens use real data from the audit database: Home, today's Lower workout (timer running, Hip thrust 3 sets, Squat 2 sets, 5 still to do), the Hip thrust page (60×12, 80×10, 90×8, rests of 2 min 5 s), History, and the Add exercises picker as a bottom sheet.
7. Every function and every text from the current app stays. I kept the admin pen and × and the rest-day, Deleted and split badges. Only three things move around: Home's Exercises button goes into the top bar, the Today box's button becomes full width, and boxed row buttons become whole-row links.
8. The system panel on the page shows the palette with hex for both themes (contrast noted), the type scale, a 4px spacing scale, radii (6/10/12/16/22, round only for small pills and day dots), borders and the one shadow (sheets only), motion curves and durations, the icon style, and all the asked states. Those are button rest, hover, pressed, focus and disabled, field focus, and the timer's idle, running, paused and finished. There is also an empty state and the Today box before the workout starts, with Start workout.
9. `DIRECTION.md` has the full token set as SCSS ready for `config/_fonts.scss`, `_colors.scss` and `_bootstrap_variables.scss`, a per-component table, and a 9-step migration order. Step 1 also fixes the 8 existing lines that pass colours through `rgba()`, which would break with the new tokens.
10. It respects the constraints: no inline styles or scripts, Turbo/Stimulus unchanged and no new JS libraries, and fonts stay on Google Fonts, which the security policy already allows. Swapping Font Awesome for an outline SVG sprite is an optional last step that only removes code.

Decision for you: on Home I showed the Today box after training started ("Logged today", Continue), because that matches the real data. The "Start workout" version of the box is in the states panel, not on the Home screen.

Not checked:
- I did not run the taste skill's gate or checker. They are built for marketing pages and would fail an app screen.
- I did not compile the SCSS against the app. In particular, Bootstrap's dark-mode variable names and the eight `rgba()` lines are only reviewed, not built.

Risk: in step 1, every indigo accent turns orange, and some of them (links, calendar fills, choice buttons) must become ink in steps 2 and 6. Don't ship step 1 on its own.

Files are in /tmp/claude-1000/-home-pedro-code-pqdesu-fitness-app--claude-worktrees-opus-plan-session-e72fa6/d91907ca-cfc9-418e-acc7-1a8504a66bda/scratchpad/new-look/: index.html, DIRECTION.md, shot-1440-light.png, shot-1440-dark.png, shot-390-light.png, shot-390-dark.png, frame-home-light.png, frame-home-dark.png, frame-workout-dark.png, frame-exercise-light.png, frame-exercise-dark.png, frame-history-dark.png, frame-picker-light.png, frame-picker-dark.png, ds-light.png, ds-dark.png, m390-ds-dark.png, m390-head-light.png. The screenshot script is .../scratchpad/new-look-shoot.mjs.

## Impeccable Assessment A, design review (impeccable-A.md)

## Assessment A (design review): Acceptable, 25/40

I scored the whole app at 25/40, in the "Acceptable" band. I found 0 P0, 8 P1, 17 P2 and 14 P3 issues. Every flow I drove works end to end.

**Design specificity:** the app is carefully engineered but reads as generic Bootstrap, not as a gym logger with its own look. The pre-filled Add set form and the workout timer are the authored parts. Indigo `#4F46E5` is used on almost everything, and the number a lifter reads (`60 kg`) is set at body size, 15px Inter 400.

**Heuristic scores:** Visibility of system status 3 · Match with the real world 3 · User control and freedom 3 · Consistency and standards 2 · Error prevention 3 · Recognition rather than recall 2 · Flexibility and efficiency 2 · Aesthetic and minimalist design 2 · Error recovery 2 · Help and documentation 3.

**Top 5 issues:**
1. P1: the Add set button is out of reach. Each logged set row is 171 to 197px tall, mostly an always-visible Tag pill and note field. With 3 sets, the form starts at y=933 on an 844px phone. After each set it slides under the tab bar (measured y=632 to 771, tab bar at 784). When the page URL has no `?date=`, the page jumps to the top instead. Fix: compact each set to one row and move Tag and Note into the set's ⋯ menu, or put the form above the list of sets.
2. P1: cards, inputs and modals are the same colour as the page (`#F6F7F9`). Bootstrap 5.3 takes their background from `$body-bg`. Surfaces are separated only by a 1.14:1 hairline. Fix: set `$card-bg`, `$input-bg` and `$modal-content-bg` to a new white `$surface` token.
3. P1: controls fail contrast. Checkbox and radio borders are 1.14:1, including the picker's exercise checkboxes. Input borders are 1.32:1 and the focus ring is 1.46:1.
4. P1: the exercise picker has no search. Its muscle groups are 12px uppercase labels that don't look tappable, and an admin sees a red × beside every row.
5. P1: logging a set costs three taps while the rest timer is used. The sequence is Add set, then a "Save rest" confirm, then Start rest. The rest clock is 22px and reads `0:00:04`.

Other P1 issues: exercise names in workout rows are squeezed to about 100px (long names wrap one word per line); fields show a green "valid" tick on pages nobody has submitted, and after a wrong password the email field and "Remember me" turn green; changing a preference (automatic timer, warm-up tag) requires your current password.

System findings: the SCSS declares 21 font sizes, four of them (12, 12.48, 12.8 and 13px) within 1px of each other. Inter weight 700 is never loaded, so 14 selectors and every `<strong>` get a browser-synthesised bold. Labels come in two styles and toggle pills in three. List rows use four different vertical paddings. The gap after the calendar and after the timer card is 40px, against 16px between other cards.

Not checked: a real phone, screen readers, the Edit timer page for a timed workout, the rest-day Today box, and the cardio timer running.

Data added to the audit database (3001 only): sets 4 and 5 on today's Hip thrust, a paused-then-resumed timer, and a long-named exercise in today's workout. Another reviewer's data (a 99999.125 kg set and a Full Body workout today) shows in my later screenshots.

Files: reports/impeccable-A.md (the full report), shots/impeccable-a/ (30 extra screenshots, plus crops of the tall phone shots in crops/), impeccable-a-scripts/ (the CDP scripts).

## Impeccable Assessment B, technical audit (impeccable-B.md)

Assessment B is done: the score is **15/20 (Good)**. Each dimension scored 3/4: Accessibility, Performance, Theming, Responsive and Implementation Integrity. The integrity verdict is PASS.

Counts by severity: P0 0 · P1 3 · P2 12 · P3 7.

Top 5 issues:
1. [P1] Checkboxes are nearly invisible. Their border is 1.14 to 1.23:1 (WCAG 1.4.11). It affects Account settings, Remember me, and the picker's Unilateral and Shared boxes. Fix: `$form-check-input-border: 1px solid $muted`.
2. [P1] Keyboard focus is hard to see. The ring on `btn-light` (44 uses) is about 1.1:1; other Bootstrap controls are 1.47:1. Fix: `$focus-ring-opacity: 1` plus a `btn-light` focus colour.
3. [P1] Home scrolls sideways at 320 px. A `white-space: nowrap` split-name chip in Recent workouts is 377 px wide (WCAG 1.4.10). The chip style is in `_lists.scss:36`.
4. [P2] Every pre-filled simple_form field shows a green "valid" ✓. Examples: Account email, Rename split. The cause is `valid_class: 'is-valid'` in `config/initializers/simple_form_bootstrap.rb`.
5. [P2] Add set is far below the fold on the exercise page. With 3 sets, the weight field is at y=1473 on an 844 px phone; each set row is 171 to 197 px tall. Once there, adding a set keeps the scroll.

Detector results: Source scan: `detect app/views` on a directory scans no `.erb` or `.scss` files; listing the files explicitly found only `overused-font` (Inter and Plus Jakarta Sans). Rendered scans: all 16 CDP scans worked (13 pages at 390×844, 3 at 1280×800), with no fallback needed. `text-overflow` on 2 logged-workout cards is a real bug: the name column is 110 px wide. `pulsing-dot` is a false positive: the dot marks a timer that is really running, and reduced motion turns it off. There was 1 advisory `straggler`.

Other things worth knowing: every text colour pair passes AA, and every control has an accessible name. One root cause, Bootstrap and simple_form defaults the colour tokens never overrode, explains 6 findings: cards and fields are the page grey, and `.text-muted` is not the `$muted` token. Every page is titled just "FitnessApp".

Data changed: while testing scroll after Add set, 2 sets (95 kg × 6) were added to Hip thrust (`/workout_exercises/17`) in the audit database. The repo was not touched, and the Chrome on port 9342 is closed.

Not checked: the touch drag gesture, the decimal comma on a real phone, and production CSS size (dev assets only were measured).

Files: reports/impeccable-B.md, shots/impeccable-b/ (screenshots), impB/run/ (detector JSON in `det/`, measurements in `meas/`).
