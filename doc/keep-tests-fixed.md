# keep-tests-fixed

## Summary

This branch adds one working rule to `CLAUDE.md`: never edit a test file just to make a failing test pass. A failing test means the app code is wrong, so fix the code and keep working until `bin/rails test` passes. It also carries the latest base data in `db/seeds/data.yml`. No app code, tests or config changed. The full suite passes: 90 runs, 0 failures.

## Timeline

1. **2026-11-20, "make a memory: don't edit test files just so tests pass; make tests precise; keep working until tests pass."** I saved this as a Claude Code memory (`never-edit-tests-to-pass.md` in the owner's local memory folder, outside the repository). That folder lives only on the owner's machine, so I offered to put the rule in `CLAUDE.md` too.
2. **"add it to Claude.md".** I made a worktree branch, `keep-tests-fixed` in `.claude/worktrees/keep-tests-fixed`, as `CLAUDE.md` asks, so the main checkout stays untouched. Then I added the rule under "How to work in this repo".
3. **"finalize it".** I ran the `finalize-branch` skill: tests, this doc, a seed data dump, commit, push and pull request, then removed the worktree.

## Starting point

`CLAUDE.md` said how to run the tests (natively, `bin/rails test`, never skip them when Ruby or PostgreSQL is missing). It said nothing about what to do when a test fails. Nothing stopped an agent from changing a test's assertion to match buggy code, which hides the bug instead of fixing it.

## Changes

### `CLAUDE.md`: the test rule

Before, the "How to work in this repo" list went straight from the line on running tests natively to the line on checking pages in a real browser.

After, a new line sits between them:

```markdown
- Never edit a test file just to make a failing test pass. Write tests that check exactly the behaviour asked for; once written, a failing test means the app code is wrong: fix the code and keep working until `bin/rails test` passes. If a test contradicts what the owner asked for, ask before changing it.
```

Why: the owner wants the tests to be a fixed, precise specification of how the app behaves.

### `db/seeds/data.yml`: base data

`bin/rails seed:dump` added one logged workout: **2026-11-20, Upper** (split `U/R/L/U/L`, weekday 5, not a rest day), which has no sets yet. Nothing was removed. The file now holds 1 user, 3 splits, 3 workouts and 46 sets.

## Decisions

- **Placement.** The rule goes right after the line on running the tests, because both are about tests. I didn't add a new section, since the existing list already covers how to work in the repo.
- **One exception: ask first.** The owner said never to change a test. I added "if a test contradicts what the owner asked for, ask before changing it". When a product rule changes, the old test is no longer right, and the owner decides that, not the agent. This addition is my own; the owner did not word it.
- **Worktree, not the main checkout.** `CLAUDE.md` (2026-11-16) asks for worktrees and to leave the main checkout alone. An older local memory, "Branches, not worktrees" (2026-11-15), says the opposite. I followed `CLAUDE.md` because it's newer, and I told the owner about the conflict.
- **Both a memory and `CLAUDE.md`.** The memory works for this owner's sessions on this machine. `CLAUDE.md` travels with the repository.

## How it works now

Any Claude session in this repository reads `CLAUDE.md` and gets the rule. When a test fails, the agent changes the app code until the suite is green, and asks the owner before touching a test that conflicts with a stated requirement. The app's behaviour has not changed.

## Tests and verification

- `bin/rails test`: 90 runs, 1235 assertions, 0 failures, 0 errors, 0 skips.
- `bin/rails test test/lib/seed_data_test.rb`: 2 runs, 0 failures.
- `bin/rails db:migrate:status`: no pending migrations.
- Not run: rubocop, brakeman and bundler-audit. No Ruby code changed, and CI runs them on push.
- Not verified, and it can't be verified by a test: whether future agents actually follow the rule.

## Every file changed (3)

- `CLAUDE.md`: adds the "never edit tests to pass" rule.
- `db/seeds/data.yml`: adds the 2026-11-20 Upper workout from the development database.
- `doc/keep-tests-fixed.md`: this change doc.

## Feature and issue lists

Nothing moved. This branch finishes no item in `doc/Features/Features.md` or `doc/Issues/Issues.md`, and it adds no potential issues.

## Known gaps

- The local memory "Branches, not worktrees" still contradicts `CLAUDE.md`. It lives outside the repository, and it's the owner's choice whether to delete it.
