# History table on a phone

Branch `history-table-mobile-columns`. It was first created as `claude/history-table-mobile-columns-78c959` and renamed before anything was pushed. It was rebased onto `master` at `92bf060` (the owner's new issue and screenshots) before committing.

## 1. Summary

This branch fixes the issue under **History page** in `doc/Issues/Issues.md`: "Table columns off-screen on a phone".

On a phone (below 768 px) the History table (`/workout_logs`) now has two columns:

- one cell per workout, with:
  - the date, as a link
  - the workout name with its Rest day chip and split chip
  - "9 exercises · 27 sets"
- the **Open** button

The table is now 363 px wide in its 363 px card, so it no longer scrolls sideways. Before, it was about 595 px. From tablet width up (768 px and more), the six columns show exactly as before.

State: all 87 tests pass, including one new test. Rubocop reports no offenses and Brakeman reports no warnings. I checked the page in Chrome at 390 px and at desktop width. The seed data was re-dumped.

## 2. Timeline

1. **"Use the skill /investigate-issues to investigate the issue with ## History page ### Table columns off-screen on a phone."**
   - I traced the cause without changing anything (section 3) and explained it.
2. **"Yes fix it by merging them, also use the browser to confirm the fix is in place and looking good."**
   - I renamed the branch to `history-table-mobile-columns`, because the repo's rule is plain words with no digits and no `claude/` prefix.
   - I merged the columns into one cell at phone width, added the styles and a test, and ran the suite and rubocop.
   - I ran a server from the worktree on port 3001 and checked History in Chrome, at desktop width and at 390 px, including a long split name with a Rest day chip.
3. **"Yes, finalize it. Also be aware that I pushed Issues.md with a new issue registered and a couple of images."**
   - The owner's personal SSH key was not loaded in the agent, so fetching failed. The owner ran `ssh-add`.
   - I fetched `master` (`92bf060`: new "Future workout logs…" issue, "Dropdowns past visible screen" issue, two screenshots) and rebased the branch onto it. The `Issues.md` change is therefore made on the owner's new version, and the pull request does not conflict with it.
   - I re-ran the tests and linters, moved the issue, re-dumped the seed data, wrote this doc, committed and pushed.

## 3. Starting point

`app/views/workout_logs/index.html.erb` drew six columns at every width: Date, Workout, Split, Exercises, Sets, and one for the Open button. All of it sat inside Bootstrap's `table-responsive` wrapper. At 390 px the table's narrowest possible width was about 595 px, for these reasons:

- `components/_tables.scss` gives every `th` and `td` `1.25rem` (20 px) of padding on each side. That is about 240 px of padding across six columns, before any content.
- Headings are `white-space: nowrap` (`_tables.scss`), so "Exercises" is one unbreakable block.
- `.chip` is `white-space: nowrap` (`components/_lists.scss`). The split name (for example "U/R/L/U/L") and the Rest day chip cannot wrap.
- The date uses `format: :long` ("November 18, 2026"). It can wrap, but never narrower than "November".
- No `@media` rule exists for `.app-table`.

`table-responsive` turned the extra width into a sideways scroll inside the card. So only Date, Workout and part of Split were visible, and Exercises, Sets and Open needed a swipe.

## 4. Changes

### 4.1 The view: one merged cell on a phone (`app/views/workout_logs/index.html.erb`)

Before:

```erb
<table class="table app-table">
  <thead><tr><th>Date</th><th>Workout</th><th>Split</th><th>Exercises</th><th>Sets</th><th></th></tr></thead>
  ...
  <td class="fw-semibold"><%= link_to l(log.date, format: :long), workout_log_path(log, from: from) %></td>
  <td><%= log.workout %><% if log.rest_day? %> <span class="chip chip-rest">Rest day</span><% end %></td>
  ...
```

After:

- The table has the extra class `history-table`, for the page's own styles.
- The header has a phone-only `<th class="d-md-none">Workout</th>`. The five data headings get `d-none d-md-table-cell`, which hides them below 768 px and shows them as table cells from 768 px up. The Open column's empty heading stays at every width.
- Each row first works out:
  - `path`, the workout's link with `from`, as before
  - `exercises` and `sets`, the two counts
  - `rest_chip` and `split_chip`, the two chips (built with `capture`)

  Each of these is written once and used in both layouts, so the phone and desktop cells can't drift apart.
- A phone-only first cell, `td.history-summary.d-md-none`, holds:
  ```erb
  <%= link_to l(log.date, format: :long), path, class: "fw-semibold" %>
  <div class="history-line"><%= log.workout %><%= rest_chip %> <%= split_chip %></div>
  <div class="history-counts"><%= pluralize(exercises, "exercise") %> · <%= pluralize(sets, "set") %></div>
  ```
- The five original cells are unchanged in content and get `d-none d-md-table-cell`.
- The Open cell stays at every width.

Why: the owner asked to fix it "by merging them". Bootstrap's display utilities already do this elsewhere in the app: `admin/users/index.html.erb` hides Joined and Workouts on a phone with `d-none d-md-table-cell`.

### 4.2 Styles (`app/assets/stylesheets/pages/_workout_log.scss`)

These are added at the end of the workout-log page file, which `application.scss` already imports after `components/tables`, so they win over the base table rules:

```scss
.history-table .history-summary { padding-right: .5rem; }
.history-line { display: flex; flex-wrap: wrap; align-items: center; gap: .25rem .375rem; margin-top: .125rem; }
.history-counts { margin-top: .125rem; font-size: .8rem; color: $muted; }
@media (max-width: 767.98px) {
  .history-table td:last-child { padding-left: 0; padding-right: 1rem; }
}
```

- `.history-line` is a wrapping flex row, so a long split name drops onto a second line instead of widening the table.
- The counts are smaller and grey, like other secondary text in the app.
- On a phone the space between the merged cell and the Open button is smaller, so the merged cell gets more room. The breakpoint `767.98px` is Bootstrap's own `md` boundary, matching `d-md-*`.

### 4.3 Test (`test/integration/navigation_flow_test.rb`)

The new test "on a phone the history puts date, workout, split and counts in one cell" does this:
- logs two sets of one exercise through `WorkoutExercise#entry_on!`
- checks that the merged cell holds the date link, the workout name, the split chip and "1 exercise · 2 sets"
- checks that five headings and five cells carry `d-none d-md-table-cell`

The existing tests still pass unchanged. Those include `assert_select "td", text: "Push"` in `dashboard_flow_test.rb` and the pagination row counts, which still pass because each workout is still one `<tr>`.

## 5. Decisions

- **Merge rather than hide.** Hiding Exercises and Sets on a phone would also have fitted, but the owner asked for merging, and the counts are useful at a glance.
- **Show both layouts in the HTML, switched by Bootstrap classes, rather than CSS grid on `<tr>`.** It is plain, uses classes the app already uses, and needs no JavaScript. The cost is that each row's data appears twice in the HTML. The shared values are built once per row, so they can't differ.
- **Keep the Open button on a phone.** It is a big, obvious tap target. The date in the merged cell is also a link.
- **Keep the desktop table exactly as it was.** The issue is only about phones.
- **Leave the global `.app-table` padding alone.** The exercise catalogue and admin users tables also use it. Changing it is a separate question, not part of this issue.
- **Rebase, not merge, onto the new `master`.** The branch had not been pushed yet, so rebasing needed no force push. The pull request then contains only this branch's work on top of the owner's latest `Issues.md`.

## 6. How it works now

- **Phone (below 768 px):** History shows a "Workout" heading over one cell per workout:
  - the date link
  - the workout name, then the Rest day chip (when the workout was done on a rest day), then the split chip, or "Deleted" for a deleted split
  - "N exercises · M sets" in small grey text

  The Open button is on the right. The table fits its card, and long chips wrap.
- **Tablet and desktop (768 px and up):** the six columns Date, Workout, Split, Exercises, Sets and Open, unchanged.
- The same applies to a calendar day with several workouts (`/workout_logs?date=…`), which uses the same view.

To try it: `bin/rails server`, sign in, open History, and use the browser's phone view (390 px).

## 7. Tests and verification

- `bin/rails test`: 87 runs, 1138 assertions, 0 failures, 0 errors, after the rebase.
- `bundle exec rubocop`: 39 files, no offenses.
- `bundle exec brakeman`: no warnings.
- `bin/rails test test/lib/seed_data_test.rb`: 2 runs, 0 failures, after the dump.
- **Chrome, desktop (1536 px):** the six columns as before, checked by screenshot.
- **Chrome, phone (390 px):** the Chrome window could not be shrunk, because it was maximized. The page was loaded in a 390 px-wide frame instead (`innerWidth` 389).
  - The table is 363 px in a 363 px box, with no sideways scroll and no page overflow.
  - The merged cell is displayed and the separate columns are hidden. Checked by screenshot.
  - Long names: the first row's text was replaced in the browser only (not in the data) with "Legs", a Rest day chip and a "Push Pull Legs Upper Lower" split chip. The chips wrapped onto a second line and the table stayed 363 px.
- **Not verified:** a real phone. The check was done in desktop Chrome at 390 px.

## 8. Every file changed (6)

Code:
- `app/views/workout_logs/index.html.erb`: merged phone-only cell, wide columns hidden below 768 px.
- `app/assets/stylesheets/pages/_workout_log.scss`: styles for the merged cell and the narrower Open column on a phone.

Tests:
- `test/integration/navigation_flow_test.rb`: new test for the merged cell and the hidden columns.

Docs and data:
- `doc/Issues/Issues.md`: "History page › Table columns off-screen on a phone" moved under "Issues resolved (DONE)", with a line on the fix.
- `doc/history-table-mobile-columns.md`: this document.
- `db/seeds/data.yml`: re-dumped. It gained the Lower workout of 2026-11-19 (split U/R/L/U/L) with its exercises and sets, and the own exercises Hip thrust, Leg extension, Adductor and Crunch. Nothing was removed. The file now holds 1 user, 3 splits, 3 workouts and 47 sets.

`doc/Features/Features.md` was not changed: no feature in it matches this fix.

## 9. Known gaps

- The other `.app-table` pages (the exercise catalogue with 4 columns, and the admin users page) keep the wide 20 px padding. Admin users already hides columns on a phone. The catalogue was not measured at 390 px.
- Not tried on a real phone.
