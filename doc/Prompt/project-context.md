# Fitness app: full project context

Written 2026-11-16, from `master` at `466ce00` (after pull request 6, `split-page-fixes`).

This file is a handoff prompt. Paste it into a new Claude Code session, or ask Claude to read it, to continue the project on another machine or user with everything that was decided so far. Nothing in it depends on earlier conversations.

---

## 1. What you are picking up

You are continuing work on a personal workout tracker built with Ruby on Rails, in the repository `pqdesu/fitness_app`. The owner is its only developer and its first user. They describe the core use as:

> I go to the gym, log my workouts and what I did for the day, and then that's it.

The original brief, in the owner's words:

> Make a simple, UI friendly and easy to use Fitness app that helps you keep track of your workouts.
> The app needs to be very intuitive, easy to use and user friendly.
> It will be a simple POST and GET request app. The user will record their exercises (of his choice by typing the name) and the amount of sets and weight used for the lift. It can also choose which brand of machine or if it is free weights.

Use the brief to judge every design choice: prefer the simplest, most obvious screen and flow, with few taps and little typing on a phone at the gym. Do not add features that were not asked for.

---

## 2. Product decisions already made

Do not reopen these unless the owner brings them up.

1. **Keep the planning layer.** Splits, workout days and planned exercises stay. The owner was offered a logging-only version and chose to keep the planning.
2. **Keep the shared exercise catalogue and the admin role.** Users can select an exercise from the catalogue, or create their own. Only an admin can add, edit or delete catalogue entries.
3. **A user-created exercise is saved as that user's own exercise.** Only they see it, and it appears in the picker next to the catalogue.
4. **Equipment is per lift.** Free weights, or a machine. For a machine the user types the brand name as free text.
5. **A split is shown as a week,** Sunday to Saturday, one circle per weekday with its initial letter, coloured when that weekday has a workout day and blank when it does not.
6. **A workout day lists only its exercises.** There are no target sets, reps or weights in the plan, and the day page does not show logged sessions.
7. **Sets are added by opening an exercise.** Each set has a weight and reps, shown in that order (weight first). "Add set" adds the next one. A recorded set can be corrected in place or deleted.
8. **Exercises are added through a modal** that shows the catalogue grouped by muscle group (Chest, Back, Shoulders, Biceps, Triceps, Legs, Calves, Core), including the user's own exercises, with the option to create a new one on the spot.
9. **A workout day's name comes from a fixed list:** Push, Pull, Legs, Lower, Upper, Anterior, Posterior, Full Body. Legs and Lower count as the same workout. This keeps a workout comparable over time, across splits.
10. **Logged workouts belong to the user, not to the split.** Deleting a split or a day keeps the history.
11. **One split is the active split.** The dashboard follows it. If the user has not chosen one, the oldest split is used.
12. **Every sub-page has one back button to its parent page,** not to the browser's previous page. Top-level pages (Dashboard, Splits, History, Exercises) have none.
13. **Splits have their own page.** The dashboard shows the month calendar, this week, today's workout from the active split, and last time's session of that workout with the heaviest set per exercise.

---

## 3. How the owner wants you to work

- **Branches, not worktrees.** Work in the main checkout on a normal branch. Do not create or suggest git worktrees: a worktree once left a hidden second copy of the repository and confused the owner. They usually create the branch themselves, so check the current branch first.
- **The owner tests before merging,** by running `rails s` from their main folder. Do not finalize a branch unprompted.
- **Finalizing uses the `finalize-branch` skill** (`.claude/skills/finalize-branch/SKILL.md`). When the owner says to finalize, finish or wrap up the branch: run the tests, write `doc/<branch>.md`, commit, push, open a pull request.
- **Never merge or pull for the owner.** Do not merge a pull request, enable auto-merge, or run `git pull` or `git merge`. Give the commands instead. In their words: "I will also do the git pull myself I want to be in control of what comes and goes."
- **Branch names** are two to five plain lowercase words joined by dashes, with no digits, dates or `claude/` prefix, for example `split-page-fixes`.
- **Change docs are very detailed.** The owner asked for "every step, decision, files changed, reason behind, how it is working now. Everything". The nine-section layout is in the skill.
- **Issues live in `doc/Issues/Issues.md`,** with screenshots in `doc/Issues/Pics/`. The owner writes issues there and asks for a section to be fixed. Move fixed issues under "Issues Resolved".
- **Prompt files live in `doc/Prompt/`.** `fitness-app-prompt.md` is an older prompt; where it differs from this file (for example it says a typed exercise name is not saved), this file is the current one.
- **Say plainly what was not verified.** Most UI work so far was checked by tests and HTTP requests, not by looking at it in a browser.

---

## 4. Stack and setup

- Ruby 3.3.5, Rails 7.1, PostgreSQL
- Devise for accounts
- Bootstrap 5.3 with SCSS (sassc-rails), Font Awesome, simple_form
- Hotwire: Turbo and Stimulus through importmap (no Node build)
- Minitest; one integration test file carries most of the coverage

Setting up a fresh clone:

```bash
git clone git@github.com:pqdesu/fitness_app.git
cd fitness_app
bin/setup
bin/rails db:seed
bin/rails server
```

PostgreSQL must be running locally; the databases are `fitness_app_development` and `fitness_app_test`. The seed creates an admin account for development (`admin@example.com` / `admin123456`, overridable with `ADMIN_EMAIL` and `ADMIN_PASSWORD`) and a starter catalogue of 14 exercises.

The development database does not travel with the repository. On a new machine the splits, days and logged workouts are gone: sign up or sign in as the admin, create a split, then run the mock task for last week's data.

```bash
bin/rails test
bin/rails mock:last_week                 # logs last week's sessions for every split
bin/rails mock:last_week EMAIL=me@x.com  # one user only
bin/rails mock:clear                     # deletes the workouts the mock task logged
```

`gh` must be signed in (`gh auth status`) for the finalize skill to open pull requests.

---

## 5. Data model

```
User (Devise; admin flag; active_split_id)
 ├─ Split (name)
 │    └─ WorkoutDay (day: one of the fixed workout names; weekday 0..6, unique per split)
 │         └─ WorkoutExercise (exercise_id, name, equipment, machine_brand)
 ├─ WorkoutLog (date, workout name, notes; workout_day_id optional)
 │    └─ WorkoutLogExercise (exercise_id, workout_exercise_id optional, name, equipment, machine_brand, notes)
 │         └─ WorkoutSet (set_number, reps_completed, weight_used, notes)
 └─ Exercise (name, muscle_group; user_id nil = shared catalogue, set = that user's own)
```

Rules worth knowing:

- `Lift` (`app/models/concerns/lift.rb`) is included by `WorkoutExercise` and `WorkoutLogExercise`. The linked exercise decides the name, and the name is also stored on the row so history survives the exercise being deleted. `machine_brand` is required when equipment is `machine` and cleared otherwise.
- Renaming an `Exercise` renames its planned and logged rows. An exercise that is part of someone's plan cannot be deleted.
- A `WorkoutLog` copies its user and workout name from the workout day when created. `WorkoutLog.of_workout("Lower")` finds Legs and Lower sessions from any split.
- A `WorkoutLogExercise` started from the plan copies the plan's exercise and equipment. `top_set` is the heaviest set, with reps as the tie-break.
- A `WorkoutSet` numbers itself as the next set. Reps can be zero (a failed attempt). Weight is optional (bodyweight).
- `User#current_split` is the active split, or the oldest split when none is chosen.

---

## 6. Pages and flows

Navbar: Dashboard, Splits, History, Exercises.

- **Dashboard (`/`, `pages#home`).** Signed out: landing page. Signed in: month calendar with this week's row and today marked, this week from the active split with today ringed, today's workout, "last time" (the most recent earlier session of the same workout, heaviest set per exercise), recent logs, and counts of splits, workouts logged and sets recorded.
- **Splits (`/splits`).** List of splits as week strips; the active one is ringed and badged. "Set as active" sends `PATCH /splits/:id/activate`.
- **Split page.** The week of circles. A coloured day opens its workout day; a blank day adds one (choose the workout from the fixed list and the weekday).
- **Workout day page.** Only the exercises of the day. "Add exercise" opens the catalogue modal. Adding one exercise opens that exercise's page; adding several returns to the day. Each row has a trash button, and shows "N sets" once sets were recorded today.
- **Exercise page (`workout_exercises#show`).** "Today" lists the sets as Set, Weight, Reps. Each row has a pen to edit in place (Stimulus `row_edit_controller.js`, Save, Cancel, Esc) and a trash to delete. The form below adds the next set, pre-filled from the last one. Adding the first set creates today's `WorkoutLog` for that day, dated in the user's time zone. Equipment for the lift is set here.
- **History (`/workout_logs`).** Logged workouts, newest first. A log page shows its exercises and sets, lets the user add exercises (planned or from the catalogue), edit the date and notes, and delete.
- **Exercises (`/exercises`).** The catalogue plus the user's own exercises. Admins manage the shared ones; users manage their own.

Conventions in the code:

- A sub-page view starts with `<% back_to "Label", some_path %>` (helper in `application_helper.rb`); the layout draws the button.
- `ExercisePicker` (`app/controllers/concerns/exercise_picker.rb`) reads what the "Add exercises" modal sends.
- Shared partials: `shared/_exercise_picker`, `shared/_equipment_fields`, `splits/_week`, `pages/_calendar`, `workout_sets/_set`.
- Styles for the app's own components are in `app/assets/stylesheets/components/_app.scss`.
- `ApplicationController` requires sign-in everywhere and runs each request in the browser's time zone, read from a cookie set by `app/javascript/time_zone.js`.
- Every lookup is scoped to the signed-in user's own records.

---

## 7. History of the work

Each merged branch has a detailed doc in `doc/`. Read the relevant one before changing that area.

| Order | Branch | What it did | Doc |
|---|---|---|---|
| 1 | `first-ui` | Code review fixes, the first UI, the admin user | `doc/first-ui-changes.md` |
| 2 | `catalogue-or-typed-exercises-and-equipment` | User-created exercises, equipment per lift, split planned as a week, plan reduced to exercises only | `doc/catalogue-or-typed-exercises-and-equipment.md` |
| 3 | `claude/universal-back-button-4813cc` | Back button on every sub-page | `doc/claude-universal-back-button-4813cc.md` |
| 4 | `dashboard-calendar-and-active-split` | Active split, new dashboard, logs that outlive splits, browser time zone | `doc/dashboard-calendar-and-active-split.md` |
| 5 | `split-page-fixes` | Program-only day page, quick remove, weight before reps, set editing, mock data task | `doc/split-page-fixes.md` |

State on 2026-11-16: `bin/rails test` on `master` passes with 39 runs, 390 assertions, 0 failures.

---

## 8. What is open

### Open issues (from `doc/Issues/Issues.md`)

**Calendar**

1. A day should only be highlighted if a workout was registered that day. Today the dashboard calendar marks every date whose weekday has a workout in the active split, whether or not anything was logged.
2. A highlighted day should be interactive: clicking it shows the workout and exercises recorded that day.

### Known gaps

- **No browser check.** Almost none of the UI has been looked at in a browser by Claude; layout, spacing and the in-place set editing are verified only by tests and HTTP requests. The owner checks by hand.
- The first page of a new browser session renders in UTC and reloads once to pick up the time zone. Without JavaScript or cookies the app stays in UTC.
- Today's log is found per workout day, so training the same workout from two splits on one date creates two logs. The mock data shows this (several "Upper" sessions on one day, one per split).
- `mock:clear` removes the mock workouts but leaves the planned exercises the mock task added to empty days. The mock task has no test.
- After editing or deleting a set, the redirect relies on the browser's referer.
- The same exercise can be added twice to a day's plan or to a logged workout.
- Equipment changed on a day's exercise does not update an entry already created for today.
- An admin cannot create a private exercise; what they create in the modal goes to the shared catalogue.
- Notes on a logged exercise and on a set exist in the database but have no input in the UI.
- No pagination on History or the catalogue; no admin screen for users (promotion is done in the console).
- `README.md` is out of date: it still mentions SQLite/MySQL, Vue.js, planned sets and reps, and a rest timer.
- Devise's mailer sender is still the placeholder address; Rubocop has a config file but is not in the Gemfile; `weight_used` is a bare `decimal` column.

---

## 9. Where to start

1. Read `CLAUDE.md`, then this file.
2. Check the current branch and `git status`.
3. Read `doc/Issues/Issues.md` for what the owner wants next. The Calendar section is the next piece of work unless they say otherwise.
4. Run `bin/rails test` before and after changes.
