# Calendar: logged days

Record of the work done on 2026-11-16 on the branch `calendar-logged-days` (from `master` at `76c7707`, after pull request 8), in the worktree `.claude/worktrees/calendar-logged-days`.

---

## 1. Summary

- Fixes the two "Calendar" issues in `doc/Issues/Issues.md`, the last open issues.
- On the dashboard calendar a day is highlighted only when a workout was logged on it, and a highlighted day is a link to what was recorded.
- **Checked:** `bin/rails test`: 48 runs, 563 assertions, 0 failures, 0 errors. `bundle exec rubocop`: 31 files, no offenses. The calendar was opened and clicked in headless Chromium at 390px (phone) and 1280px (desktop), with no browser errors.
- **Not checked:** a real phone, Safari or Firefox.
- No migration. No new route.

---

## 2. Timeline

| Step | Request | What happened |
|---|---|---|
| 1 | "Now create a new branch and fix the calendar issue" | Confirmed `master` held the merged pull request 8, created the worktree and the branch `calendar-logged-days`, started Docker containers for the tests (the machine has no Ruby or PostgreSQL), made the changes in section 4, extended the tests, ran the suite and Rubocop, and checked the calendar in a headless browser. Moved the Calendar section of `Issues.md` to "Issues Resolved". |
| 2 | "Finalize" | Reran tests and Rubocop, wrote this doc, committed, pushed, handed over the pull request, removed the worktree. |

---

## 3. Starting point

The issues, as written by the owner:

1. Should only have the day highlighted if workout was registered that day.
2. The highlighted day should be interactive. I can click on it to see the recorded exercises and workout.

How the calendar behaved before (`app/views/pages/_calendar.html.erb`):

- It received `workout_weekdays`, the weekday numbers that have a workout day in the active split.
- Every date falling on one of those weekdays got the class `has-workout`, drawn as a small dot under the number. So every Monday of the month had a dot if the split had a Monday workout, whether or not anything was logged, including future dates.
- Days were `<span>` elements; nothing could be clicked.

The change doc of the branch that added the dots (`doc/dashboard-calendar-and-active-split.md`) already noted they were not requested.

---

## 4. Changes

### 4.1 The dashboard loads the logged workouts of the visible month

`app/controllers/pages_controller.rb`, in `home`:

```ruby
# The calendar marks the days a workout was logged on, and each opens what was recorded.
calendar_dates = helpers.month_weeks(@today).flatten
@logs_by_date = current_user.workout_logs.where(date: calendar_dates.first..calendar_dates.last)
                            .order(:id).group_by(&:date)
```

`month_weeks` is the helper the calendar already uses, so the range is exactly the dates drawn, including the greyed days of the neighbouring months. One query; only the signed-in user's logs.

### 4.2 Only logged days are highlighted, and they are links

`app/views/pages/_calendar.html.erb` now takes `logs_by_date` instead of `workout_weekdays` (`home.html.erb` passes it).

Before:

```erb
<span role="gridcell"
      class="<%= class_names("calendar-day", ..., "has-workout": workout_weekdays.include?(date.wday)) %>"
      ...><%= date.day %></span>
```

After, for each date:

```erb
<% logs = logs_by_date.fetch(date, []) %>
<% if logs.any? %>
  <%= link_to date.day,
        (logs.one? ? workout_log_path(logs.first, from: "dashboard") : workout_logs_path(date: date.iso8601, from: "dashboard")),
        role: "gridcell", class: classes, "aria-current": current,
        title: workouts, "aria-label": "#{l date, format: '%A, %B %-d'}: #{workouts}" %>
<% else %>
  <%= tag.span date.day, role: "gridcell", class: classes, "aria-current": current %>
<% end %>
```

- A day with one workout links to that workout's page with `from=dashboard`, which that page already understands: its back button reads "Dashboard".
- A day with several workouts (for example Push and Pull on the same date) links to that day's list (4.3).
- The link's `title` and `aria-label` name the workouts: "Monday, November 9: Push and Pull workouts".
- A day with nothing logged stays a plain `<span>`, whatever the split plans for it.

### 4.3 The workouts of one day

`WorkoutLogsController#index` accepts `?date=YYYY-MM-DD`:

```ruby
def index
  @date = Date.iso8601(params[:date]) if params[:date].present?
  logs = current_user.workout_logs.order(date: :desc, id: :desc)
  logs = logs.where(date: @date) if @date
  @workout_logs = paginate(logs, per: 20).includes(workout_day: :split, workout_log_exercises: :workout_sets)
rescue Date::Error
  redirect_to workout_logs_path
end
```

`app/views/workout_logs/index.html.erb`, when a date is given:

- the title is "Workouts on November 09, 2026";
- it is a sub-page, so it has a back button: "Dashboard" when it was opened from the calendar (`from=dashboard`), otherwise "History";
- its links to each workout carry `from=dashboard` on, so the workout's back button also returns to the dashboard;
- a date with nothing logged says "No workouts were logged on this day." with a link to the full history;
- a date that is not a date redirects to the full history.

Without a date the page is the History it was.

### 4.4 Style

`app/assets/stylesheets/components/_app.scss`: the dot (`.has-workout::after`) is replaced by a ring.

- A logged day: a 2px ring in the primary colour, bold primary text, white inside (so it shows on the tinted row of the current week); filled on hover and keyboard focus.
- A logged day of a neighbouring month: grey ring.
- Today, when logged: keeps its filled circle and gets a white inner ring.

### 4.5 Tests

`test/integration/workout_flow_test.rb`, in "the dashboard shows the month, this week, today's workout and last time's heaviest sets":

- the old assertion (two planned days marked in the current week) became: with nothing logged, no day is highlighted and the calendar has no links;
- after logging on the 2nd, the 9th and today: exactly those three days are highlighted; each links to its workout with `from=dashboard`; today is both highlighted and current; the label reads "Monday, November 9: Push workout"; a planned day with nothing logged (the 18th) is a plain span;
- opening the link shows the workout, its exercises and the Dashboard back button;
- with a second workout on the 9th: the day links to `/workout_logs?date=2026-11-09&from=dashboard`, labelled "Push and Pull workouts"; that page lists both, links to both, and goes back to the dashboard; another user's workout on the 10th is not highlighted;
- the same page without `from` goes back to History; an empty day shows the empty message; a bad date redirects.

### 4.6 Docs

- `doc/Issues/Issues.md`: the Calendar section moved under "Issues Resolved". There are no open issues left.
- `doc/Prompt/project-context.md`: open issues, the dashboard description, the history table and "where to start" updated.
- `CLAUDE.md`: one line in the code map about the calendar.

---

## 5. Decisions

| Decision | Alternative rejected | Why |
|---|---|---|
| "Registered" means a logged workout exists on that date. | Requiring at least one set. | A log is created by the first set, so the two normally agree; a log is what History and the dashboard count. See section 9 for the one case where they differ. |
| A highlighted day opens the existing workout page. | A panel or modal under the calendar listing the day's exercises. | That page already shows "the recorded exercises and workout", and already knows how to go back to the dashboard. Nothing new to learn or maintain. |
| A day with several workouts opens a list of that day. **Assumption:** the owner did not say what such a day should do. | Opening the first workout only; one link per workout squeezed into the cell. | Nothing is hidden, and a 36px calendar cell has room for one tap target. |
| The day's list is History with a `?date=` filter. | A new route and view. | Same table, same data; a filter is a few lines. |
| The planned-day dots are removed. | Keeping dots for planned days and adding a ring for logged ones. | The issue says "only" highlighted when registered. The week strip beside the calendar already shows the plan. |
| A ring, not a dot. | A larger dot; a filled circle. | A clickable day should look like a button. Today already uses the filled circle. |
| No month navigation. | Previous / next month arrows. | Not asked for. |
| Logs of other months' greyed days are highlighted too. | Only the current month's dates. | They are drawn on the calendar and were logged; leaving them plain would be wrong information. |

---

## 6. How it works now

On the dashboard, the month calendar shows:

- this week's row tinted, today filled (unchanged);
- a ring around every day on which a workout was logged, in any split, including splits deleted since;
- no mark on days that are only planned.

Tapping a ringed day:

- one workout that day: its page, with the exercises, sets and notes, and "← Dashboard" to go back;
- several workouts that day: "Workouts on <date>", a list of them, each opening its page; "← Dashboard" on both.

The data model, the routes and the migrations are unchanged. The only new input is the optional `date` query parameter on `GET /workout_logs`.

To try it:

```bash
bin/rails server
bin/rails mock:last_week
```

---

## 7. Tests and verification

**Environment.** As on the previous branch, the machine had no Ruby or PostgreSQL, so everything ran in Docker: a `postgres:16-alpine` container and a `ruby:3.3.5` container (with `libpq-dev` and `nodejs`) with the worktree mounted. The owner's own development database was not touched.

**Automated.** Run after the changes and again before committing:

- `bin/rails test`: 48 runs, 563 assertions, 0 failures, 0 errors, 0 skips (541 assertions on `master`).
- `bundle exec rubocop`: 31 files inspected, no offenses.

**Browser.** A development server ran from the worktree in the container, with a seeded admin, one split (Push Monday, Pull Tuesday, Legs Wednesday), last week's mock workouts, a second workout added on Monday the 9th, and a set logged today. A Playwright script (headless Chromium, time zone America/Sao_Paulo) at 390×844 and 1280×900:

- read the highlighted days: the 9th ("Push and Pull workouts"), the 10th, the 11th and today, all links; the planned but unlogged days of the other weeks were plain;
- clicked a day with one workout: landed on `/workout_logs/2?from=dashboard`, "Pull workout", four exercises, back button "Dashboard";
- went back, clicked the day with two: landed on `/workout_logs?date=2026-11-09&from=dashboard`, "Workouts on November 09, 2026", two rows.

Screenshots of the calendar at both widths were looked at: the rings are clear on white and on the tinted current-week row, and today shows its inner ring.

**Not verified:**

- Any browser other than Chromium, and any real phone.
- The hover and keyboard-focus styles (not captured in the screenshots).
- A month in which a greyed day of a neighbouring month has a workout (covered by the code path, not by a test or screenshot).

---

## 8. Every file changed

11 files: 10 modified, 1 added (this doc).

Controllers
- `app/controllers/pages_controller.rb`: loads the visible month's logged workouts, grouped by date.
- `app/controllers/workout_logs_controller.rb`: `index` accepts a `date` filter.

Views and styles
- `app/views/pages/_calendar.html.erb`: highlights logged days only, as links.
- `app/views/pages/home.html.erb`: passes `logs_by_date` to the calendar.
- `app/views/workout_logs/index.html.erb`: the one-day variant (title, back button, empty state, links).
- `app/assets/stylesheets/components/_app.scss`: ring style for logged days, replacing the dot.

Tests
- `test/integration/workout_flow_test.rb`: the assertions of section 4.5.

Docs
- `doc/Issues/Issues.md`: Calendar section moved to "Issues Resolved".
- `doc/Prompt/project-context.md`: updated for the calendar.
- `CLAUDE.md`: code map line for the calendar.
- `doc/calendar-logged-days.md` (new): this file.

---

## 9. Known gaps

- **A workout with no sets still highlights its day.** Adding a set and then deleting it leaves an empty workout (a gap noted on the previous branch), and its day stays ringed until that workout is deleted.
- **The calendar shows the current month only.** Earlier months are reached through History.
- **Changing a workout's date** (Details on its page) moves its ring; there is no check beyond the existing "one workout per workout per day" rule.
- **The day's list scrolls sideways on a phone,** like History, because the table has six columns.
- **Verified in Chromium only** (section 7).
