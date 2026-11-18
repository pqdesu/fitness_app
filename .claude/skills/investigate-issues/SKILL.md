---
name: investigate-issues
description: Investigate the issues the user listed in the project's Issues.md (on master by default), under the section they name - trace each one through the current code to its root cause and explain it, without changing anything. Use when the user asks to read, inspect, investigate, diagnose or explain issues from Issues.md, or to find what is causing them, before any fix.
---

# Investigate issues

The user writes issues in the project's issues file in plain words, often with typos and from a phone user's view: "the back button goes to the split page". This skill turns each one into a root cause in the code and explains it. It is diagnosis only. Nothing is changed until the user asks for a fix.

## Inputs

- **Section:** the heading the user names, for example `## General` or `## History page`. If they name none, take every issue under the open part of the file, which is everything above `# Issues resolved`.
- **Branch:** `master` unless the user names another. Read the file from that branch, not from the checkout, which may be on a different branch.
- **File:** `doc/Issues/Issues.md`, unless CLAUDE.md or the user points elsewhere.

## Never

- Never edit, create or delete files, run migrations, commit or push. This is read-only, so no worktree or branch is needed.
- Never fix an issue in passing, even a one-line one. Report it and let the user decide.
- Never write to the main checkout.
- Never trust the issue text for the cause. It describes a symptom. Find the cause in the code.

## Steps

### 1. Read the issues

```bash
git show master:doc/Issues/Issues.md | awk '/^## General$/{f=1;print;next} f&&/^##? /{exit} f'   # put the section's name in place of General
git log --oneline -1 master; git rev-parse HEAD master                       # is the checkout on the same commit?
```

- List each `###` issue under the section, with the user's own description.
- If the checkout is not at master's commit, read the code from master too (`git show master:<path>`). Otherwise the cause you find may not be the one the user sees.
- Read CLAUDE.md, and the project context it points to, for the product rules that bear on these issues.

### 2. Trace each issue to its cause

For every issue, follow the symptom back to the code that produces it. Do not stop at the first plausible file.

- **Start from what the user sees or does.** Find the view, partial or helper that draws the thing, by grepping its class, text or route. For a UI flow ("I clicked X on page Y"), follow the exact path: the link's `href`, the controller action, the view it renders, and what that view declares.
- **Check every layer that touches it:**
  - layout and partials
  - helpers
  - styles: the component file, `application.scss` import order, Bootstrap variable overrides
  - JavaScript: `app/javascript`, Stimulus controllers, `config/importmap.rb`
  - controllers and models
- **Look for what is missing as well as what is wrong.** "It never disappears" can mean there is no code for it at all. Say so, and show where you looked (for example the list of Stimulus controllers).
- **Find how far the cause reaches.** A global CSS rule, a shared helper or partial, or one pattern repeated across many views. Count the uses: "16 `back_to` calls, each with a fixed target".
- **Note side effects** the user did not report but the same cause creates. For example, a rule meant for flash messages that also pins an inline form error to a corner.
- **Name the exact places:** `path:line` for every link in the chain, and the short code excerpt that shows the cause.

When the cause is unclear from reading, you may look at it live: run the app from the current checkout on a free port and open it in Chrome at phone width (390 px). Only read and navigate there. Do not create, change or delete data.

### 3. Explain

Answer in the chat, one section per issue, in the user's terms first and the code second:

```markdown
## 1. <issue title, short>

**What causes it.** <one or two sentences in plain words>

<the chain, step by step, each step with a clickable path:line link and, where it helps, a 2-6 line code excerpt>

- **<symptom from the issue text>:** <why the code above produces it>
- **<second symptom, if any>:** <why>
- **Side effect:** <anything else the same cause breaks, if found>

<one or two sentences on what a fix would need, the shape only, no code>
```

- Use the user's example from the issue as the worked example, for instance "the workout circle in the Active split box".
- Say plainly what you could not confirm, and how you would check it.
- When the issue text is ambiguous ("show up more"), give your reading and ask instead of guessing silently.
- Do not paste whole files, and do not write the fix.

### 4. Hand over

End by saying nothing has been changed, and ask whether to fix them. Ask which first if there are several, or whether the user wants changes to the request first. If they say yes, the repo's normal workflow takes over:

- a worktree and branch named for the work
- the fix, tests, and a check in Chrome at phone width
- later, when asked, `finalize-branch`, which also moves the fixed issues under `# Issues resolved`
