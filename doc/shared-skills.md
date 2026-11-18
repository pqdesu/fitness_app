# Shared skills

Branch `shared-skills`.

## 1. Summary

This branch adds the `investigate-issues` skill to the repository, in `.claude/skills/investigate-issues/SKILL.md`, so every session and machine has it. It also adds a line to CLAUDE.md telling sessions when to use it.

The skill writes down the routine the owner used on 2026-11-18. They asked for the issues under one section of `doc/Issues/Issues.md` on `master` to be read, traced to their causes in the code, and explained, before any fix.

`finalize-branch` was already shared in `.claude/skills/finalize-branch/SKILL.md` on `master`, so the branch adds no copy of it (see section 3). The base seed data was re-dumped as `finalize-branch` requires.

State: the 86 tests pass. The skill was not yet tried on a real request.

## 2. Timeline

1. **"Can you make a skill about how I asked in the beginning to investigate issues?"**
   - I wrote `investigate-issues` as a personal skill in `~/.claude/skills/investigate-issues/SKILL.md`, next to the personal `finalize-branch`.
   - It was not put in the repo then: the session's worktree had just been removed, and the main folder is the owner's.
2. **"Yes please make it shared, also the finalize branch too."**
   - I found that `master` already tracks `.claude/skills/finalize-branch/SKILL.md`, and that it is newer than the personal copy (section 3).
   - I created the `shared-skills` worktree from `master` and copied `investigate-issues` into `.claude/skills/`.
   - I added the CLAUDE.md line.
   - The personal copies were left in place. Removing them is the owner's call; the commands are in section 6.
3. **"Yes, finalize."**
   - I ran the tests, dumped the seed data, wrote this doc, committed, pushed and opened the pull request.
   - I followed the repo's `finalize-branch`, not the older personal copy.

## 3. Starting point

- **`investigate-issues`** existed only in the owner's personal folder (`~/.claude/skills/`). Other machines and sessions started elsewhere did not have it.
- **`finalize-branch`** has two copies:
  - **Repo** (`.claude/skills/finalize-branch/SKILL.md`, tracked since the commit that added CLAUDE.md). It has steps 3a (move finished items in `doc/Features/Features.md` and `doc/Issues/Issues.md`) and 3b (update the seed data with `update-seed-data`). It also has a rule limiting which files finalizing may edit.
  - **Personal** (`~/.claude/skills/finalize-branch/SKILL.md`). It is an older copy without steps 3a and 3b, and it is the one sessions load when both exist. On the `alerts-and-back-button` branch those two steps were done by hand, because the personal copy ran.

So `finalize-branch` was already shared. What stops the shared version from running is the personal copy, not the repository.

## 4. Changes

### 4.1 `.claude/skills/investigate-issues/SKILL.md` (new)

The same text as the personal skill. It contains:

- **Frontmatter:** name `investigate-issues`. The description says when to use it: reading, inspecting, investigating, diagnosing or explaining issues from Issues.md before any fix.
- **Inputs:** the section the user names (or all open issues), the branch (`master` by default, read with `git show master:…`) and the file (`doc/Issues/Issues.md`).
- **Never:** no edits, migrations, commits or pushes; no fixes in passing; nothing written to the main checkout; the issue text is a symptom, not the cause.
- **Steps:**
  1. Read the section from the branch, and check whether the checkout is at that commit.
  2. Trace each issue from what the user sees or taps, through view, helper, styles, JavaScript, controller and model. Look for missing code as well as wrong code, count how far the cause reaches, note side effects, and give `path:line` for each link in the chain. The app may be looked at live in Chrome at phone width, read-only.
  3. Explain each issue in a fixed shape: the cause in plain words, then the chain with links and short excerpts, then why each symptom happens, side effects, and what a fix would need, without code.
  4. Hand over: say nothing was changed, and ask whether and what to fix. A yes leads into the repo's normal workflow (worktree, fix, tests, Chrome check, later `finalize-branch`).

### 4.2 `CLAUDE.md`

One line was added under "How to work in this repo", after the Issues.md line:

```markdown
- When asked to read, investigate or explain issues from `Issues.md` (usually one section, on `master`), use the `investigate-issues` skill (`.claude/skills/`). It traces each issue to its cause and explains it without changing anything, then asks before fixing.
```

### 4.3 `db/seeds/data.yml`

`bin/rails seed:dump` added 20 lines and removed none:

- **Plan:** Barbell curl (shared catalogue, free weights) in the planned exercises of the `U/R/L/U/L` split's Friday (weekday 5) Upper day.
- **Logged workout:** Upper on 2026-11-18, not a rest day, with Barbell curl and one set of 13 reps × 100 kg.

Totals now: 1 user, 3 splits, 2 workouts, 28 sets. No new user email.

### 4.4 `doc/shared-skills.md` (new)

This file.

## 5. Decisions

- **No second copy of `finalize-branch`.** The repo already has it, and its version is the newer one. Copying the personal file over it would have removed steps 3a and 3b. *Rejected:* overwriting with the personal copy.
- **The personal copies are not deleted by the session.** They are the owner's own files outside the repository, and deleting them is the owner's decision.
  - `finalize-branch` can go now, since `master` already has the newer one.
  - `investigate-issues` should go after this branch is merged and pulled. Until then, sessions in the main folder find it only in the personal folder.
- **The skill is copied unchanged.** It was written for this repo (Issues.md path, `master`, phone-width Chrome check, `finalize-branch` hand-off), so it needed no edits to be shared.
- **The worktree sits in a reused folder.** This session can only write inside its own worktree folder, `.claude/worktrees/issues-general-investigation-02e805`. That folder was removed after the last branch was finalized, so the `shared-skills` worktree was moved into it with `git worktree move`. Only the folder name differs from the usual `.claude/worktrees/<branch>`. The branch name is clean.
- **Features.md and Issues.md are not touched.** This branch finishes no feature and fixes no issue.

## 6. How it works now

- Ask, for example: "Read Issues.md on master under `## History page`, find the cause and explain it." A session follows `investigate-issues`: it reads the section from `master`, traces each issue in the code, explains it, changes nothing, and asks whether to fix.
- `/investigate-issues` also runs it directly.
- For the shared `finalize-branch` to be the one that runs, remove the older personal copy:

  ```bash
  rm -r ~/.claude/skills/finalize-branch
  ```

- After this branch is merged and pulled, the personal `investigate-issues` is a duplicate:

  ```bash
  rm -r ~/.claude/skills/investigate-issues
  ```

## 7. Tests and verification

**Run:**
- `bin/rails test`: 86 runs, 1126 assertions, 0 failures, 0 errors, 0 skips. No code changed, so the tests only confirm that nothing broke.
- `bin/rails seed:dump`: totals as in 4.3. The diff of `db/seeds/data.yml` has additions only.
- `bin/rails test test/lib/seed_data_test.rb`: 2 runs, 0 failures.

**Checked by reading:**
- The skill's section-reading command (`awk '/^## General$/{f=1;print;next} f&&/^##? /{exit} f'`) stops at the next `##` or `#` heading.

**Not verified:**
- The skill has not been run on a real request.
- Which copy of a skill wins when a personal and a repo skill share a name was seen only once: the personal `finalize-branch` loaded on 2026-11-18. It was not tested further.

## 8. Every file changed (4)

- `.claude/skills/investigate-issues/SKILL.md`: new; the investigate-issues skill.
- `CLAUDE.md`: one line saying when to use `investigate-issues`.
- `db/seeds/data.yml`: re-dumped; Barbell curl added to Friday Upper, and the 2026-11-18 Upper workout.
- `doc/shared-skills.md`: this change doc.

## 9. Known gaps

- Until the owner removes `~/.claude/skills/finalize-branch`, sessions keep loading the older personal copy without steps 3a and 3b.
- The skill reads `master` by default. If issues are written on another branch first, the user has to name that branch.
