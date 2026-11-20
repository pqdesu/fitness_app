# dropdowns-off-screen

## 1. Summary

This branch fixes the open issue "Dropdowns past visible screen" (`doc/Issues/Issues.md`, section "Dropdowns").

- The fields whose list ran past the bottom of the screen were native `<select>`s. The browser draws a select's list itself, and a page cannot make it open upward.
- The muscle group and the equipment of a lift are now **pills to tap**: every option is on screen at once, so there is no list to open. On a phone this is also one tap instead of two.
- One shared partial, `shared/_choices`, draws the pills. It reuses the Bootstrap `btn-check` pattern the "Move a workout" pop-up already uses.

**State:**
- `bin/rails test`: 90 runs, 1235 assertions, 0 failures, 0 errors.
- `bundle exec rubocop`: no offenses. `bundle exec brakeman`: no warnings.
- Impeccable's design detector (`impeccable detect --json --changed`): no findings.
- The changed pages were checked at phone width (390 × 844) in headless Chrome on WSL, signed in as the seeded development admin.
- Not tried on a real phone (see section 9).

## 2. Timeline

1. **"Just pulled, please check the new version of the app."** `master` at `faeb6d7` (PR #19) was reviewed: tests, rubocop, brakeman and bundler-audit were clean. Nothing was changed.
2. **"Install Chrome on WSL headless to inspect mobile layout better."** Chrome for Testing (headless shell 158) was installed in the home folder without root, with a `chrome-headless` launcher in `~/.local/bin`. This is outside the repo.
3. **Installing the ponytail, impeccable, Emil Kowalski and ui-ux-pro-max skills, and updating Node to v26.13.1.** Outside the repo.
4. **"Now investigate the issue on Dropdowns and fix it. Use ponytail in full, and also the impeccable UI skill and Emil's skill."**
   - The `investigate-issues` skill traced the issue (section 3).
   - Emil's `mobile-native` skill confirmed the cause: Chrome's device mode is not a phone. On a phone, a select opens the system picker, which never runs off the screen.
   - Ponytail (full) picked the smallest complete fix: reuse an existing pattern, no new library, no hand-built dropdown.
   - Impeccable's context and craft floor set the checks: 44 px touch targets, real content at 390 px, and its detector at the end.
5. The fix was built, tested and checked in headless Chrome. "Free weights" wrapped onto two lines in a half-empty grid; the grid was changed to `auto-fit` so two options share the row.
6. **"Finalize it."** This doc, the seed data check, the commit. The push and the pull request are left to the owner (section 6).

The branch was created as `claude/new-app-version-review-3efb9a` (the session's review worktree) and renamed `dropdowns-off-screen` before anything was committed. A second worktree was tried first, but this session may only write inside its own worktree, so that one was removed and its branch deleted (it had no commits).

## 3. Starting point

The owner's example (`doc/Features/Pics/Screenshot 2026-11-19 133850.png`) is the "Muscle group" field under "Create your own" in the "Add exercises" pop-up. Its list opened downward and ran under the bottom of the screen.

Every dropdown in the app:

| Dropdown | Where | Kind |
|---|---|---|
| Muscle group | `shared/_exercise_picker.html.erb:46`, the "Add exercises" pop-up, near its bottom | native `<select>` |
| Muscle group | `exercises/_form.html.erb:8`, the admin's exercise form | native `<select>` (simple_form) |
| Equipment | `shared/_equipment_fields.html.erb:5`, the exercise page (card at the bottom on a phone) and the logged exercise's edit page | native `<select>` |
| Workout, Day of the week | `workout_days/_form.html.erb:4,6`, at the top of the page | native `<select>` (simple_form) |
| User menu | `shared/_navbar.html.erb:22`, at the top | Bootstrap dropdown with Popper |

- A native select's list is drawn by the browser, outside the page. CSS and JavaScript cannot make it open upward.
  - On a real phone it opens the system picker (an iOS wheel, an Android sheet), which never runs off the screen.
  - Desktop Chrome's device mode draws its desktop list instead, and that list ran past the screen. The issue's own text says it was seen only there.
- The Bootstrap user menu already flips upward when there is no room below (Popper's `flip`), and it sits at the top of the page.

## 4. Changes

### 4.1 `shared/_choices.html.erb` (new): options as pills

```erb
<fieldset class="choices-field">
  <legend class="form-label"><%= label %></legend>
  <div class="choices">
    <% choices.each do |text, value| %>
      <% input_id = "#{id}_#{value.presence || 'none'}" %>
      <%= f.radio_button field, value, id: input_id, class: "btn-check", checked: value.to_s == selected.to_s,
            data: local_assigns[:data] %>
      <%= label_tag input_id, text, class: "btn btn-outline-primary" %>
    <% end %>
  </div>
  <% if (error = f.object.try(:errors)&.full_messages_for(field)&.first) %><div class="invalid-feedback d-block"><%= error %></div><% end %>
</fieldset>
```

- **Locals:**
  - `f`: the form builder
  - `field`: the attribute
  - `label`: the legend text
  - `choices`: `[text, value]` pairs
  - `selected`: the value to check
  - `id`: a prefix that is unique on the page
  - `data`: optional, put on every radio
- **Radio buttons, not a select:** the same parameter is posted (`exercise[muscle_group]`, `workout_exercise[equipment]`), so no controller changed.
- **A fieldset and legend** give the group its name for screen readers. Each pill is a real radio, so arrow keys move between pills and Tab moves to the next field.
- **`checked:` is passed explicitly.** The picker's `form_with scope: :exercise` has no model, so Rails could not work out which pill to check on its own. "Other" (value `""`) is checked there.
- **The error line** replaces the inline error simple_form drew for the muscle group. `f.object.try(:errors)`, because a `form_with` without a model gives `f.object == false`; `&.errors` failed on that in the first test run.

### 4.2 `components/_choices.scss` (new), imported in `application.scss` after `components/exercise_picker`

```scss
.choices-field legend { float: none; font-size: inherit; }
.choices {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(6rem, 1fr)); // two options share the row
  gap: .5rem;
  .btn { display: flex; align-items: center; justify-content: center; min-height: 2.75rem; padding: .375rem .5rem; }
}
.inline-form .choices-field legend { font-size: .78rem; }
```

- **The legend rules** undo Bootstrap's reboot style for `<legend>` (large and floated), so it looks like the other field labels. Inside `.inline-form` it takes that form's small label size.
- **Pill height** of 2.75rem (44 px) is the touch target the impeccable and Emil skills ask for.
- **`auto-fit`, not `auto-fill`:** with only two options (equipment), `auto-fill` kept an empty third column and "Free weights" wrapped onto two lines. `auto-fit` lets the two pills share the row. The nine muscle groups fill three per row at 390 px.

### 4.3 `shared/_exercise_picker.html.erb`: the "Add exercises" pop-up

- **Before:** "Exercise name" (`col-12 col-sm-6`), "Muscle group" select (`col-7 col-sm-3`) and "Create" (`col-5 col-sm-3`) on one row.
- **After:** the name, the muscle-group pills and "Create" each take the full width (`col-12`). Nine pills need the width, and a full-width "Create" is easier to reach with a thumb.
- The id prefix is `"#{id}_muscle_group"`, with the picker's own id. The split page has one picker per workout day, so the ids stay unique.

### 4.4 `exercises/_form.html.erb`: the admin's exercise form

`f.input :muscle_group, collection: …, include_blank: "Other"` became the same partial, inside a `div.mb-3` to keep simple_form's spacing, with `selected: exercise.muscle_group`.

### 4.5 `shared/_equipment_fields.html.erb`: equipment of a lift

- The select became pills for `Lift::EQUIPMENT.invert.to_a` ("Free weights", "Machine").
- `data: { reveal_target: "source", action: "reveal#toggle" }` is on every radio, so picking "Machine" still shows "Machine brand".
- **Both columns are now `col-12`:** the pills on one row, the brand field under them. Side by side in the narrow card, the pills had no room.
- **The id prefix** is `"#{f.object_name}_#{f.object.id}_equipment"`.

### 4.6 `reveal_controller.js`

```js
// before
const show = this.sourceTarget.value === this.whenValue
// after
const show = this.sourceTargets.find((input) => input.checked)?.value === this.whenValue
```

There are now several source targets, the radios, and the value is the checked one. The controller is used only for equipment.

### 4.7 `test/integration/exercises_flow_test.rb`

The test "the muscle group is chosen from the list, not typed" now checks:
- the pill labels ("Other" plus `Exercise::MUSCLE_GROUPS`, in order)
- that the radio for the saved group (Chest) is checked
- that there is no text input and no `<select>` on the page

The part that posts "Pecs" and expects 422 is unchanged.

### 4.8 `doc/Issues/Issues.md`

- **Moved:** "Dropdowns past visible screen" went under "Issues resolved", in a new "Dropdowns" section, with a line on the cause and the fix. The open-issues part is now empty.
- **Added under "Potential issues":** "Muscle group and equipment pills not tried on a real phone", in a new "General" section.

## 5. Decisions

| Decision | Rejected alternative | Why |
|---|---|---|
| Replace the low-on-screen selects with pills | A hand-built dropdown that flips up (Popper on a custom list) | It would give up the phone's system picker, need JavaScript and keyboard handling written from scratch, and only fix what desktop emulation shows. Pills have no list to open at all. |
| Reuse `btn-check` + `btn-outline-primary` | A new look for the pills | The "Move a workout" pop-up already uses it, so the app keeps one style for picking an option. |
| One partial for three places | Markup copied into each view | Three call sites with the same markup; the partial also keeps the ids and the error line the same everywhere. |
| Leave the workout day form's two selects | Convert them too | They sit at the top of the page, so their list has room, and the issue named no others. The workout list is long, so pills would make that form taller. |
| Leave the user menu | Nothing needed | Bootstrap's dropdown already flips up through Popper. |
| No new JavaScript | A script to measure space and flip lists | Not needed once there is no list. |

**Assumption:** the owner's "dropdowns" means the select fields like the one in the screenshot. The navbar's user menu was checked and left alone.

## 6. How it works now

- **"Add exercises" pop-up, "Create your own":** type the name, tap a muscle group pill ("Other" is preselected), tap "Create".
- **Exercise page, "Equipment" card:** tap "Free weights" or "Machine". "Machine brand" shows only while "Machine" is picked, and is disabled (so not saved) otherwise.
- **The admin's exercise form:** the saved muscle group's pill is filled in.
- The parameters posted are the same as before, so controllers, models and validations are unchanged.

To try it:

```bash
bin/rails server -p 3001        # from the worktree, or from the main folder after merging
```

Then open the split page, press "Plan exercises" on a day and scroll to "Create your own". Or open any exercise and look at its "Equipment" card.

## 7. Tests and verification

- `bin/rails test`: 90 runs, 1235 assertions, 0 failures, 0 errors, 0 skips. The first run after the change had 19 errors (`f.object` is `false` in a `form_with` without a model), fixed in 4.1.
- `bundle exec rubocop`: 40 files, no offenses.
- `bundle exec brakeman`: no warnings.
- `bin/rails test test/lib/seed_data_test.rb`: 2 runs, 0 failures.
- Impeccable detector on the changed files: no findings.
- **Headless Chrome, 390 × 844, mobile emulation**, driven over the DevTools protocol by a script in the session's scratch folder (not in the repo):
  - **Split page pop-up:** the nine pills are shown, three per row, with "Other" checked. The page is no wider than the screen.
  - **Exercise page:** with "Machine" saved, the brand field shows. Tapping "Free weights" hides it. The two pills share the row. The page is no wider than the screen.
  - **Admin exercise form:** the "Chest" pill is checked. The page is no wider than the screen.
- **Not verified:**
  - on a real phone
  - with the keyboard open
  - in dark mode (the app has no dark theme)
  - the logged exercise's edit page (`workout_log_exercises/edit`), which uses the same partial as the exercise page but was not opened

## 8. Every file changed (10)

Code:
- `app/views/shared/_choices.html.erb` (new): the pills partial.
- `app/assets/stylesheets/components/_choices.scss` (new): the pills' grid, size and legend.
- `app/assets/stylesheets/application.scss`: imports `components/choices`.
- `app/views/shared/_exercise_picker.html.erb`: muscle group as pills, full-width rows.
- `app/views/exercises/_form.html.erb`: muscle group as pills.
- `app/views/shared/_equipment_fields.html.erb`: equipment as pills, brand under them.
- `app/javascript/controllers/reveal_controller.js`: reads the checked radio.

Tests:
- `test/integration/exercises_flow_test.rb`: checks the pills instead of the select.

Docs:
- `doc/Issues/Issues.md`: issue moved to resolved, one potential issue added.
- `doc/dropdowns-off-screen.md` (new): this doc.

`db/seeds/data.yml` is unchanged: `bin/rails seed:dump` found nothing new (1 user, 3 splits, 2 workouts, 46 sets).

## 9. Known gaps

- **Not tried on a real phone:** tap feel, a focus ring left on a tapped pill on iOS, thumb reach. Recorded as a potential issue.
- **The workout day form still uses selects.** On a phone they open the system picker. In desktop emulation their list could only run off the screen if the form were scrolled to the very bottom, which it is not.
- **More muscle groups make the pop-up taller,** one row per three groups.
- **Not pushed by the session:** the personal SSH agent (`~/.ssh/personal-agent.sock`) was not running, and starting it needs the key's passphrase. The owner pushes and opens the pull request (the final report gives the commands).
