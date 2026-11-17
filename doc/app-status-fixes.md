# App status fixes

Branch: `app-status-fixes` (first named `claude/app-status-code-review-2a3766`, renamed to follow the naming rule). Date: 2026-11-17. Based on `master` at `b6cd6aa`.

The review this branch answers is [app-status-review.md](app-status-review.md). It lists every finding with its status. This document is the change doc: what was asked, what was changed, why, and how the app works now.

## 1. Summary

The owner asked for a check of the whole app, then for everything it found to be fixed, with two exceptions (production email, and reordering exercises, which is already planned).

- **Upgrade:** Rails 7.1.6 to 8.1.4.1, Devise 4.9.4 to 5.0.4, Puma 7.1.0 to 8.1.2, every other gem to its newest version, and the Rails 8.1 behaviour defaults. Ruby moved from 3.3.5 to 3.3.13 at the end (section 4.13).
- **Security:** account lock after wrong passwords, longer passwords, the only admin cannot delete their account, a content security policy, length limits, two vulnerable gems updated, security scanners and CI added.
- **Data:** unique indexes behind the "once only" rules, and `workout_days.weekday` is required.
- **Code:** dead code and unused gems removed, repeated lookups shared, the home page logic moved to a `Dashboard` object, the stylesheet split into 19 files, the integration tests split into seven files.
- **Fixes seen by the user:** the muscle group is a dropdown on the exercise form (the one open issue), the add-set form is the same on both pages, and the recent workout row no longer wraps its date on a phone.

State: 74 tests pass (1024 assertions), rubocop has no offenses, brakeman has 0 warnings, bundler-audit finds no vulnerabilities. The pages were opened in Chrome at phone width. The Docker image was not built, and the CI workflow has not run yet.

## 2. Timeline

| # | The owner asked | What was done |
|---|---|---|
| 1 | "Perform a check on the status of this app": issues, gaps, security, technical issues, redundant and duplicated code, structure | Read every model, controller, view, script, config file and the schema; ran the tests and rubocop; checked the development database for bad data. Reported the findings. No code changed |
| 2 | "Write the whole find in a md file on doc" | Wrote `doc/app-status-review.md` |
| 3 | Fix everything except production email and the exercise reorder; check `Features.md` and `Issues.md`; try the Rails, Devise and Puma upgrade first and keep it only if nothing breaks | Renamed the branch. Upgraded and ran the suite: nothing broke, so the upgrade was kept. Then fixed the findings (sections 4.1 to 4.8). Recorded the status of each in the review doc |
| 4 | "I added Claude extension to Chrome please check there" | The extension was not connected yet; reported how to connect it |
| 5 | "logged in try again" | Opened every page in Chrome in a 390 px wide frame. No overflow, no policy violation, all interactive parts work. Found one layout wart that predates the branch |
| 6 | Fix that wart; run a check again for anything missing; say how to run a server because `rails s` stopped working; check all gems on the new version; refactor to newer ways of writing the code | Fixed the recent workout row. Found why `rails s` failed (section 4.10). Updated every gem and removed the `json` pin. Moved to Rails 8.1 defaults, `params.expect`, `normalizes` and the hash shorthand. Searched for leftovers and fixed three |
| 7 | "Finalize this branch" | This document, the commit, the push and the pull request |

## 3. Starting point

At `master` (`50773c3` when the work started):

- Rails 7.1, whose security support ended in October 2025.
- 62 tests passing, rubocop clean, and no way found for one user to reach another user's data.
- No account lock, passwords of 6 characters, no content security policy, no scanners, no CI.
- The only admin could delete their own account through "Cancel my account".
- The "once only" rules (one workout per day, an exercise once on a day and once in a workout, unique exercise names) were checked in Ruby only.
- One open issue: the muscle group could be typed on the exercise form.
- Ownership joins, the session lookup, the rest day check and several view fragments were written out in several places.
- One 708-line stylesheet, one 1,271-line integration test file, and a home page action that set 17 instance variables.
- Unused gems, unused Rails parts, empty test stubs and unused styles.

## 4. Changes

### 4.1 Upgrade

Before: `gem "rails", "~> 7.1.6"`, `config.load_defaults 7.1`.

After: `gem "rails", "~> 8.1.0"`, `config.load_defaults 8.1`.

Steps:

1. Changed the Gemfile and ran `bundle update rails devise puma`. Result: Rails 8.1.4.1, Devise 5.0.4, Puma 8.1.2, Rack 3.2.8.
2. Ran the whole suite with no code change: 62 runs, 0 failures, no deprecation warning. The first run took 382 seconds because every parallel test process rebuilt its caches at once; the next took 40 seconds.
3. Later (request 6): `bundle update` for every gem, then `config.load_defaults 8.1`. The suite passed again.
4. The `json < 3` pin was removed. It existed because json 3 broke `execjs`; with `execjs` 2.10.2, json 3.1.0 works. Checked by building the assets in production mode from an empty cache.

Reason: Rails 7.1 gets no security fixes. The owner asked to keep the upgrade only if nothing broke.

### 4.2 Accounts and security

**The only admin cannot delete their account.**

- `User#last_admin?` is true for an admin when no other admin exists.
- `before_destroy :keep_an_admin` on `User` refuses the deletion. It is declared before the associations so nothing of the user is deleted first.
- `Users::RegistrationsController#destroy` (new) redirects back to the account page with a message. Without it Devise would sign the admin out and say the account was cancelled, although the model had refused.
- `config/routes.rb`: `devise_for :users, controllers: { registrations: "users/registrations" }`.
- `devise/registrations/edit.html.erb` shows an explanation instead of the button for the only admin.

**Account lock.** `User` has Devise `:lockable`. In `config/initializers/devise.rb`: `lock_strategy = :failed_attempts`, `maximum_attempts = 10`, `unlock_strategy = :time`, `unlock_in = 15.minutes`. Migration `20261117130000_add_lockable_to_users` adds `failed_attempts` and `locked_at`. Unlocking is by time only because the app sends no email.

**Passwords.** `config.password_length = 8..128` (was 6). Existing passwords keep working; the rule applies when a password is set.

**Password reset.** `config.paranoid = true`: the answer is the same whether the email exists or not.

**Content security policy.** `config/initializers/content_security_policy.rb` was fully commented out. Now:

```ruby
policy.default_src :self
policy.font_src    :self, :data, "https://fonts.gstatic.com"
policy.style_src   :self, "https://fonts.googleapis.com"
policy.img_src     :self, :data
policy.script_src  :self
policy.object_src  :none
policy.base_uri    :self
policy.form_action :self
policy.frame_ancestors :self
```

A nonce covers the inline import map and the style Turbo adds for its progress bar. The nonce follows the session id, so pages in Turbo's cache stay valid.

**Length limits.** Exercise and lift names 80, split name 60, machine brand 60, set note 200, exercise note 500, workout note 2000.

**Scanners and CI.** `brakeman` and `bundler-audit` added to the Gemfile. bundler-audit found `msgpack` 1.8.0 and `ruby-lsp` 0.26.2 vulnerable; both were updated. `.github/workflows/ci.yml` runs the tests, rubocop, brakeman and bundler-audit on every push and pull request.

**Gemfile.** `ruby-lsp` moved to the `development` group. `simple_form` comes from rubygems (`~> 5.4`) and no longer from GitHub.

### 4.3 Database

Migration `20261117140000_add_unique_indexes_and_require_weekday`:

| Change | Rule it backs |
|---|---|
| `workout_days.weekday` is `NOT NULL` | Every workout day is on a weekday |
| Unique index on `workout_logs (user_id, workout, date)`, replacing the non-unique one | One logged workout per workout per day |
| Unique index on `workout_exercises (workout_day_id, exercise_id)` where the exercise is set | An exercise is on a workout day once |
| Unique index on `workout_log_exercises (workout_log_id, exercise_id)` where the exercise is set | An exercise is in a logged workout once |
| Unique index on `LOWER(name)` of catalogue exercises, and on `user_id, LOWER(name)` of a user's own | Unique exercise names |

`ApplicationController` rescues `ActiveRecord::RecordNotUnique` and sends the user back with "That was already saved, so nothing was added twice." Reason: two requests at the same moment (a double tap) could both pass the Ruby check. Legs and Lower being the same workout stays a model rule; a plain index cannot express it.

Both migrations were run on the development database, which `master` shares. They add columns and indexes and one `NOT NULL`; nothing is dropped or renamed.

### 4.4 The open issue: muscle group

Before, in `exercises/_form.html.erb`: `f.input :muscle_group, placeholder: "Chest"` (free text).

After: `f.input :muscle_group, collection: Exercise::MUSCLE_GROUPS, include_blank: "Other"`, and in `Exercise`:

```ruby
validates :muscle_group, inclusion: { in: MUSCLE_GROUPS, message: "must be one of the listed muscle groups" }, allow_nil: true
```

The picker modal's select now offers the same fixed list.

### 4.5 Shared code

| New | Replaces |
|---|---|
| `has_many :workout_exercises`, `:workout_log_exercises`, `:workout_sets` (through) on `User` | Seven hand-written ownership joins in four controllers. Now `current_user.workout_sets.find(id)` |
| `WorkoutLog.session_of(workout, date)` and the `with_sets` scope | The session lookup written out in a model, three controllers; and `includes(workout_log_exercises: :workout_sets)` in five places |
| `WorkoutDay#log_on(date)` | `WorkoutExercise#log_on`, which asked an exercise for the day's log |
| `Split#rest_day?(date)` | The same check in `WorkoutLog` and `WorkoutLogsController` |
| `ApplicationController`: `from_dashboard?`, `errors_of(record)`, `require_admin!(back:, message:)` | `params[:from] == "dashboard"` in many places, `errors.full_messages.to_sentence` in ten, two admin checks |
| `ExercisePicker#picker_exercises` (a helper method) | `@picker_exercises = ...` in three actions |
| `workout_sets/_form`, `workout_sets/_table` | The add-set form and the set table, each written twice. The form now has `min`, `step` and `inputmode` on both pages |
| `splits/_empty` | The "no splits yet" block on two pages |
| Helpers `weight_and_reps(set)`, `day_logs_path(logs, date)`, `exercise_picker_button(css)` | The same line or link written two to four times |

`WorkoutExercise#entry_in(log)` now reads the log's loaded exercises instead of running a query, so the workout day page asks once for today's log with its sets, not twice per exercise.

`ExercisePicker#picked_exercises` returns a new exercise unsaved. It is saved together with the row it is added to, inside the caller's transaction, so it does not stay behind when the add fails.

### 4.6 The Dashboard object

Before: `PagesController#home` set 17 instance variables in 40 lines, and the view computed more.

After:

```ruby
def home
  @dashboard = Dashboard.new(current_user, Date.current) if user_signed_in?
end
```

`app/models/dashboard.rb` answers each question once, the first time the page needs it: `split`, `days`, `week_plan`, `week_moved?`, `today_workout`, `today_log`, `last_log`, `today_summary`, `today_lifts`, `calendar_weeks`, `calendar_logs`, `week_dates`, `week_logs`, `week_summary`, `movable_days`, `exercise_counts`, `other_workouts`, `rest_day_choices`, `recent_logs`. The `month_weeks` helper moved into it as `calendar_weeks`.

`logs_count` and `sets_count` are kept as methods. `doc/Prompt/home-page-overview-context.md` records that the owner wants them kept for later; as methods they cost nothing until a page shows them.

### 4.7 Styles

`components/_app.scss` (708 lines) was cut along its own section comments into 9 files in `components/` and 10 in `pages/`. `application.scss` imports them in the original order; the two `_index.scss` files are gone. Checked by compiling before and after: the only difference was the removed unused rules (`.avatar*`, the legend fix, `.stat-tile`, `.stat-value`, `.stat-label`, `.plain-list`).

`sassc-rails` (unmaintained) was replaced by `dartsass-sprockets`. The compiled stylesheet has the same 5,277 selectors. `config/initializers/sass.rb` silences the deprecation warnings that come from Bootstrap and Font Awesome.

The recent workout row: the chips are wrapped in `.recent-chips`, and `.recent-toggle` is a grid. On a phone the chips are on their own row under the summary; from the `sm` breakpoint up they are beside it, as before.

### 4.8 Removed

- Gems: `jbuilder`, `capybara`, `selenium-webdriver`, `dotenv-rails`, `sassc-rails`.
- `require "rails/all"` became the six parts the app uses. `app/channels`, `config/cable.yml`, `config/storage.yml` and the Active Storage lines of the environment files are gone.
- Five empty model test stubs, the channel test, `test/application_system_test_case.rb`, `fixtures :all`.
- `lib/templates/erb/scaffold/_form.html.erb`.
- Everything that handled a workout day without a weekday: the "Not on a weekday yet" card, `weekday || 7`, the `if weekday` guards, `where.not(weekday: nil)` in the mock task.
- `set_number` from the permitted set parameters. The app numbers a set itself.

### 4.9 Newer ways of writing the code

| Change | Where |
|---|---|
| `params.expect(split: [:name])` for `params.require(:split).permit(:name)` | Eight places in the controllers and `ExercisePicker` |
| `normalizes :name, with: ->(name) { name.squish.presence }` for a `before_validation` block | `Exercise` (name, muscle group), `WorkoutSet` (notes), `WorkoutLogExercise` (notes) |
| `where(date:)` for `where(date: date)` | 23 places, applied by rubocop; `.rubocop.yml` enforces it |
| `:unprocessable_content` for the deprecated `:unprocessable_entity` | Controllers, Devise config, tests |

### 4.10 Why `rails s` stopped working

A server had been left running on port 3010 from the worktree. It wrote `tmp/pids/server.pid`, and Rails refuses to start a second server while that file exists. The server was stopped and the file removed. Nothing in the code caused it.

### 4.11 Tests

`test/integration/workout_flow_test.rb` (1,271 lines, 27 tests) was split by area into seven files. The tests were moved unchanged. The shared setup is the `FlowTest` class in `test/test_helper.rb`.

Three existing tests changed, each because the behaviour changed on purpose:

- A doubled plan row can no longer be saved, so the test now checks the database refuses it.
- `log_on` is called on the workout day.
- A `set_number` sent with the form is ignored, not rejected.

Twelve tests were added: the only admin (model and pages), a regular user cancelling, the account lock, the password length with the reset answer, the policy header, the muscle group dropdown, the add-set form on both pages, the length limits, and two for `Dashboard`.

### 4.13 Ruby 3.3.13 and the CI error

The first CI run failed in all three jobs with "Unavailable version 3.3.5 for ruby on ubuntu-26.04". `runs-on: ubuntu-latest` now means Ubuntu 26.04, where `ruby/setup-ruby` builds only the latest patch of a series (3.3.13), and it reads the version from `.ruby-version` (3.3.5). The owner chose to move the project to 3.3.13 rather than pin the runner to `ubuntu-24.04`, so the same Ruby is used on the machine, in the Docker image and in CI.

Changed: `.ruby-version`, `ruby "3.3.13"` in the `Gemfile`, `ARG RUBY_VERSION=3.3.13` in the `Dockerfile`, the `RUBY VERSION` block of `Gemfile.lock`, and the docs that name the version. `ci.yml` itself did not need to change. Developers need `rbenv install 3.3.13` (a current ruby-build is required) and `bundle install`. Not verified: the workflow has not run on GitHub with this change.

### 4.14 The lint job and vendor/bundle

The first lint run on GitHub that got past Ruby setup failed with "Unable to find gem rubocop-discourse". The CI installs the gems into `vendor/bundle`, inside the project. `.rubocop.yml` lists its own `Exclude`, which replaces RuboCop's default list (that default skips `vendor`), so RuboCop walked into `vendor/bundle`, found the `.rubocop.yml` that the `mini_mime` gem ships (it inherits from `rubocop-discourse`), and stopped. Locally the gems are outside the project, so it never happened. `'vendor/**/*'` was added to the `Exclude` list. Reproduced here by copying `mini_mime` into `vendor/bundle` (same error before, 34 files and no offenses after).

### 4.12 Docs

- `doc/claude-universal-back-button-4813cc.md` is now `doc/universal-back-button.md`.
- The two screenshots have names without spaces, and `Issues.md` and `Features.md` link to them by a relative path.
- `CLAUDE.md`, `README.md` and `doc/Prompt/project-context.md` describe the new stack, commands and code map.
- `doc/Issues/Issues.md`: "Exercise name edit" (the muscle group typed) moved to "Issues resolved" as "Muscle group typed when editing an exercise". The "Alerts" issue the owner added on `master` stays open.
- `doc/Features/Features.md`: no feature was finished by this branch, so nothing moved.

## 5. Decisions

| Decision | Alternative rejected | Why |
|---|---|---|
| Keep the upgrade | Stay on 7.1 | The suite passed unchanged; the owner's condition was "if it breaks leave it" |
| Unlock by time | Unlock by email | The app sends no email yet |
| Sign-up stays open | Close it or require confirmation | It changes who can use the app; it is the owner's decision. Still open |
| `frame-ancestors 'self'` | `'none'` | The browser check loads pages in a frame on the app's own page; other sites still cannot frame it |
| Keep the dashboard counts as methods | Delete them | The owner asked to keep them; as methods they run no query until used |
| Withdraw the "private twin" finding | Forbid a user's own exercise with a catalogue name | An existing test and `CLAUDE.md` allow it on purpose. The validation was written, failed that test, and was removed |
| Leave simple_form in three forms | Rewrite them by hand | It changes how every form and error looks; not asked |
| Remove the system test gems | Write system tests | Chrome and chromedriver are not installed on the machine |
| No `rate_limit` or `allow_browser` | Add them as "newer Rails" | They are new behaviour, not a newer way to write the same code |
| Product gaps untouched | Build them | The rule is not to add features beyond what is asked |
| Base the branch on `master` at `b6cd6aa` | Leave it on `50773c3` | `master` gained a commit to `Issues.md`; nothing was committed yet, so moving the base avoids a conflict for the owner |

Assumption: no production database exists yet, so the new unique indexes and the `NOT NULL` meet no bad data. The development database had none.

## 6. How it works now

Run it:

```bash
bin/setup
bin/rails server
bin/rails test
bundle exec rubocop
bundle exec brakeman
bundle exec bundler-audit check --update
```

After pulling this branch into a folder, run `bundle install`. The development database already has both migrations.

Behaviour that changed for the user:

- Ten wrong passwords lock the account for 15 minutes.
- A new password needs 8 characters.
- The only admin sees an explanation instead of "Cancel my account".
- The muscle group of an exercise is chosen from a list.
- A double tap that would save something twice shows a message instead of an error page.
- On a phone, a recent workout shows its chips under the date.
- Text fields refuse text over their limit.

Everything else behaves as before.

For developers: find records through `current_user`; read form fields with `params.expect`; tidy text with `normalizes`; a new outside host must be added to the content security policy; no inline `style=` or inline scripts.

## 7. Tests and verification

| Check | Result |
|---|---|
| `bin/rails test` | 74 runs, 1024 assertions, 0 failures, 0 errors |
| `bundle exec rubocop` | 34 files, no offenses |
| `bundle exec brakeman` | 0 warnings |
| `bundle exec bundler-audit check --update` | No vulnerabilities found |
| `bin/rails zeitwerk:check` | All is good |
| Production-mode boot with eager load | Works |
| `assets:precompile` in production mode, empty cache | Builds, no warning |
| `bundle outdated` | Only `marcel` and `prism`, held by other gems |
| Chrome, 390 px frame, signed in as the seed admin | 11 pages: none wider than the screen, scripts load, no policy violation. Navbar, user menu, set editing, machine brand field, picker modal, dashboard toggles and modals work. Recent row checked at 390 px and at desktop width |
| Server from the main folder (`master`) | Starts, pages answer 200 on the migrated database |

Not verified:

- The Docker image was not built.
- The CI workflow has not run; it runs on the first push.
- No form was submitted in the browser. Saving, moving and the account lock are covered by the tests only.
- The JavaScript has no automated tests.

## 8. Every file changed

119 files: 38 added, 19 deleted, 59 modified, 3 renamed.

**Project root (7)**

- `.github/workflows/ci.yml` (added): tests, rubocop, brakeman, bundler-audit.
- `.rubocop.yml`: enforces the hash shorthand.
- `CLAUDE.md`: stack, commands, code map.
- `Dockerfile`: `nodejs` in both stages.
- `Gemfile`, `Gemfile.lock`: Rails 8.1, gems removed, added and updated.
- `README.md`: Rails 8.1 and the scanner commands.

**Styles (26)**

- `app/assets/stylesheets/application.scss`: imports the new files in order.
- Deleted: `components/_app.scss`, `components/_avatar.scss`, `components/_form_legend_clear.scss`, `components/_index.scss`, `pages/_home.scss`, `pages/_index.scss`.
- Added in `components/`: `_cards.scss`, `_empty_state.scss`, `_exercise_picker.scss`, `_layout.scss`, `_lists.scss`, `_pagination.scss`, `_row_link.scss`, `_tables.scss`.
- Added in `pages/`: `_auth.scss`, `_dashboard_calendar.scss`, `_dashboard_moves.scss`, `_dashboard_recent.scss` (with the recent row fix), `_dashboard_rest_day.scss`, `_dashboard_today.scss`, `_dashboard_week.scss`, `_landing.scss`, `_split_week.scss`, `_splits_cards.scss`, `_workout_log.scss`.

**Controllers, helper, script (15)**

- `app/channels/application_cable/channel.rb`, `connection.rb` (deleted).
- `application_controller.rb`: `RecordNotUnique` rescue, `from_dashboard?`, `errors_of`, `require_admin!` with arguments.
- `concerns/exercise_picker.rb`: `picker_exercises`, unsaved new exercise, `params.expect`.
- `exercises_controller.rb`: shared admin check and error helper.
- `pages_controller.rb`: builds `Dashboard`.
- `splits_controller.rb`: `from_dashboard?`.
- `users/registrations_controller.rb` (added): the only admin cannot cancel.
- `workout_days_controller.rb`: one query for today's sets.
- `workout_exercises_controller.rb`, `workout_log_exercises_controller.rb`, `workout_sets_controller.rb`: records through `current_user`.
- `workout_logs_controller.rb`: `session_of`, `rest_day?`, keeps the flash.
- `app/helpers/application_helper.rb`: three helpers added, `month_weeks` removed.
- `app/javascript/controllers/reveal_controller.js`: stale comment fixed.

**Models (10)**

- `concerns/lift.rb`: length limits.
- `dashboard.rb` (added).
- `exercise.rb`: `normalizes`, muscle group validation, name length.
- `split.rb`: `rest_day?`, name length.
- `user.rb`: `:lockable`, `last_admin?`, the destroy guard, three through associations.
- `workout_day.rb`: `log_on`.
- `workout_exercise.rb`: `entry_in` in memory.
- `workout_log.rb`: `session_of`, `with_sets`, notes length.
- `workout_log_exercise.rb`, `workout_set.rb`: `normalizes`, notes length.

**Views (19)**

- `devise/registrations/edit.html.erb`: explanation for the only admin.
- `exercises/_form.html.erb`: muscle group dropdown.
- `pages/_calendar.html.erb`, `_lifts.html.erb`, `_week_overview.html.erb`: shared helpers.
- `pages/_recent_workout.html.erb`: chips wrapper, shared helper.
- `pages/home.html.erb`: reads from `Dashboard`.
- `shared/_exercise_picker.html.erb`: fixed muscle group list.
- `splits/_empty.html.erb` (added).
- `splits/index.html.erb`, `splits/show.html.erb`: shared empty state, no unscheduled card.
- `workout_days/show.html.erb`, `workout_logs/new.html.erb`: picker button helper.
- `workout_exercises/show.html.erb`, `workout_logs/show.html.erb`: shared set form and table.
- `workout_log_exercises/edit.html.erb`, `workout_logs/index.html.erb`: shared helpers.
- `workout_sets/_form.html.erb`, `workout_sets/_table.html.erb` (added).

**Config (10)**

- `config/application.rb`: only the Rails parts in use, defaults 8.1.
- `config/cable.yml`, `config/storage.yml` (deleted).
- `config/environments/development.rb`, `production.rb`, `test.rb`: unused settings removed; the test environment has a mailer host.
- `config/initializers/content_security_policy.rb`: the policy.
- `config/initializers/devise.rb`: lock, password length, paranoid, status name.
- `config/initializers/sass.rb` (added).
- `config/routes.rb`: the registrations controller.

**Database (3)**

- `db/migrate/20261117130000_add_lockable_to_users.rb` (added).
- `db/migrate/20261117140000_add_unique_indexes_and_require_weekday.rb` (added).
- `db/schema.rb`.

**Docs (8)**

- `doc/Features/Features.md`: screenshot link.
- `doc/Features/Pics/screenshot-2026-11-15-200616.png`, `screenshot-2026-11-16-221022.png` (renamed).
- `doc/Issues/Issues.md`: one issue moved to resolved, screenshot link.
- `doc/Prompt/project-context.md`: stack and paths.
- `doc/app-status-review.md` (added): the review with the status of each finding.
- `doc/app-status-fixes.md` (added): this document.
- `doc/universal-back-button.md` (renamed).

**Lib (2)**

- `lib/tasks/mock.rake`: no weekday filter, hash shorthand.
- `lib/templates/erb/scaffold/_form.html.erb` (deleted).

**Tests (19)**

- Deleted: `test/application_system_test_case.rb`, `test/channels/application_cable/connection_test.rb`, `test/integration/workout_flow_test.rb`, `test/models/exercise_test.rb`, `split_test.rb`, `workout_exercise_test.rb`, `workout_log_exercise_test.rb`, `workout_set_test.rb`.
- Added: `test/integration/accounts_flow_test.rb`, `dashboard_flow_test.rb`, `exercises_flow_test.rb`, `logging_flow_test.rb`, `navigation_flow_test.rb`, `splits_flow_test.rb`, `week_moves_flow_test.rb`, `test/models/dashboard_test.rb`.
- Modified: `test/models/user_test.rb`, `test/models/workout_recording_test.rb`, `test/test_helper.rb`.

## 9. Known gaps

- **Sign-up is open to anyone.** The owner has not decided.
- **No system tests.** The JavaScript is checked by hand only.
- **Two form styles** (simple_form and hand-written) remain.
- **Production is not set up**: mail host and delivery, database, deploy. The owner said this is fine for now.
- **The Docker image was not built** after `nodejs` was added.
- **CI has not run yet.**
- **Product gaps** from the review are untouched: a workout for a past day, an export, a workout outside the split on a planned day. The exercise reorder is planned by the owner.
- **The "Alerts" issue** the owner added on `master` is open and not part of this branch.
- **Anyone with a checkout of an older branch** needs `bundle install` after this is merged, and old branches will see two migrations in the database that they have no file for. That is harmless.
