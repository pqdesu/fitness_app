# Fitness app

A simple workout tracker built with Ruby on Rails. You plan your training week, go to the gym, and log what you did: the exercise, then each set's weight and reps.

## What it does

- **Splits.** A split is a training program shown as a week, Sunday to Saturday. Each weekday can hold one workout day (Push, Pull, Legs, Lower, Upper, Anterior, Posterior or Full Body). One split is the active split, which the dashboard follows.
- **Workout days.** A workout day lists its exercises, picked from the shared catalogue or created by you.
- **Logging.** Open an exercise and add sets: weight first, then reps. The first set of the day creates that day's workout. There is one logged workout per workout per day. A set can be corrected in place, given a note, or deleted.
- **Equipment.** Chosen per lift: free weights, or a machine whose brand you type.
- **Dashboard.** The month calendar, this week, today's workout from the active split, and the heaviest set of each exercise from the last time you did that workout.
- **History.** Every logged workout, newest first. Logged workouts belong to you and stay when a split is deleted.
- **Exercises.** The shared catalogue plus your own exercises, which only you see.
- **Admin.** An admin manages the shared catalogue and the user accounts (make or unmake an admin, delete a user). An admin can also keep private exercises like anyone else.

## Stack

- Ruby 3.3.5, Rails 8.1
- PostgreSQL
- Devise for accounts
- Bootstrap 5 with SCSS, Font Awesome, simple_form
- Hotwire (Turbo and Stimulus) through importmap, with no Node build
- Minitest

## Getting started

PostgreSQL must be running locally.

```bash
git clone git@github.com:pqdesu/fitness_app.git
cd fitness_app
bin/setup
bin/rails db:seed
bin/rails server
```

Then open http://localhost:3000.

The seed creates an admin account for development (`admin@example.com` / `admin123456`) and a starter catalogue of 14 exercises. Set `ADMIN_EMAIL` and `ADMIN_PASSWORD` to use other credentials; in production the seed refuses to run without `ADMIN_PASSWORD`.

## Commands

```bash
bin/rails test                           # the test suite
bundle exec rubocop                      # the linter
bundle exec brakeman                     # security scan of the code
bundle exec bundler-audit check --update # known vulnerabilities in the gems
bin/rails mock:last_week                 # logs last week's sessions for every split, as mock data
bin/rails mock:last_week EMAIL=me@x.com  # the same, for one user
bin/rails mock:clear                     # deletes what the mock task added
```

## Configuration

| Variable | Used for |
|---|---|
| `ADMIN_EMAIL`, `ADMIN_PASSWORD` | The admin account created by `db:seed` |
| `MAILER_SENDER` | The address password-reset emails come from |

## Documentation

The project context, the decisions made so far and a detailed doc for each merged branch are in [`doc/`](doc/). Start with [`doc/Prompt/project-context.md`](doc/Prompt/project-context.md).
