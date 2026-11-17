---
name: update-seed-data
description: Save the development database's real data (users, own exercises, splits, workout days, planned exercises, moves, logged workouts and sets) into db/seeds/data.yml, merged with what the file already holds, so the next push carries it and a pull plus bin/rails db:seed brings it to any machine. Use before committing or pushing work on a branch, as part of finalize-branch, and whenever the user asks to update, save or refresh the seed data or base data.
---

# Update the seed data

The app is about dates: this week, last time, the calendar, History. So its base data is kept in git, in `db/seeds/data.yml`, and it only grows. Every dump keeps everything the file already had, updates records that are in both, and adds what is new in the database. After a pull, `bin/rails db:seed` creates whatever the file has that the local database lacks. It never changes or deletes what is already there.

The code is `lib/seed_data.rb`, `lib/seed_data/` (dumper, loader, merge) and `lib/tasks/seed.rake`. Its test is `test/lib/seed_data_test.rb`.

## What is saved and how it is matched

Records are matched by what identifies them, never by database id, so the file means the same thing on every machine:

| Record | Matched by |
|---|---|
| user | email (no password is ever written) |
| exercise (catalogue, own, planned, logged) | name, ignoring capitals |
| split | name |
| workout day | weekday |
| move of a workout for one week | `week_start` (the Sunday) |
| logged workout | workout and date |
| set | set number |

Mock workouts (`notes` starting "Mock data", made by `bin/rails mock:last_week`) are never written.

## Steps

1. **Check the database is current.** `bin/rails db:migrate:status` must show no `down` migration. Otherwise stop and tell the user. The worktrees and the main folder share one development database (CLAUDE.md), so ask before migrating.
2. **Dump.** Run `bin/rails seed:dump`. It prints the totals in the file, plus a note if there are mock workouts it skipped. The file is written in the current checkout.
3. **Read the diff.** Run `git diff --stat db/seeds/data.yml`, then `git diff db/seeds/data.yml`.
   - Expect added lines, and changed values for records you edited in the app.
   - A removed line is only right when a value really changed. For example, a renamed split shows up as a new split, and the old name stays.
   - If old workouts disappear, stop and report it. That should never happen.
   - Look at the user emails. Every user in the database goes into a file that is committed and pushed. If an email is new and is not an `example.com`/`example.test` address, ask the user before committing it.
4. **Check that it loads.** Run `bin/rails test test/lib/seed_data_test.rb`. After a big change, also load the file into a scratch database and dump it again; the file must come out the same:

   ```bash
   DATABASE_URL=postgres:///fitness_app_seed_check bin/rails db:create db:schema:load db:seed
   DATABASE_URL=postgres:///fitness_app_seed_check bin/rails runner 'SeedData.dump("<scratchpad>/roundtrip.yml")'
   diff db/seeds/data.yml <scratchpad>/roundtrip.yml
   dropdb fitness_app_seed_check
   ```

5. **Commit it with the branch's work.** Commit `db/seeds/data.yml` with the branch's other changes, or in its own commit ("Update the base seed data") when nothing else changed. Only commit when the user asked for a commit, or as part of `finalize-branch`.
6. **Report.** Give the totals the task printed, what was added since the last version of the file (new workouts by date, new splits or exercises), and any mock workouts that were skipped.

## After a pull (on any machine)

```bash
bin/rails db:migrate
bin/rails db:seed      # admin, starter catalogue, then everything in db/seeds/data.yml that is missing
```

A user the file creates gets the password in `SEED_USER_PASSWORD`. In development that defaults to `admin123456`, the same default as the seeded admin. In production it must be set, or seeding stops.

## Never

- Never run `db:reset`, `db:drop`, `db:seed:replant` or `mock:clear` to "clean up" before a dump. The shared database holds the owner's real data.
- Never add data by editing the YAML by hand. Add it through the app, then dump. Editing by hand is only for removing something for good, and only when the user asks.
- Never put passwords, tokens or other secrets in the file.
- Never commit mock data. The dump leaves it out, so don't add it back by hand.
