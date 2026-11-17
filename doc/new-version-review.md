# Review of the new version (after the `app-status-fixes` pull)

Date: 2026-11-17. Reviewed at `master` merge commit `6a4dbbf` ("Merge branch 'master' of github.com:pqdesu/fitness_app"), which joined the owner's `9f94f16` (only edits `doc/Features/Features.md`) with PR #12 (`app-status-fixes`: Rails 8.1, Devise 5, Puma 8, Ruby 3.3.13, account security, unique indexes, `Dashboard` object, split stylesheet, split integration tests, CI).

This document is the full list of what the review found, so a new worktree can fix all of it. Nothing in the repository was changed by the review. The throwaway probe tests that produced the evidence below were written in a scratchpad outside the repo; their results are copied into this document so nothing depends on them.

Contents

1. How the review was done
2. State of the checks
3. Incident: the unique index migration failed on the dev database
4. Findings that are real bugs (fix first)
5. Security findings
6. Performance findings
7. Old code and leftovers
8. Structure and cleanliness findings
9. Test and tooling gaps
10. Things verified as correct (do not "fix")
11. Open items from the project's own docs
12. Suggested order of work, with a test for each fix
13. Questions only the owner can answer

Severity words used: **Bug** (wrong behaviour the user can hit), **Risk** (not wrong today, can hurt later), **Cleanup** (no behaviour change), **Gap** (missing coverage or tooling).

---

## 1. How the review was done

1. Read the git history of the merge: `git log --graph`, `git diff --stat 6a4dbbf^1 6a4dbbf` (120 files, 3906 insertions, 2782 deletions against the owner's side), and the change doc `doc/app-status-fixes.md`.
2. Read every file under `app/models`, `app/controllers`, `app/helpers`, `app/javascript`, plus `config/routes.rb`, `config/application.rb`, `config/environments/production.rb`, the CSP and Devise initializers, `db/schema.rb`, the two new migrations, `Gemfile`, `.rubocop.yml`, `Dockerfile`, `.github/workflows/ci.yml`, `.gitignore`, `lib/tasks/mock.rake`, the layout, and the views that contain delete buttons.
3. Ran: `bin/rails test`, `bundle exec rubocop`, `bundle exec brakeman` (default and `-w1`, the most sensitive level), `bundle exec bundler-audit check --update`, `bin/importmap audit`, `bin/rails zeitwerk:check`, `bundle outdated`.
4. Wrote three temporary integration tests on the repo's own `FlowTest` base (so they use the same users and exercises as the real tests) and ran them with `bin/rails test <path>`:
   - a **query counter** over eight pages, then the same after growing the data from 1 split / 5 workout days to 5 splits / 25 workout days;
   - an **edge input probe** with 39 malformed or hostile requests (huge numbers, arrays where strings are expected, other users' ids, invalid enums, very long strings, signed-out and non-admin access);
   - an **outcomes probe** that prints the flash message of each request, to tell "rejected cleanly" from "saved".
5. Read the dev database (read only) to find why the migration failed (section 3).

Environment notes found on the way (not app bugs, but they cost time):

- `.ruby-version` moved to 3.3.13 but the machine only had 3.3.5. Fix on the machine: `git -C ~/.rbenv/plugins/ruby-build pull`, `rbenv install 3.3.13`, then `gem install bundler -v '~> 2.6'` (Ruby 3.3.13 ships bundler 2.5.22, the project asks for `~> 2.6`), then `bundle install`.
- The README and `doc/app-status-fixes.md` say "Developers need `rbenv install 3.3.13` (a current ruby-build is required) and `bundle install`". They do not mention the bundler version. Add one line (section 7, item 14).

---

## 2. State of the checks (on Ruby 3.3.13, in the review worktree)

| Check | Result |
|---|---|
| `bin/rails test` | 74 runs, 1024 assertions, 0 failures, 0 errors, 0 skips (13 s) |
| `bundle exec rubocop` | 34 files inspected, no offenses |
| `bundle exec brakeman` | 0 warnings; also 0 at `-w1` (weak confidence included); 12 controllers, 12 models, 52 templates scanned |
| `bundle exec bundler-audit check --update` | No vulnerabilities found (advisory DB of 1378 advisories) |
| `bin/importmap audit` | No vulnerable packages found |
| `bin/rails zeitwerk:check` | All is good |
| `bundle outdated` | 3 gems behind: `marcel` 1.2.1 → 2.1.0 (a major), `prism` 1.9.0 → 2.1.0 (a major), `regexp_parser` 2.13.2 → 2.13.3 |
| Browser check at phone width | **Not done in this review.** The PR says it was done on its own branch. The dashboard and the split stylesheet were not looked at by eye here |
| Docker image build | **Not done.** The PR says it was not built either |
| GitHub Actions | **Not seen running** with the Ruby 3.3.13 change (the PR says so too) |

---

## 3. Incident: the unique index migration failed on the dev database

### What happened

`rails db:migrate` in the main folder ran the first two pending migrations and failed on the third:

```
== 20261117120000 CreateWorkoutDayMoves   migrated
== 20261117130000 AddLockableToUsers      migrated
== 20261117140000 AddUniqueIndexesAndRequireWeekday: migrating
-- change_column_null(:workout_days, :weekday, false)
-- remove_index(:workout_logs, [:user_id, :workout, :date])
-- add_index(:workout_logs, [:user_id, :workout, :date], {:unique=>true})
PG::UniqueViolation: could not create unique index "index_workout_logs_on_user_id_and_workout_and_date"
DETAIL: Key (user_id, workout, date)=(1, Upper, 2026-11-13) is duplicated.
```

PostgreSQL runs a migration inside one transaction, so the third migration rolled back completely (the `weekday` change and the `remove_index` were undone). The first two stayed applied. `db:migrate:status` before the run showed those three as `down`.

### Why (read only inspection of the dev database)

Eight `workout_logs` rows share a (user, workout, date) with another row:

| Date | Workout | Log ids | Exercises / sets in each |
|---|---|---|---|
| Mon 2026-11-09 | Upper | 11, 15 | 6 / 18 and 2 / 6 |
| Fri 2026-11-13 | Upper | 9, 13, 17 | 6 / 18 each |
| Sat 2026-11-14 | Lower | 10, 14, 18 | 4 / 12 each |

All eight have `notes = "Mock data"`, and each points at a different `workout_day_id`, so they come from different splits. They were created within two seconds of each other on 2026-11-15 16:31 UTC by `bin/rails mock:last_week`. The rule at that time was "one logged workout per split per day", so several splits could each log the same "Upper" on the same day. The new rule (CLAUDE.md: "There is one logged workout per workout per day. Sets added from any split join it") is now enforced by a unique index, and the existing rows break it.

13 of the 14 `workout_logs` rows in the dev database are mock data (`notes LIKE 'Mock data%'`). The one real log is not part of the conflict.

The other conditions the migration needs were checked and are clean in the dev database: no `workout_days` row with a null `weekday`; no duplicate lower-cased shared exercise names; no exercise twice on one workout day; no exercise twice in one logged workout.

### What to do

For the owner's database now: `bin/rails mock:clear` then `bin/rails db:migrate` (the task deletes the mock workouts and the plans it added, except exercises with real sets).

For the code, see finding **B4** (the migration should not crash on existing data).

---

## 4. Findings that are real bugs (fix first)

### B1. A huge reps value crashes the request with a 500

- Where: `app/models/workout_set.rb:11` — `validates :reps_completed, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }` has no upper bound. The column is a 4-byte integer.
- Reproduction (request): `POST /workout_exercises/:id/workout_sets` with `workout_set[reps_completed]=99999999999999`.
- Result: `ActiveModel::RangeError: 99999999999999 is out of range for ActiveModel::Type::Integer with limit 4 bytes` → HTTP 500 in production. `WorkoutSetsController#create` only rescues `ActiveRecord::RecordInvalid`. The same applies to `PATCH /workout_sets/:id` (`update`).
- Related: a value of `1000000` reps is accepted and saved ("Set 1 added." in the probe), as is `99999.999` kg. Both are absurd for a workout log.
- Fix: add `less_than_or_equal_to:` to `reps_completed` (pick a limit the owner agrees to; 1000 would still cover timed bodyweight holds that the mock data stores as seconds, e.g. Plank = 60). The limit must be below 2,147,483,647 so the validation, not the database, answers. Consider the same for `set_number` (it is generated, so no user input reaches it).
- Test: a flow test that posts `99999999999999` and `1000001` (or whatever the limit plus one is), expects a redirect with an alert, and expects `WorkoutSet.count` unchanged; a model test for the boundary values.

### B2. Array parameters where a string is expected give 500 errors

`params[:x]` can be an Array or a Hash when a client sends `x[]=1` or `x[a]=1`. Three places call string methods on it without checking.

| Request | Code | Error |
|---|---|---|
| `GET /workout_logs?page[]=1` (also `/exercises`, `/admin/users` through `Paginated`) | `app/controllers/concerns/paginated.rb:10` `params[:page].to_i` | `NoMethodError: undefined method 'to_i' for an instance of Array` |
| `GET /workout_logs?date[]=1` | `app/controllers/workout_logs_controller.rb:15` `Date.iso8601(params[:date])`; the `rescue Date::Error` at line 19 does not catch it | `TypeError: no implicit conversion of Array into String` |
| `GET /splits/:id/workout_days/new?weekday[]=1` | `app/controllers/workout_days_controller.rb:19` `params[:weekday].presence&.to_i` | `NoMethodError: undefined method 'to_i' for an instance of Array` |

Not affected (checked, handled): `?workout[]=Push` on `workout_logs#new` and `#create` (the `include?` check redirects), `?from[]=dashboard` (`params[:from] == "dashboard"` is just false), `exercise=x` as a string (`params.expect` returns 400), `workout_set[]=...` (redirects with an alert), `page=abc` and `page=999…9` (clamped).

- Also check: `WeekMovesController#create` uses `Integer(params[:weekday], exception: false)`, which returns nil for an Array — safe. `params[:workout_day_id]` goes through `find_by(id:)`, which with an Array does an `IN` — safe.
- Fix: read as strings, e.g. `params[:page].to_s.to_i`, `Date.iso8601(params[:date].to_s)` with `rescue Date::Error`, `params[:weekday].to_s.presence&.to_i`. A single private helper in `ApplicationController` (for example `param_text(:page)`) would give one place to do it. Alternative: `rescue_from ActionController::BadRequest` is not enough because these are `NoMethodError`/`TypeError`, not bad requests.
- Test: one flow test that requests each URL above and expects a non-500 status (200 or a redirect).

### B3. A workout's date has no limit

- Where: `app/models/workout_log.rb:13` `validates :date, presence: true`. `PATCH /workout_logs/:id` (the "Workout details" form, `workout_log_params` permits `:date`) accepts any date.
- Probe results: `0001-01-01`, `2200-05-05` and `99999-01-01` were all saved ("Workout details saved."). After the change the dashboard (`GET /`) and History (`GET /workout_logs`) still returned 200, so nothing breaks, but a one-digit typo moves a workout to a year no page shows.
- Consequences to think about when choosing the rule: a future date makes a workout "logged" in the future; the dashboard's week and calendar queries ignore it; `rest_day` is computed on create only (so changing the date later never recomputes it, by design — CLAUDE.md says "the mark is never recalculated").
- Fix options (owner to choose, see section 13): not after today; or within a range such as the last 5 years to today. Apply to `new_record? || date_changed?` like the other date rules. The `new` path already uses `Date.current`, so only the edit can set a bad date.
- Test: model test for the boundaries, flow test that a bad date is rejected and the flash says why.

### B4. The unique index migration crashes on existing data

- Where: `db/migrate/20261117140000_add_unique_indexes_and_require_weekday.rb`. It does `remove_index` + `add_index ... unique: true` on `workout_logs (user_id, workout, date)`, then adds unique indexes on `workout_exercises`, `workout_log_exercises` and `exercises`, then `change_column_null :workout_days, :weekday, false`.
- Problem: it assumes the data already follows the new rules. Any database with a duplicate stops at the first one with a raw `PG::UniqueViolation` and no hint of what to do (section 3 is the live example). `change_column_null ... false` would also fail on a row with a null `weekday`, and the `exercises` indexes on `LOWER(name)` fail on two names that differ only in case.
- Fix options:
  1. Add a pre-check at the top of `up` that counts the duplicates for each index and raises one readable error naming the rows and the fix (for example "8 workout logs repeat a workout on a day; run `bin/rails mock:clear` if they are mock data"). Cheapest and safest, because deleting or merging real workouts must be the owner's decision.
  2. Or merge duplicates in the migration (move `workout_log_exercises` of the later log into the first, then delete the later log). This is destructive and has to handle the "exercise once per log" rule while merging; not recommended without the owner.
- Also: the 3 other tables' duplicates are the same class of problem; the pre-check should cover all four indexes and the null weekdays.
- Test: a migration test is awkward in Rails; at least test the pre-check as a plain Ruby object extracted into `lib` or the migration file, or document the manual procedure in the change doc.
- Related: `mock:last_week` was the source of the duplicates (section 3). It now skips a workout already logged that day ("a workout already logged that date is skipped"), so new mock data does not create them. The old rows remain until `mock:clear`.

---

## 5. Security findings

### Overall result

No way found for one user to read or change another user's data, and no way for a non-admin to reach admin features. Details in section 10. The items below are hardening, not holes.

### S1. Content security policy nonce is the session id (Risk, low)

- Where: `config/initializers/content_security_policy.rb:25` `config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s.presence || SecureRandom.base64(16) }`, with `nonce_directives = %w[script-src style-src]` (line 26).
- This is the Rails default template. The nonce is the same on every request of one session, so a script injected through some future XSS that already saw one page of that session can reuse it. A fresh nonce per response is the stronger design.
- Why it was probably kept: Turbo caches pages and replaces the body; a per-request nonce needs the `csp-nonce` meta tag (already rendered by `csp_meta_tag` in the layout) so Turbo-inserted scripts and styles carry the right nonce. The current setting works with that without extra care.
- Fix: `->(request) { SecureRandom.base64(16) }`, then test in a real browser with Turbo navigation, Bootstrap modals and collapses, and the importmap script (the tests do not run JavaScript). Revert if the console shows CSP violations. Do not change it without that browser check.

### S2. No rate limiting on sign-up and password reset (Risk, medium)

- Devise `:lockable` (`config/initializers/devise.rb`: `maximum_attempts = 10`, `unlock_in = 15.minutes`, `lock_strategy = :failed_attempts`, `unlock_strategy = :time`) only protects sign-in with a wrong password. `POST /users` (sign-up) and `POST /users/password` (reset request) have no throttle, so a bot can create unlimited accounts or flood one address with reset emails once mail is set up (S3).
- Side effect of lockable: anyone who knows an email can lock that account for 15 minutes by failing 10 times (and again after it unlocks). The lock is by account, not by IP. With `paranoid = true` the response does not reveal whether the account exists, which is good.
- Fix: Rails 8 has `rate_limit` built in: `rate_limit to: 10, within: 3.minutes, only: :create` in `Users::RegistrationsController` and a Devise passwords controller, and on sessions `create`. It needs a cache store (the default in production is the Rails cache; check `config.cache_store`, the app has no Solid Cache). Alternatively the `rack-attack` gem. Decide the numbers with the owner.
- Test: a flow test that the 11th request in the window returns 429.

### S3. Production mail is not configured (Risk, already known and deferred by the owner)

- `config/environments/production.rb:4`: `config.action_mailer.default_url_options = { host: "http://TODO_PUT_YOUR_DOMAIN_HERE" }`.
- Two problems: the value is a placeholder, and `host:` must be a bare host name (`example.com`), with the scheme in `protocol: "https"`. Putting `http://` in `host` produces broken links in reset emails. No `delivery_method` or SMTP settings exist, so reset emails cannot be sent in production.
- The owner excluded "production email" from the earlier fix round, so this stays open until they choose a provider. Record it as open in `doc/Issues/Issues.md` so it is not forgotten. `MAILER_SENDER` already sets the From address.

### S4. Nothing limits how much one account can create (Risk, low)

- Sign-up is open, and each account can create unlimited splits, workout days (limited to 7 per split by the weekday uniqueness), exercises, logs and sets. No per-user cap exists. For a personal app this is acceptable; for a public deployment add caps (for example own exercises ≤ 300) or rely on the rate limit of S2.

### S5. The time zone cookie has no `Secure` flag (Risk, very low)

- `app/javascript/time_zone.js:19` sets `time_zone=...; path=/; max-age=31536000; samesite=lax`. The value is validated server-side (`ActiveSupport::TimeZone[reported]` returns nil for anything unknown, and the server then falls back to the stored `users.time_zone` or the default), so a forged cookie only changes the forger's own dates.
- With `force_ssl = true` the cookie only travels over HTTPS in practice. Adding `; secure` when `location.protocol === "https:"` is a one-line hardening.

### S6. Existence oracle through a foreign `workout_exercise_id` (Risk, very low)

- `WorkoutLogExercisesController#create` (`app/controllers/workout_log_exercises_controller.rb`) builds `workout_log.workout_log_exercises.new(workout_exercise_id: params[:workout_exercise_id])` from any id. `WorkoutLogExercise#copy_from_plan` runs first and reads the other user's plan row, then `workout_exercise_fits_the_log` rejects it.
- The saved record is never created and nothing of the other user's row is shown. But the error texts differ: a foreign existing id gives "Workout exercise must be planned for the same workout as the log", while a non-existent id fails on the name ("Name can't be blank" family). So ids can be told apart as existing or not. It reveals nothing but existence of a numeric id, and ids are sequential anyway.
- Fix (cheap, consistent with the rest of the app, which finds records "through the owner"): look the plan row up with `current_user.workout_exercises.find_by(id: ...)` and treat nil as "choose an exercise", so both cases give the same message.

### S7. Account deletion and admin actions: checked, no change needed

Listed so nobody re-opens them: `Admin::UsersController` blocks acting on yourself, so the last admin can never be deleted or demoted there; `Users::RegistrationsController#destroy` blocks the last admin from cancelling; `User#keep_an_admin` is a `before_destroy` guard. `@user.destroy!` in the admin controller would raise if the guard aborted, but it cannot abort there (the current admin always remains).

### S8. Smaller hardening notes

- `config.hosts` is not set for production. Rails 8 does not enforce a host allow-list in production by default. Set it (or use `config.hosts << "your.domain"`) when the domain is known, so Host header tricks cannot build links with a foreign host. The `/up` health check should be excluded with `config.host_authorization = { exclude: ->(r) { r.path == "/up" } }`.
- No `Permissions-Policy` header is configured. Rails 8 has `config/initializers/permissions_policy.rb` as an optional file; the app needs no camera, microphone or geolocation, so denying them is free.
- The CSP has no `report_uri`/`report_to`, so violations are only visible in the browser console. Fine for now.
- Logging: `config/initializers/filter_parameter_logging.rb` filters `passw, secret, token, _key, crypt, salt, certificate, otp, ssn`, which covers passwords and reset tokens. Emails are not filtered; acceptable.
- Sessions use the default cookie store, which is `SameSite=Lax` and secure under `force_ssl`. No `:timeoutable`, so a session lasts until closed or "remember me" expires; reasonable for a phone app.
- Secrets in git: none. `config/master.key` and `.env*` are ignored; only `config/credentials.yml.enc` is committed (normal).

---

## 6. Performance findings

### P1. Query counts per page (measured, flat as data grows)

Measured with a subscriber on `sql.active_record` (schema and transaction statements excluded), signed in as a user with the data below.

| Page | 1 split, 5 days (3 logged weeks, 9 sets per day) | 5 splits, 25 days, 20 more logs | Verdict |
|---|---|---|---|
| `GET /` (dashboard) | 24 | 26 | No N+1; grows by 2 with 4 more splits |
| `GET /splits` | 6 | 6 | Flat (`includes(:workout_days)`) |
| `GET /splits/:id` | 4 | — | Fine |
| `GET /workout_days/:id` | 7 | — | Fine; `entry_in` reads loaded associations |
| `GET /workout_exercises/:id` | 6 | — | Fine |
| `GET /workout_logs` (History, 20 per page) | 9 | 9 | Flat (`with_sets.includes(workout_day: :split)`) |
| `GET /workout_logs/:id` | 10 | — | Fine; see P3 |
| `GET /exercises` | 4 | 4 | Flat |
| `GET /admin/users` | 3 | — | Fine |
| `GET /splits` with no active split | — | 6 | `Split#active?` is not called in this list (only on `splits#show`), so no N+1 |

No change required. The items below are about the future or about trimming.

### P2. The "Add exercises" modal loads the whole catalogue on every page that has it (Risk, low today)

- `app/controllers/concerns/exercise_picker.rb:13` `Exercise.visible_to(current_user).order(:name).to_a` is a `helper_method`; `shared/_exercise_picker.html.erb` renders one checkbox row per exercise grouped by muscle group, into every page that includes the modal (workout day page, workout log page, new log page).
- Fine for tens of exercises. With a catalogue of hundreds, every one of those pages ships all of them in HTML. Options: render the list lazily (a Turbo Frame loaded when the modal opens), or add a client-side filter box and keep the render. The product brief wants few taps, so a search box inside the modal may be wanted anyway; that is a feature, so ask the owner (section 13).
- Also: `visible_to` is `where(user_id: [nil, user.id])`, which is `user_id IS NULL OR user_id = ?`; PostgreSQL will not use the partial unique indexes for it, but the table is tiny. No index action needed.

### P3. The workout log page loads the log's exercises twice (Cleanup)

- `WorkoutLogsController#show` loads `@log_exercises = @workout_log.workout_log_exercises.includes(:workout_sets, :workout_exercise).order(:id)` and then `@workout_day.workout_exercises...reject { |planned| planned.entry_in(@workout_log) }`. `entry_in` calls `log.workout_log_exercises.select {...}` on the log's own association, which loads it once more (a different relation from `@log_exercises`). Cost: one extra query. Fix: preload the association on `@workout_log` (`includes(:workout_log_exercises)` when finding it) or pass `@log_exercises` to a variant of `entry_in`.

### P4. The dashboard runs five separate workout log queries (Cleanup, optional)

- `Dashboard` reads `today_log` and `last_log` (two `with_sets` queries with `includes(workout_day: :split)`), `calendar_logs` (the month), `week_logs` (the week, with sets) and `recent_logs` (5 latest, with sets). They overlap (the week and the recent five are mostly the same rows). The page is 24 queries and fast; merging the week and the recent query would save about 3 queries. Not worth a risky change unless the page ever feels slow. Each is memoised, so nothing repeats inside a request.

### P5. Index on `workout_logs (user_id, date)` (Cleanup, optional)

- The only index with `user_id` first is the new unique `(user_id, workout, date)`. The dashboard calendar and week queries filter `user_id = ? AND date BETWEEN ...` without `workout`, so PostgreSQL can use only the `user_id` prefix and filter the rest. Irrelevant at one user's volume (a few hundred rows a year); if a user ever has tens of thousands of logs, add `index [:user_id, :date]`. The plain `index_workout_logs_on_user_id` becomes redundant once either exists.

### P6. Per-request writes in `browser_time_zone` (Cleanup)

- `ApplicationController#browser_time_zone` calls `current_user.update_column(:time_zone, reported)` whenever the cookie differs from the stored value. That is one write on the first request after a change of zone, not every request (the next request matches). Correct and cheap. Noted only because it is a write in an `around_action` on GET requests.

### P7. `Exercise#rename_linked_lifts` uses `update_all` (Cleanup, correct but note)

- `app/models/exercise.rb` `after_update :rename_linked_lifts` runs `workout_exercises.update_all(name:)` and `workout_log_exercises.update_all(name:)`. That is one statement each (good for performance) but skips validations, callbacks and `updated_at`. Intended ("keep them in step"). If `updated_at` on those rows ever matters, use `update_all(name:, updated_at: Time.current)`.

---

## 7. Old code and leftovers

1. **`config/application.rb:18`** `config.action_controller.raise_on_missing_callback_actions = false if Rails.version >= "7.1.0"`. A leftover from the 7.1 upgrade. The condition is always true on 8.1, and comparing version strings with `>=` is wrong in general ("10.0" < "7.1.0" as strings). The setting turns off an error that helps catch a typo in an `only:` list. Every `only:` action in the app exists (checked: `splits` show/edit/update/destroy/activate; `workout_days` show/edit/update/destroy; `workout_exercises` show/update/destroy; `workout_log_exercises` edit/update/destroy; `workout_logs` show/update/destroy and new/create; `exercises` new/create, edit/update/destroy and edit/update; admin `update`/`destroy`). Remove the line, then run the tests; they will fail loudly if one is missing.
2. **`app/views/devise/registrations/edit.html.erb:36`** "Cancel my account" has `data: { confirm: "Are you sure?", turbo_confirm: "Are you sure?" }`. `confirm` belonged to rails-ujs, which the app does not load. Keep only `turbo_confirm`. (A `turbo_confirm` on `button_to` is better put on the `form:` option like the other delete buttons in the app.)
3. **Migrations declare `ActiveRecord::Migration[7.1]`** (all existing ones, including the two new ones). New migrations on a Rails 8.1 app should use `[8.1]`. Old ones should stay as they are. Fix the two added by PR #12 only if you are editing them anyway (B4).
4. **`Dockerfile`**: `FROM ... as base` and `as build` (lowercase `as`; Docker warns `FromAsCasing`; write `AS`). `libvips` is installed in both stages but the app loads no Active Storage or image processing (`config/application.rb` requires only `active_model`, `active_record`, `action_controller`, `action_mailer`, `action_view`, `rails/test_unit`); remove it. `nodejs` is installed in both stages; it is only needed for `execjs`, which `autoprefixer-rails` uses (item 5). `curl` in the final stage is for a health check that the Dockerfile does not define; either add a `HEALTHCHECK` against `/up` or drop `curl`. The image was never built, so none of this was tested.
5. **`autoprefixer-rails`** (Gemfile) hooks into Sprockets and needs a JavaScript runtime (`execjs` → Node). Sass output already targets modern phone browsers; the gem's benefit is small and it is the reason Node is in the image. Consider removing the gem and `nodejs` together, then compare the compiled CSS for missing `-webkit-` prefixes in a browser before committing to it.
6. **`sprockets-rails` + `dartsass-sprockets`** is the older asset pipeline (Rails 8 defaults to Propshaft + `dartsass-rails`). It works and the PR rebuilt the assets from an empty cache. Mention only as a later migration; no action now.
7. **`WorkoutLog has_many :workout_exercises, through: :workout_log_exercises`** (`app/models/workout_log.rb:8`) was not seen used in the code read (the controllers use `workout_log_exercises`). Search the views before removing; if unused, delete it.
8. **`Dashboard#logs_count` and `#sets_count`** are unused by any box. The owner asked to keep them (CLAUDE.md). Do not remove.
9. **Empty test directories** `test/controllers`, `test/helpers`, `test/mailers`, `test/system`, `test/fixtures/files` exist locally (git does not track empty directories, so they are not in the repo). Nothing to do, except that `test/system` being empty is the gap in section 9.
10. **`app/assets/stylesheets/components/_alert.scss`** positions every alert `fixed; bottom: 16px; right: 16px; z-index: 1000` and nothing hides it. This is the one open entry in `doc/Issues/Issues.md` ("Alerts do not look appropriate to the UI of the app… make it disappear after… 5 seconds"). The flashes partial `app/views/shared/_flashes.html.erb` renders `alert-info` for notices and `alert-warning` for alerts with a close button. Fix with a small Stimulus controller (for example `flash_controller.js`) that removes the element after ~5 s, plus styling to match the app. No inline scripts or `style=` (CSP). Move the issue to "Issues Resolved" when done (CLAUDE.md rule).
11. **Log out is a link with `data-turbo-method="delete"`** (`app/views/shared/_navbar.html.erb:31`). It works with Turbo. Without JavaScript the link does a GET and gets a 404 (`sign_out_via = :delete`). Acceptable for this app; if you want it to work without JavaScript use `button_to ... method: :delete` styled as a dropdown item.
12. **`<meta name="viewport" content="..., shrink-to-fit=no">`** in the layout: `shrink-to-fit` is an obsolete Safari-only value. Harmless; can be dropped.
13. **`<title>FitnessApp</title>`** is static on every page. A per-page title (`content_for :title`) helps browser history and tabs. Optional.
14. **README/doc**: add to the setup notes that Ruby 3.3.13 comes with bundler 2.5.22 and the project needs `gem install bundler -v '~> 2.6'`.
15. **`bundle outdated`**: `marcel` and `prism` have new major versions (transitive; Rails and `ruby-lsp` pull them in). Update only when Rails or `ruby-lsp` allow it; `regexp_parser` has a patch update. Add `.github/dependabot.yml` (bundler and github-actions ecosystems, weekly) so this is not a manual step. CI already runs `bundler-audit`, which catches vulnerabilities but not plain staleness.
16. **`.github/workflows/ci.yml`**: `actions/checkout@v4` and `ruby/setup-ruby@v1` are fine. It runs `bin/rails db:prepare`, which loads `schema.rb`, so CI never exercises the migrations themselves (this is how B4 slipped through). A job that runs `db:create db:migrate` on an empty database, and then `git diff --exit-code db/schema.rb`, catches a migration that does not produce the committed schema.

---

## 8. Structure and cleanliness findings

### C1. `Date.current` is read in ten places in the controllers

`grep -n "Date.current" app/controllers/*.rb` finds ten uses. The time zone is applied for the whole request by `ApplicationController#use_browser_time_zone` (`Time.use_zone`), so `Date.current` is correct everywhere. But `Dashboard` takes `today` as an argument while the controllers read the clock themselves, and the mock task uses its own. A single `today` helper in `ApplicationController` (memoised, private, also a `helper_method` if views need it) would give one place, make controllers easy to test at a fixed date and remove ten copies. No behaviour change.

### C2. The "Nothing added: …" message is built in six places

`grep -rn "Nothing added" app/controllers` finds six, across `WorkoutExercisesController`, `WorkoutLogExercisesController` and `WorkoutLogsController`. Also repeated: `"Set not added: …"`, `"Not moved: …"`, `"Equipment not saved: …"`, `"Details not saved: …"`. A small helper such as `refused(action, error)` in `ApplicationController` (next to `errors_of`) removes the repetition and keeps the punctuation consistent (some messages end with a period inside the helper, some after `errors_of`, and `ExercisesController#destroy` has none: `"…was not deleted: #{errors_of(@exercise)}"` without a period).

### C3. `WorkoutSetsController#create` is hard to follow

`app/controllers/workout_sets_controller.rb:4` pre-declares `workout_set = nil; back = nil`, then opens a transaction, branches on `params[:workout_exercise_id]`, assigns `back`, builds the set, and aborts with `raise ActiveRecord::Rollback unless workout_set.save`, so that a failed set does not leave an empty workout behind. Then it re-checks `workout_set.persisted?` and rescues `RecordInvalid` for a failed `entry_on!`. It works (and is tested), but it is the most tangled method in the app. Extract the transaction into a model method, for example `WorkoutExercise#add_set_on(date, attributes)` returning the set, so the controller is "call, then redirect by result". `entry_on!` already is "the one way sets of a split's workout reach a log" per CLAUDE.md, so this is the natural home.

### C4. `WorkoutExercisesController#create` filters inline

`app/controllers/workout_exercises_controller.rb:17` computes `on_day` only `unless error`, then branches three ways with an `elsif` that reassigns `exercises`. Move "which of these are not on the day yet" to the model (`WorkoutDay#add_exercises(exercises)` returning the added and the skipped) and the controller reads as three redirects.

### C5. `ExercisePicker#picked_exercises` returns a tuple

It returns `[exercises, error]` (`[[exercise], nil]` / `[[], "message"]`), and all three callers unpack it. A small result object (`PickedExercises` with `exercises` and `error`, or just raise a named error) is clearer. Only worth it together with C2.

### C6. `ExercisePicker#find_or_build_exercise` has an edge case (Bug-adjacent, low)

`app/controllers/concerns/exercise_picker.rb:32`: the lookup `Exercise.visible_to(current_user).where("LOWER(name) = ?", name.downcase).order(:id).first` returns an existing exercise before looking at `shared_exercise_requested?`. For an admin who types a name that matches **their own private** exercise and ticks "Add to the shared catalogue", the private one is returned and no shared exercise is created, silently. Expected: either create the shared one (the unique indexes allow a shared and a private exercise with the same name), or say why it was not created. Also `.downcase` in Ruby versus `LOWER()` in PostgreSQL can differ for non-ASCII letters (for example "Ä"); use `ActiveRecord::Base.connection` lowering consistently or compare through the model's `normalizes`/`uniqueness` logic.

### C7. `WorkoutDay` mixes constants and validations

`app/models/workout_day.rb` defines `NAMES` and `SAME_WORKOUT` between associations and validations, puts `def self.names_for` between two `validates`, and a second `validates :weekday` after it. Reorder: constants, associations, callbacks, validations, class methods, instance methods. No behaviour change. (`validates :day` before the `names_for` method, `validates :weekday` after it.)

### C8. `Split#week_move_error` returns user-facing text from the model

It returns strings such as "choose a day from today to Saturday" that the controller wraps ("Not moved: …"). The rule is in the right place; the wording could be an error object or i18n key instead of a string. Low value; leave unless more messages are added.

### C9. `Dashboard` is a good object, but a few methods are cheap to merge

`several_splits?` runs `user.splits.count` (a COUNT query) while `current_split` may already have loaded splits; `week_moved?` runs `exists?`. Fine; mention only because the "each question is asked once" comment is not true of these two (they are asked once each, but not memoised: calling them twice in a view runs the query twice). Add `@x ||=` if a view calls them more than once.

### C10. `User#current_split` is queried per call

`active_split || splits.order(:id).first` — `order` builds a new relation on every call, so for a user with no active split it is a query each time it is called. `Split#active?` calls it, and `splits#show` calls `active?` once, so it is harmless today. Memoise inside `User` (or pass the current split in) if more callers appear.

### C11. `Lift` concern comment vs. `Exercise` rename

`Lift#normalize_lift` copies the exercise's name onto the row at every validation (`self.name = exercise.name if exercise`). The admin rename path uses `update_all` to keep rows in step. Two mechanisms for one rule. They agree today; a comment in `Lift` that points to `Exercise#rename_linked_lifts` would prevent a future drift.

### C12. Test and view naming

`test/models/workout_recording_test.rb` is named for "recording" while the domain words are "log" and "set". Cosmetic; rename when touched.

---

## 9. Test and tooling gaps

1. **Nothing tests JavaScript, layout or CSP.** `test/system` is empty and no system-test gem (Capybara, Selenium) is in the Gemfile. CLAUDE.md says "Look at changed pages in a real browser at phone width before calling UI work done. The tests do not run the JavaScript or show the layout." That rule is the only guard. Cheap, valuable additions without a browser: a test that renders each page and fails if the HTML contains an inline `style="`, an inline `<script>` without a nonce, or `onclick=`, because the CSP forbids them and the production build would break silently. A real system test for the "time zone reload" and the modals would need Capybara + a headless Chrome, which is heavier; ask the owner (section 13).
2. **No test for the migrations** (B4). At minimum, a test that loads the pre-check logic with sample duplicates.
3. **Rubocop skips `test/**`, `config/**`, `db/**`, `bin/**`** (`.rubocop.yml` Exclude list). `test/` is about 1,970 lines of code that style rules never see. Remove `test/**/*` from the exclusion and fix what it reports (mostly string quoting and line length, which are already relaxed).
4. **`Style/FrozenStringLiteralComment`, `Metrics/*` and several others are disabled** in `.rubocop.yml`. Fine by the owner's choice; note that `Metrics/MethodLength` being off is how C3 and C4 grew. If you fix C3 and C4, consider turning `Metrics/MethodLength` back on with a generous maximum (20).
5. **No tests for the edge cases in B1, B2, B3, S6, C6.** Each fix should come with its own flow or model test (listed in section 12).
6. **No test that every migration runs on an empty database** (item 16 in section 7).
7. **Parallel tests** use `number_of_processors` workers. On this machine that was 12 and the suite takes 13 s. On a small CI runner the PR notes a first run of 382 s because each worker built its caches at once; later runs took 40 s. If CI becomes slow, set `parallelize(workers: 2)` for CI only.
8. **Mock task** has a test (`test/tasks/mock_task_test.rb`). Add a case for "a workout already logged that day by another split is skipped" if it is not there (it is the rule that created the duplicates).

---

## 10. Things verified as correct (do not "fix")

### Authorization and ownership (probe: 39 requests)

| Probe | Result |
|---|---|
| `GET /splits/:id` of another user | 404 |
| `GET /workout_days/:id` of another user | 404 |
| `POST /workout_exercises/:id/workout_sets` of another user's plan row | 404 |
| `GET /workout_logs/:id` of another user | 404 |
| `POST /workout_logs/:id/workout_log_exercises` for another user's log | 404 |
| `PATCH /splits/:id/activate` of another user's split | 404 |
| `POST /splits/:id/week_move` with another user's `workout_day_id` | redirect, "Not moved: choose a workout." (the day is found through `@split.workout_days`, which is the user's own split) |
| Foreign `workout_exercise_id` on `workout_log_exercises#create` | redirect, "Nothing added: Workout exercise must be planned for the same workout as the log." (see S6 for the message difference) |
| Signed out: `/splits`, `/exercises`, `/workout_logs`, `/admin/users` | 302 to sign in; `/` (landing page) is 200 by design |
| Signed in, not admin: `GET /admin/users` | 302 with "Only an admin can do that." |
| Not admin: `POST /exercises` | 302, nothing created |
| Not admin: `PATCH /admin/users/:id` with `admin=false` on an admin | 302 and the admin stayed an admin |

All controllers find records through `current_user` (`current_user.splits`, `.workout_days`, `.workout_exercises`, `.workout_log_exercises`, `.workout_sets`, `.workout_logs`), `Exercise.visible_to(current_user)` for the picker, and `current_user.exercises` (or visible ones for an admin) for edit/delete. No `Model.find(params[:id])` was found outside the admin controller, where it is intended.

### Input validation outcomes

| Probe | Result |
|---|---|
| `weight_used = 1e30` | rejected: "Weight used must be less than 100000." |
| `weight_used = -3` | rejected: "must be greater than or equal to 0" |
| `weight_used = abc` | rejected (non-numeric) |
| set note of 500 characters | rejected: "Notes is too long (maximum is 200 characters)." |
| exercise name of 5000 characters | rejected: "Name is too long (maximum is 80 characters)." |
| exercise `muscle_group = Bogus` | rejected by the inclusion validation |
| workout day `day = Bogus`, `weekday = 99` | 422 with errors |
| workout day `weekday = 9999…9` (30 digits) | 422 |
| `equipment = laser` | rejected by the inclusion validation |
| `?page=abc`, `?page=-5`, `?page=99…9` (30 digits) | 200, clamped to a valid page |
| `?date=2026-13-45` | redirect to History (rescued) |
| `params.expect` with a string where a hash is expected (`exercise=x`) | 400 |
| `workout_set[]=1&workout_set[]=2` | redirect with an alert, no crash |
| `workout=Bogus` or `workout[]=Push` on the new-log pages | redirect with "Choose one of the listed workouts." |

### Everything else that is right

- **CSRF:** `protect_from_forgery` is on by default; `csrf_meta_tags` is in the layout; forms use Rails helpers.
- **XSS:** no `html_safe`, `raw`, inline `style=`, `onclick`, `javascript:` or `<script>` in `app/views` or `app/helpers` (grep found none); `target="_blank"` is not used.
- **Open redirect:** `redirect_back` uses `fallback_location`; with Rails 8.1 defaults `redirect_back` does not allow other hosts.
- **Mass assignment:** every controller reads fields with `params.expect(model: [...])`. `admin` is never permitted from a form; `Admin::UsersController#update` reads `params[:admin] == "true"` (anything else becomes `false`).
- **Passwords:** 8–128 characters, `stretches` 12 in production, Devise `paranoid` on (no account enumeration on reset or sign-in), `reset_password_within` 6 hours, `expire_all_remember_me_on_sign_out`.
- **Database integrity:** unique indexes behind every "once only" rule (workout per day, exercise once per workout day and per log, catalogue and own names case-insensitively, set number per exercise, one move per workout day per week), foreign keys on every reference with `on_delete` set where the model nulls or cascades (`workout_logs.workout_day_id` nullify, `workout_day_moves.workout_day_id` cascade, `users.active_split_id` nullify), `NOT NULL` on required columns, and `weight_used` `decimal(8,3)` matching the validation limit `< 100_000`.
- **Race handling:** a double tap that hits a unique index raises `ActiveRecord::RecordNotUnique`; `ApplicationController` rescues it with a message. The one rule with no index is "Legs and Lower are the same workout", which is a model rule only (comment in the migration says so); two parallel requests could create both. Accepting that is reasonable for one person at a gym; if it matters, add a generated column or store a canonical workout name for the index.
- **User deletion order:** `has_many :splits`, `:workout_logs`, `:exercises` are destroyed in that order; the `restrict_with_error` on `Exercise#workout_exercises` cannot block it because the splits (and their plan rows) are gone first; `workout_log_exercises` are nullified or destroyed with the logs.
- **Time zones:** `use_browser_time_zone` validates the cookie against `ActiveSupport::TimeZone`, falls back to `users.time_zone`, then the default; `time_zone.js` guards against reload loops (does not reload a non-GET page, stops when the cookie is already the zone).
- **Zeitwerk and eager load:** clean.

---

## 11. Open items from the project's own docs

- `doc/Issues/Issues.md`: one open issue, "Alerts" (this document, section 7 item 10).
- `doc/Features/Features.md` (the owner's own wish list, edited in `9f94f16`): not started and not part of this fix round unless the owner asks. For reference, the list now includes Bodyweight as a weight selection (the app already treats `weight_used` nil as bodyweight and prints "Bodyweight"), multiple selections of days, a progression chain, auto suggestion, "routine instead of sets with breaks in between", an extendable add-set, a timer, and interval training. The Features file also still asks for cardio, equipment types and brands, set tags, moving exercises and per-exercise notes. None of that is a flaw in the current code. CLAUDE.md says "Do not add features beyond what is asked", so do not start them while fixing this review.
- `doc/app-status-review.md` and `doc/app-status-fixes.md` (from PR #12) list production email and exercise reordering as intentionally left out. Production email is S3 here. Reordering is planned.

---

## 12. Suggested order of work, with the test for each fix

Work in a new worktree on a branch with plain lowercase words and no digits (CLAUDE.md), for example `review-fixes`:

```bash
git worktree add .claude/worktrees/review-fixes -b review-fixes master
```

Run the tests with `bin/rails test`, then `bundle exec rubocop` and `bundle exec brakeman` before finishing. Use the `finalize-branch` skill when finalizing.

| # | Work | Files | Test to add |
|---|---|---|---|
| 1 | **B1** reps upper bound | `app/models/workout_set.rb` | model test: limit and limit+1; flow test: `reps_completed=99999999999999` gives an alert, no 500, no set saved |
| 2 | **B2** array params | `app/controllers/concerns/paginated.rb`, `workout_logs_controller.rb`, `workout_days_controller.rb` | flow test: `page[]=1`, `date[]=1`, `weekday[]=1` all non-500 |
| 3 | **B3** log date range | `app/models/workout_log.rb` | model test for past, future, year 0001/2200/99999; flow test that the edit form shows the error |
| 4 | **B4** migration pre-check | `db/migrate/20261117140000_…rb` and `doc/` | test the pre-check with sample duplicates; run `db:migrate` on a copy of the dev database that still has the mock duplicates, then after `mock:clear` |
| 5 | **S6** foreign plan row lookup | `app/controllers/workout_log_exercises_controller.rb` | flow test: a foreign id and a non-existent id give the same alert |
| 6 | **C6** shared-exercise edge | `app/controllers/concerns/exercise_picker.rb` | flow test: admin with own "Squat" ticks shared and types "squat" → a shared exercise exists after, or a clear refusal (decide first, section 13) |
| 7 | **S2** rate limits | registrations, passwords, sessions controllers | flow test: the request over the limit returns 429 |
| 8 | **Section 7 items 1, 2, 3, 4, 14, 16** leftovers | `config/application.rb`, `devise/registrations/edit.html.erb`, new migrations' version, `Dockerfile`, README, `ci.yml` | existing suite must still pass; CI migration job |
| 9 | **Alerts** open issue | `shared/_flashes.html.erb`, new `flash_controller.js`, `components/_alert.scss`, `doc/Issues/Issues.md` | flow test that the markup has the Stimulus data attributes; check in a browser at phone width |
| 10 | **C1–C5** refactors | controllers, `WorkoutExercise`/`WorkoutDay` models | no new behaviour; the existing flow tests cover them; run rubocop |
| 11 | **S1, S5, S8** hardening | CSP initializer, `time_zone.js`, production config | S1 needs a browser check (Turbo navigation, modals, collapses); never merge it unverified |
| 12 | **Section 9** test tooling | `.rubocop.yml`, a no-inline-style/script test, `dependabot.yml` | the new test itself |
| 13 | **P2, P3, P4, P5** performance | `exercise_picker`, `workout_logs_controller#show`, `Dashboard`, a migration for an index | `assert_queries_count` style test on the pages (the probe in section 6 shows the numbers to hold: dashboard 24, splits 6, history 9, log 10, exercises 4) |

Do items 1–6 first: they are the real bugs. Items 7–9 next. The rest can follow in any order.

Before the new work, on the owner's machine: `bin/rails mock:clear`, back up the development database (the worktree and the main folder share one), then `bin/rails db:migrate`. Say so in the change doc if a fix adds a migration (CLAUDE.md: "Say so before running a migration that drops or renames something `master` still reads").

---

## 13. Questions only the owner can answer

1. **Reps limit (B1):** what is the largest sensible value? (Timed holds stored as seconds would need a larger limit than plain reps.)
2. **Date rule (B3):** not in the future, or a range such as the last N years to today? Should a workout be allowed to be logged in the future at all?
3. **Migration (B4):** is a readable stop with instructions enough, or should the migration merge duplicates itself?
4. **Rate limits (S2):** acceptable numbers and the response (a message, or a plain 429)? Is the app going to be public, or only used by the owner and a few people (this decides S4 and S8)?
5. **Production email (S3):** which provider and domain? Until then, password reset cannot work in production.
6. **Admin shared-name edge (C6):** when an admin ticks "Add to the shared catalogue" for a name they already have as a private exercise, create the shared one next to it, or refuse with a message?
7. **Catalogue modal (P2):** should the modal get a search box? (It is a feature; CLAUDE.md says not to add features unasked.)
8. **System tests (section 9 item 1):** is adding Capybara and a headless Chrome to CI wanted, or should the browser check stay manual?
9. **Autoprefixer and Node (section 7 item 5):** are older browsers a target? If not, drop the gem and Node from the image.
10. **CSP nonce (S1):** do you want a per-request nonce, given it must be checked in a real browser?
