---
name: plan-features
description: Plan the features the user listed in the project's Features.md (on master by default), under the section they name - read the app's current code and work out how each feature could be built in it, without changing anything. Use when the user asks to read, study, plan, scope or explain how to implement features from Features.md, before any code is written.
---

# Plan features

The user writes features in the project's features file in plain words, often with typos and from a phone user's view: "make the exercises movable, so I can move around the order". This skill turns each one into an implementation plan grounded in the code as it is today. It is planning only. Nothing is changed until the user asks for the feature to be built.

## Inputs

- **Section:** the heading the user names, for example `### General` or `### Exercise page`. If they name none, take every feature in the open part of the file, which is everything above `# Near Future`. Take `# Near Future` features only when the user asks for them. Never plan what is under `# Features added (DONE)`.
- **Features:** one feature is one `-` bullet, with its indented lines. When the user names one feature ("the timer", "bottom nav bar"), plan only that one.
- **Branch:** `master` unless the user names another. Read the file from that branch, not from the checkout, which may be on a different branch.
- **File:** `doc/Features/Features.md`, unless CLAUDE.md or the user points elsewhere.

## Never

- Never edit, create or delete files, run migrations, commit or push. This is read-only, so no worktree or branch is needed.
- Never start building a feature in passing, even a one-line one. Plan it and let the user decide.
- Never write to the main checkout.
- Never plan more than the feature asks for. CLAUDE.md says to add nothing beyond what is asked; extras go under "Open questions" as a question, not into the plan.

## Steps

### 1. Read the features

```bash
git show master:doc/Features/Features.md | awk '/^### General$/{f=1;print;next} f&&/^(#|---)/{exit} f'   # put the section's name in place of General
git show master:doc/Features/Features.md | sed -n '/^# Near Future/,/^# Features added/p'                 # only when the user asks for Near Future
git log --oneline -1 master; git rev-parse HEAD master                                                 # is the checkout on the same commit?
```

- A section name such as `### Exercise page` appears under both `# Features` and `# Near Future`. The awk line takes the first one; for the Near Future one, run it on the output of the `sed` line.
- List each feature under the section, with the user's own words.
- Open every image a feature points to (`doc/Features/Pics/...`, or an absolute path) with the Read tool. It is part of the request.
- If the checkout is not at master's commit, read the code from master too (`git show master:<path>`). Otherwise the plan may not fit the code the user has.
- Read CLAUDE.md and the project context it points to (`doc/Prompt/project-context.md`). Their product rules bind every plan: few taps and little typing on a phone, the planning layer, the shared catalogue, what only an admin may do, the one-log-per-day rules.
- Read `doc/Issues/Issues.md` for open issues and "Potential issues" in the same area. A plan should not make one worse, and may fix one on the way if it touches the same code; say so.

### 2. Read the code each feature touches

For every feature, find where it would live before deciding how to build it. Do not stop at the first plausible file.

- **Check what already exists.** Some features are partly done or done another way ("notes for the set" when sets already have notes). Grep for the idea, not only the word: model columns in `db/schema.rb`, partials, helpers, Stimulus controllers, routes (`bin/rails routes` or `config/routes.rb`). Say what is there and what is missing.
- **Start from where the user would see it.** Find the page, partial or helper that draws that part of the app, by grepping its class, text or route, and follow it back: the link's `href`, the controller action, the model method, the table.
- **Walk every layer the feature needs, and name what changes in each:**
  - data: new tables or columns (`db/schema.rb`), unique indexes for "once only" rules, what existing rows get
  - models and concerns: validations, `normalizes`, associations, and the one-place methods the code map names (`Split#week_plan`, `WorkoutExercise#entry_on!`, `WorkoutLog.session_of`, `Dashboard`, `WorkoutSummary`) that the feature should go through rather than around
  - controllers and routes: which action, `params.expect`, finding records through `current_user`, admin checks
  - views, partials, helpers: which existing partial to extend (`workout_sets/_form`, `shared/_exercise_picker`, `splits/_week`, `pages/_calendar`) rather than a new one
  - JavaScript: an existing Stimulus controller or Bootstrap collapse/modal before a new controller; `config/importmap.rb` for anything new
  - styles: `components/` or `pages/`, and the import order in `application.scss`
  - content security policy, for any outside host (`config/initializers/content_security_policy.rb`); no inline `style=` or scripts
  - seed data: `lib/seed_data/` (`Dumper`, `Loader`) and `db/seeds/data.yml` must carry any new user data; the mock task (`lib/tasks`, `test/tasks/mock_task_test.rb`) if logged workouts change
  - tests: which `test/integration/*_flow_test.rb` file, model tests, `test/models/dashboard_test.rb`
- **Reuse before adding.** Prefer an existing helper, partial, concern, gem or Bootstrap component. Do not propose a new gem when a few lines or something installed does it.
- **Find how far it reaches.** A change to a shared partial or concern touches every page that uses it; count them ("`workout_sets/_table` is used by 2 pages").
- **Find conflicts.** Say when a feature clashes with a product rule, another feature in the list, or an open issue, and with what exactly.
- **Order and overlap.** Note when features share work (the equipment catalogue and the bodyweight option both change `Lift`), or when one should come first.
- **Name the exact places:** `path:line` for every file the plan touches, and a short excerpt where it shows why the plan goes there.

When the current behaviour is unclear from reading, you may look at it live: run the app from the current checkout on a free port and open it in Chrome at phone width (390 px). Only read and navigate there. Do not create, change or delete data.

### 3. Explain

Answer in the chat, one section per feature, in the user's terms first and the code second:

```markdown
## 1. <feature title, short>

**What it would do.** <one or two sentences in plain words, from the user's view on a phone>

**What is there now.** <what already exists or is partly done, with path:line links; "nothing yet" when that is so>

**How to build it.**
- **Data:** <tables, columns, indexes, what existing rows get; or "no change">
- **Models:** <...>
- **Controllers and routes:** <...>
- **Views and JavaScript:** <which pages and partials, what the user taps>
- **Seed data and tests:** <...>

**Size.** <small / medium / large, and why: files touched, migration, new page>

**Open questions.** <the choices only the user can make, each as a short question with your suggestion>
```

- Plan in prose and short lists of files and changes. A 2-6 line excerpt of the current code is fine; do not write the new code.
- Use the user's example from the feature as the worked example, for instance "Plate Loaded Pec Deck from MTorture".
- Say plainly what you could not confirm, and how you would check it.
- When the feature text is ambiguous ("timer for exercise"), give your reading and ask instead of guessing silently.
- After the sections, if there are several features, add a short suggested order with the reason (shared work, dependencies, size).

### 4. Hand over

End by saying nothing has been changed, and ask whether to build them. Ask which first if there are several, and for answers to the open questions. If they say yes, the repo's normal workflow takes over:

- a worktree and branch named for the work
- the feature, tests, and a check in Chrome at phone width
- later, when asked, `finalize-branch`, which also moves the built features under `# Features added (DONE)`
