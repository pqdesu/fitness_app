# Fitness app: full project context

Written 2026-11-16, from `master` at `466ce00` (after pull request 6, `split-page-fixes`). Updated the same day on the branch `known-gaps-fixes`, which fixes the "Known gaps" this file used to list; sections 2, 3, 5, 6 and 8 describe the app as it is on that branch.

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
14. **An admin is a normal user with extras.** The owner's words: "Admin can create catalogue exercises but it can also create private exercises. Only difference of the admin is to create catalogue exercises and other admin stuff like delete user, manage stuff etc". An exercise an admin creates is private unless they tick "Add to the shared catalogue" (ticked by default on the catalogue's own "New exercise" page, unticked in the modal).
15. **Weights keep three decimals,** for example 1.111 kg.
16. **One logged workout per workout per day.** Sets added from two splits on the same date go into the same log, and the same exercise into the same entry. (Decided while fixing the known gaps; the owner asked for the gap to be fixed, not for this exact rule.)
17. **An exercise is on a day once and in a logged workout once.** Typing the name of an exercise the user can already pick uses that exercise.

---

## 3. How the owner wants you to work

- **Work in a worktree.** On 2026-11-16 the owner asked for worktrees again ("Please work in a worktree like the other times"), replacing the earlier "branches, not worktrees" rule. Create it under `.claude/worktrees/<branch>` on a branch named for the work, and leave the main checkout alone. The earlier confusion came from a server in the main folder not showing the worktree's changes, so always say where the work can be seen.
- **The owner tests before merging.** Do not finalize a branch unprompted. A server started from the main folder shows the main folder's branch; run one from the worktree on another port, or give the command to check the branch out.
- **Look at UI changes in a browser.** The first real browser check (on `known-gaps-fixes`, headless Chromium at phone and desktop widths) found that the in-place set editing was unusable on a phone, which no test had shown.
- **Finalizing uses the `finalize-branch` skill** (`.claude/skills/finalize-branch/SKILL.md`). When the owner says to finalize, finish or wrap up the branch: run the tests, write `doc/<branch>.md`, commit, push, open a pull request.
- **Never merge or pull for the owner.** Do not merge a pull request, enable auto-merge, or run `git pull` or `git merge`. Give the commands instead. In their words: "I will also do the git pull myself I want to be in control of what comes and goes."
- **Branch names** are two to five plain lowercase words joined by dashes, with no digits, dates or `claude/` prefix, for example `split-page-fixes`.
- **Change docs are very detailed.** The owner asked for "every step, decision, files changed, reason behind, how it is working now. Everything". The nine-section layout is in the skill.
- **Issues live in `doc/Issues/Issues.md`,** with screenshots in `doc/Issues/Pics/`. The owner writes issues there and asks for a section to be fixed. Move fixed issues under "Issues Resolved".
- **Prompt files live in `doc/Prompt/`.** `fitness-app-prompt.md` is an older prompt; where it differs from this file (for example it says a typed exercise name is not saved), this file is the current one.
- **Say plainly what was not verified.** Before `known-gaps-fixes`, UI work was checked by tests and HTTP requests only.
- **No Ruby on the machine?** Run the tests in Docker: a `ruby:3.3.5` container with `libpq-dev` and `nodejs` installed, a `postgres` container, and `DATABASE_URL` pointing at it.

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
User (Devise; admin flag; active_split_id; time_zone)
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
- A `WorkoutSet` numbers itself as the next set. Reps can be zero (a failed attempt). Weight is optional (bodyweight) and is a `decimal(8, 3)`.
- `User#current_split` is the active split, or the oldest split when none is chosen.
- A user has one `WorkoutLog` per workout per date (Legs and Lower together). `WorkoutExercise#entry_on!(date)` finds or creates that log and the exercise's entry in it; every set added from an exercise page goes through it.
- A `WorkoutLogExercise` may link to a planned exercise of the log's own day, or of the same workout in another of the user's splits.
- An exercise is unique per workout day and per logged workout (checked when adding). An `Exercise` name is unique in the catalogue and among one user's own, ignoring case.

---

## 6. Pages and flows

Navbar: Dashboard, Splits, History, Exercises.

- **Dashboard (`/`, `pages#home`).** Signed out: landing page. Signed in: month calendar with this week's row and today marked, this week from the active split with today ringed, today's workout, "last time" (the most recent earlier session of the same workout, heaviest set per exercise), recent logs, and counts of splits, workouts logged and sets recorded.
- **Splits (`/splits`).** List of splits as week strips; the active one is ringed and badged. "Set as active" sends `PATCH /splits/:id/activate`.
- **Split page.** The week of circles. A coloured day opens its workout day; a blank day adds one (choose the workout from the fixed list and the weekday).
- **Workout day page.** Only the exercises of the day. "Add exercise" opens the catalogue modal. Adding one exercise opens that exercise's page; adding several returns to the day. Each row has a trash button, and shows "N sets" once sets were recorded today.
- **Exercise page (`workout_exercises#show`).** "Today" lists the sets as Set, Weight, Reps. Each row has a pen to edit in place (Stimulus `row_edit_controller.js`, Save, Cancel, Esc) and a trash to delete. Editing also shows a field for a note on the set, on a second row with Save and Cancel. The form below adds the next set, pre-filled from the last one. Adding the first set creates today's `WorkoutLog` for that workout, dated in the user's time zone. Equipment for the lift is set here, and today's entry follows a change.
- **History (`/workout_logs`).** Logged workouts, newest first, 20 per page. A log page shows its exercises and sets, lets the user add exercises (planned or from the catalogue), edit the date and notes, and delete. The pen on a logged exercise edits its equipment and a note.
- **Exercises (`/exercises`).** The catalogue plus the user's own exercises, 30 per page. Admins manage the shared ones; everyone manages their own.
- **Users (`/admin/users`, admin only, in the user menu).** Every account, with "Make admin" / "Remove admin" and "Delete". An admin's own row has no actions, so one admin always remains.

Conventions in the code:

- A sub-page view starts with `<% back_to "Label", some_path %>` (helper in `application_helper.rb`); the layout draws the button.
- `ExercisePicker` (`app/controllers/concerns/exercise_picker.rb`) reads what the "Add exercises" modal sends.
- Shared partials: `shared/_exercise_picker`, `shared/_equipment_fields`, `splits/_week`, `pages/_calendar`, `workout_sets/_set`.
- Styles for the app's own components are in `app/assets/stylesheets/components/_app.scss`.
- `Paginated` (`app/controllers/concerns/paginated.rb`) and `shared/_pagination` page the long lists.
- `ApplicationController` requires sign-in everywhere and runs each request in the browser's time zone, read from a cookie set by `app/javascript/time_zone.js`. The zone is also saved in `users.time_zone` and used when a browser has not reported one yet.
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
| 6 | `known-gaps-fixes` | One workout per day, no duplicate exercises, admin private exercises and users page, three-decimal weights, notes, pagination, saved time zone, Rubocop | `doc/known-gaps-fixes.md` |

State on 2026-11-16: `bin/rails test` on `master` passes with 39 runs, 390 assertions, 0 failures. On the branch `known-gaps-fixes` (doc: `doc/known-gaps-fixes.md`): 48 runs, 541 assertions, 0 failures, and `bundle exec rubocop` reports no offenses.

---

## 8. What is open

### Open issues (from `doc/Issues/Issues.md`)

**Calendar**

1. A day should only be highlighted if a workout was registered that day. Today the dashboard calendar marks every date whose weekday has a workout in the active split, whether or not anything was logged.
2. A highlighted day should be interactive: clicking it shows the workout and exercises recorded that day.

### Known gaps

The gaps this section listed until 2026-11-16 are fixed on the branch `known-gaps-fixes`. What is left:

- **Time zone, first visit ever.** The zone is now saved on the user, so a new session starts in it. Only a user's very first page still renders in UTC and reloads once, and a user whose browser has never run the script stays in UTC.
- **Data from before the new rules is not merged.** Two logs of the same workout on one date, or an exercise doubled on a day or in a log, stay as they are; the rules apply to what is added from now on. With two logs of a workout on one date, new sets go to the older one. Mock workouts logged by the old task can be removed with `mock:clear` and logged again.
- **`mock:clear` only removes plans added by the new task.** Planned exercises the old task added to empty days carry no mark and stay.
- **Deleting the last set of the day leaves an empty logged workout** (it shows as "0 sets" in History until deleted).
- **Notes are added by editing.** A set's note is typed after pressing its pen, and a logged exercise's note on its edit page; the "Add set" form has no note field, to keep it to two fields.
- **History and the users table scroll sideways on a phone** when the columns do not fit.
- **Rubocop's config was relaxed to the code's existing style** (symbol arrays as `[:a, :b]`, `end` aligned with the variable, no method or block length limits) instead of rewriting the code.
- **Admin screen is users only:** make or unmake an admin, delete a user. Nothing else is managed there.

---

## 9. Where to start

1. Read `CLAUDE.md`, then this file.
2. Check the current branch and `git status`.
3. Read `doc/Issues/Issues.md` for what the owner wants next. The Calendar section is the next piece of work unless they say otherwise.
4. Run `bin/rails test` before and after changes.
