# exercise-picker-delete

## 1. Summary

An admin can now delete an exercise straight from the "Add exercises" pop-up: every row there has a small red × after the name. It asks first in the app's own confirm box ("Delete Squat for everyone?" for a shared exercise, "Delete Pec Fly?" for the admin's own), deletes, and returns to the page the pop-up was on (a split, a workout day, a logged workout, or a new workout), with "Squat deleted." on top. An exercise that is in someone's plan is still refused, with the usual alert, on the same page.

On the way, the app's confirm box was made to open above another open pop-up. Before, it opened behind "Add exercises" and could not be seen.

State: tested. `bin/rails test`: 156 runs, 2184 assertions, 0 failures. Rubocop: no offenses. Brakeman: no warnings. Checked in Chrome at 390 px (see section 7 for how and what was not).

## 2. Timeline

1. **"Please plan the feature on Exercise page in Features.md."** The `plan-features` skill read the one open feature under `### Exercise page` ("Admins are also able to delete exercises already created with a small button on the side of the name in the modal.") and the code it touches, and gave a plan with four open questions (normal users too? rows marked "Added"? keep the pop-up open? warn that a shared delete is for everyone?). Nothing was changed.
2. **"Yes, build it."** The owner did not answer the open questions, so the suggested answers were used (section 5). Built, tested, checked in Chrome. The browser check found the confirm box opening behind the pop-up, which was fixed. The checkbox's accessible name was also fixed.
3. **"Finalize it."** This doc, the feature moved to DONE in `Features.md`, potential issues added to `Issues.md`, seed data refreshed, commit, push, pull request.

## 3. Starting point

- `ExercisesController#destroy` already deleted any exercise an admin can see (the shared catalogue and the admin's own), and a normal user's own exercises (`set_exercise`). An exercise in anyone's plan is refused (`has_many :workout_exercises, dependent: :restrict_with_error`); logged workouts keep the name and lose only the link (`dependent: :nullify`).
- It was only offered on the Exercises page (`/exercises`), in each row's ⋯ menu, and always redirected to `/exercises`.
- The "Add exercises" pop-up (`shared/_exercise_picker`) had no delete. Each row is a `<label>` holding the checkbox, the name, "Added" and "Yours", and all rows sit inside the "Add selected" `<form>`.
- Goal (owner's words): "Admins are also able to delete exercises already created with a small button on the side of the name in the modal."

## 4. Changes

### The × in the pop-up (`app/views/shared/_exercise_picker.html.erb`)

Before, a row was:

```erb
<label class="picker-row ...">
  <%= check_box_tag "exercise_ids[]", exercise.id, false, id: "#{id}_#{exercise.id}", class: "form-check-input", disabled: taken %>
  <span class="picker-name"><%= exercise.name %></span>
  ...Added / Yours...
</label>
```

After, for an admin only, the row ends with:

```erb
<%= link_to exercise_path(exercise), class: "btn btn-link btn-sm text-danger picker-delete",
      "aria-label": "Delete #{exercise.name}", title: "Delete #{exercise.name}",
      data: { turbo_method: :delete, turbo_action: "advance",
              turbo_confirm: "Delete #{exercise.name}#{' for everyone' if exercise.shared?}?" } do %>
  <i class="fa-solid fa-xmark" aria-hidden="true"></i>
<% end %>
```

- A link with `turbo_method: :delete`, not the house `button_to` / `menu_delete`: those build a `<form>`, and the row is already inside the "Add selected" form; forms cannot nest (the browser drops the inner one). The navbar's Log out uses the same kind of link.
- A link inside a `<label>` is interactive content, so tapping it does not tick the row's checkbox (checked in Chrome).
- `turbo_action: "advance"`, like the pop-up's two forms, so the page loads in full afterwards and the pop-up can open again.
- The checkbox now has `aria-labelledby` pointing at the name's `<span>` (new id `<picker id>_<exercise id>_name`). Without it, a screen reader read the whole label, including the ×: "Lat pulldown Added Delete Lat pulldown".

### Back to the same page (`app/controllers/exercises_controller.rb`)

`destroy` used `redirect_to exercises_path` for both success and refusal; it now uses `redirect_back_or_to exercises_path` (already used by `WeekMovesController`). From the Exercises page it still lands on the Exercises page; from a page with the pop-up it lands back there. Without a Referer it falls back to `/exercises`.

### Tap target (`app/assets/stylesheets/components/_exercise_picker.scss`)

`.picker-delete`: at least 2.75 rem (44 px) square, centred icon, no underline (a link is underlined by default), negative vertical margin so the row keeps its height.

### Confirm box above another pop-up (`app/assets/stylesheets/components/_confirm.scss`)

```scss
.modal-backdrop ~ .modal-backdrop { z-index: $zindex-modal + 5; }
.confirm-modal { z-index: $zindex-modal + 10; ... }
```

Both the confirm box and "Add exercises" are Bootstrap modals at z-index 1055; the confirm box comes earlier in the page, so the pop-up was drawn over it and the question could not be seen or answered. Now the confirm box is 1065 and its own backdrop (the second one in the page) 1060, between the two, so the pop-up behind is tinted. With only one modal open nothing changes (the first backdrop stays 1050).

### Tests (`test/integration/exercises_flow_test.rb`)

New test "an admin deletes an exercise from the Add exercises modal":

- a normal user sees no × in the pop-up on their workout day, even for their own exercise;
- an admin sees one on every row, including a row marked "Added", each a delete link with a confirm; a shared exercise's says "Delete Squat for everyone?";
- a delete sent from the workout day returns to it, with "Squat deleted.";
- an exercise in a plan is kept, and the alert comes back on the same page;
- another user's own exercise is a 404 for the admin.

### Docs

- `CLAUDE.md` code map: the pop-up's × and `redirect_back_or_to`; the confirm box sits above another open modal.
- `doc/Features/Features.md`: the feature moved to "Features added (DONE)".
- `doc/Issues/Issues.md`: three potential issues added (section 9).

## 5. Decisions

- **Admins only.** The feature says admins. A normal user can already delete their own exercises from the Exercises page, and the server would allow it from the pop-up too, but it was not asked. Rejected: an × on "Yours" rows for everyone. (Assumption: the owner's silence on the open question meant the suggestion.)
- **An × on every row, "Added" ones too.** Same list behaving the same everywhere; a planned one is refused anyway, an extra one keeps its name in the workout. (Assumption, as above.)
- **The pop-up closes after a delete.** The page reloads; keeping it open would need JavaScript. Accepted cost: deleting a second exercise means opening "Add exercises" and the group again. (Assumption, as above.)
- **"for everyone" in the question for shared exercises**, since deleting one removes it from every user's catalogue and unlinks their past workouts (names stay).
- **A link, not a button inside a nested form,** because forms do not nest. Rejected: a `<button form="...">` pointing to one hidden form per exercise outside the main form: more markup for the same result.
- **`redirect_back_or_to`** rather than a `return_to` parameter: one word, and it also covers the Exercises page.
- **Fix the stacking in CSS** rather than closing the pop-up before asking: the owner keeps the context of the list behind the question, and Cancel leaves the pop-up as it was.
- **Branch and folder.** The plan was to build in a new worktree `.claude/worktrees/exercise-picker-delete`, but the session's hook only allows writing inside the session's own worktree. That empty worktree was removed and the session's branch (`claude/exercise-page-feature-plan-616ffd`, at master's commit, no changes) was renamed to `exercise-picker-delete`; its folder kept the name `exercise-page-feature-plan-616ffd`.

## 6. How it works now

1. An admin opens "Add exercises" (a split's day card, a workout day, a logged workout, or a new workout) and opens a muscle group.
2. Each row: checkbox, name, "Added" / "Yours", then a red ×.
3. Tapping × opens the app's confirm box on top of the pop-up: "Delete Bench press for everyone?" (shared) or "Delete Pec Fly?" (own), with Cancel and Delete.
4. Delete: `DELETE /exercises/:id` through Turbo; `ExercisesController#destroy` deletes it and goes back to the page, with "Bench press deleted." If the exercise is in any plan (anyone's), nothing is deleted and the alert "Bench press was not deleted: …" shows on the same page.
5. Cancel: the confirm box closes, the pop-up stays open and its rows can still be ticked.

A normal user's pop-up is unchanged. Nothing in the data model changed.

To try it: `bin/rails server -p 3005` from the branch, sign in as an admin, open a workout day, "Add exercise".

## 7. Tests and verification

- `bin/rails test`: 156 runs, 2184 assertions, 0 failures, 0 errors.
- `bundle exec rubocop`: 57 files, no offenses. `bundle exec brakeman`: no warnings.
- Chrome (WSL), signed in as the development admin on a server from this branch (port 3005), on a workout day: the × on every row, no underline; tapping × did not tick the checkbox; the confirm box opened above the pop-up with the pop-up tinted; Delete removed a throwaway exercise ("Zz picker test", created for the check through `rails runner`) and returned to the same workout day with the notice; Cancel left the pop-up open and a row could still be ticked.
- Not verified: Chrome would not shrink its maximised window, so 390 px was checked inside a 390 × 844 frame in the page, not with device emulation, and not on a phone. The refused delete (exercise in a plan) is covered by the test only, not tried in the browser. The pop-up on the split page, a logged workout and a new workout was not opened in the browser (same partial). A screen reader was not used; the accessible name was checked in Chrome's accessibility tree only before the fix, and by the attribute after it.

## 8. Every file changed

Code:
- `app/views/shared/_exercise_picker.html.erb`: the admin's × on each row; the checkbox named by the exercise name alone.
- `app/controllers/exercises_controller.rb`: `destroy` returns to the page it came from.
- `app/assets/stylesheets/components/_exercise_picker.scss`: size and look of the ×.
- `app/assets/stylesheets/components/_confirm.scss`: the confirm box and its backdrop above another open modal.

Tests:
- `test/integration/exercises_flow_test.rb`: the new test.

Docs and data:
- `CLAUDE.md`: code map lines for the pop-up's × and the confirm box.
- `doc/exercise-picker-delete.md`: this doc.
- `doc/Features/Features.md`: the feature moved to DONE.
- `doc/Issues/Issues.md`: three potential issues.
- `db/seeds/data.yml`: refreshed by `bin/rails seed:dump` (see section 10).

## 9. Known gaps

- After Cancel in the confirm box, Bootstrap's focus trap of the "Add exercises" pop-up is off (the second modal took it over), so Tab can leave the pop-up until it is closed and opened again. Mouse and touch are not affected. Added to `Issues.md`.
- Deleting a shared exercise deletes it for every user and unlinks their past workouts (their names stay). The confirm says "for everyone", but nothing lists who used it. Added to `Issues.md`.
- Not tried on a real phone. Added to `Issues.md`.
- Moved in `Features.md`: "Admins are also able to delete exercises already created with a small button on the side of the name in the modal." (Exercise page → Features added (DONE), Exercise page).

## 10. Seed data

`bin/rails seed:dump` was run before committing. The file now holds 2 users, 3 splits, 6 workouts and 48 sets. It gained one user already in the development database, `notadmin@example.com` (not an admin, Asia/Tokyo); nothing was removed, and no workouts, splits or exercises changed. The throwaway "Zz picker test" exercise was deleted in the browser check before the dump, so it is not in the file. `test/lib/seed_data_test.rb`: 4 runs, 0 failures.
