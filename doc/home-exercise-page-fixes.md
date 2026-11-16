# Home and exercise page fixes

Branch: `home-exercise-page-fixes` (created by the session as `claude/home-exercise-page-issues-d9d442`, renamed before the first push). Date: 2026-11-16.

## 1. Summary

The branch fixes the two open issues of `doc/Issues/Issues.md`:

- **Home page, "Split override".** The dashboard's Today box now shows the sets recorded today instead of always showing the previous session. A second workout on the same day is only possible from another split. The old Push workout of 16 November was deleted from the development database.
- **Exercise page, "Exercise name edit".** An admin can rename an exercise from the workout day page, with a pencil button on each exercise row.

State: all 51 tests pass (603 assertions) and rubocop reports no offenses. The pages were checked through the HTML the server returns, with the real development data. They were **not** looked at in a browser, so the phone-width layout is unverified (see section 9).

## 2. Timeline

1. **"Read Issues.md, inspect the issues for home page then for exercise page, and explain how you will fix them."**
   Read the issue file, the screenshot (it is in `doc/Features/Pics/`, not `doc/Issues/Pics/` as the issue says), the home page, the models and controllers, and queried the development database read-only. Found two workouts logged on 16 November: log 5 (Push, split PPL/UL, 2 sets) and log 19 (Upper, split U/R/L/U/L, 27 sets). Explained a plan and two open questions. Nothing was changed.
2. **A screenshot of the Today box showing "Last time · Sunday, November 15", with "have a look why is that and fix it. Also please do the other fixes as well."**
   This showed what "I can only see the previously set one" meant: the Today box. Found the cause (section 3), changed the Today box, added the one-workout-per-split-per-day rule, added the admin rename button, wrote tests, adjusted two older tests and the mock task. The command that deletes log 5 was blocked by the session's permission check, so the record was left and reported.
3. **"I grant you permission to delete."**
   Deleted log 5 (Push, 16 November 2026, PPL/UL, 2 exercises with one set each) with a one-off `bin/rails runner` command that first checked the workout, date and split of the record. Log 19 is the only workout left on that date.
4. **"I moved the issues to resolved on the doc on master. Please now finalize this branch."**
   Dropped this branch's own edit of `doc/Issues/Issues.md`, so the branch does not touch that file and cannot conflict with the owner's edit. Renamed the branch, ran the tests, wrote this doc, pushed and opened the pull request.

## 3. Starting point

### Today box

`PagesController#home` loaded one session for the Today box, `@last_log`, the latest session of today's workout **before today**:

```ruby
@last_log = last_session_of(@today_workout) if @today_workout

def last_session_of(workout_day)
  current_user.workout_logs.of_workout(workout_day.day).where(date: ...@today)
              .includes(...).order(date: :desc, id: :desc).first
end
```

The view listed that session's heaviest sets under "Last time". Sets recorded today were never shown there. So after 27 Upper sets on Monday 16 November, the box still showed the Upper session of Sunday 15 November (Bench press 80 kg × 6, Incline dumbbell press 36 kg × 5). The owner read this as the old workout hiding the new one. It was not caused by having two workouts on the day.

### Two workouts on one day

The only rule was "one logged workout per workout name per day" (`WorkoutLog#only_session_of_workout_that_day`). Any two different workouts could be logged on the same day, including two from the same split, for example by opening Wednesday's workout day on a Monday and adding a set.

### Exercise name

The name belongs to the `Exercise` record. It could only be changed from the Exercises page (Edit). The workout day page had only a remove button and an open arrow on each row.

## 4. Changes

### 4.1 Today box shows today's sets

`app/controllers/pages_controller.rb`

- `last_session_of` became `session_of(workout_day)`, which returns the user's sessions of that workout (any split) with the associations preloaded.
- `@today_log` is the session of today's workout dated today; `@last_log` is still the latest one before today.

```ruby
if @today_workout
  @today_log = session_of(@today_workout).where(date: @today).order(:id).first
  @last_log = session_of(@today_workout).where(date: ...@today).order(date: :desc, id: :desc).first
end
```

`app/views/pages/home.html.erb`

- `today_lifts` is the list of today's logged exercises that have at least one set.
- When `today_lifts` is not empty the box shows "Logged today · N sets" (a link to today's workout, with `from=dashboard`), the heaviest set of each exercise in a list with the class `today-lifts`, and then one line "Last time · <date>" (class `today-previous`) linking to the previous session.
- Otherwise it behaves as before: the "not logged before" sentence, or "Last time" with the list `last-lifts`.
- The "Last time · date · source" text is captured once (`last_time`) and used in both places.

`app/views/pages/_lifts.html.erb` (new): the list of exercises with their heaviest set, moved out of `home.html.erb` so today's list and last time's list share it. Locals: `lifts`, `list_class`.

`app/assets/stylesheets/components/_app.scss`: `.today > .today-previous` gives the closing "Last time" line its padding and a top border.

Reason: at the gym the owner wants to see what was done today. The comparison with last time stays one tap away.

### 4.2 A second workout on the same day only from another split

`app/models/workout_log.rb`: a new validation, run when the log is created or its date changes.

```ruby
validate :only_workout_of_its_split_that_day, if: -> { new_record? || date_changed? }

def only_workout_of_its_split_that_day
  return if user.nil? || date.nil? || workout_day.nil? || errors[:date].any?

  other = user.workout_logs.joins(:workout_day).where(date: date).where.not(id: id)
              .find_by(workout_days: { split_id: workout_day.split_id })
  return if other.nil?

  errors.add(:base, "#{other.workout} is already logged on #{I18n.l(date, format: :long)} in #{workout_day.split.name}. " \
                    "A second workout that day has to come from another split")
end
```

- It compares the split of the workout day the log was started from.
- A log whose split or day was deleted (`workout_day` nil) is not restricted.
- It is skipped when the older "same workout twice" rule already added an error on the date, so one mistake gives one message.

`app/controllers/workout_sets_controller.rb`: `WorkoutExercise#entry_on!` creates today's log with `create!`. When the new rule refuses it, `ActiveRecord::RecordInvalid` is now rescued and the user is sent back to the exercise page with "Set not added: Push is already logged on November 16, 2026 in PPL. A second workout that day has to come from another split." The `back` path is now set before `entry_on!` so the rescue can use it. The surrounding transaction rolls back, so no empty workout is left.

`app/controllers/workout_logs_controller.rb` is unchanged: its `update` already shows validation errors, so moving a workout onto a date its split already has a workout on reports the same message.

`lib/tasks/mock.rake`: `mock:last_week` skips a day when that split already has a workout logged on the date, with the line "skipped … (<split> already has a workout logged that day)". Without this the task would raise on such a day.

### 4.3 Admin renames an exercise from the workout day

`app/views/workout_days/show.html.erb`: each exercise row gets a pencil link, only when `current_user.admin?` and the row has a linked exercise. It goes to `edit_exercise_path(exercise, workout_day_id: day.id)`.

`app/controllers/exercises_controller.rb`

- `set_return_day` (before `edit` and `update`) reads `params[:workout_day_id]` and looks it up among the signed-in user's own workout days. A day of another user, or a missing one, gives `nil`.
- `update` redirects to that day when there is one, otherwise to the Exercises page as before.

`app/views/exercises/edit.html.erb`: the back button is the workout day ("Push") when the page was opened from one, otherwise "Exercises".

`app/views/exercises/_form.html.erb`: a hidden `workout_day_id` field carries the day through the form, and Cancel goes back to the day.

No new permission was needed: `ExercisesController#set_exercise` already lets an admin edit the shared catalogue and their own exercises, and lets a normal user edit only their own.

### 4.4 Tests

`test/integration/workout_flow_test.rb`, three new tests:

- "once today's workout has sets the dashboard shows them, with last time as a link"
- "a second workout on the same day only comes from another split"
- "an admin renames an exercise from the workout day"

Two older tests logged two workouts from one split on the same date, which the new rule forbids:

- the dashboard test: the second workout of 9 November now comes from a second split;
- `test/models/workout_day_test.rb`: the Push log is on another date.

### 4.5 Development database

Log 5 was deleted: Push, 16 November 2026, from split PPL/UL, with its 2 logged exercises (Overhead press, Calf raise) and their 2 sets. This is data only; no migration and no schema change. The worktree and the main folder share this database, so the deletion was visible in the main folder's server at once.

### 4.6 CLAUDE.md

One product rule and two code-map lines were added (the per-split rule, the Today box, the rename from a workout day).

## 5. Decisions

- **"Only if the split changes" means "the set comes from another split's workout day".** Assumption, stated to the owner before and after the change. The alternative, "only after the active split was changed", was rejected because it would also block logging from a split that is not the active one, which the app allows everywhere else. It can be tightened later.
- **Today's sets replace last time's list; last time stays as a link.** Showing both lists was rejected as too long on a phone. Dropping "last time" completely was rejected because the comparison is the reason the box exists.
- **A logged exercise without sets is not listed for today.** If none of today's exercises has a set, the box keeps showing last time.
- **The rule is a model validation, not a controller check.** It then also covers moving a workout to another date and the mock task.
- **The rule does not touch existing data.** Days that already have two workouts from one split stay as they are; the validation runs only on create and on a date change. 15 November and last week's mock data were left alone.
- **Rename reuses the existing edit form.** A separate inline rename on the day page was rejected: the form already exists, also edits the muscle group, and has the permission checks.
- **The pencil is for admins only**, as the issue says. A normal user still renames their own exercises from the Exercises page.
- **The return day is passed as an id, not as a URL**, and looked up among the user's own days, so the redirect cannot be pointed anywhere else.
- **`doc/Issues/Issues.md` is not changed on this branch.** The owner moved the issues to resolved in their main folder; this branch's own edit was dropped to avoid a conflict.

## 6. How it works now

- **Dashboard, Today box.** Before the first set of the day: last time's heaviest sets, as before. After it: "Logged today · N sets", today's heaviest set per exercise, then "Last time · <date>". Both dates link to the logged workout and come back to the dashboard.
- **Logging.** The first set of the day creates the day's workout. More sets of the same workout join it, from any split (unchanged). A different workout from the **same** split on that day is refused with a message. A workout from **another** split is allowed, as a second workout of the day.
- **History.** Changing a logged workout's date follows the same rule.
- **Workout day page.** An admin sees a pencil next to each exercise. It opens "Edit exercise"; Save or Cancel returns to the day. The rename applies to the exercise everywhere: every user's plans and logged history (`Exercise#rename_linked_lifts`, unchanged).

To try it: `bin/rails server`, sign in as the seeded admin, open the dashboard and a workout day.

## 7. Tests and verification

- `bin/rails test`: 51 runs, 603 assertions, 0 failures, 0 errors, 0 skips.
- `bundle exec rubocop`: 31 files inspected, no offenses.
- With the worktree's server on `127.0.0.1:3001` and the real development data, the returned HTML was read: the Today box showed "Logged today · 27 sets", the nine exercises of 16 November with their heaviest sets, and "Last time · Sunday, November 15"; the Upper day page had nine pencil links; the edit page had the day as back button, the hidden `workout_day_id` and Cancel.
- **Not verified:** nothing was looked at in a browser. The Chrome extension was not connected and the machine has no browser. The layout at phone width, in particular the extra button on each exercise row, has not been seen.

## 8. Every file changed

15 files: 13 changed, 2 new.

Application
- `app/controllers/pages_controller.rb`: loads today's session as well as last time's.
- `app/controllers/workout_sets_controller.rb`: reports a refused workout instead of raising.
- `app/controllers/exercises_controller.rb`: remembers the workout day the edit was opened from and returns to it.
- `app/models/workout_log.rb`: one logged workout per split per day.
- `app/views/pages/home.html.erb`: Today box shows today's sets, then the "last time" link.
- `app/views/pages/_lifts.html.erb` (new): list of exercises with their heaviest set.
- `app/views/workout_days/show.html.erb`: admin-only pencil on each exercise row.
- `app/views/exercises/edit.html.erb`: back button to the day when opened from one.
- `app/views/exercises/_form.html.erb`: hidden `workout_day_id`, Cancel back to the day.
- `app/assets/stylesheets/components/_app.scss`: style of the closing "last time" line.
- `lib/tasks/mock.rake`: skips a day its split already has a workout on.

Tests
- `test/integration/workout_flow_test.rb`: three new tests, one older test adjusted.
- `test/models/workout_day_test.rb`: one test adjusted to the new rule.

Docs
- `CLAUDE.md`: the new rule and two code-map lines.
- `doc/home-exercise-page-fixes.md` (new): this file.

## 9. Known gaps

- The phone-width layout was not checked in a browser (section 7).
- "Only if the split changes" was implemented under the assumption in section 5.
- Older days with two workouts from the same split are still in the database and are not cleaned up.
- The screenshot path in the exercise issue points to `doc/Issues/Pics/`; the file is in `doc/Features/Pics/`. Left for the owner, since the branch no longer edits `Issues.md`.
- Renaming a shared exercise from a workout day renames it for every user. That is how the Exercises page already worked, but it is now one tap closer.
