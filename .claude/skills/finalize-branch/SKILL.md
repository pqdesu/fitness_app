---
name: finalize-branch
description: Finalize finished work on the current branch or worktree - write a detailed change doc into doc/, commit and push, open a GitHub pull request (never merge it), then delete the worktree. Use when the user says to finalize, finish, wrap up or ship the work on this branch.
---

# Finalize branch

Hands finished work over to the user as an open pull request, with a detailed doc, and cleans up the worktree. Run the steps in order. Worktree deletion is always last: once a session's own worktree folder is deleted, shell commands stop working.

## What this skill must never do

The user merges and pulls themselves; they want control over what goes into the default branch and what comes into their main folder.

- Never merge the pull request (`gh pr merge`), and never enable auto-merge.
- Never run `git pull`, `git merge`, `git fetch` into, `git switch` or `git checkout` in the main folder, and never write files there.
- Never push to the default branch.
- Never delete the local or remote branch: the open pull request needs the remote one, and the local one is not merged yet.
- Never use `--force`, and never discard uncommitted changes.
- Never edit any file other than the three this skill is allowed to write: the change doc (step 3), `doc/Features/Features.md` and `doc/Issues/Issues.md` (step 3a). No code, tests, config or other docs are touched while finalizing.

## Stop rules

Stop and report, without opening a pull request or deleting anything, if:

- The current branch is the default branch (`master` or `main`). There is nothing to finalize.
- Tests fail (step 2).
- `gh auth status` fails.

## 1. Work out where you are

```bash
git rev-parse --abbrev-ref HEAD             # branch being finalized
git worktree list                           # first line is the main folder
git rev-parse --show-toplevel               # this checkout
git remote show origin | grep 'HEAD branch' # default branch
git status --short
```

Record: `DEFAULT` (default branch), `MAIN` (path of the main folder), `HERE` (this checkout), and whether `HERE` differs from `MAIN` (that means this session is in a worktree).

### Give the branch a clean name

The user wants branch names that read cleanly on GitHub: a few plain words, no numbers. Generated names such as `claude/universal-back-button-4813cc` do not qualify. Before anything is pushed, rename the branch when its name has any of:

- a tool or session prefix (`claude/`, or anything else before a slash)
- a random or hex suffix, or any digit anywhere
- words that do not describe the change

The clean name is two to five lowercase words joined by dashes, describing what the branch does: `universal-back-button`, `split-week-on-dashboard`. No slashes, no digits, no dates, no issue numbers. If the name is already clean, keep it.

```bash
git branch --list CLEAN; git ls-remote --heads origin CLEAN   # both must print nothing
git branch -m CLEAN                                           # renames the current branch, also inside a worktree
```

- If the clean name is taken locally or on origin, choose different words. Do not add a number to make it unique.
- If the branch was already pushed under its old name or has an open pull request, do not rename it: that would orphan the remote branch or close the pull request. Keep the old name and say so in the final report.
- Renaming changes only the branch. The worktree folder keeps its name and is removed in step 6 as usual.

`BRANCH` is the name after this step. Use it for the doc file, the push and the pull request, and give the old name once in the final report.

## 2. Check the work

Run the project's test suite if it has one (for Rails: `bin/rails test`). If it fails, stop and show the output. If there is no suite, say so in the doc and the final report.

## 3. Write the change doc

Write a Markdown file at `doc/<BRANCH>.md` (replace any slash with a dash if the branch could not be renamed), inside the current checkout (`HERE`), so that it is committed on the branch. It reaches the main folder when the user merges the pull request and pulls. Do not write it straight into the main folder.

If `doc/` already holds a file for this branch, update it instead of adding a second one.

The doc must be detailed. Base it on the real diff (`git diff DEFAULT...HEAD --stat`, `git log DEFAULT..HEAD`) and on what happened in the session, not on memory alone. Include:

1. **Summary**: what the branch does, in a few lines, and its state (tested or not).
2. **Timeline**: each request from the user and what was done for it.
3. **Starting point**: how things were before, and the problems or goals.
4. **Changes**: for each change, before and after (with code where it helps), and the reason.
5. **Decisions**: every decision taken, the alternative rejected, and why. Mark assumptions as assumptions.
6. **How it works now**: behaviour, data model or flow, and how to run and try it.
7. **Tests and verification**: what was run with results, and plainly what was not verified.
8. **Every file changed**: grouped, with a one-line description each. The count must match `git diff --stat`.
9. **Known gaps**: what is unfinished, deferred or risky.

Do not put passwords, tokens or other secrets in the doc, except development-only seed values that are already in the repository.

## 3a. Update the feature and issue lists

These two files are the only existing files this skill may edit, and it edits them only to record the state of the work, in `HERE` so the change is committed on the branch:

- `doc/Features/Features.md`: move each feature this branch finished from its section (for example "Home page") to the matching section under "Features added (DONE)", creating that section heading if it is missing. Keep the wording of the item as the owner wrote it, and keep the unfinished items where they are.
- `doc/Issues/Issues.md`: move each issue this branch fixed to "Issues Resolved". Leave open issues alone.

Rules for both:

- Only move or tick items the diff really finishes. Do not add, reword, reorder or delete other items, and do not touch any other file, in any part of the repository, for this step.
- If an item is only partly done, leave it in place and say so in the final report.
- Edit the copies inside `HERE`, never the ones in the main folder.
- If a file does not exist in the branch, skip it and say so in the final report.

Mention in the change doc which items were moved.

## 4. Commit and push the branch

```bash
git add -A
git status --short      # read it: nothing unexpected (secrets, logs, tmp files)
git commit -m "<what and why>"
git push -u origin BRANCH
```

Use the commit attribution the session specifies. If there is nothing to commit, carry on. Afterwards confirm nothing is left behind:

```bash
git status -sb          # clean, and not ahead of origin/BRANCH
```

## 5. Open the pull request

```bash
gh pr view BRANCH --json number,state,url   # reuse an open PR if one exists
gh pr create --base DEFAULT --head BRANCH --title "<title>" --body "<summary, path of the doc file, test result>"
```

Leave it open. Do not merge it, approve it, or turn on auto-merge.

## 6. Delete the worktree (last, and only in a worktree)

Skip this step when the session is in the main folder (`HERE` equals `MAIN`): leave the branch checked out as it is.

In a worktree, first tell the user in one line which folder is about to be removed and that the branch stays. Invoking this skill is the go-ahead, so do not wait for a reply. Do every other shell command first, including anything needed for the final report. Then:

```bash
git status --short                    # must be empty
git status -sb                        # must not be ahead of origin/BRANCH
git -C MAIN worktree remove HERE
git -C MAIN worktree prune
```

If either check fails, do not remove the worktree; report why. `worktree remove` and `prune` only detach the extra checkout; they change nothing in the main folder's files or branches.

## 7. Report

Tell the user:

- the pull request URL, and that it is open and not merged
- the path of the doc on the branch (`doc/<name>.md`)
- the test result
- what was deleted (the worktree path) and that the local and remote branch still exist
- the steps left for them, as commands they can run:
  1. merge the pull request on GitHub
  2. in the main folder: `git pull origin DEFAULT`
  3. optional cleanup once merged: `git branch -d BRANCH` and `git push origin --delete BRANCH`
- which items moved in `Features.md` and `Issues.md`
- anything skipped, failed or not verified
- when a worktree was removed: this session can no longer run commands, so further work needs a new session from the main folder
