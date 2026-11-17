# new-version-review-fix

Date: 2026-11-17. Branch `new-version-review-fix`, worked directly in the main folder (the owner asked for no worktree this time).

## 1. Summary

This branch does four things:

1. Fixes the four bugs that `doc/new-version-review.md` lists as "fix first" (B1–B4):
   - **B1:** a huge reps value crashed the request.
   - **B2:** a list parameter (`page[]=1`) crashed three pages.
   - **B3:** a workout's date had no limit.
   - **B4:** the unique index migration crashed on existing duplicates with no hint.
2. Adds base seed data: `db/seeds/data.yml` holds the owner's real data, and `bin/rails db:seed` loads it on any machine. `bin/rails seed:dump` merges new data into the file and never drops old data.
3. Adds the `update-seed-data` skill, so the seed file is updated before every commit and push. `finalize-branch` and CLAUDE.md point to it.
4. Cleans up the development database: removes 48 planned exercises that `mock:last_week` had added to empty workout days and that the cleanup of the time could not remove.

State:
- **Checks:** `bin/rails test` gives 84 runs and 0 failures. `rubocop` reports no offenses, `brakeman` 0 warnings, and `bundler-audit` no vulnerabilities.
- **Phone width:** the changed pages were checked in a real browser at 390 px.

## 2. Timeline

1. **"Read the review doc; fix the four bugs first; back up the dev database and run `mock:clear` before migrating; work on the current branch; the browser checks at phone width were never done."**
   - Read `doc/new-version-review.md`.
   - Backed up the database (`tmp/db_backups/fitness_app_development-2026-11-17.dump`) and ran `mock:clear`, which deleted nothing.
   - Found that every migration had already run and no mock data was left: one real workout, from 2026-11-16.
   - Fixed B1–B4 with tests and ran the B4 migration on a scratch copy of the database.
   - Did the phone-width browser check.
2. **"Add the History table issue to Issues.md under the right page."** Added a new "History page" section with the entry.
3. **"Give me a PR title and description."** Wrote them in chat.
4. **"Make a seed file with the current data as the base data, and a skill that keeps it updated with the latest data so push and pull carry the new and the old data."**
   - Built `lib/seed_data/` and the `seed:dump` and `seed:load` tasks.
   - Dumped the data and tested a round trip through an empty database.
   - Wrote the skill and linked it from `finalize-branch` and CLAUDE.md.
5. **"Why are there exercises on Wednesday, Friday and Saturday that I never added?"** Traced them to the mock task (section 3).
6. **"Delete them, and keep in the seed file only what I really added (yesterday's 9 logged exercises with their sets)."**
   - Backed up the database again (`tmp/db_backups/fitness_app_development-2026-11-17-before-plan-cleanup.dump`).
   - Deleted the 48 rows and rebuilt `db/seeds/data.yml` from the cleaned database.
7. **"Finalize the branch, and include the new Issues.md entry."** The owner committed the entry (Back button) in `6fb7e49`, and it is part of this branch. This doc is the last step.

## 3. Starting point

- **Review:** the branch started from `e7da91e`, which added `doc/new-version-review.md`, the full review of the version after the `app-status-fixes` pull.
- **B1:** `WorkoutSet` validated `reps_completed >= 0` with no upper bound. `99999999999999` overflowed the 4-byte column and raised `ActiveModel::RangeError`, which is a 500 in production.
- **B2:** three places called `.to_i` or `Date.iso8601` on `params[...]`, so `?page[]=1`, `?date[]=1` and `?weekday[]=1` raised `NoMethodError` or `TypeError`, again a 500:
  - `Paginated#paginate`
  - `WorkoutLogsController#index`
  - `WorkoutDaysController#new`
- **B3:** `WorkoutLog` only checked that a date was present. The "Workout details" form saved `0001-01-01` or `99999-01-01`, and the workout disappeared from every page.
- **B4:** `20261117140000_add_unique_indexes_and_require_weekday` assumed the data already followed the new "once only" rules. On the owner's database it stopped at the first duplicate with a raw `PG::UniqueViolation`; section 3 of the review covers the incident.
- **Dev database:** every migration had run and no mock workouts were left. It still held 48 planned exercises from `mock:last_week`:
  - The run on 2026-11-16 at 01:31 JST gave every empty workout day a "typical plan".
  - That version of the task (`cdd81eb`) had no way to remove those plans.
  - The later `mock:clear` finds plans through the mock workouts, which were already deleted, so it could not find them either.
- **Seed data:** none beyond the admin user and the starter catalogue.

## 4. Changes

### B1. Reps have an upper limit

`app/models/workout_set.rb`:

```ruby
# before
validates :reps_completed, presence: true,
                           numericality: { only_integer: true, greater_than_or_equal_to: 0 }
# after
MAX_REPS = 1000
validates :reps_completed, presence: true,
                           numericality: { only_integer: true, greater_than_or_equal_to: 0,
                                           less_than_or_equal_to: MAX_REPS }
```

The validation now refuses the value before the database sees it. `WorkoutSetsController` already turns a failed save into the alert "Set not added: Reps completed must be less than or equal to 1000.", and the transaction still rolls back the workout a first refused set would have started.

### B2. List parameters are ignored

`app/controllers/application_controller.rb` gets a private helper:

```ruby
def text_param(key)
  value = params[key]
  value if value.is_a?(String)
end
```

It is used in three places:
- `Paginated`: `text_param(:page).to_i`
- `WorkoutLogsController#index`: `date = text_param(:date)` before `Date.iso8601`
- `WorkoutDaysController#new`: `text_param(:weekday).presence&.to_i`

A list or hash now acts as if the parameter was not sent: page 1, the whole History, the first free weekday.

### B3. A workout's date is between 2000-01-01 and today

`app/models/workout_log.rb` gets `EARLIEST_DATE = Date.new(2000, 1, 1)` and a `date_in_range` validation. It runs on create and whenever the date changes, the same as the other date rules. Its messages are "can't be in the future" and "can't be before 2000".

`app/views/workout_logs/show.html.erb` gives the date field `min: WorkoutLog::EARLIEST_DATE, max: Date.current`, so the phone's date picker greys out the days the rule refuses. `Date.current` follows the browser's time zone, because the request runs inside `Time.use_zone`.

### B4. The migration checks the data first

`db/migrate/20261117140000_add_unique_indexes_and_require_weekday.rb`:

- **`CHECKS`:** one SQL query per rule. It lists the rows that would break a new index or the `NOT NULL`:
  - workout days without a weekday
  - a workout repeated on a day, with "(all mock data)" added when every row of the group is mock data
  - an exercise twice on a workout day
  - an exercise twice in a logged workout
  - shared exercise names that differ only in capitals
  - one user's own exercise names that differ only in capitals
- **`rows_that_break_the_rules`:** a public method, so the test can call it. It returns `{ rule => [rows] }`.
- **`change`:** starts with `reversible { |dir| dir.up { stop_on_rows_that_break_the_rules! } }`, so the check only runs when migrating up. It raises an `ActiveRecord::MigrationError` that lists the rows and says: "If they are mock data, run `bin/rails mock:clear` and migrate again. Otherwise delete or merge the extra rows…".
- **Version:** the migration version moved from `[7.1]` to `[8.1]`, as the review suggested for a migration that is being edited anyway.
- **Schema:** the schema it produces is unchanged, and `db/schema.rb` did not change.

### Base seed data

- **`db/seeds/data.yml`:** YAML, readable in a diff. It holds:
  - the shared catalogue
  - users with their time zone and active split
  - each user's own exercises
  - splits, workout days by weekday, and planned exercises with their equipment and machine brand
  - this week's moves
  - logged workouts with their entries and sets: rest day mark, notes, the plan row the entry came from, set number, reps, weight as text with all three decimals, and set notes

  It never holds passwords or mock workouts.
- **`lib/seed_data.rb`:** the `SeedData` module, with `PATH`, `dump`, `load`, `read`, `counts`, `describe` and `mock_workouts_in_database`.
- **`lib/seed_data/dumper.rb`:** reads the database (ordered by id, with every association loaded up front), merges it into the file, sorts each user's workouts by date and writes the file without empty fields.
- **`lib/seed_data/merge.rb`:**
  - `KEYS` says how each list is matched. Users by email; exercises by name, ignoring capitals; splits by name; days by weekday; moves by `week_start`; workouts by workout and date; sets by number.
  - The database's value wins for every field it has.
  - Items only in the file are kept, in their order, and new items are appended. So the file only grows.
- **`lib/seed_data/loader.rb`:** creates whatever the file has and the database lacks, inside one transaction. It never updates or deletes, so running it again changes nothing. Details:
  - A missing user gets the password in `SEED_USER_PASSWORD`. In development that defaults to `admin123456`, like the seeded admin; in production it must be set.
  - Workouts load in date order, inside the user's own time zone, so the date rule's "today" is the user's day.
  - Moves load after the days, because adding a workout day clears the split's moves.
  - `rest_day` is written as stored, never worked out again, following the project rule.
  - An invalid record raises with the workout, date and email in the message.
- **`lib/tasks/seed.rake`:** `seed:dump` (warns if mock workouts were skipped) and `seed:load`.
- **`db/seeds.rb`:** after the admin and the starter catalogue, it runs `SeedData.load` when the file exists.

### Skill and instructions

- **`.claude/skills/update-seed-data/SKILL.md`:** when to run it (before a commit or push, inside `finalize-branch`, or on request) and how:
  1. Check that no migration is pending.
  2. Run `seed:dump`.
  3. Read the diff. Stop if old workouts disappear, and ask before committing a new real email.
  4. Run the test, plus a scratch database round trip after big changes.
  5. Commit the file.
  6. Report what it gained.

  It also covers what to do after a pull, and what never to do: no `db:reset` or `mock:clear` to clean up, no hand-adding data, no secrets, no mock data.
- **`.claude/skills/finalize-branch/SKILL.md`:** new step 3b runs `update-seed-data` before the commit, and `db/seeds/data.yml` joins the files that skill may write.
- **`CLAUDE.md`:**
  - the `db:seed` and `seed:dump` commands
  - the rule to update the base data before committing or pushing
  - a code map line for `db/seeds/data.yml` and `lib/seed_data/`

### Docs

- **`doc/Issues/Issues.md`:**
  - A new open "History page" section: at 390 px the History table is about 595 px wide inside a 364 px box, so the Exercises and Sets columns start off-screen until the table is swiped.
  - The owner's own "Back button" entry under General, committed in `6fb7e49`.
- **`doc/new-version-review.md`:** the review itself, committed by the owner in `e7da91e`. It is part of this branch's diff against `master`.

### Development database, not in git

- **Backups:** two backups in `tmp/db_backups/` (ignored by git).
- **`mock:clear`:** run once; it deleted nothing.
- **Mock planned exercises:** deleted `WorkoutExercise` ids 9–56. The rule was "created between 2026-11-15 16:31:00 and 16:31:59 UTC, with no logged entry"; it matched exactly 48 rows, and the script refused to delete if the count was anything else.
- **Days now empty:**
  - PPL/UL: Legs (Wed), Upper (Fri), Lower (Sat)
  - UL: all four days
  - U/R/L/U/L: Lower (Wed), Upper (Fri), Lower (Sat)
- **Still in the database:** the 16 planned exercises the owner added (PPL/UL Push and Pull, and the 9 of U/R/L/U/L Monday) and the one logged workout.
- **Seed file:** rebuilt from the cleaned database instead of edited by hand.

## 5. Decisions

- **Reps limit 1000:** this is the review's suggestion. It is far above any real set and still allows timed holds stored as seconds (a 60-second plank). Rejected: no limit, which leaves the 500 in place, and the column's own maximum, which gives no protection against typos. *Assumption:* the owner agrees to 1000. It is one constant.
- **Date between 2000-01-01 and today:** a workout is logged on the day it is done. "Start workout" and the add-set path always use today, and moves never create logs. Rejected: a rolling "last N years" window, which would make old workouts uneditable as time passes. *Assumption:* the owner never needs to log a future workout or one from before 2000.
- **Two existing tests travel in time:** `dashboard_test.rb` and `workout_summary_test.rb` logged workouts on 2026-11-18, which is in the future on the day this was written. They now `travel_to` that week instead of the rule being loosened.
- **The migration stops instead of merging duplicates:** which of two workouts to keep is the owner's decision (review section 13, question 3). Merging also has to respect "an exercise once per log". Rejected: automatic merge.
- **One helper for list parameters:** `text_param` instead of `.to_s` at each call. `.to_s` would turn `["1"]` into `'["1"]'` and give weekday 0 (Sunday) instead of "not sent".
- **A `min`/`max` on the date field:** added during the browser check. It matches the new rule and saves taps on a phone.
- **Seed data as YAML matched by natural keys:** ids differ between machines, and YAML reads well in a diff. Rejected: `pg_dump` in git (binary, and it overwrites) and Rails fixtures (ids, and they are for tests).
- **The dump only adds; the load only creates:** the owner asked for the next push to carry the new data and keep the old, because the app relies on dates. The load never overwrites, so a machine with more local data loses nothing. The cost: removing something from the file needs a hand edit, which the skill allows only for removals the owner asks for. A renamed split appears as a new split, and the old name stays.
- **Mock workouts are never dumped:** they are not real data.
- **The loader uses the models, not raw inserts:** every validation runs, so the file cannot load data the app would refuse.
- **`lib/seed_data/` is split into three classes:** rubocop's `Metrics/ClassLength` (100 lines) flagged one class of 217 lines.
- **The seed file was rebuilt after the cleanup:** the owner asked that the file keep only what they really added. Removing records is the one case where the file may lose data, and rebuilding from the cleaned database was checked line by line against the old file. Only the 48 planned exercises and a move the owner had already undone in the app went away.
- **The phone check ran in a 390 px frame:** the browser window could not be resized. A frame on the same origin (`frame-ancestors 'self'` allows it) gives true phone-width media queries.
- **A throwaway user for the browser check:** created with a generated password and deleted afterwards, so the owner's admin password was never used.

## 6. How it works now

- **Adding a set:**
  - Reps from 0 to 1000 are saved.
  - More than that is refused with an alert, no set is saved, and no empty workout is left behind.
  - Editing a set follows the same rule ("Set not updated: …").
- **Workout details:** the date can be from 2000-01-01 to today. The picker shows only those days, and any other date is refused with "Details not saved: Date can't be in the future." (or "…before 2000").
- **URLs:** `?page[]=…`, `?date[]=…` and `?weekday[]=…` act as if the parameter was not sent.
- **Migrating a database with duplicates:**
  - Nothing changes, and the message lists the rows by user, workout, date and log ids, marking mock data.
  - After `bin/rails mock:clear`, or after removing the rows by hand, the migration runs.
- **Base data:**

  ```bash
  bin/rails seed:dump   # dev database -> db/seeds/data.yml (merge, never drops)
  bin/rails db:seed     # admin, starter catalogue, then whatever the file has and the database lacks
  bin/rails seed:load   # the file only
  ```

  `data.yml` now holds:
  - the admin (Asia/Tokyo, active split U/R/L/U/L) and the 15 catalogue exercises, including Pokemon
  - the 6 own exercises and the 3 splits with 13 days
  - the 16 planned exercises
  - the workout of Monday 2026-11-16 (Upper, U/R/L/U/L): 9 exercises, 27 sets
- **Before a commit or push:** the `update-seed-data` skill runs (also inside `finalize-branch`).

## 7. Tests and verification

| Check | Result |
|---|---|
| `bin/rails test` | 84 runs, 1115 assertions, 0 failures, 0 errors, 0 skips |
| `bundle exec rubocop` | 39 files, no offenses |
| `bundle exec brakeman -q` | 0 security warnings |
| `bundle exec bundler-audit check` | no vulnerabilities |
| `bin/rails zeitwerk:check` | all is good |

New tests:

- **`test/models/workout_recording_test.rb`:** reps of 0 and 1000 are valid; 1001, -1 and `"99999999999999"` are refused by the validation, not by the database.
- **`test/integration/logging_flow_test.rb`:**
  - A too-large value redirects with the alert, saves no set and starts no workout; editing a set refuses it too.
  - A future date, year 0001 and year 99999 are refused with their messages; the date field has `min`/`max`.
- **`test/models/workout_log_test.rb`:** the date boundaries (today, 2000-01-01, tomorrow, 1999-12-31, year 1) and refused updates.
- **`test/integration/navigation_flow_test.rb`:** `page[]`, `page[a]`, `date[]` and `weekday[]` on History, Exercises, admin Users and the new workout day page all return 200.
- **`test/migrations/add_unique_indexes_precheck_test.rb`:**
  - clean data passes
  - a repeated workout is listed with "(all mock data)", and `migrate(:up)` raises before its first change
  - shared names that differ only in capitals are found

  Each test drops the index it needs inside its transaction, so the test database is unchanged afterwards.
- **`test/lib/seed_data_test.rb`:**
  - Dumping, deleting everything, then loading twice gives the same user, time zone, active split, rest day mark, plan link, own exercise link, machine brand, three-decimal weight and move, and the same file when dumped again.
  - A second dump keeps a deleted workout, adds a new one, keeps the old split name after a rename, and leaves out mock workouts.

Proved against the old code: with the controller and model changes stashed, the new B1–B3 tests failed (`NoMethodError: undefined method 'to_i' for an instance of Array`, missing constants).

By hand:

- **B4 migration:**
  - On a scratch database restored from the backup, rolled back `20261117140000`, planted two mock Push workouts on 2026-11-14 and migrated. It stopped with "1 workout logs that repeat a workout on a day: user 1, Push on 2026-11-14: workout logs 20, 21 (all mock data)".
  - After `mock:clear` it migrated, and `db/schema.rb` stayed unchanged. The scratch database was dropped.
- **Seed round trip:** loaded into an empty scratch database with `db:seed` (twice), dumped it again, and the file was identical (before and after the cleanup). The scratch database was dropped.
- **Browser at 390 px, with a throwaway user and the server on port 3001, both removed afterwards:**
  - Dashboard, Splits, a split, a workout day, an exercise page, History, Exercises, a logged workout and New split: no page scrolls sideways.
  - The "Show days" collapse, recent-workout dropdowns and their lifts, the navbar menu and the "Move a workout" modal (full screen on the phone) all open.
  - Too-large reps and a future date show the alert and save nothing.

Not verified:

- **CSP:** the console showed no CSP errors, but messages from inside a frame may not reach the extension's console, so this is unconfirmed.
- **Docker and Actions:** the Docker image and GitHub Actions were not run for this branch.

## 8. Every file changed (29)

Against `master`, including this doc.

App code (7):
- `app/controllers/application_controller.rb`: `text_param` helper (B2).
- `app/controllers/concerns/paginated.rb`: reads the page through `text_param` (B2).
- `app/controllers/workout_days_controller.rb`: reads the weekday through `text_param` (B2).
- `app/controllers/workout_logs_controller.rb`: reads the date through `text_param` (B2).
- `app/models/workout_log.rb`: `EARLIEST_DATE` and the `date_in_range` validation (B3).
- `app/models/workout_set.rb`: `MAX_REPS` and the upper bound on reps (B1).
- `app/views/workout_logs/show.html.erb`: `min`/`max` on the workout date field (B3).

Database and seeds (3):
- `db/migrate/20261117140000_add_unique_indexes_and_require_weekday.rb`: the pre-check and a readable stop; version `[8.1]` (B4).
- `db/seeds.rb`: loads `db/seeds/data.yml` after the admin and the catalogue.
- `db/seeds/data.yml`: the base data (new).

Seed data code (5, new):
- `lib/seed_data.rb`: the `SeedData` module, with the path, entry points and counts.
- `lib/seed_data/dumper.rb`: reads the database and writes the merged file.
- `lib/seed_data/merge.rb`: matching keys and the merge that never drops data.
- `lib/seed_data/loader.rb`: creates what is missing, through the models.
- `lib/tasks/seed.rake`: the `seed:dump` and `seed:load` tasks.

Tests (9):
- `test/integration/logging_flow_test.rb`: reps limit and date range flows.
- `test/integration/navigation_flow_test.rb`: list parameters return 200.
- `test/lib/seed_data_test.rb`: seed round trip, keeping old data, skipping mock data (new).
- `test/migrations/add_unique_indexes_precheck_test.rb`: the migration pre-check (new).
- `test/models/dashboard_test.rb`: travels to its fixed Wednesday.
- `test/models/workout_log_test.rb`: date boundaries.
- `test/models/workout_recording_test.rb`: reps boundaries.
- `test/models/workout_summary_test.rb`: travels to the week of its fixed dates.

Instructions and skills (3):
- `.claude/skills/update-seed-data/SKILL.md`: the new skill (new).
- `.claude/skills/finalize-branch/SKILL.md`: step 3b, and `data.yml` joins the files it may write.
- `CLAUDE.md`: seed commands, the "update before pushing" rule, the code map line.

Docs (3):
- `doc/Issues/Issues.md`: History table issue, and the owner's Back button issue.
- `doc/new-version-review.md`: the review (committed by the owner).
- `doc/new-version-review-fix.md`: this doc (new).

## 9. Known gaps

- **The rest of the review is not done:** S1–S8, P2–P5, sections 7–9 and the owner questions in section 13. Next in the review's order are S6 (same message for a foreign or missing plan row), C6 (an admin's shared exercise with the name of their own), then S2 (rate limits) and the Alerts issue.
- **Limits not confirmed by the owner:** 1000 reps and 2000-01-01 to today.
- **Open issues found in this work:**
  - The History table on a phone: Exercises and Sets start off-screen.
  - Alerts sit over the content at the bottom of the screen and never disappear (the open Alerts issue).
- **Removing data from the seed file:** it only grows, so removing something means editing `db/seeds/data.yml` by hand, and a renamed split keeps its old name in the file. Two splits of one user with the same name would be ambiguous: the first one by id is used.
- **Every user's email goes into git:** today that is only `admin@example.com`. The skill asks before committing a new real email.
- **CI never runs the migrations:** it loads `schema.rb` (review section 7, item 16). The B4 pre-check is covered by its own test, but a migration run on an empty database is still not part of CI.
- **The seed loader in production:** if `data.yml` has users other than the admin, `db:seed` in production needs `SEED_USER_PASSWORD`, and it does load the owner's workouts there.
