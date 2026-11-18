# Alerts and back button

Branch `alerts-and-back-button` (first created as `claude/issues-general-investigation-02e805`, renamed before anything was pushed).

## 1. Summary

This branch fixes the two issues listed under **General** in `doc/Issues/Issues.md`:

- **Alerts.** Flash messages now look like the rest of the app. Each one is a white card at the top of the screen with a coloured icon, the message and a × button. It fades in over 0.5 s, stays 5 s with a thin bar counting down, then fades out over 0.5 s. Delete confirmations no longer use the browser's `confirm()` pop-up. They open an in-app box over a tinted, slightly blurred page.
- **Back button.** The back button is now a round arrow with no text. It goes back to the page the user was really on before, not to a fixed "parent" page. Form pages (new, edit) are skipped once saved, and so is the page of a record that was just deleted. When the tab has no earlier page, for example a link opened directly, it goes to the page's parent as before.

State: all 86 tests pass. Rubocop reports no offenses and Brakeman reports no warnings. The new behaviour was checked in Chrome, at phone width (390–400 px) where the window allowed it. The seed data was re-dumped and had not changed.

## 2. Timeline

1. **"Read Issues.md on master, under General. Find the cause of the 2 issues and explain it."**
   I read the code and explained the causes without changing anything (section 3).
2. **"Turn the back button's text into an arrow. Fix both issues. First fix the alert, watch out for mobile layouts, use Chrome to inspect it, and stop there."**
   - I renamed the branch to `alerts-and-back-button`, because the repo's rule is plain words with no digits and no `claude/` prefix.
   - I rewrote the flash partial and added a Stimulus controller that removes the card after 5 s.
   - I replaced the old global `.alert` rule with a `.flash` stylesheet.
   - I added a test, then checked the result in Chrome at phone width. I stopped there, as asked.
3. **"Make the alert show up more and disappear more smoothly, like a 0.5 seconds fade. When deleting I get a browser alert: turn it into an in-app box that pops up and tints the background."**
   - I changed the fade to 0.5 s in each direction.
   - I fixed a bug that could cut the fade-out short (section 4.2).
   - I replaced Turbo's confirm method with an in-app modal used by every `data-turbo-confirm`.
   - I checked it in Chrome: the look, Cancel and Delete.
4. **"Yes, back button."**
   - I added the per-tab page trail and the arrow, with its controller.
   - I changed `back_to` to take only a path and updated the 16 calls and the tests.
   - In Chrome I checked the dashboard-circle example, a deeper chain, skipping a form, the fallback and the delete rule.
5. **"Yes, finalize."**
   - I moved both issues under "Issues resolved", updated the code map in CLAUDE.md and re-dumped the seed data.
   - I wrote this doc, committed, pushed and opened the pull request.

## 3. Starting point

### Alerts

`app/views/shared/_flashes.html.erb` printed Bootstrap's stock `alert alert-info` (notice) and `alert alert-warning` (alert) boxes with a close button. The app's only styling was one rule in `components/_alert.scss`:

```scss
.alert { position: fixed; bottom: 16px; right: 16px; z-index: 1000; }
```

- **Look.** The rest of the app uses white cards with a thin `$line` border, a soft shadow and 1rem corners. The alerts were Bootstrap's tinted boxes in the bottom-right corner, sized to their text. The notice was pale blue because `$info` is set to a variable named `$yellow` whose value is blue. The alert was pale orange.
- **They never left.** No JavaScript dismissed them. Only the × closed them.
- **Side effect.** The rule matched *every* `.alert`. It also pinned the inline error box on the "edit logged exercise" page (`workout_log_exercises/edit`, `alert alert-danger`) to the bottom-right corner.
- **Delete confirmations** used `data-turbo-confirm`. Turbo shows that with the browser's native `confirm()` dialog.

### Back button

Every sub-page named its own fixed target with `<% back_to "Label", path %>`. `ApplicationHelper#back_to` drew a link with an arrow and the label. So the button always went to the same "parent", whichever way the user arrived. For example:

- The circles in the dashboard's Active split box link to `workout_day_path(day)`.
- `workout_days/show` declares `back_to @workout_day.split.name, @workout_day.split`.
- So back from there opened the split page instead of the dashboard.

Nothing recorded the page the user came from. The only exception was a hand-made `?from=dashboard` parameter, honoured by three pages.

## 4. Changes

### 4.1 Flash messages: new markup and style

**Before**, in `_flashes.html.erb`:

```erb
<% if notice %>
  <div class="alert alert-info alert-dismissible fade show m-1" role="alert">
    <%= notice %>
    <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
  </div>
<% end %>
<% if alert %> ... alert-warning ... <% end %>
```

**After**:

```erb
<% messages = { notice: notice, alert: alert }.compact_blank %>
<% if messages.any? %>
  <div class="flash-stack" data-turbo-temporary>
    <% messages.each do |kind, message| %>
      <div class="flash flash-<%= kind %>" role="<%= kind == :alert ? "alert" : "status" %>"
           data-controller="flash" data-flash-delay-value="5000">
        <span class="flash-icon"><i class="fa-solid fa-circle-exclamation | fa-circle-check"></i></span>
        <p class="flash-text"><%= message %></p>
        <button type="button" class="flash-close" data-action="flash#dismiss" aria-label="Close">…</button>
        <span class="flash-timer" aria-hidden="true"></span>
      </div>
    <% end %>
  </div>
<% end %>
```

The new `components/_flash.scss` replaces `components/_alert.scss`, which is deleted:

- **`.flash-stack`:** `position: fixed` at the top centre, `z-index: 1090`, above the sticky navbar like Bootstrap's toasts. It respects `env(safe-area-inset-top)` for phones with a notch. It has `pointer-events: none`, so the space around the cards does not block taps.
- **`.flash`:** a white card with a `$line` border, `$border-radius-xl`, a soft shadow and `max-width: 26rem`. On a phone it spans the width with a 12 px gutter each side.
- **Icon:** a 2 rem circle in the message's colour at 12 % (`color-mix`). A notice is green (`$green`, with a check) and an alert is red (`$red`, with an exclamation mark).
- **`.flash-close`:** a 36 px round button for the ×.
- **`.flash-timer`:** a 3 px bar along the bottom that shrinks over 5 s, so the user can see the message is about to leave.
- **Reduced motion:** with `prefers-reduced-motion: reduce` there is no animation and no timer bar.

`application.scss` imports `components/flash` (and `components/confirm`) where `components/alert` was.

**Why:** the messages now match the cards. They sit where a phone user looks, at the top, without covering the thumb area. Because the global `.alert` rule is gone, the inline `alert-danger` on the edit page sits in its form again. `data-turbo-temporary` keeps the messages out of Turbo's page cache, so going back does not show an old message again. `role="status"` (polite) for notices and `role="alert"` for errors let screen readers announce them.

### 4.2 Flash messages leave by themselves, with a 0.5 s fade

`app/javascript/controllers/flash_controller.js` is new:

- On `connect` it starts a timer (`delay` value, 5000 ms).
- `dismiss()` (timer or ×) adds `is-leaving`. That class runs the `flash-out` animation (0.5 s, `ease-in-out`). When the card's own `animationend` fires, the card is removed.
- As a fallback, a 600 ms timeout removes it anyway. This is for reduced motion, where no animation runs and so no `animationend` comes.

Animations: `flash-in` (0.5 s, `ease-out`) goes from opacity 0 and 6 px higher to its place. `flash-out` is the reverse.

**Bug found and fixed:** the timer bar inside the card ends its own 5 s animation at about the moment the fade-out starts. Its `animationend` event bubbles up to the card, which could remove the card before the fade had played, so it vanished instead of fading. The listener now only acts when `event.target === this.element`.

### 4.3 In-app delete confirmation

- `app/views/shared/_confirm.html.erb` is new. It is a Bootstrap modal (`#confirm-modal`, `modal-dialog-centered`) holding a red trash icon, a title, a detail line, and **Cancel** and **Delete** buttons. The layout renders it once on every page.
- `app/javascript/confirm_dialog.js` is new. It is pinned in `config/importmap.rb` and imported in `application.js`. It sets `Turbo.config.forms.confirm`, so every existing `data-turbo-confirm` uses the box. No view had to change.
- **Splitting the message:** the text is cut at its first `?`. The question becomes the title and the rest becomes the grey detail. For example, "Delete this split and its days?" with "Your logged workouts are kept." below.
- **Button label:** the red button shows the message's first word when that is "Delete" or "Remove", and "Yes" otherwise. "Cancel my account" uses "Are you sure?", so it gets "Yes".
- **When the answer is given:** the promise resolves only on `hidden.bs.modal`, after the box has finished closing. Turbo therefore never caches the page with the box still open. Cancel, Esc and a tap outside the box all resolve `false`.
- **Fallback:** if the modal element is missing, it falls back to `window.confirm`.

New stylesheet, `components/_confirm.scss`:

- The box is 22 rem wide at most, white, with 1.5 rem corners and a deep shadow. Everything is centred.
- The two buttons sit side by side at equal width, each about 42 px tall for a thumb.
- `.modal-backdrop.show` gets `backdrop-filter: blur(2px)`.

In `config/_bootstrap_variables.scss`, `$modal-backdrop-bg: $gray` and `$modal-backdrop-opacity: .45` tint the page with the app's text colour instead of pure black. This also applies to the "Add exercises" picker, which is intended.

### 4.4 Back button: arrow, and the page visited before

**Helper.** Before:

```ruby
def back_to(label, path)
  content_for :back, link_to(tag.i(class: "fa-solid fa-arrow-left") + label, path, class: "back-link"), flush: true
end
```

After:

```ruby
def back_to(path)
  content_for :back, link_to(tag.i(class: "fa-solid fa-arrow-left", aria: { hidden: true }), path,
                             class: "back-link", aria: { label: "Back" }, title: "Back",
                             data: { controller: "back", action: "back#go" }), flush: true
end
```

All 16 calls in 13 views lost their label argument. For example, `back_to @workout_day.split.name, @workout_day.split` became `back_to @workout_day.split`. The ternaries in `workout_logs/index`, `workout_logs/show` and `exercises/edit` keep their logic and only drop the labels.

**Style.** `.back-link` in `components/_layout.scss` is now a 40 px white circle with a `$line` border and a dark arrow. On hover or focus it turns indigo on `$primary-soft`, and it shrinks slightly when pressed.

**Trail.** `app/javascript/back_trail.js` is new. It is pinned and imported in `application.js`, so it runs on every page. It keeps the tab's pages in `sessionStorage` (`back-trail`, at most 50 entries). On every `turbo:load`:

- The same URL as the last entry (a reload, or a form that redirects to its own page) only refreshes that entry's `skip` flag.
- The URL of the entry before the last (the browser's Back, or a link to that page) pops the last entry.
- Any other URL is pushed.

Each entry also records `skip`, read from the new `body[data-back-skip]`. The layout sets it to true on `new`, `edit`, `create` and `update` actions, so form pages are never a back target.

On `turbo:submit-start`, when the form is a DELETE (Rails' hidden `_method` or the form's method) aimed at the current page's path, that path and every path under it (such as `/splits/3/edit`) are removed from the trail. Turbo fires `turbo:submit-start` only after the confirmation box is accepted, so a cancelled delete forgets nothing.

**Arrow.** `app/javascript/controllers/back_controller.js` is new. On click, without a modifier key, it asks `takePreviousPage()` for the last entry that is neither the current URL nor skipped. It cuts the trail back to that entry and visits it with `Turbo.visit`. When there is none, the link is followed normally to its `href`, the parent page.

### 4.5 Issues and project notes

- In `doc/Issues/Issues.md`, both General issues moved under "Issues resolved (DONE)" with a line on the fix and a link to this doc. The open list keeps only the History table issue.
- In `CLAUDE.md`, the code map line on `back_to "Label", path` now describes `back_to path`, the trail and the skip rules. A new line covers the flash cards and the in-app confirm box.

## 5. Decisions

- **Messages at the top, not the bottom.** Top-centre is where phone users look for a system message. The Issues list also plans a bottom navigation bar, which bottom alerts would collide with. *Rejected:* keeping the bottom-right corner.
- **Above the navbar (`z-index` 1090).** The card overlays the navbar for a few seconds instead of depending on its height. *Rejected:* positioning below a hard-coded navbar height.
- **Green notice and red alert,** not the theme's `info` and `warning`. Almost every notice in the app confirms a success ("Set 1 added"), and every alert is a refusal or an error.
- **"Show up more" read as "appear more smoothly".** *Assumption:* the request was about the fade, not a bigger or louder card. The card's size and colours did not change in that round.
- **One confirm box for the whole app.** It replaces Turbo's confirm method, so every existing `data-turbo-confirm` uses it, not only "Delete workout". *Rejected:* a confirm only for that one button, which would leave the browser pop-up everywhere else.
- **Nothing focused when the box opens.** Bootstrap focuses the dialog itself. I first focused Cancel, but its focus state looked pressed and grey. With the dialog focused, a stray Enter deletes nothing either.
- **A trail of our own, not plain `history.back()`.** `history.back()` alone would step back into a saved edit form, into the page of a just-deleted record (a 404), or out of the app when a page was opened directly. The trail skips forms and deleted pages, and falls back to the parent link.
- **`Turbo.visit` to the previous page (advance),** not `history.back()`. The target can be several history entries back after skipping, so going there is a new visit. The browser's own Back still works and updates the trail.
- **One trail per tab (`sessionStorage`).** Each tab has its own path. It clears when the tab closes, and it needs no server state. If storage is blocked, the arrow falls back to the parent link.
- **Screen-reader label "Back", not "Back to PPL".** The arrow may lead somewhere other than the parent, so naming the parent would be wrong. With the visible label gone, the helper only needs the path, so the label argument was removed rather than left unused.
- **`?from=dashboard` left as it is.** It still decides where a deleted workout returns to (the dashboard) and the fallback target. It is no longer what makes the back button work.

## 6. How it works now

- **A flash message** (any `notice` or `alert`) shows at the top as a card. It fades in, counts down 5 s, then fades out, or leaves at once on ×.
- **Any `data-turbo-confirm`** (deleting a workout, a split, a day, a user or a catalogue exercise, removing an exercise, cancelling the account) opens the in-app box over a tinted page. Cancel, Esc or a tap outside the box does nothing. The red button goes ahead.
- **The back arrow** on a sub-page goes to the page you were on before. For example:
  - Dashboard → Monday circle → arrow → Dashboard.
  - Dashboard → day → exercise → arrow → day → arrow → Dashboard.
  - History → split → Edit → Save → arrow → History.
  - Opened directly → arrow → the page's parent.

To try it:

```bash
bin/rails server -p 3001     # from this branch's checkout
```

Then open http://localhost:3001 at phone width. Locally you can sign in with the seed admin (`admin@example.com`, development password from `db/seeds.rb`).

## 7. Tests and verification

**Run:**

- `bin/rails test`: 86 runs, 1126 assertions, 0 failures, 0 errors, 0 skips.
- `bundle exec rubocop`: 39 files, no offenses.
- `bundle exec brakeman -q`: no warnings.
- `bin/rails test test/lib/seed_data_test.rb`: 2 runs, 0 failures. `bin/rails seed:dump` left `db/seeds/data.yml` unchanged (1 user, 3 splits, 1 workout, 27 sets).

**New and changed tests** (`test/integration/navigation_flow_test.rb` and others):

- **Flash markup:** a notice is a `.flash.flash-notice[role=status][data-controller=flash]` inside `.flash-stack[data-turbo-temporary]`, with the × wired to `flash#dismiss`. An alert is `.flash-alert[role=alert]`. A page without a message has no stack.
- **Confirm box:** the workout page's delete form carries its `data-turbo-confirm`, and the layout includes `#confirm-modal` with title, detail, Cancel and accept.
- **Back arrow:** every sub-page has exactly one `a.back-link[aria-label=Back][data-controller=back][data-action='back#go']` with no text. Its `href` is still the parent. Top-level pages have none.
- **Skip flag:** an edit page has `body[data-back-skip=true]` and a show page has `false`.
- In `dashboard_flow_test.rb`, `exercises_flow_test.rb` and the navigation test, assertions on the old visible labels now assert the target (`href`) only.

**In Chrome:**

- **Flash look:** red alert on the sign-in redirect and green notice from "Forgot your password?", at about 400 px. Long text wraps and there is no sideways scroll. The × removes the card, and it also leaves by itself.
- **Fade timing:** checked by stepping through the animations. Opacity goes 0 → 0.68 → 1 over 0.5 s coming in, and 1 → 0.5 → 0 over 0.5 s going out. The test Chrome window does not play animations live, so the live fade was not watched.
- **Confirm box:** opened from an injected test form carrying the real message texts (no real delete was made). Title and detail render correctly. Cancel keeps the page and leaves no backdrop. Delete goes ahead.
- **Back arrow:** signed in as the seed admin on port 3001, navigating only. The circle → arrow → dashboard, the deeper chain, the edit skip and the fallback were checked. The delete rule was checked by firing `turbo:submit-start` from a test form, so nothing was deleted.
- **Arrow at phone width:** the window would not resize then, so the page was loaded in a 390 px frame. The arrow is a 40 px circle above the title with no sideways scroll.
- **Console:** no errors and no content-security-policy refusals.

**Not verified:**

- The confirm box from a real delete of real data.
- The arrow after a real save of an edit form (the redirect was simulated by visiting the same URL).
- Safari or iOS. `color-mix` and `backdrop-filter` need Safari 16.2 or later; older browsers show a plain tint and a plain icon circle.

## 8. Every file changed (36)

Styles:
- `app/assets/stylesheets/application.scss`: imports `components/flash` and `components/confirm` instead of `components/alert`.
- `app/assets/stylesheets/components/_alert.scss`: deleted (the global `.alert` corner rule).
- `app/assets/stylesheets/components/_flash.scss`: new; flash cards, icon, close button, timer bar, 0.5 s fades, reduced motion.
- `app/assets/stylesheets/components/_confirm.scss`: new; confirm box, icon, buttons, backdrop blur.
- `app/assets/stylesheets/components/_layout.scss`: `.back-link` is now a 40 px round arrow button.
- `app/assets/stylesheets/config/_bootstrap_variables.scss`: modal backdrop colour `$gray` at .45.

JavaScript:
- `app/javascript/application.js`: imports `confirm_dialog` and `back_trail`.
- `app/javascript/confirm_dialog.js`: new; Turbo's confirm method opens `#confirm-modal`.
- `app/javascript/back_trail.js`: new; per-tab page trail, form skip, deleted-page removal, `takePreviousPage()`.
- `app/javascript/controllers/flash_controller.js`: new; 5 s timer, fade-out and removal.
- `app/javascript/controllers/back_controller.js`: new; the arrow goes to the previous page, or follows its link.
- `config/importmap.rb`: pins `confirm_dialog` and `back_trail`.

Helpers and layout:
- `app/helpers/application_helper.rb`: `back_to(path)` draws the arrow with `aria-label="Back"` and the back controller.
- `app/views/layouts/application.html.erb`: `data-back-skip` on `<body>`, and renders `shared/confirm`.
- `app/views/shared/_flashes.html.erb`: the flash cards.
- `app/views/shared/_confirm.html.erb`: new; the confirm box.

Views, `back_to` without its label:
- `app/views/exercises/edit.html.erb`
- `app/views/exercises/new.html.erb`
- `app/views/splits/edit.html.erb`
- `app/views/splits/index.html.erb`
- `app/views/splits/new.html.erb`
- `app/views/splits/show.html.erb`
- `app/views/workout_days/edit.html.erb`
- `app/views/workout_days/new.html.erb`
- `app/views/workout_days/show.html.erb`
- `app/views/workout_exercises/show.html.erb`
- `app/views/workout_log_exercises/edit.html.erb`
- `app/views/workout_logs/index.html.erb`
- `app/views/workout_logs/new.html.erb`
- `app/views/workout_logs/show.html.erb`

Tests:
- `test/integration/navigation_flow_test.rb`: arrow and fallback test, skip-flag check, new flash and confirm-box tests.
- `test/integration/dashboard_flow_test.rb`: back assertions check the target, not the label.
- `test/integration/exercises_flow_test.rb`: the same.

Docs:
- `doc/Issues/Issues.md`: the two General issues moved to resolved.
- `CLAUDE.md`: code map lines for the back arrow and trail, flash cards and the confirm box.
- `doc/alerts-and-back-button.md`: this file.

## 9. Known gaps

- **Long messages.** 5 s may be short for a long error, such as "Set not added: Push is already logged on … in PPL". There is no pause on hover or touch.
- **Growing browser history.** The arrow makes a new forward visit, not a browser "back". After using the arrow, the browser's own Back button returns to the page you just left with the arrow.
- **Deleted pages reached from elsewhere.** Only the deleted record's own path, and paths under it, leave the trail. Pages of child records reached through other URLs can stay in it. An example is a workout day's page after its split was deleted elsewhere. Reaching one with the arrow would need several steps back and would show the not-found page.
- **Guessed button label.** The confirm box guesses its button label from the message's first word. A new confirm worded differently gets "Yes". A `data-turbo-confirm-button` attribute could make it explicit if needed.
- **`?from=dashboard`.** It still decides where a deleted workout returns to. It could be replaced with the trail later, but that was not asked for.
