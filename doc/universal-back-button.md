# Universal back button

Branch: `claude/universal-back-button-4813cc` (base `master` at `f043845`)
Date: 2026-11-15

## 1. Summary

Every sub-page of the app now shows one back button above its title. It always
leads to the page's parent (for example "New exercise" goes back to the exercise
list), not to whatever the browser visited last. The four top-level pages
(Dashboard, Splits, History, Exercises) and the login pages have no back button,
because the navbar already reaches them.

State: the test suite passes (28 runs, 252 assertions, 0 failures). The button
was also exercised against a running dev server over HTTP. Its appearance was
**not** looked at in a browser.

This resolves "General, issue 1" in `doc/Issues/Issues.md`. The "Home page"
issue in that file was deliberately left alone.

## 2. Timeline

1. **"Read Issues.md and first check how to apply the universal back button.
   Only focus on this issue."** Read the issue, the routes, the layout, the
   navbar and every link and redirect in the views and controllers. Reported an
   approach (a fixed "up to parent" button declared per view, drawn by the
   layout), a table of each page's parent, and one open decision (where a logged
   workout should go back to). Nothing was changed.
2. **"Yes, implement."** Added the `back_to` helper, the layout slot and the
   style, replaced the eyebrow breadcrumb in eleven views, and added an
   integration test. The first run of the new test failed because it opened
   `/exercises/new` as a normal user, and that page is admin-only; the test was
   fixed to open it as the admin. The view was correct.
3. **"Verify the changes you made actually work."** Started the dev server on
   port 3055, signed in as the seeded admin, opened all eleven sub-pages,
   followed each back button and checked the landing page. The Chrome extension
   was not connected and no browser is installed on the machine, so this was
   done over HTTP with a script rather than visually. The server was stopped
   afterwards.
4. **"Finalize branch."** Reran the tests, wrote this doc, committed, pushed and
   opened a pull request.

## 3. Starting point

- There was no back button. Each sub-page only had a small grey "eyebrow" link
  above the title (`<p class="eyebrow">`), such as `Exercises` above
  "New exercise" or `Splits / PPL` above a workout day. It was easy to miss and
  was written by hand, differently, in every view.
- The browser's back button was the only real way back, and it returns to the
  previously visited page. After a failed form submit or an "add set" redirect
  that is the same page or the form, which is what the issue complains about.
- Redirects after create, update and delete were already correct (creating an
  exercise already redirects to the exercise list). No controller needed to
  change.

## 4. Changes

### 4.1 `back_to` helper

`app/helpers/application_helper.rb`, new method:

```ruby
# Declares the page a view sits under. The layout draws it as the back button,
# so every sub-page gets the same control in the same place.
def back_to(label, path)
  content_for :back, link_to(tag.i(class: "fa-solid fa-arrow-left") + label, path, class: "back-link"), flush: true
end
```

Reason: one place builds the button, so its markup and icon are identical
everywhere. `flush: true` makes a second call replace the first instead of
appending a second button. The label is concatenated onto a safe buffer, so it
is HTML-escaped (labels come from user-typed split and day names).

### 4.2 Layout slot

`app/views/layouts/application.html.erb`:

```erb
<% else %>
  <%= yield :back %>
  <%= yield %>
<% end %>
```

Before, only `<%= yield %>` was there. The slot sits in the non-Devise branch,
inside `<main>`, directly above the page content. A view that declares nothing
renders nothing.

### 4.3 Views: eyebrow replaced by `back_to`

In each of the eleven sub-page views the `<p class="eyebrow">…</p>` breadcrumb
was removed and one line was added at the top of the file. Example
(`app/views/exercises/new.html.erb`):

Before:

```erb
<div class="page-header"><div><p class="eyebrow"><%= link_to "Exercises", exercises_path %></p><h1>New exercise</h1></div></div>
```

After:

```erb
<% back_to "Exercises", exercises_path %>
<div class="page-header"><div><h1>New exercise</h1></div></div>
```

Parent of each page:

| View | Button label | Goes to |
|---|---|---|
| `exercises/new` | Exercises | `exercises_path` |
| `exercises/edit` | Exercises | `exercises_path` |
| `splits/new` | Splits | `splits_path` |
| `splits/show` | Splits | `splits_path` |
| `splits/edit` | split name | the split |
| `workout_days/new` | split name | the split |
| `workout_days/show` | split name | the split |
| `workout_days/edit` | day name | the workout day |
| `workout_exercises/show` | day name | the workout day |
| `workout_logs/show` | day name | the workout day |
| `workout_log_exercises/edit` | "<day> workout" | the logged workout |

Two labels use the saved value rather than the current attribute
(`@split.name_was`, `@workout_day.day_was`), so that when a rename is rejected
and the form is shown again, the button still shows the real name and not the
invalid text being typed. `splits/edit` already did this in its eyebrow; it is
new for `workout_days/edit`, whose eyebrow pointed at the split, not the day.

The eyebrow text on the four top-level pages ("Programs", "History",
"Dashboard", "Catalogue") is plain text, not a link, and was left as it is.

### 4.4 Style

`app/assets/stylesheets/components/_app.scss`, new `.back-link` rule: a small
muted pill-shaped link with an arrow icon, 0.75rem above the page header, which
turns blue with a light blue background on hover and keyboard focus. The
`.eyebrow` rule stays because the top-level pages still use it.

### 4.5 Test

`test/integration/workout_flow_test.rb`, new test "every sub-page has one back
button to its parent, top-level pages have none". It checks, for each of the
eleven pages, exactly one `a.back-link` with the expected label and the
expected `href`; that the four top-level pages have none; and that a rejected
split rename still shows the saved name on the button.

## 5. Decisions

- **Fixed parent, not browser history.** Rejected: `history.back()` or
  `redirect_back`/referrer. Those repeat the browser's behaviour that the issue
  describes as the problem, and break after a failed submit.
- **Declared in the view, drawn by the layout.** Rejected: writing a link in
  each page header (the eyebrow approach), which is how the pages drifted apart;
  and a central route-to-parent map in a helper, which separates the rule from
  the page it belongs to.
- **Replace the eyebrow breadcrumbs instead of keeping both.** Two controls for
  the same thing would be noise. Consequence: the two-level trail on workout
  day, planned exercise and logged workout pages (for example `Splits / PPL`)
  is now a single step up.
- **Logged workout goes back to its workout day, not to History.** The page is
  reachable from History, the dashboard and the workout day, and a fixed parent
  can pick only one. This was put to the user as the open decision with the
  workout day recommended (it matches the old eyebrow), and the user answered
  "Yes, implement" without choosing History. Treated as acceptance of the
  recommendation; this is an assumption worth confirming.
- **Edit workout day goes back to the workout day**, not the split. Its Cancel
  button already goes to the workout day, so the two now agree. (Assumption: the
  page you came from is the right parent.)
- **No button on top-level and login pages.** The navbar covers them, and
  Dashboard has no parent.
- **No controller or route changes.** The redirects were already right.

## 6. How it works now

A sub-page view starts with `<% back_to "Label", some_path %>`. That stores a
link in `content_for :back`. The layout prints it inside `<main>` above the
page content. To give a new page a back button, add that one line; to leave a
page without one, add nothing.

To try it:

```bash
bin/rails server
```

Sign in, open any split, workout day or exercise page, and use the `← …`
button above the title.

## 7. Tests and verification

- `bin/rails test`: 28 runs, 252 assertions, 0 failures, 0 errors, 0 skips
  (run again just before the commit).
- Running app, over HTTP (dev server on port 3055, signed in as the seeded
  admin, development database): all eleven sub-pages returned 200 with exactly
  one back button, placed inside `<main>` before the page header; following each
  button returned 200 and landed on the expected parent page; the four top-level
  pages had no back button; the compiled stylesheet contained the `.back-link`
  rules.
- **Not verified:** how the button looks (size, spacing, hover, mobile width).
  No browser was available in the session. Devise pages were not opened in the
  running app, though the test suite renders them.

## 8. Every file changed

16 files (15 code and test files, plus this doc).

Helper, layout, style:

- `app/helpers/application_helper.rb`: new `back_to` helper.
- `app/views/layouts/application.html.erb`: prints the `:back` slot above the page.
- `app/assets/stylesheets/components/_app.scss`: `.back-link` style.

Views (eyebrow removed, `back_to` added):

- `app/views/exercises/new.html.erb`: back to Exercises.
- `app/views/exercises/edit.html.erb`: back to Exercises.
- `app/views/splits/new.html.erb`: back to Splits.
- `app/views/splits/show.html.erb`: back to Splits.
- `app/views/splits/edit.html.erb`: back to the split.
- `app/views/workout_days/new.html.erb`: back to the split.
- `app/views/workout_days/show.html.erb`: back to the split.
- `app/views/workout_days/edit.html.erb`: back to the workout day.
- `app/views/workout_exercises/show.html.erb`: back to the workout day.
- `app/views/workout_logs/show.html.erb`: back to the workout day.
- `app/views/workout_log_exercises/edit.html.erb`: back to the logged workout.

Test and doc:

- `test/integration/workout_flow_test.rb`: new back-button test.
- `doc/claude-universal-back-button-4813cc.md`: this file.

## 9. Known gaps

- The button's appearance has not been seen in a browser.
- A logged workout opened from History or the dashboard goes "back" to its
  workout day, not to where the user came from. If that feels wrong, the fix is
  one line in `app/views/workout_logs/show.html.erb`.
- `doc/Issues/Issues.md` lives only in the main folder (`/doc` is in
  `.gitignore`), so the issue was not moved to "Issues Resolved" by this branch.
- `/doc` is ignored by `.gitignore`; this file was added with `git add -f`, the
  same way the existing tracked doc in `doc/` must have been.
- The "Home page" issue (splits on their own page, week on the dashboard) is
  untouched.
