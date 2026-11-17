# Week workout moves, and the home page overview

Record of the work on the branch `week-workout-moves`, in the worktree `.claude/worktrees/week-workout-moves`. The branch was cut on 2026-11-17 from `home-page-overview` at `8b47602`, which itself sits on `master` after pull request 10. `home-page-overview` was pushed but never had a pull request, so against `master` this branch carries two stages of work:

- **Stage 1, `home-page-overview`** (commit `3b80da3`, made on 2026-11-16 and 2026-11-17 on the owner's other Windows user): the weekly summary, the dropdowns, "Start workout" and rest day workouts.
- **Stage 2, `week-workout-moves`** (2026-11-17, this session): moving a workout to another day for one week, and starting a workout that is not in the split on a rest day.

Stage 1 is described from its commit and from `doc/Prompt/home-page-overview-context.md`, the handoff file its session wrote. Stage 2 is described from this session.

---

## 1. Summary

- Finishes the five "Home page" features in `doc/Features/Features.md` (stage 1) and the four "Home page" issues in `doc/Issues/Issues.md` (two in stage 1, two in stage 2).
- **Stage 1:** the dashboard has a "This week" summary under the active split, recent workouts are dropdowns, the Today box has "Start workout" / "Continue", a rest day can start a workout of the split, and a workout logged on a rest day is marked.
- **Stage 2:** a workout of the split can be moved to another day **for the current week only**; the split's plan is never changed. On a rest day the split's workouts are shown by name only, each with a pop-up to move it to today or train it as an extra, and a workout that is not in the split can be started by picking its exercises.
- **Checked:** `bin/rails test`: 62 runs, 732 assertions, 0 failures, 0 errors. `bundle exec rubocop`: 34 files, no offenses. In stage 2 the home page and the new workout page were fetched over HTTP from a development server and rendered, with the pop-ups in the HTML and the new styles in the compiled stylesheet.
- **Not checked:** stage 2 was **not seen in a browser**. The Chrome extension was not connected and the machine has no headless browser, so the layout at phone width and the pop-ups opening (Bootstrap JavaScript) are unverified. Stage 1 was checked in a browser at 393px, 430px and 440px by its own session.
- Two migrations, both additive: `workout_logs.rest_day` (stage 1) and the table `workout_day_moves` (stage 2). Both are already applied to the development database on the machine this session ran on.

---

## 2. Timeline

### Stage 1 (other session, from its handoff file)

| Step | Request | What happened |
|---|---|---|
| 1 | Weekly overview under the week of the split; remove the Splits, Workouts logged and Sets recorded boxes | "This week" summary added to the active split card; the three boxes removed. |
| 2 | Recent workouts: whole block clickable | Done first as a link, then replaced by step 4. |
| 3 | Make it work on iPhone 16 and later | Layout checked at 393px, 430px, 440px. |
| 4 | Recent workouts as a dropdown | Each row opens to exercise pills with the heaviest set; a pill opens the rest of its sets. |
| 5 | The same for the active split | Weekday rows behind a "Show days" toggle. |
| 6 | A Today box with a quick start button | "Start workout" / "Continue". |
| 7 | Issue: deleting a workout opened from the home page went to History | It returns to the dashboard. |
| 8 | Issue: no way to start a workout on a rest day | Rest day panel with the split's workouts; `workout_logs.rest_day` and the "Rest day" chip. |
| 9 | Let the finalize skill edit `Features.md` and `Issues.md` only | Step 3a added to the skill. |

### Stage 2 (this session)

| Step | Request | What happened |
|---|---|---|
| 1 | "Read the prompt under doc/Prompt/project-context.md ... understand what was done and what still needs to be done" | Read `project-context.md`, `home-page-overview-context.md`, `Issues.md`, `Features.md` and the branch's commits. Found Ruby 3.3.5 behind rbenv (the shell needed `~/.rbenv/shims` on its path) and ran the tests: 59 runs, 0 failures. Reported the state and the open issues. |
| 2 | "Only focus on the Issues from Home page. Please analyze it and tell me how you would fix them." | Read the home page code. Proposed the one-off workout for issue 1 and, for issue 2, name-only pills with a pop-up, with "move" changing the split. Asked three questions. |
| 3 | The owner's answers: a move counts "for the week of that split not the split in general"; it must be offered when the workout is planned on one day too; it must work for every split. "I want to be able to move them at free will." | Redesigned the move as a per-week record and explained the plan, with the choices in section 5. |
| 4 | "Yes please build it." | Created the worktree and branch, built sections 4.7 to 4.12, wrote the tests, ran the suite and Rubocop. Tried the browser check and could not do it (see section 7). Moved the two issues in `Issues.md`. Left a server on port 3001 for the owner. |
| 5 | The owner asked why this Windows user has no splits, and for a seed of the other user's splits if it could be made from this folder | Answered that the development database is per machine and user. No seed was made: the other user's data is not reachable from here and is not in the repository. Gave a `pg_dump` command for the other user. |
| 6 | "Thank you finalize this please" | Reran the tests, wrote this doc, moved the finished features in `Features.md`, committed. |

---

## 3. Starting point

### Before stage 1 (`master` after pull request 10)

- The dashboard's left column had the month calendar and three boxes: Splits, Workouts logged, Sets recorded.
- The active split card showed the week circles only.
- Recent workouts was a flat list; only the name was a link.
- The Today box showed today's workout and last time's heaviest sets, with no button, and on a rest day nothing could be started from it.
- Deleting a workout always returned to History.

### Before stage 2 (`home-page-overview` at `8b47602`)

The two open Home page issues, in the owner's words:

> **Only Split workout are selectable on rest day.** I want to be able to either add the split day or create a new one.

> **Days on the split names and repetitive workout names.** Since the workout is static and only Admin can edit, I believe, change the way it is now to only display the workout name wihtout the date and incase it is the same as on one of the say, for example: I do Lower on Tuesday and there is Lower on Wednesday and Saturday. Have a option to move either one, like a info pop up. Make this possible for all splits.

How the rest day panel behaved (`app/views/pages/home.html.erb`):

- One pill per workout day of the active split, labelled with the name and the day: "Upper Mon", "Lower Wed", "Lower Sat". Each was a link to that workout day.
- Nothing outside the split could be started.
- There was no way to train a workout on another day except as a rest day extra. The weekday of a workout day could only be changed on the split itself, for every week.

---

## 4. Changes

### Stage 1

#### 4.1 Weekly summary under the active split

- **Before:** three totals boxes under the calendar.
- **After:** `pages/_week_overview.html.erb` under the week circles: Workouts, Exercises, Sets, Top weight for this week (Sunday to Saturday), and a "Show days" / "Hide days" toggle that opens one row per day. A logged day links to its workout, or to `/workout_logs?date=…` when the day has several. Unlogged days show "Rest", or "–" for days ahead.
- **How:** `WorkoutSummary` (`app/models/workout_summary.rb`), a plain Ruby class over loaded logs with `workouts`, `exercises`, `sets`, `top_weight` and `sets_in(log)`. `PagesController#home` loads `@week_dates`, `@week_logs` and `@week_summary`.
- **Reason:** the owner asked for a weekly overview in place of the boxes.

#### 4.2 Recent workouts as dropdowns

- **Before:** a list with the name as a link.
- **After:** `pages/_recent_workout.html.erb`. Closed: name, date, set count, "Rest day" chip, split name, chevron. Open: exercise and set counts, one pill per exercise with its heaviest set (a pill opens every set in order), the notes, and "Open workout".
- **Reason:** the owner asked for a summary first and detail on opening.

#### 4.3 Today box: "Start workout" and "Continue"

- **After:** on a planned day, "Start workout" until today has sets, then "Continue"; both open the workout day. With sets the line reads "Logged today · N exercises · N sets · top N kg".
- **Reason:** a quick button to start. No log is created by the button (section 5).

#### 4.4 Rest day workouts

- **After:** on a rest day the Today box has "Start workout", which opens a panel of the split's workouts. `WorkoutLog#mark_rest_day` sets the new column `workout_logs.rest_day` when the log is created. The chip "Rest day" shows in the Today box, Recent workouts and History, and "Rest day, trained anyway" on the workout page.
- **Migration:** `20261117100000_add_rest_day_to_workout_logs.rb`, a boolean with default false.

#### 4.5 Deleting a workout from the dashboard

- **Before:** `destroy` redirected to History.
- **After:** the Delete button passes `from`, and `WorkoutLogsController#destroy` redirects to the dashboard when `params[:from] == "dashboard"`.

#### 4.6 The finalize skill

- `.claude/skills/finalize-branch/SKILL.md` got step 3a: finalizing may move finished items in `Features.md` and `Issues.md`, and may edit no other existing file.

### Stage 2

#### 4.7 A move belongs to one week

New table and model:

```ruby
create_table :workout_day_moves do |t|
  t.references :workout_day, null: false, foreign_key: { on_delete: :cascade }, index: false
  t.date :week_start, null: false   # the Sunday the week starts on
  t.integer :weekday, null: false   # 0 = Sunday .. 6 = Saturday: where the workout is that week
  t.timestamps
end
add_index :workout_day_moves, [:workout_day_id, :week_start], unique: true
```

`WorkoutDayMove` (`app/models/workout_day_move.rb`) says "this workout day, in the week starting on this Sunday, is on this weekday". A workout day has at most one move per week. The `workout_days` table is not written to, so the plan stays as it is and a week without a row follows the plan.

`Split` (`app/models/split.rb`) reads and writes moves:

- `week_plan(date)`: the week of that date as it is trained, `weekday => workout day`. It is the plan with that week's moves applied. Everything that asks "what is on today" now reads this.
- `week_move_error(day, weekday, today)`: why a move is refused, or nil.
- `move_for_week!(day, weekday, date)`: moves the day, and when the target weekday has a workout, puts that one on the weekday the first leaves (a swap). A workout that lands back on its planned weekday has its move row deleted instead of stored. Returns the other workout day, or nil.
- `clear_week_moves(date)`: back to the plan for that week.
- `moves_of_week(date)`: the move rows of that week.

`WorkoutDay` (`app/models/workout_day.rb`):

- `has_many :workout_day_moves, dependent: :delete_all`.
- `after_save :clear_moves_of_split, if: :saved_change_to_weekday?`: creating a workout day or changing a weekday deletes every move of that split. **Reason:** a move made earlier could otherwise sit on a weekday the plan now uses, giving two workouts on one day.

#### 4.8 Moving from the dashboard

- **Route:** `resource :week_move, only: [:create, :destroy]` inside `resources :splits`: `POST` and `DELETE /splits/:split_id/week_move`.
- **Controller:** `WeekMovesController`. `create` takes `workout_day_id` and `weekday`, refuses with a flash ("Not moved: …") when `week_move_error` gives a reason, otherwise moves and redirects to the dashboard, or to the workout day when `open` is sent. `destroy` clears this week's moves. The split is looked up among the signed-in user's own, so another user's split answers 404.
- **Active split card** (`home.html.erb`): under the week circles, a row with "Move a workout" (when something can still be moved) and, once a move exists, "Moved this week" with "Back to the plan".
- **Pop-up** (`pages/_move_workout.html.erb`, Bootstrap modal `#move-workout`): "Which workout" lists the workouts not trained yet this week with the day they are on ("Wednesday", or "Tuesday, planned Wednesday" when already moved). "Move to" is one button per day from today to Saturday, labelled with the day and what is on it ("Today / Free", "Wed / Lower"). The button is "Move for this week".
- **Week circles** (`splits/_week.html.erb`): a new optional local `plan`. With it, a moved workout is drawn on its new day with the class `is-moved` (dashed circle, light fill), and the day it left is blank and links to the split page instead of "add a workout day", because that weekday is still taken in the plan. Without `plan` the partial behaves as before, so the Splits pages show the plan.
- **Today box:** `@today_workout` comes from `week_plan`, so a moved workout is today's workout. Under the title it says "Moved from Wednesday, this week only".

Rules a move must pass (`Split#week_move_error`):

| Rule | Message |
|---|---|
| The target is today or a later day of this week | "choose a day from today to Saturday" |
| The workout was not logged this week | "Lower is already logged this week" |
| When the target is today, today has no workout logged from this split | "today already has a workout logged in Upper Lower" |

#### 4.9 Rest day panel: names only, with a pop-up per workout

- **Before:** one link per workout day, "Lower Wed" and "Lower Sat".
- **After:** one pill per workout **name** in this week's plan. A pill opens a pop-up (`pages/_rest_day_start.html.erb`, modal `#rest-start-N`) titled "Lower today", which says where the workout is planned and has one row per day it is on, with that day's exercise count and two actions:
  - **Move to today**: posts to `week_move` with today's weekday and `open`, so the workout is moved for this week and its workout day opens. Not shown for a day already trained this week, which reads "done this week".
  - **Train as extra**: the link the pill used to be. It opens the workout day; the first set logs a rest day workout and the week stays as planned.
- **Reason:** the owner asked for the name without the day, and for an option to move either day when a workout is planned on several. Their answer in step 3 asked for the move with one day too, so the pop-up always opens.

#### 4.10 A workout that is not in the split

- **Panel:** under the split's pills, "Something else" lists the fixed workouts the split does not have. Legs and Lower count as the same workout, so a split with Legs does not offer Lower.
- **Routes:** `new` and `create` added to `resources :workout_logs`.
- **`WorkoutLogsController#new`** (`workout_logs/new.html.erb`): a page titled "Push workout" with today's date, the chip "Not in your split", and "Add exercise", which opens the existing "Add exercises" modal. Nothing is saved. If today already has a workout of that name, it redirects to that workout instead.
- **`WorkoutLogsController#create`:** reads the modal through `ExercisePicker`, then in one transaction creates today's log (`workout`, `date`, `rest_day`, no workout day) and one entry per exercise, and redirects to the workout page, where sets are added as on any logged workout. With nothing chosen it returns to the `new` page with "Nothing added".
- **Rest day mark:** a log without a workout day has no split of its own, so the controller sets `rest_day` itself: true when the active split has nothing on today this week.
- Only the fixed names are accepted; anything else redirects to the dashboard with "Choose one of the listed workouts."

#### 4.11 Rest day mark follows the moved week

`WorkoutLog#mark_rest_day`:

```ruby
# before
self.rest_day = workout_day.split.workout_days.where(weekday: date.wday).none?
# after
self.rest_day = !workout_day.split.week_plan(date).key?(date.wday)
```

A workout moved to Tuesday and trained on Tuesday is that day's planned workout, so it is not a rest day workout. Training on the weekday a workout was moved away from is.

#### 4.12 `PagesController#home`

New: `@week_plan`, `@week_moved`, `@movable_days` (this week's plan without the workout days already logged this week), `@exercise_counts` (for the pop-up rows) and `@other_workouts`. `@today_workout` is `@week_plan[@today.wday]` instead of a lookup by planned weekday.

#### 4.13 Styles

At the end of `components/_app.scss`: `.week-moves`, `.week-moves-note`, `.today-moved`, `.move-days`, `.rest-start-days`, `.rest-start-actions`, and `.week-day.is-moved` next to the other week rules. Buttons are at least 44px high.

---

## 5. Decisions

### Stage 1 (taken by its session; from the handoff file)

| Decision | Rejected | Why |
|---|---|---|
| Keep `@splits_count`, `@logs_count`, `@sets_count` in the controller | Removing them with the boxes | The owner said they might be used again. |
| A recent workout row is a toggle; "Open workout" is the only link out | The whole row as a link | A dropdown has to open on tap. The owner agreed. |
| The split summary is this week's totals: sets, top weight, exercises | All-time totals | The owner's choice. |
| "Start workout" creates no log | Creating an empty log | The owner's choice. An abandoned start leaves nothing in the calendar or History. |
| Exercises in the week summary are distinct names with at least one set | Counting every entry | **Assumption** of that session; the owner has not confirmed it. |
| `rest_day` is stored when the log is created | Computing it on each page | Editing the split later must not rewrite history. |
| Bootstrap collapse, no new JavaScript | A Stimulus controller | The app already loads Bootstrap. |

### Stage 2

| Decision | Rejected | Why |
|---|---|---|
| A move is a row per workout day per week | Changing `workout_days.weekday` | The owner: "Move should only count for the week of that split not the split in general." My first proposal changed the split and was turned down. |
| A move hangs off a workout day | Anything tied to a split's shape | The owner: it must work "regardless of being Upper Lower or Push Pull Legs Upper Lower or Push Pull Legs". |
| The move is offered for a workout planned on one day too | A pop-up only for repeated workouts | The owner's answer 2. It costs one extra tap on a rest day. |
| Moving onto a day with a workout swaps the two | Refusing, or two workouts on one day | "I want to be able to move them at free will", and a split has one workout a day. **Assumption:** the owner approved the plan that said this, but did not ask for a swap by name. |
| Only the current week can be changed | Planning next week's moves | Simplest thing that covers "if something happens and I need to work out a different day". **Assumption**, stated in the plan. |
| The target is today or later | Any day of the week | Sets are logged on today's date, so a workout on a past day could not be trained. **Assumption**, stated in the plan. |
| A workout logged this week cannot be moved | Moving it anyway | It has nothing left to move. **Assumption**, stated in the plan. |
| A moved workout trained on its new day is not a rest day workout | Marking it | That day is its planned day for the week. **Assumption**, stated in the plan. |
| A swap may send the other workout to a day already past | Refusing such a swap | Refusing would block moving a missed workout onto a taken day. The other workout can be moved forward again. **Assumption**, reported after building. |
| Changing the plan's weekdays deletes the split's moves | Keeping them and resolving clashes | A kept move could put two workouts on one day. **Assumption**, reported after building. |
| "Create a new one" means a workout outside the split, from the fixed list | A new workout day in the split | The earlier rest day issue said a rest day workout "does not change the split". **Assumption:** the owner approved the plan but the wording of the issue allows the other reading. |
| The one-off workout is saved when its first exercise is added | Saving on the tap; saving on the first set | It keeps "an abandoned start leaves nothing". It cannot wait for the first set as a split workout does, because without a plan the log is the only place its exercises can be. |
| The one-off workout reuses the logged workout page | A new page for it | That page already works without a workout day (it does for deleted splits). |
| "Move to today" opens the workout day | Returning to the dashboard | On a rest day the next step is to train it; it saves a tap. |
| Pop-ups are Bootstrap modals with plain forms | New JavaScript | Same reason as stage 1. |
| A new branch and worktree cut from `home-page-overview` | Working on `home-page-overview` in the main folder | `CLAUDE.md` asks for a worktree and a named branch, and the main folder is the owner's. It had `home-page-overview` checked out with uncommitted edits, which were left alone. |
| No seed of the other user's splits | Inventing one | The owner said not to make one if it could not be made from this folder, and the data is not here. |

---

## 6. How it works now

### Data model

```
Split
 └─ WorkoutDay (day, weekday: the plan)
      └─ WorkoutDayMove (week_start, weekday: where it is that one week)   ← new
WorkoutLog (…, rest_day)                                                   ← column from stage 1
```

`Split#week_plan(date)` is the one place that answers "what is on which day this week".

### Moving a workout

1. Dashboard, active split card: "Move a workout".
2. Pick the workout, pick a day from today to Saturday, "Move for this week".
3. The week circles, the Today box and the rest day mark follow the moved week. The Splits pages keep showing the plan.
4. "Back to the plan" removes this week's moves. Next week has none.

### A rest day

1. Today box: "Rest day", "Start workout".
2. "From your split": tap a workout name. In its pop-up, "Move to today" (this week only, then the workout day opens) or "Train as extra" (the week stays, the workout is saved with the "Rest day" chip).
3. "Something else": tap a workout name, "Add exercise", choose exercises. The workout is saved with the "Rest day" chip and opens for its sets.

### Running it

```bash
git fetch origin
git switch week-workout-moves
bin/setup
bin/rails db:migrate
bin/rails server
```

`db:migrate` adds `workout_logs.rest_day` and the table `workout_day_moves`. Both only add; `master` ignores them, so the database can be shared with a checkout of `master`.

---

## 7. Tests and verification

Run on 2026-11-17 in the worktree, natively (Ruby 3.3.5 through rbenv, PostgreSQL):

- `bin/rails test`: **62 runs, 732 assertions, 0 failures, 0 errors, 0 skips.** Before stage 2 the branch had 59 runs.
- `bundle exec rubocop`: **34 files inspected, no offenses.**

Tests added in stage 2 (`test/integration/workout_flow_test.rb`):

- "a workout is moved to another day for this week only, and the split keeps its plan": the pop-ups' contents, a past day refused, "Move to today" opening the workout day, the split's weekdays unchanged, the Today box and week circles after the move, the split page still showing the plan, the moved workout not marked as a rest day, a logged workout not offered or movable, the vacated day being a rest day, and the next week following the plan.
- "moving a workout onto a day that has one swaps the two, and the week can go back to the plan": the swap, moving back removing the rows, "Back to the plan", moves cleared when the plan's weekdays change, and another user's split answering 404.
- "on a rest day a workout outside the split is started by picking its exercises": the names offered, nothing saved on opening or with nothing chosen, the log created with the first exercise as a rest day workout with no workout day, the split untouched, the same workout reopened, and an unknown name refused.

Two existing tests were updated for the name-only pills.

Stage 1 added (per its commit): the weekly summary, the recent dropdown, delete from the dashboard and the rest day workout in the integration test, `test/models/workout_summary_test.rb`, and the rest day cases in `test/models/workout_log_test.rb`.

Other checks in stage 2:

- A development server from the worktree was pointed at a throwaway database with one demo user and an Upper / Lower / Lower split. Signed in over HTTP, the home page returned 200 with `#move-workout`, `#rest-start-0` and `#rest-start-1` in it, and the compiled stylesheet held the new rules. The throwaway database was dropped afterwards.

**Not verified:**

- **Stage 2 in a browser.** `CLAUDE.md` asks for changed pages to be looked at at phone width. The Chrome extension was not connected and no headless browser is installed, so nobody has seen the "Move a workout" pop-up, the rest day pop-ups, the dashed moved circle, the "Move a workout" row or the new workout page, and nothing confirms the modals open on tap.
- A real phone, Safari or Firefox, in either stage.
- The owner had not tried stage 2 when it was finalized. The development database on this machine has no splits.

---

## 8. Every file changed

30 files against `master`.

**New (13)**

| File | What it is |
|---|---|
| `app/controllers/week_moves_controller.rb` | Moves a workout for this week (`create`) and goes back to the plan (`destroy`). |
| `app/models/workout_day_move.rb` | One workout day on another weekday for one week. |
| `app/models/workout_summary.rb` | Totals over loaded logs (stage 1). |
| `app/views/pages/_move_workout.html.erb` | The "Move a workout" pop-up. |
| `app/views/pages/_recent_workout.html.erb` | A recent workout as a dropdown (stage 1). |
| `app/views/pages/_rest_day_start.html.erb` | The rest day pop-up of one workout. |
| `app/views/pages/_week_overview.html.erb` | "This week" and the day rows (stage 1). |
| `app/views/workout_logs/new.html.erb` | Start page of a workout that is not in the split. |
| `db/migrate/20261117100000_add_rest_day_to_workout_logs.rb` | `workout_logs.rest_day` (stage 1). |
| `db/migrate/20261117120000_create_workout_day_moves.rb` | The table `workout_day_moves`. |
| `doc/Prompt/home-page-overview-context.md` | Stage 1's handoff file. |
| `doc/week-workout-moves.md` | This doc. |
| `test/models/workout_summary_test.rb` | Tests of the summary (stage 1). |

**Changed (17)**

| File | What changed |
|---|---|
| `.claude/skills/finalize-branch/SKILL.md` | Step 3a (stage 1). |
| `app/assets/stylesheets/components/_app.scss` | Stage 1's overview, dropdown and chip styles; stage 2's move row, pop-ups and moved circle. |
| `app/controllers/pages_controller.rb` | Week logs and summaries (stage 1); the week plan, movable days, exercise counts and other workouts (stage 2). |
| `app/controllers/workout_logs_controller.rb` | Delete returns to the dashboard (stage 1); `new` and `create` for a workout outside the split (stage 2). |
| `app/models/split.rb` | `week_plan`, `week_move_error`, `move_for_week!`, `clear_week_moves`, `moves_of_week`. |
| `app/models/workout_day.rb` | Its moves, and clearing the split's moves when a weekday changes. |
| `app/models/workout_log.rb` | `mark_rest_day` (stage 1), now reading the week plan (stage 2). |
| `app/views/pages/home.html.erb` | Stage 1's Today box, overview and recent list; stage 2's move row, moved note, rest day panel and pop-ups. |
| `app/views/splits/_week.html.erb` | Optional `plan` local: moved and vacated days. |
| `app/views/workout_logs/index.html.erb` | Rest day chip (stage 1). |
| `app/views/workout_logs/show.html.erb` | Rest day chip; Delete passes `from` (stage 1). |
| `config/routes.rb` | `week_move` under splits; `new` and `create` on workout logs. |
| `db/schema.rb` | The column and the table. |
| `doc/Features/Features.md` | The five Home page features moved to "Features added (DONE)". |
| `doc/Issues/Issues.md` | The two Home page issues moved to "Issues resolved (DONE)". |
| `test/integration/workout_flow_test.rb` | Stage 1's tests; stage 2's three tests and two updated ones. |
| `test/models/workout_log_test.rb` | Rest day cases (stage 1). |

Moved in the lists:

- `Features.md`, from "Home page" to "Features added (DONE) / Home page": the weekly overview, the clickable Recent Workouts block, the Recent workout dropdown, the Active split dropdown, the Today box with a start button. The clickable block was replaced by the dropdown at the owner's choice (section 5) and is moved with it.
- `Issues.md`, to "Issues resolved (DONE) / Home page": "Only Split workout are selectable on rest day" and "Days on the split names and repetitive workout names". "Deleting workout" and "No add workout on rest day button" were moved there in stage 1.

---

## 9. Known gaps

- **Stage 2 has not been seen in a browser** (section 7). This is the main risk: layout at phone width and the pop-ups are untested by eye.
- **"Back to the plan" after training a moved workout.** The workout returns to its planned day, which then shows "Start workout" again that week although it was trained.
- **A swap can put a workout on a day already past.** Moving a missed Monday workout onto Thursday sends Thursday's to Monday. It can be moved forward again, but nothing warns about it.
- **Editing the split clears its moves**, including this week's, without saying so.
- **Only the current week.** Next week cannot be arranged in advance.
- **A workout outside the split has no plan.** Its exercises are picked each time, and it has no "last time" list on the dashboard.
- **Starting a one-off workout takes two taps before the catalogue:** the pill, then "Add exercise", because the modal cannot open by itself without JavaScript.
- **A second workout from the same split on one day is still refused.** After training an extra on a rest day, starting another workout of the split fails on its first set, as before this branch.
- **A workout day without a weekday** (data from before weekdays existed) is not in the week plan and is not offered on a rest day.
- **Logs from before `rest_day` existed are not marked** (stage 1).
- **`doc/Prompt/project-context.md` and `CLAUDE.md` do not describe this branch.** The finalize skill may not edit them. `project-context.md` still ends at `calendar-logged-days`; the code map in `CLAUDE.md` has no line for `WorkoutDayMove` or `Split#week_plan`.
- **`home-page-overview` needs no pull request of its own:** all of it is in this branch.
