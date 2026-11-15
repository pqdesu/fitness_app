# Fitness app

A simple workout tracker in Ruby on Rails. The owner's own description of the core use: "I go to the gym, log my workouts and what I did for the day, and then that's it."

The full project context (product brief, every decision, data model, page flows, current state, open issues) is in [doc/Prompt/project-context.md](doc/Prompt/project-context.md). Read it before making product or design choices.

## Product rules

- Top priority is a very intuitive, simple, user-friendly UI: few taps and little typing to log a set on a phone at the gym.
- Plain POST and GET: record entries, read them back. Do not add features beyond what is asked.
- Keep the planning layer (splits, workout days, planned exercises), the shared exercise catalogue and the admin role. Do not propose removing them.
- Users pick an exercise from the catalogue or create their own; only an admin changes the shared catalogue.
- Equipment is chosen per lift: free weights, or a machine whose brand the user types.
- A workout day lists only exercises. Sets (weight, then reps) are added when the user opens an exercise.

## How to work in this repo

- Work in the main checkout on a normal branch. Do not create or suggest git worktrees. The owner usually creates the branch, so check the current branch before making one.
- The owner tests by running `rails s` from the main folder before merging. Do not finalize work unprompted.
- When asked to finalize, finish or wrap up a branch, use the `finalize-branch` skill (in `.claude/skills/`). It writes a detailed change doc to `doc/<branch>.md`, pushes, and opens a pull request.
- Never merge a pull request, enable auto-merge, or run `git pull` / `git merge` for the owner. Give them the commands instead; they decide what goes into `master` and what comes into their folder.
- Branch names are a few plain lowercase words joined by dashes, with no digits and no `claude/` prefix.
- Change docs must be very detailed: every step, decision, file changed, the reason, and how it works now.
- Open and resolved issues are tracked in [doc/Issues/Issues.md](doc/Issues/Issues.md). When an issue is fixed, move it under "Issues Resolved".

## Stack and commands

Ruby 3.3.5, Rails 7.1, PostgreSQL, Devise, Bootstrap 5 with SCSS, Hotwire (Turbo and Stimulus) through importmap, simple_form, Minitest.

```bash
bin/setup                 # gems and database
bin/rails db:seed         # admin user and starter catalogue (idempotent)
bin/rails server
bin/rails test
bin/rails mock:last_week  # logs last week's sessions for every split, as mock data
bin/rails mock:clear      # deletes the workouts the mock task logged
```

## Code map

- Program: `Split` has many `WorkoutDay` (one per weekday, name from a fixed list) has many `WorkoutExercise`.
- Record: `WorkoutLog` (belongs to the user, survives split deletion) has many `WorkoutLogExercise` has many `WorkoutSet`.
- `Lift` concern (`app/models/concerns/lift.rb`) is shared by planned and logged exercises: name copy, equipment, machine brand.
- `Exercise` without a user is in the shared catalogue; with a user it is that user's own.
- Sub-pages declare their back button with `<% back_to "Label", path %>` at the top of the view; the layout draws it.
- Dates follow the browser's time zone, sent in a cookie by `app/javascript/time_zone.js`.
- Most behaviour is covered by `test/integration/workout_flow_test.rb`.
