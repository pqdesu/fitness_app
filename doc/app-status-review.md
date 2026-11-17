# App status review

Date: 2026-11-17. Reviewed at commit `50773c3` (master after the home page overview merge).

The first version of this document was a review only. The owner then asked for everything to be fixed except two items, so the section "What was done" below records, finding by finding, what was fixed on the branch `app-status-fixes`, what was left, and why. The findings further down are kept as they were written, with corrections marked.

## What was done

Asked by the owner on 2026-11-17: fix everything, except

- **Password-reset emails in production** (Production 1): the app is not in production yet, so this stays as it is.
- **Reordering exercises on a workout day** (Product gaps): already planned as a feature. It is in `doc/Features/Features.md` under "Exercise page".

`doc/Features/Features.md` and `doc/Issues/Issues.md` were read first. Besides the reorder feature, the only finding they already mention is the muscle group typed when editing an exercise (Technical 2), which was the one open issue. The other three product gaps (a workout for a past day, export, a workout outside the split on a planned day) are in neither file.

### Result of the checks after the fixes

| Check | Before | After |
|---|---|---|
| `bin/rails test` | 62 runs, 732 assertions, 0 failures, about 60 s | 74 runs, 0 failures, 10 to 30 s |
| `bundle exec rubocop` | no offenses | no offenses |
| `bundle exec brakeman` | not installed | 0 warnings |
| `bundle exec bundler-audit check --update` | not installed | found msgpack 1.8.0 and ruby-lsp 0.26.2 vulnerable; both updated; now "No vulnerabilities found" |
| Real browser at phone width | not done | Done in Chrome, signed in as the seed admin, in a 390 px wide frame (see "Browser check" below) |

### The upgrade trial (Rails, Devise, Puma)

The owner asked to check first whether the upgrade breaks the app, and to leave it and note it here if it does. It does not break:

1. `Gemfile` changed from `rails ~> 7.1.6` to `rails ~> 8.1.0`, then `bundle update rails devise puma`.
2. Result: Rails 7.1.6 to 8.1.4.1, Devise 4.9.4 to 5.0.4, Puma 7.1.0 to 8.1.2 (Rack 3.2.8, responders 3.2.1).
3. The whole suite passed unchanged on the new versions (62 runs, 0 failures), with no deprecation warnings in `log/test.log`.
4. The first run after the change took 382 seconds, because every parallel test process recompiled the stylesheet and rebuilt its caches at once. The second run took 40 seconds. It was a one-off, not a regression.
5. The upgrade was kept. At first `config.load_defaults` stayed at `7.1`; in the second round (below) it moved to `8.1`.
6. The Ruby version stays 3.3.5, which Rails 8.1 supports. Ruby itself was not upgraded: the new version is Rails.

### Security

| # | Finding | Status | What was done |
|---|---|---|---|
| 1 | Rails 7.1 out of support | Fixed | Rails 8.1.4.1, Devise 5.0.4, Puma 8.1.2 (see the trial above) |
| 2 | The last admin can delete their own account | Fixed | `User#last_admin?`; a `before_destroy` on `User` refuses the deletion; `Users::RegistrationsController#destroy` (new, wired in `config/routes.rb`) redirects back with a message instead of signing the admin out; the account page shows an explanation instead of the button. Tests in `user_test.rb` and `accounts_flow_test.rb` |
| 3 | No brute-force protection | Fixed | Devise `:lockable`: 10 wrong passwords lock the account for 15 minutes, unlocked by time only (the app sends no email). Migration `20261117130000_add_lockable_to_users` adds `failed_attempts` and `locked_at`. Minimum password length raised from 6 to 8; existing passwords keep working, the rule applies when a password is set |
| 4 | Sign-up is open to anyone | **Left: owner's decision** | Closing sign-up or requiring email confirmation changes who can use the app, and confirmation needs working email. Nothing was changed |
| 5 | Password reset reveals which emails exist | Fixed | `config.paranoid = true`; a test checks both answers are the same |
| 6 | No Content Security Policy | Fixed, checked in Chrome | `config/initializers/content_security_policy.rb`: own files only, plus the two Google Fonts hosts, `data:` images for Bootstrap's icons, a nonce for the import map and for Turbo's progress bar style, no framing by other sites, forms post to the app only. A test checks the header |
| 7 | No scanning, no CI | Fixed | `brakeman` and `bundler-audit` added to the Gemfile; `.github/workflows/ci.yml` runs tests, rubocop and both scanners on every push and pull request. The workflow has not run yet: it runs for the first time when the branch is pushed |
| 8 | `ruby-lsp` ships to production | Fixed | Moved to the `development` group, and updated to 0.26.11 (0.26.2 has a critical advisory) |
| 9 | No length limits | Fixed | Exercise and lift names 80, split name 60, machine brand 60, set note 200, exercise note 500, workout note 2000. A test covers a few |
| 10 | simple_form from GitHub | Fixed | `gem "simple_form", "~> 5.4"` from rubygems (5.4.1) |

### Production

| # | Finding | Status | What was done |
|---|---|---|---|
| 1 | Password-reset emails | Left, as the owner said | Not in production yet |
| 2 | Docker image has no JavaScript runtime | Fixed, **not built** | `nodejs` added to both stages of the `Dockerfile`. The image was not built to confirm |
| 3 | sassc-rails unmaintained | Fixed | Replaced by `dartsass-sprockets`. The compiled stylesheet has the same 5,277 selectors; only quoting and the order of a few grouped selectors differ. `config/initializers/sass.rb` silences the deprecation warnings that come from Bootstrap and Font Awesome. **Correction:** this review said the swap would also remove the `json < 3` pin. It does not: the pin is there for `execjs`, which `autoprefixer-rails` still uses. The pin stays |
| 4 | No production database or deploy setup | Left | Same reason as Production 1: not in production yet |

### Technical

| # | Finding | Status | What was done |
|---|---|---|---|
| 1 | "Once only" rules without an index | Fixed | Migration `20261117140000_add_unique_indexes_and_require_weekday`: unique indexes on `workout_logs (user_id, workout, date)`, `workout_exercises (workout_day_id, exercise_id)`, `workout_log_exercises (workout_log_id, exercise_id)`, and on exercise names (catalogue, and per user, ignoring capitals). `ApplicationController` rescues `ActiveRecord::RecordNotUnique` and sends the user back with "That was already saved, so nothing was added twice", which also covers two sets getting the same number. The test that edited a doubled row now checks the database refuses the double |
| 2 | Muscle group typed on the exercise form | Fixed | The form uses a select from `Exercise::MUSCLE_GROUPS` with "Other" for empty; the model validates it. Moved to "Issues resolved" in `doc/Issues/Issues.md` |
| 3 | Two unused queries on the dashboard | Fixed, counts kept | `doc/Prompt/home-page-overview-context.md` records that the owner wants `logs_count` and `sets_count` kept for later. They are now `Dashboard#logs_count` and `#sets_count`, which only query when a page asks, so they are kept and cost nothing today |
| 4 | A query per exercise on two pages | Fixed | `WorkoutExercise#entry_in` reads the log's loaded exercises; `WorkoutDaysController#show` loads today's log once with its exercises and sets |
| 5 | Add-set form differs | Fixed | One partial, `workout_sets/_form`, with `min`, `step` and `inputmode` on both pages. A test checks both pages |
| 6 | `set_number` accepted | Fixed | Removed from the permitted parameters; the test now checks a sent number is ignored |
| 7 | Typed exercise saved when the add fails | Fixed | `ExercisePicker#picked_exercises` returns the new exercise unsaved; it is saved with the row it is added to, inside the caller's transaction |
| 8 | Lost error message | Fixed | `WorkoutLogsController#new` keeps the flash before its redirect |
| 9 | Deprecated status name | Fixed | `:unprocessable_content` everywhere (controllers, Devise config, tests) |
| 10 | Slow test suite | Explained | The time is the stylesheet being compiled by each parallel test process when its cache is cold. Warm runs take 10 to 30 seconds |
| 11 | No system tests | **Left** | System tests need Chrome and chromedriver on the machine, and neither is installed. The unused `capybara` and `selenium-webdriver` gems and `test/application_system_test_case.rb` were removed rather than kept unused. The JavaScript is still untested |
| 12 | Private twin of a catalogue exercise | **Not an issue: withdrawn** | An existing test (`workout_recording_test.rb`, "an exercise name is unique in the catalogue and among a user's own") creates a user's own "Bench press" beside the catalogue's on purpose, and `CLAUDE.md` states the rule the same way. A validation against it was written and then removed |

### Dead or leftover code

All removed, except where noted:

- `components/_avatar.scss`, `components/_form_legend_clear.scss`, `pages/_home.scss`.
- Found while splitting the stylesheet and also removed: `.stat-tile`, `.stat-value`, `.stat-label` (the totals boxes that are gone) and `.plain-list`.
- The five empty model test stubs, the channel test, `test/application_system_test_case.rb`, `fixtures :all`.
- Gems `jbuilder`, `capybara`, `selenium-webdriver`, `dotenv-rails` (no `.env` file exists in the main folder either).
- `require "rails/all"` replaced by the six parts the app uses; `app/channels`, `config/cable.yml`, `config/storage.yml` and the Active Storage lines of the three environment files removed. `app/jobs/application_job.rb` stays: Action Mailer loads Active Job.
- Workout days without a weekday: `workout_days.weekday` is now `NOT NULL`; the "Not on a weekday yet" card, `weekday || 7`, the `if weekday` guards and the `where.not(weekday: nil)` in the mock task are gone.
- The stale comment in `reveal_controller.js`; `lib/templates/erb/scaffold/_form.html.erb`.

### Duplicated code

| Repeated | Status | Now |
|---|---|---|
| Ownership joins (7 places) | Fixed | `has_many :workout_exercises`, `:workout_log_exercises`, `:workout_sets` through, on `User`; controllers call `current_user.workout_sets.find(id)` |
| "This user's session of this workout on this date" | Fixed in 4 of 6 places | `WorkoutLog.session_of(workout, date)`, used by `WorkoutDay#log_on`, `Dashboard`, `WorkoutLogsController` and `WorkoutDaysController`. The `WorkoutLog` validation and the mock task ask a different question ("does another one exist") and stay |
| Rest day check | Fixed | `Split#rest_day?(date)` |
| `@picker_exercises` in 3 actions | Fixed | `picker_exercises` helper method in `ExercisePicker` |
| `errors.full_messages.to_sentence` | Fixed | `errors_of(record)` in `ApplicationController` |
| Two admin checks | Fixed | `require_admin!(back:, message:)` |
| `params[:from] == "dashboard"` | Fixed | `from_dashboard?`, a helper method |
| `includes(workout_log_exercises: :workout_sets)` | Fixed | `WorkoutLog.with_sets` scope |
| `set_split` in two controllers | Left | Two lines each; sharing them would cost more than it saves |
| Add-set form, set table | Fixed | `workout_sets/_form`, `workout_sets/_table` |
| Link to a day's workout or its list | Fixed | `day_logs_path(logs, date)` helper |
| `weight × reps` line | Fixed | `weight_and_reps(set)` helper |
| "No splits yet" empty state | Fixed | `splits/_empty` |
| "Add exercise" button (4 places) | Fixed | `exercise_picker_button(css)` helper |
| `_lifts` and the pills of `_recent_workout` | Left | They share the `weight_and_reps` line now; the markup around it is different on purpose |

### Structure

| # | Finding | Status | What was done |
|---|---|---|---|
| 1 | One 708-line stylesheet | Fixed | Split along its own section comments into 9 files in `components/` and 10 in `pages/`, imported in the original order from `application.scss`. Checked by compiling before and after: the only difference in the output was the removed unused rules |
| 2 | Heavy dashboard action | Fixed | `Dashboard` (`app/models/dashboard.rb`), tested by `test/models/dashboard_test.rb`. `PagesController#home` is one line; the view reads from the object |
| 3 | Two form styles | **Left** | Rewriting the three simple_form forms and the Devise pages by hand changes how every form and its error messages look, which needs to be seen in a browser. simple_form now comes from rubygems |
| 4 | A method on the wrong model | Fixed | `WorkoutDay#log_on(date)`; `WorkoutExercise#log_on` is gone |
| 5 | One very large test file | Fixed | Seven files in `test/integration/`, by area (accounts, splits, dashboard, week moves, logging, exercises, navigation), on a shared `FlowTest` setup in `test/test_helper.rb`. The 27 tests were moved unchanged, then 9 were added |
| 6 | Docs | Fixed | `doc/claude-universal-back-button-4813cc.md` is now `doc/universal-back-button.md`; the two screenshots have names without spaces; `Issues.md` and `Features.md` link to them by a relative path |

### Product gaps

Not touched. The reorder is planned (owner). The other three are new features, the project rule is not to add features beyond what is asked, and they are not in `Features.md`.

### Things to know before merging

- **The development database is shared with `master`.** Both migrations were run on it. They only add two columns, add indexes and make `workout_days.weekday` required, so `master` keeps working on it.
- **The branch was renamed** from `claude/app-status-code-review-2a3766` to `app-status-fixes`, to follow the naming rule. The worktree folder kept its old name.
- **Nothing is committed or pushed.**
- **One layout wart seen in the browser**, there before this branch and fixed in the second round: on the dashboard, a recent workout that has both the "Rest day" chip and the split chip left so little room that its date wrapped over four lines.

### Browser check

Done on 2026-11-17 in Chrome against the worktree server on port 3010. The Chrome window would not resize, so each page was loaded in a 390 px wide frame on the app's own page, which gives the phone layout. For that the policy says `frame-ancestors 'self'` (the app may frame itself; other sites still cannot) instead of `'none'`.

- **Pages opened:** dashboard, Splits, both splits, a workout day, an exercise page, History, a logged workout, Exercises, edit and new exercise, Users, Account settings, new split, log in, landing page.
- **Layout:** no page is wider than the screen.
- **Content security policy:** no violation was reported on any page, also after three Turbo visits in a row. Turbo, Stimulus and Bootstrap load, and the fonts (Inter, Plus Jakarta Sans, Font Awesome) load.
- **JavaScript that works:** the navbar toggler and the user menu; editing a set in place and cancelling; the machine brand field appearing for "Machine"; the "Add exercises" modal; "Show days", the rest day panel, a recent workout opening, and the "Move a workout" modal on the dashboard; the time zone cookie.
- **Changed pages:** the add-set form is the same on the exercise page and the logged workout page (weight has `min 0` and the decimal keyboard); the exercise form has the muscle group dropdown with the saved group selected; the account page of the only admin shows the explanation instead of "Cancel my account".
- **Not done:** nothing was submitted, so no data was changed. Saving a set, moving a workout and the lock after ten wrong passwords are covered by the tests only.

## Summary

The app is in good shape for daily use. All 62 tests pass (732 assertions, 0 failures), rubocop reports no offenses in 34 files, and no way was found for one user to read or change another user's data. The real problems are in production readiness and account security, plus some dead code and repeated code.

The five items to act on first:

1. Rails 7.1 no longer gets security fixes (Security 1).
2. The last admin can delete their own account (Security 2).
3. Login has no brute-force protection (Security 3).
4. Password-reset emails cannot work in production (Production 1).
5. The "once only" rules have no database index behind them (Technical 1).

## Second round (same day)

The owner asked for five more things.

### 1. The recent workout row

`pages/_recent_workout.html.erb` wraps the chips in a `.recent-chips` span, and `.recent-toggle` in `pages/_dashboard_recent.scss` is now a grid. On a phone the chips are on a row of their own under the summary, so the date stays on one line; from Bootstrap's `sm` breakpoint up they are beside the summary, before the chevron, as before. Seen in Chrome at 390 px and at desktop width.

### 2. Why `rails s` stopped working

In the worktree, `bin/rails server` answered "A server is already running (pid ..., file tmp/pids/server.pid)" and exited. The server left running for the owner on port 3010 had written that pid file, and Rails refuses to start a second server while it exists. That server is now stopped and the pid file removed. A server started from the main folder was tried too and works (Rails 7.1 there, pages answer 200).

### 3. Gems and app on the new version

The new version is **Rails** (7.1.6 to 8.1.4.1). **Ruby is still 3.3.5.**

- `bundle update` brought every gem to its newest version: among others bootstrap 5.3.8, pg 1.7.0, turbo-rails 2.0.23, importmap-rails 2.2.3, simple_form 5.4.1, sprockets 4.4.1, execjs 2.10.2, autoprefixer-rails 10.6.1.0.
- The `json < 3` pin is gone. It was there because json 3 broke execjs; with execjs 2.10.2, json 3.1.0 works. Checked by building the assets in production mode from an empty cache and by the tests.
- `bundle outdated` now lists only `marcel` and `prism`, which other gems hold at their current major version.
- `bin/rails zeitwerk:check`: all good. The app boots and eager-loads in production mode. `assets:precompile` builds with no warning.
- No deprecation warning in `log/test.log` after a full run.
- brakeman: 0 warnings. bundler-audit: no vulnerabilities.

### 4. Code moved to the newer ways of writing it

| Change | Where | Why |
|---|---|---|
| `config.load_defaults 8.1` | `config/application.rb` | The app now uses Rails 8.1's own behaviour defaults, not 7.1's |
| `params.expect(split: [:name])` for `params.require(:split).permit(:name)` | all 8 places in the controllers and `ExercisePicker` | Rails 8. A request with the wrong shape of parameters gets a 400 answer, not an error page |
| `normalizes :name, with: ...` for a `before_validation` block | `Exercise` (name, muscle group), `WorkoutSet` (notes), `WorkoutLogExercise` (notes) | Rails 7.1+. The value is tidied when it is assigned, and also when it is looked up |
| Hash shorthand, `where(date:)` for `where(date: date)` | 23 places in `app/` and `lib/`, by rubocop | Ruby 3.1+. `.rubocop.yml` now enforces it (`Style/HashSyntax`, `EnforcedShorthandSyntax: always`) |

`Lift#normalize_lift` stays a `before_validation`: the name there comes from the linked exercise, which `normalizes` cannot express. Not done, because they are new behaviour and not a way of writing the same thing: Rails 8's `rate_limit` and `allow_browser`.

### 5. A second look for anything missing

A search of the code for everything the review said to remove or share. Three small leftovers were found and fixed: the error sentence written out in `workout_log_exercises/edit.html.erb` (now `errors_of`, which is a helper for views too), commented-out Action Cable settings in two environment files, and commented-out gems for parts the app no longer loads in the `Gemfile`. Nothing else was missing. The items left on purpose are unchanged: open sign-up, system tests, the two form styles, the production setup and the product gaps.

### Checks at the end of the second round

- `bin/rails test`: 74 runs, 1024 assertions, 0 failures.
- rubocop: no offenses. brakeman: 0 warnings. bundler-audit: no vulnerabilities.
- Chrome, 390 px frame, on the 8.1 defaults: dashboard, Splits, a split, a workout day, an exercise page, History, a logged workout, Exercises, edit exercise, Users and Account settings. No page wider than the screen, scripts load on every page, no policy violation.

## How it was checked

| Check | Result |
|---|---|
| `bin/rails test` | 62 runs, 732 assertions, 0 failures, 0 errors, 0 skips, about 60 seconds |
| `bundle exec rubocop` | 34 files, no offenses |
| `bundle outdated --only-explicit` | 17 gems behind, three by a major version (rails, devise, puma) |
| Reading | Every model, controller, concern, helper, view, JavaScript file, the routes, the schema, the seeds, the mock task, the Dockerfile and the config files |
| Development database | No workout day without a weekday, no doubled plan rows, no doubled log entries, no doubled logs, no muscle group outside the fixed list |

Not checked:

- The pages were not opened in a browser, so layout and JavaScript behaviour were not looked at.
- The Docker image was not built, so Production 2 is a reading of the Dockerfile, not a confirmed failure.
- Brakeman and bundler-audit are not installed, so no automated security scan was run.
- The reason the test suite takes 60 seconds was not investigated.

## What is sound

- **Ownership.** Every controller finds its records through `current_user` (`current_user.splits.find`, `current_user.workout_logs.find`, or a join on the owning user). Exercise ids from the picker go through `Exercise.visible_to(current_user)`.
- **Admin actions.** `Admin::UsersController` runs `require_admin!` before everything. Only an admin reaches the catalogue form, and `shared_exercise_requested?` checks `current_user.admin?` on the server, not only in the view.
- **Strong parameters.** Each controller permits a short list. `exercise_id`, `user_id` and `admin` are never permitted from a form.
- **Output.** Views use `<%= %>` throughout, with no `raw` or `html_safe` on user text.
- **Redirects.** `redirect_back` is used once and Rails 7.1 defaults refuse another host.
- **Production basics.** `force_ssl` is on, `master.key` and `.env*` are git-ignored, the seed refuses to run in production without `ADMIN_PASSWORD`.
- **Structure.** Models hold the rules, controllers are short (the longest is 97 lines), concerns hold what is truly shared, and comments explain reasons.

## Security

### 1. Rails 7.1 no longer gets security fixes

`Gemfile` pins `rails ~> 7.1.6`. Security support for 7.1 ended in October 2025, and the current release is 8.1. Any vulnerability found in Rails since then is not patched in the version the app runs. Devise (4.9.4, latest 5.0.4) and Puma (7.1.0, latest 8.1.2) are also a major version behind.

What to do: upgrade Rails one minor version at a time (7.2, then 8.0, then 8.1), running the tests at each step.

### 2. The last admin can delete their own account

`Admin::UsersController#set_user` blocks an admin from changing or deleting their own account on the users page, and its comment says this keeps one admin. But the Devise account page still has "Cancel my account" (`app/views/devise/registrations/edit.html.erb:33`), which deletes the signed-in user with no check. If the only admin uses it, nobody can manage the catalogue or the users, and the only fix is the Rails console or the seed.

What to do: refuse the deletion when the user is the last admin (a `before_destroy` on `User`), or hide the button for admins.

### 3. Login has no brute-force protection

`User` uses `:database_authenticatable, :registerable, :recoverable, :rememberable, :validatable`. `:lockable` is off, there is no rate limiting (no rack-attack), and `config.password_length` is `6..128`. Anyone can try passwords against an email without limit.

What to do: turn on `:lockable`, or add rack-attack on the sign-in and password-reset paths, and raise the minimum password length.

### 4. Sign-up is open to anyone

`:registerable` is on and `:confirmable` is off. Anyone who reaches the site can create an account with any email, real or not. For a personal tracker this may not be wanted.

What to do: decide whether sign-up should stay open. If not, remove `:registerable`'s sign-up routes and let the admin create accounts, or add confirmation.

### 5. Password reset reveals which emails have accounts

`config.paranoid` is not set in `config/initializers/devise.rb`. The reset page answers differently for an email that exists and one that does not.

What to do: set `config.paranoid = true`.

### 6. No Content Security Policy

`config/initializers/content_security_policy.rb` is entirely commented out, so the browser gets no policy. The layout already calls `csp_meta_tag`, so the app is ready for one. The stylesheet loads Google Fonts (`config/_fonts.scss`), which the policy would have to allow.

### 7. No security scanning and no CI

Brakeman and bundler-audit are not in the Gemfile, and there is no `.github` folder. Tests and rubocop only run when someone runs them by hand.

What to do: add a workflow that runs `bin/rails test`, `bundle exec rubocop`, `brakeman` and `bundler-audit` on every push.

### 8. An editor tool ships to production

`gem "ruby-lsp", "~> 0.26.2"` is at the bottom of the `Gemfile`, outside any group, so it is installed in production. It belongs in the `development` group.

### 9. No length limits on text

Exercise names, split names, machine brand, set notes, exercise notes and workout notes have no `length` validation. The note field in `workout_sets/_set` has `maxlength: 200` in the HTML only, which the server does not enforce.

### 10. simple_form comes from GitHub

`gem "simple_form", github: "heartcombo/simple_form"` follows the repository's main branch instead of a released version. `Gemfile.lock` pins the commit, so installs are repeatable, but `bundle update` takes whatever is on the branch.

## Production gaps

### 1. Password-reset emails cannot work in production

`config/environments/production.rb` has `config.action_mailer.default_url_options = { host: "http://TODO_PUT_YOUR_DOMAIN_HERE" }` and no delivery method or SMTP settings. A reset email would not be sent, and its link would point at the placeholder.

### 2. The Docker image very likely fails

`autoprefixer-rails` depends on `execjs`, which needs a JavaScript runtime (Node) when it loads. The `Dockerfile` installs `build-essential git libpq-dev libvips pkg-config` in the build stage and `curl libvips postgresql-client` in the final stage, with no Node. `assets:precompile` in the build stage should fail with "Could not find a JavaScript runtime". Not confirmed by a build.

### 3. sassc-rails is unmaintained

`sassc-rails` wraps LibSass, which is end-of-life. **Correction:** the `json < 3` pin is there for `execjs`, which `autoprefixer-rails` uses, not for `sassc-rails`. Moving to `dartsass-sprockets` removes `sassc-rails` and keeps the pin.

### 4. No production database or deploy setup

`config/database.yml` production uses a local socket with user `fitness_app`. There is no `DATABASE_URL` note, no deploy config and no backup of the data.

## Technical issues

### 1. The "once only" rules have no database index behind them

These rules are checked in Ruby only:

| Rule | Where it is checked | Database |
|---|---|---|
| One logged workout per workout per day | `WorkoutLog#only_session_of_workout_that_day` | Index on `(user_id, workout, date)` is not unique |
| An exercise is on a workout day once | `WorkoutExercise#not_already_on_day` | No index on `(workout_day_id, exercise_id)` |
| An exercise is in a logged workout once | `WorkoutLogExercise#not_already_in_log` | No index on `(workout_log_id, exercise_id)` |
| An exercise name is unique in its list | `Exercise` uniqueness validation | No unique index |

Two requests at the same moment (a double tap on "Add set" on a slow connection) can both pass the check and both save. The development database has no duplicates today, so unique indexes can be added. The Legs and Lower equivalence cannot be put in a plain index and would stay a Ruby rule.

A related case: `WorkoutSet#number_set` takes the highest set number plus one. Two simultaneous sets get the same number, and the unique index on `(workout_log_exercise_id, set_number)` then raises `RecordNotUnique`, which is not rescued and shows an error page.

### 2. The open issue is still open

`doc/Issues/Issues.md` lists "Exercise name edit": the muscle group can be typed. `app/views/exercises/_form.html.erb:7` is still `f.input :muscle_group, placeholder: "Chest"`. The picker modal already uses a select from `Exercise::MUSCLE_GROUPS`. The model has no inclusion validation on `muscle_group` either, so the fix needs both the select and the validation.

### 3. Two unused queries on every dashboard load

`app/controllers/pages_controller.rb:41-43` sets `@logs_count` and `@sets_count`. Neither is used in any view. The second is a count over a three-table join.

### 4. A query per exercise on two pages

- `WorkoutDaysController#show` (line 9) calls `planned.entry_in(log)` and then `.workout_sets.count` for each exercise of the day: about two queries per exercise.
- `WorkoutLogsController#show` (line 30) calls `planned.entry_in(@workout_log)` for each planned exercise: one query each.

At the size of one person's workout this is not slow, but both can be answered from records already loaded.

### 5. The add-set form differs between the two pages

`app/views/workout_exercises/show.html.erb:34-39` gives the weight field `min: 0` and `inputmode: "decimal"`, and the reps field `inputmode: "numeric"`. The same form in `app/views/workout_logs/show.html.erb:58-63` has none of these, so a negative weight is only stopped by the server, and the phone keyboard may differ.

### 6. set_number is accepted from the form

`WorkoutSetsController#workout_set_params` permits `:set_number`, but no form sends it; the model numbers a new set itself. Removing it from the list makes the code say what the app does.

### 7. A typed exercise is saved even when the add fails

`ExercisePicker#picked_exercises` saves the new exercise before the controller's transaction starts. If adding it to the day or the workout then fails, the exercise stays in the user's list.

### 8. A lost error message

`WorkoutLogsController#create` redirects to `new` with an alert when saving fails. `new` redirects again when today's workout exists, and the alert does not survive the second redirect. This only happens from a stale page.

### 9. Deprecated status name

`:unprocessable_entity` appears in 8 places (controllers and `config/initializers/devise.rb`). The current Rack prints a deprecation warning for each use and asks for `:unprocessable_content`.

### 10. The test suite is slow

62 tests take about 60 seconds, one per second. Not investigated. A likely cause is the stylesheet being compiled in each parallel test process, but that is a guess.

### 11. No system tests

`test/application_system_test_case.rb` exists but there is no `test/system` content. The JavaScript is untested: editing a set in place (`row_edit_controller.js`), the machine brand field (`reveal_controller.js`) and the time zone cookie (`time_zone.js`).

### 12. A private twin of a catalogue exercise (withdrawn)

**Correction:** this is intended behaviour, covered by an existing test. See "What was done".

The name is unique per list (`scope: :user_id`), so an admin using the "New exercise" page can create a private "Bench press" beside the catalogue's. The picker avoids this through `find_or_build_exercise`; `ExercisesController#create` does not.

## Dead or leftover code

| What | Where | Note |
|---|---|---|
| Unused styles | `components/_avatar.scss`, `components/_form_legend_clear.scss` | No view uses `.avatar*`; no form has a `legend` |
| Empty stylesheet | `pages/_home.scss` | One comment line |
| Empty test stubs | `test/models/exercise_test.rb`, `split_test.rb`, `workout_exercise_test.rb`, `workout_log_exercise_test.rb`, `workout_set_test.rb` | 7 lines each, only the commented example |
| Unused test files | `test/channels/application_cable/connection_test.rb`, `test/application_system_test_case.rb` | Nothing uses channels or system tests |
| Unused gems | `jbuilder`, `capybara`, `selenium-webdriver`, `dotenv-rails` | No `.jbuilder` view, no system test, no `.env` file |
| Unused Rails parts | `require "rails/all"` in `config/application.rb`, `app/channels`, `app/jobs`, `config/cable.yml`, `config/storage.yml` | Action Cable, Active Storage, Action Mailbox, Action Text and Active Job are loaded and not used |
| Legacy branches for a workout day without a weekday | "Not on a weekday yet" card in `splits/show.html.erb:26-39`, `d.weekday \|\| 7` in `splits/index.html.erb:30`, `if weekday` in `WorkoutDay#weekday_name` and `Split#week_plan`, `where.not(weekday: nil)` in `mock.rake` | No such row exists; the column can become `NOT NULL` and these go |
| Stale comment | `app/javascript/controllers/reveal_controller.js:4` | Mentions "Type my own", which no longer exists |
| Generator template | `lib/templates/erb/scaffold/_form.html.erb` | Only used by `rails generate scaffold` |
| Unused fixtures line | `fixtures :all` in `test/test_helper.rb` | `test/fixtures` holds no fixtures |

## Duplicated code that can be shared

### Controllers and models

| Repeated | Where | Shorter form |
|---|---|---|
| `WorkoutExercise.joins(workout_day: :split).where(splits: { user_id: current_user.id })` | `workout_exercises_controller.rb:56`, `workout_sets_controller.rb:10` and `:64` | `has_many :workout_exercises, through: :workout_days` on `User`, then `current_user.workout_exercises.find(id)` |
| `WorkoutLogExercise.joins(:workout_log).where(workout_logs: { user_id: current_user.id })` | `workout_log_exercises_controller.rb:47`, `workout_sets_controller.rb:16` | `has_many :workout_log_exercises, through: :workout_logs` on `User` |
| `WorkoutSet.joins(workout_log_exercise: :workout_log).where(workout_logs: { user_id: … })` | `workout_sets_controller.rb:56`, `pages_controller.rb:42` | `has_many :workout_sets, through: :workout_log_exercises` on `User` |
| "This user's session of this workout on this date" (`workout_logs.of_workout(name).where(date: date).order(:id).first`) | `WorkoutExercise#log_on`, `PagesController#home` through `session_of`, `WorkoutLogsController#set_workout`, `WorkoutLog#only_session_of_workout_that_day`, `mock.rake` | One method, for example `User#session_of(workout, date)` |
| Rest day check `!split.week_plan(date).key?(date.wday)` | `WorkoutLog#mark_rest_day`, `WorkoutLogsController#rest_day_today?` | `Split#rest_day?(date)` |
| `@picker_exercises = Exercise.visible_to(current_user).order(:name)` | `WorkoutDaysController#show`, `WorkoutLogsController#show` and `#new` | A method in the `ExercisePicker` concern |
| `errors.full_messages.to_sentence` | 10 places; `ExercisesController` has an `errors_for` helper used once | One helper in `ApplicationController` |
| `require_catalogue_admin!` and `require_admin!` | `ExercisesController`, `ApplicationController` | One method taking the redirect path and message |
| `params[:from] == "dashboard"` | 19 lines: `SplitsController`, `WorkoutLogsController`, `workout_logs/index`, `workout_logs/show`, `splits/index`, and the links that add `from: "dashboard"` | One helper, for example `from_dashboard?` |
| `set_split` | `WorkoutDaysController`, `WeekMovesController` (same body) | Acceptable as it is; noted for completeness |

### Views

| Repeated | Where | Shorter form |
|---|---|---|
| Add-set form (weight, reps, button) | `workout_exercises/show.html.erb:31-44`, `workout_logs/show.html.erb:55-68` | `workout_sets/_form` partial; also fixes Technical 5 |
| Set table header and rows | `workout_exercises/show.html.erb:24-27`, `workout_logs/show.html.erb:48-51` | `workout_sets/_table` partial |
| Link to a day's workout, or its History list when there are several | `pages/_calendar.html.erb:22`, `pages/_week_overview.html.erb:31` | One helper |
| `format_weight(weight) × pluralize(reps, "rep")` | `pages/_lifts.html.erb:8`, `pages/_recent_workout.html.erb:36` and `:43` | One helper, for example `set_line(set)` |
| "No splits yet" empty state | `pages/home.html.erb:42-46`, `splits/index.html.erb:13-17` | One partial |
| "Add exercise" button that opens the picker | `workout_days/show.html.erb` (twice), `workout_logs/show.html.erb`, `workout_logs/new.html.erb` | One partial or helper |
| List of lifts with their top set | `pages/_lifts` and the pills in `pages/_recent_workout` | They overlap; could share the top-set line at least |

## Structure

Good overall. The weaker spots:

1. **One 708-line stylesheet.** `components/_app.scss` holds the styles of every page, in sections marked by comments (Layout, Cards, Tables, Dashboard calendar, Today box, Recent workouts and so on), while `pages/` holds one empty file. Splitting it along those comments would match the folders that already exist.
2. **A heavy dashboard action.** `PagesController#home` sets 17 instance variables, and `home.html.erb` is 168 lines with logic in the view (`today_lifts`, the `last_time` capture, the grouping for the rest day pop-ups). A plain Ruby dashboard object, in the style of `WorkoutSummary`, would hold this and be testable on its own.
3. **Two form styles.** `splits/_form`, `workout_days/_form` and `exercises/_form` use `simple_form`; every other form uses `form_with` with hand-written Bootstrap classes. `simple_form` costs two initializers (548 lines) and a GitHub-sourced gem for three small forms and the Devise pages.
4. **A method on the wrong model.** `WorkoutDaysController#show` finds the day's log with `@workout_exercises.first&.log_on(Date.current)`: it asks the first exercise for something that belongs to the workout day. A day with no exercises has no log by this route.
5. **One very large test file.** `test/integration/workout_flow_test.rb` is 1,271 lines and covers most behaviour. Splitting it by area (splits, logging, week moves, admin, exercises) would make a failing test easier to place.
6. **Docs.** `doc/claude-universal-back-button-4813cc.md` breaks the naming rule (no digits, no `claude` prefix). `doc/Issues/Issues.md` refers to a screenshot by a path on another machine (`/home/pedro/code/pqdesu/...`). The screenshots in `doc/Features/Pics` have spaces in their names.

## Product gaps

Observations only. The project rule is not to add features beyond what is asked, so none of these is a proposal.

- A workout can only be started for today. A past day means logging it today and changing the date under Details.
- Exercises on a workout day cannot be reordered; they show in the order they were added.
- There is no export or backup of the logged history.
- On a day that has a planned workout, the dashboard offers no way to start a workout outside the split; that panel only shows on a rest day.

## Outdated gems

From `bundle outdated --only-explicit` on 2026-11-17:

| Gem | Current | Latest |
|---|---|---|
| rails | 7.1.6 | 8.1.4.1 |
| devise | 4.9.4 | 5.0.4 |
| puma | 7.1.0 | 8.1.2 |
| json | 2.21.2 | 3.1.0 (pinned below 3 on purpose) |
| bootsnap | 1.18.6 | 1.26.1 |
| selenium-webdriver | 4.38.0 | 4.52.0 |
| autoprefixer-rails | 10.4.21.0 | 10.6.1.0 |
| bootstrap | 5.3.5 | 5.3.8 |
| pg | 1.6.2 | 1.7.0 |
| turbo-rails | 2.0.20 | 2.0.23 |
| importmap-rails | 2.2.2 | 2.2.3 |
| jbuilder | 2.14.1 | 2.15.1 |
| dotenv-rails | 3.1.8 | 3.2.0 |
| ruby-lsp | 0.26.2 | 0.26.11 |
| web-console | 4.2.1 | 4.3.0 |
| debug | 1.11.0 | 1.11.1 |
| simple_form | 5.4.0 (44384d3) | 5.4.1 (18f38aa) |
