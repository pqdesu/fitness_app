# Handover prompt: design audit of the fitness app (2026-11-25)

You are taking over the results of a full design audit of this app. The audit is finished; your job is to act on it. This file holds **everything** the audit found: the instructions below, then every report embedded **verbatim, byte for byte**, with a SHA-256 for each so you can prove nothing was lost or changed. Read all of it before you plan anything. Nothing here is a summary you can trust over the embedded reports: when this header and a report disagree, the report wins, and when two reports disagree, section 6 says how to decide.

## 1. What was done, by whom

The owner asked for "a full audit of my app, the whole design": **Impeccable** for the fonts, spacing and the rest; **Emil Kowalski**'s skills to see what can improve toward a professional, minimalist look; and the **taste skill** to present a new look that is minimalist, futuristic and simple. "Do not miss any small detail."

Four reviewers ran in parallel as isolated sub-agents, all on the same screenshots and the same running copy of the app:

| # | Reviewer | Skills used | Result | Embedded below as |
|---|---|---|---|---|
| A | Impeccable critique, Assessment A (design review) | impeccable: critique, critique-rubric, typeset, layout, operate, colorize, adapt, craft-floor | **25/40, Acceptable.** P0 0 · P1 8 · P2 17 · P3 14 | `evidence/scratchpad/reports/impeccable-A.md` |
| B | Impeccable audit, Assessment B (detector + technical) | impeccable: audit, `impeccable detect` over CDP on the logged-in app | **15/20, Good.** P0 0 · P1 3 · P2 12 · P3 7. Integrity: PASS | `evidence/scratchpad/reports/impeccable-B.md` |
| E | Emil Kowalski review | emil-design-eng, review-animations (+STANDARDS), mobile-native, break-ui (+CATALOG), remove-animations, find-animation-opportunities, apple-design | P0 0 · P1 8 · P2 13 · P3 24; all 29 transitions/animations reviewed; 17 worst-case data results | `evidence/scratchpad/reports/emil.md` |
| T | taste skill, new look "Readout" | design-taste-frontend (taste-skill 2.5.1), minimalist-ui | A concept page (light + dark) and a direction doc with SCSS tokens and a 9-step migration | `evidence/scratchpad/new-look/DIRECTION.md` + `new-look/readout-concept.html` (not embedded: HTML, see inventory) |

The merged report written for the owner is `README.md` (embedded first). The brief every reviewer received is `evidence/scratchpad/audit-brief.md` (embedded). Each reviewer's final message is `evidence/reviewer-handbacks.md` (embedded).

## 2. Where everything is

All paths are relative to the worktree root `/home/pedro/code/pqdesu/fitness_app/.claude/worktrees/opus-plan-session-e72fa6` (branch `claude/opus-plan-session-e72fa6`, based on `master` at `0bd4a1b`). Everything lives in `doc/design-audit/`. **Nothing is committed.** The app's code and the owner's development database were never changed.

**Path rule.** The reports cite files under the session scratchpad `/tmp/claude-1000/-home-pedro-code-pqdesu-fitness-app--claude-worktrees-opus-plan-session-e72fa6/d91907ca-cfc9-418e-acc7-1a8504a66bda/scratchpad/`, which may be gone. Every one of those files was mirrored byte for byte: replace that prefix with `doc/design-audit/evidence/scratchpad/`. Short names in the reports map the same way: `shots/png/phone--home.png` → `doc/design-audit/evidence/scratchpad/shots/png/phone--home.png`; `shots/emil/wc-home.png`, `shots/impeccable-a/…`, `shots/impeccable-b/…`, `impB/run/det/*.json`, `impB/run/meas/*.json` likewise. Report A sometimes names a tall capture as `phone--home-0/1/2`: those are its crops in `evidence/scratchpad/shots/impeccable-a/crops/`. The concept `new-look/index.html` was copied to `doc/design-audit/new-look/readout-concept.html` (identical bytes; the mirror keeps `index.html` too).

**What is not mirrored:** the cloned skill repositories (installed in `~/.claude/skills/`, not audit output) and the audit server's 2.8 MB log.

`doc/design-audit/1-impeccable-design-review.md`, `2-impeccable-technical-audit.md` and `3-emil-polish-review.md` are byte-identical friendly-named copies of the three reports in `evidence/scratchpad/reports/`. Impeccable's own saved copy of report B's scored part is `evidence/impeccable-history/2026-11-25T14-25-45Z__project.md` (also in `.impeccable/audit/` at the worktree root, which git ignores).

## 3. Rules you must follow (from CLAUDE.md and the owner)

- Read `CLAUDE.md` and `doc/Prompt/project-context.md` first. The product rules there are fixed: keep the planning layer (splits, workout days, planned exercises), the shared catalogue and the admin role; "plain POST and GET"; **do not add features beyond what is asked**.
- Run on the `opusplan` model. Plan each fix in plan mode first; sub-agents that implement run on Sonnet or Haiku.
- Work in a new worktree on a plain branch: `git worktree add .claude/worktrees/<branch> -b <branch> master`. Branch names: a few lowercase words with dashes, no digits, no `claude/` prefix (e.g. `design-audit-fixes`, `readout-look`). Leave the main checkout alone.
- Run `bin/rails test`, `bundle exec rubocop`, `bundle exec brakeman`; all must pass. **Never edit a test just to make it pass**; if a test contradicts the owner, ask.
- Look at every changed page in a real browser at phone width (390 px, and 320 px for overflow) before calling UI work done; the owner also wants it clicked through like a user, in the Chrome installed on WSL.
- The content security policy forbids inline `style=` attributes and inline scripts. New outside hosts (fonts, scripts) must be added to `config/initializers/content_security_policy.rb`; Google Fonts are already allowed.
- Hotwire only (Turbo morphs, Stimulus); no new JS libraries.
- Never merge a pull request or run `git pull`/`git merge` for the owner. To finish a branch, use the `finalize-branch` skill (change doc in `doc/<branch>.md`, seed data update, push, PR).
- Record risks a branch leaves behind in `doc/Issues/Issues.md` under "Potential issues".

## 4. Decisions the owner has not made yet (ask before acting on them)

The owner was last asked "What should I plan first?" with two options and has not answered:
1. **Fix the P1s first** on the current look (recommended: they hold whatever the look), or
2. **Adopt Readout** (the new look) and fold the fixes into its migration.

These findings change behaviour, not just looks. Each needs the owner's yes before you build it (CLAUDE.md: no features beyond what is asked):
- **Rest timer, three taps per set** (A P1-5): save the measured rest without the "Save rest?" confirm (keep it only past 10 min); optional setting "Start rest after each set".
- **Preferences without password** (A P1-8): a separate Preferences form for `timer_auto_start` and `auto_warm_up`.
- **Search in the exercise picker** (A P1-4, E P2-13): a filter field with a small Stimulus controller.
- **Set note and Tag into the set's ⋯ menu** (A P1-1, E P1-4): changes how a note is written; the owner asked for notes on sets.
- **Add-set form above the sets** (A P1-1 option 2) vs one-row sets with the form below.
- **Flash after Add set**: A P2-9 moves it to the bottom on phones; E says drop it once the new row lights up.
- **"Last time" and History skip empty workouts** (A P2-7); **last session's sets on the exercise page** (A P2-15).
- **Move "Delete workout"** to the end of the page (A P2-10); **move Home's Exercises button** (A P3-13, T).
- **PWA manifest / theme-color** (E P2-6): makes the app installable.
- **Font Awesome → SVG sprite** (B P2, T optional last step).
- Readout's own decision: Home shows the Today box after training started ("Logged today", Continue); the "Start workout" version is only in the states panel.

## 5. The fixes, merged (pointer list; full detail, exact values and file:line are in the reports)

P1, in recommended order (letters = which reviewers found it):
1. Exercise page: one ~48 px row per set; Add set in reach; keep scroll after Add set (A P1-1, B P2, E P1-4). `workout_sets/_set.html.erb:55-88`, `workout_exercises/show.html.erb:34-50`, `WorkoutSetsController#create`.
2. Exercise rows: drop the boxed chevron button, sets chip onto the meta line, pen and × into ⋯ (A P1-6, B P2 text-overflow, E P1-3). `workout_days/_planned_exercise.html.erb:4-17`, `workout_logs/show.html.erb:55-71`.
3. Surfaces: `$surface: #FFFFFF`; `$card-bg`, `$input-bg`, `$modal-content-bg`, `$dropdown-bg`, `$list-group-bg` (A P1-2, B P2).
4. Control contrast: checkbox/radio border, input border, focus ring (A P1-3, B P1 ×2, A P2-4). Values in A and B differ slightly; see section 6.
5. Overflow: split chip `_lists.scss:36`; set edit bar at 320 px `_set.html.erb:93-113` (B P1, E P1-1, E P1-2).
6. Green ✓: `config/initializers/simple_form_bootstrap.rb` (A P1-7, B P2).
7. Touch: gate hovers with `(hover: hover) and (pointer: fine)`, no tap highlight, `touch-action: manipulation`, `:active` press (E P1-5, E P1-6, E P2-1, B P3).
8. Picker search + group style (A P1-4, E P2-13) — needs the owner's yes.
9. Rest timer three taps (A P1-5) — needs the owner's yes.
10. Confirm box icon and verb (E P1-7). `shared/_confirm.html.erb:5`, `confirm_dialog.js:24`.
11. Picker footer safe area (E P1-8).
12. Preferences without password (A P1-8) — needs the owner's yes.

Then the P2 and P3 items in each report (type scale, faux bold, number size, quieter indigo, one grey, tag pills, motion vocabulary, spacing rhythm, flash placement, numbers wrapping, calendar legend, copy, admin pages, page titles, Font Awesome, 200% zoom, the Account tab keyboard, and the rest).

## 6. Where the reviewers disagree, and how to decide

| Topic | A (Impeccable design) | B (Impeccable tech) | E (Emil) | T (Readout) | Decide |
|---|---|---|---|---|---|
| Card edge | white surface + stronger shadow `0 1px 2px rgba($shadow,.06), 0 1px 1px rgba($shadow,.04)` | surfaces white | border **or** shadow, not both; borders `rgba(#101828,.08)` | no shadows, 1 px lines; one shadow for sheets only | Current look: E's rule. Readout: T. |
| Checkbox border | `1.5px solid #8A919E` | `1px solid $muted` | — | `line-strong` tokens | Either passes 3:1; take A's value on the current look. |
| Focus ring | `2px $blue` with 2 px surface gap, opacity 1 | opacity 1 + a `btn-light` focus colour | — | `signal` border + 3 px `signal-soft` ring | Current look: A. Readout: T, but check 3:1 against both themes. |
| Type | 8-step scale `.75/.8125/.875/1/1.125/1.375/1.75/2.25rem`; load Inter 700 | `overused-font` (Inter, Plus Jakarta Sans) | heading tracking `-.025em` | Geist + Geist Mono, its own scale | Readout replaces the fonts; otherwise A. |
| Uppercase labels | remove the 12 "eyebrows" (craft-floor ban) | — | uppercase 12 px wants `.06em` | uses mono 11 px uppercase micro labels on purpose | Readout's labels are part of its identity; on the current look, follow A. |
| Radii | — | — | 3 steps: 10 / 16 / pill | 6 / 10 / 12 / 16 / 22 | Follow the look you build. |
| Flash after Add set | move to the bottom on phones | — | remove it once the new row lights up | — | Owner decides (section 4). |
| Rest clock size | 36 px m:ss | — | — | — | A. |
| Primary colour | indigo for the one primary action only | — | quiet the blue | signal orange, everything else ink | Follow the look; the principle (one accent, one job) is shared. |

## 7. Reproduce the audit environment

The audit ran the app from this worktree against a **copy** of the development database, so the owner's data was never touched. To look again:

```bash
# 1. the copy (skip if it still exists: psql -l | grep fitness_app_design_audit)
createdb fitness_app_design_audit
pg_dump -Fc fitness_app_development | pg_restore -d fitness_app_design_audit --no-owner
# 2. a known password, in the copy only
DATABASE_URL=postgres:///fitness_app_design_audit bin/rails runner 'User.find_each { |u| u.update!(password: "auditpass123", password_confirmation: "auditpass123", locked_at: nil, failed_attempts: 0) }'
# 3. the server, on another port (3000 is the owner's)
DATABASE_URL=postgres:///fitness_app_design_audit bin/rails server -p 3001 -b 127.0.0.1
```

Logins (password `auditpass123`): `admin@example.com` (admin, 3 splits, active split U/R/L/U/L, history) and `notadmin@example.com` (no data, for empty states).

Today's workout data used for the in-gym screens (audit date Wednesday 2026-11-25; today's workout is `/workout_days/11`, Lower). It was created with:

```ruby
today = Date.new(2026,11,25)
[[17, [[60,12],[80,10],[90,8]]], [18, [[100,8],[110,6]]]].each do |we_id, sets|
  e = WorkoutExercise.find(we_id).entry_on!(today)
  sets.each_with_index { |(w, r), i| e.workout_sets.find_or_create_by!(set_number: i + 1) { |s| s.weight_used = w; s.reps_completed = r; s.rest_seconds = (i.zero? ? nil : 125) } }
end
log = WorkoutExercise.find(17).workout_day.log_on(today)
log.update!(started_at: 35.minutes.ago)   # => log 7, entries 19 (Hip thrust) and 20 (Squat)
```

The reviewers then added worst-case data in the same copy (in their hand-backs): A added sets 4 and 5 to Hip thrust, a paused-then-resumed timer and a long-named exercise; B added 2 sets of 95 kg × 6 to Hip thrust (8 sets total); E added split 4, workout day 14, workout log 8 (17 exercises, 14 sets on entry 21), plan row 26, a timer backdated 3 hours, one set with a 3-hour rest and all three tags, and a 99,999.125 kg set. The copy still exists unless someone dropped it (`dropdb fitness_app_design_audit`).

Screenshots: `evidence/scratchpad/shots/shoot.mjs` (headless Chrome over CDP, Node 26 at `~/.nvm/versions/node/v26.13.1/bin/node`, Chrome at `/usr/bin/google-chrome`; the default Node is 20.17 and too old). Run `node shoot.mjs <outdir>` with the server on 3001. It captures 63 images: every GET page at 390×844 (full page, with the viewport stretched so the fixed tab bar sits at the bottom), menus and modals open, the empty user, logged-out pages, and 11 pages at 1280×800. No page overflowed sideways at 390 px with normal data. Reviewer scripts: `evidence/scratchpad/impeccable-a-scripts/`, `evidence/scratchpad/impB/` (`scan.mjs`, `probe*.mjs`, `tmp/*.js`), `evidence/scratchpad/emil/*.mjs`, `evidence/scratchpad/new-look-shoot.mjs`.

Impeccable commands (skill at `~/.claude/skills/impeccable`, v4.10.0; v4.11.0 is available): `scripts/impeccable context`, `scripts/impeccable detect --json <files>` (a directory scans no `.erb`/`.scss`: list files explicitly), `scripts/impeccable detect --cdp <port> --target <url part> --json` on a logged-in headless Chrome. The project has no `PRODUCT.md` or `DESIGN.md`; Impeccable's `init` (PRODUCT.md) comes first for a redesign, and `document` (DESIGN.md) should record whichever look is chosen.

## 8. Verify you have everything

Every file in `doc/design-audit/` is listed below with its size and SHA-256. To check the folder: `cd doc/design-audit && sha256sum -c <(sed -n 's/^| `\(.*\)` | [0-9]* | `\([0-9a-f]\{64\}\)` |$/\2  \1/p' HANDOVER-PROMPT.md)`.

The embedded files follow the inventory. Each sits between two marker lines:

```
<!-- BEGIN VERBATIM FILE: <path> | bytes: <n> | sha256: <hash> -->
...the file's exact bytes...
<!-- END VERBATIM FILE: <path> -->
```

The file's bytes are everything after the newline that ends the BEGIN line, up to but not including the single newline that precedes the END line (one newline is added before END so it starts its own line). To extract and check them all:

```bash
python3 - <<'PY'
import re, hashlib
t = open('doc/design-audit/HANDOVER-PROMPT.md', 'rb').read()
for m in re.finditer(rb'<!-- BEGIN VERBATIM FILE: (.+?) \| bytes: (\d+) \| sha256: ([0-9a-f]{64}) -->\n(.*?)\n<!-- END VERBATIM FILE: \1 -->', t, re.S):
    body = m.group(4)
    ok = len(body) == int(m.group(2)) and hashlib.sha256(body).hexdigest() == m.group(3).decode()
    print('OK ' if ok else 'BAD', m.group(1).decode())
PY
```

### Inventory

| Path (relative to `doc/design-audit/`) | Bytes | SHA-256 |
|---|---|---|
| `1-impeccable-design-review.md` | 76057 | `b8fe57173efcf86b5257fcf08a32417ac8d6a408a15da2251d15d2ade8bdb808` |
| `2-impeccable-technical-audit.md` | 40064 | `819182ad88a2ff9443a32b3703cc535bdd1a7a98bcc8d3a8021ae7bea68bbe25` |
| `3-emil-polish-review.md` | 40747 | `73467bc66a4faf9acc8a761f45a60a0aaa12d16f5215c7905d073d9a3280a39d` |
| `README.md` | 15884 | `bc024571a4213feb54e11d32d6a480d39d01868f05c582346bdb7c98e6a5b28f` |
| `evidence/impeccable-history/2026-11-25T14-25-45Z__project.md` | 39637 | `4222c0906a9b09f7d24c5642546ad02b9454e7ea1487fb02d712f3fb281c4aca` |
| `evidence/reviewer-handbacks.md` | 15138 | `277fcbb9161c4e21a20a64f9fa38727d74314de6f3bd67c68d73126f78d15528` |
| `evidence/scratchpad/audit-brief.md` | 3119 | `f78d66018dec370fef16736a2ea4d52d52b48a3692b1c4b42d7d57b11d63bde4` |
| `evidence/scratchpad/crop-390-home.png` | 124196 | `8c5acecb9d438872d91babfe0ece71f70eb359e0e32590326ac5e0d26ba06b78` |
| `evidence/scratchpad/crop-390-late.png` | 115702 | `f2eaeb0357aec18806bdf0697cdad58f07cd0964e2d92adfc3c28b7c2dcc61e7` |
| `evidence/scratchpad/emil/app.css` | 401820 | `ea694792c8142429adf7314ebbbafa0f74848e7d1838cfc562268f7d46e61af5` |
| `evidence/scratchpad/emil/cdp.mjs` | 4535 | `a31e384af498b744e83ec1d55dfaaa360a73b67101998f805a71548f9dd0c660` |
| `evidence/scratchpad/emil/probe.mjs` | 1869 | `d9fcf4b71f51b33cc5aa699f4d36e8678396d3266eaa8a03fe791f493559d155` |
| `evidence/scratchpad/emil/seed.mjs` | 2334 | `0c52cf3596b69dae47dc36e72cbb2d8d89ae5d35dae88b855a5064b606f35d1e` |
| `evidence/scratchpad/emil/seed2.mjs` | 1719 | `9eb2de90ca42f85c987a6be99aec2ae94e57b9ddfca4883bffcb45521be8bdc4` |
| `evidence/scratchpad/emil/shots.mjs` | 3220 | `8221a57287bcce8d90a268448fc8c26cd00f000dcceb8c03c657dadebc72a89e` |
| `evidence/scratchpad/emil/shots2.mjs` | 2928 | `633a50e5f70fe61642e640d52e1e633072bb1d0bb4e0ba0afb098771f8a3aa95` |
| `evidence/scratchpad/impB/probe-narrow.mjs` | 8500 | `3b9cc97de4afc97b7058a14609f2d768ee91a889a05e5187240d4db9728ef11a` |
| `evidence/scratchpad/impB/probe-tab.mjs` | 9185 | `c7e838e54c2146d48a5416a32b0310953ffebd2cb7d00563ced09fac76ccb555` |
| `evidence/scratchpad/impB/probe.mjs` | 8396 | `e71b6b9d3dd0500471bc9b33de2274aa80b64990c617aca80801434d9b4b0a51` |
| `evidence/scratchpad/impB/run/det/desktop--exercise-17.err` | 0 | `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` |
| `evidence/scratchpad/impB/run/det/desktop--exercise-17.json` | 553 | `6c17fed7d4f44af42ea5639d836faac44dd0fccc40834e3e76d165d396d5d3a9` |
| `evidence/scratchpad/impB/run/det/desktop--home.err` | 0 | `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` |
| `evidence/scratchpad/impB/run/det/desktop--home.json` | 533 | `aaafebf20f9a747b052d56b8af994485f10da909c8a2f267a23f90fb1c931381` |
| `evidence/scratchpad/impB/run/det/desktop--workout-day-11.err` | 0 | `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` |
| `evidence/scratchpad/impB/run/det/desktop--workout-day-11.json` | 1091 | `7d3de2cd6b622a00900f69bfe1c5e64f2f43ad4605893f92ba3d1f4c4b4fd07a` |
| `evidence/scratchpad/impB/run/det/phone--account.err` | 0 | `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` |
| `evidence/scratchpad/impB/run/det/phone--account.json` | 543 | `aae1283269e09572aeeb4435f9c7402015a04de2153f268c71266a01f458db90` |
| `evidence/scratchpad/impB/run/det/phone--admin-equipment.err` | 0 | `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` |
| `evidence/scratchpad/impB/run/det/phone--admin-equipment.json` | 548 | `b2ea5e6bc59a506d7120bd05efa89f0b181e03ffd24e56633d7bde94cf9f2c29` |
| `evidence/scratchpad/impB/run/det/phone--exercise-17.err` | 0 | `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` |
| `evidence/scratchpad/impB/run/det/phone--exercise-17.json` | 553 | `6c17fed7d4f44af42ea5639d836faac44dd0fccc40834e3e76d165d396d5d3a9` |
| `evidence/scratchpad/impB/run/det/phone--exercises.err` | 0 | `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` |
| `evidence/scratchpad/impB/run/det/phone--exercises.json` | 1193 | `f8152abc7ff02d029c55e6fad76fb68fc538ba3296fa5383e02875738bacbf97` |
| `evidence/scratchpad/impB/run/det/phone--history.err` | 0 | `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` |
| `evidence/scratchpad/impB/run/det/phone--history.json` | 545 | `966340139f0557e519faf06e72657760e862625c757de8e4a99c961c086f1195` |
| `evidence/scratchpad/impB/run/det/phone--home.err` | 0 | `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` |
| `evidence/scratchpad/impB/run/det/phone--home.json` | 533 | `7a6a1d4d8e564f059f8dd7059750e258e122674443c371f4283468550f9902be` |
| `evidence/scratchpad/impB/run/det/phone--log-1.err` | 0 | `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` |
| `evidence/scratchpad/impB/run/det/phone--log-1.json` | 1181 | `fd55b333d11812131f01f4a3021079ee77eb2f6f7d6f005b53b03441de47198d` |
| `evidence/scratchpad/impB/run/det/phone--log-7.err` | 0 | `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` |
| `evidence/scratchpad/impB/run/det/phone--log-7.json` | 1724 | `62e573b8049fe64264c6e6855b43d38321d4cd31ff8287ebb890c7fdcc8de710` |
| `evidence/scratchpad/impB/run/det/phone--month.err` | 0 | `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` |
| `evidence/scratchpad/impB/run/det/phone--month.json` | 548 | `e29e824e8d87007615b374ba16776beb8b4152e527ae78f1aeb32a9cc6a4620e` |
| `evidence/scratchpad/impB/run/det/phone--signin.err` | 0 | `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` |
| `evidence/scratchpad/impB/run/det/phone--signin.json` | 3 | `37517e5f3dc66819f61f5a7bb8ace1921282415f10551d2defa5c3eb0985b570` |
| `evidence/scratchpad/impB/run/det/phone--split-3.err` | 0 | `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` |
| `evidence/scratchpad/impB/run/det/phone--split-3.json` | 541 | `3f70410480158410747e974d0d52bacf39f52345f0a4b4f9ee61650c8fe89f42` |
| `evidence/scratchpad/impB/run/det/phone--splits.err` | 0 | `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` |
| `evidence/scratchpad/impB/run/det/phone--splits.json` | 539 | `56fb963ff48f3ac5533df17c96d6b3d111e69d159e7f9d34428edbccff84847d` |
| `evidence/scratchpad/impB/run/det/phone--workout-day-11.err` | 0 | `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` |
| `evidence/scratchpad/impB/run/det/phone--workout-day-11.json` | 1091 | `7d3de2cd6b622a00900f69bfe1c5e64f2f43ad4605893f92ba3d1f4c4b4fd07a` |
| `evidence/scratchpad/impB/run/meas/desktop--exercise-17.json` | 29611 | `53a2d12add096330b70f8c6415fa4827dd251f9c657a1aee277d67dc3a04d2ec` |
| `evidence/scratchpad/impB/run/meas/desktop--home.json` | 9629 | `abad9793e81ba1a963c66a944263e96f477d576cacd0217486fc86c4f6cfe59e` |
| `evidence/scratchpad/impB/run/meas/desktop--workout-day-11.json` | 33184 | `d6f7951e65416c76b91a70f059b0adfc90527158fb9d2a8be0834ed13ff42c19` |
| `evidence/scratchpad/impB/run/meas/phone--account.json` | 4745 | `2edc4823d6c64bd1bf6587169550b53f42bb70bf43f62d42f58c395c30cd1646` |
| `evidence/scratchpad/impB/run/meas/phone--admin-equipment.json` | 4710 | `6df5158f2147c11e4d7ce412679dedf895ac55faa463e78c2e7d662bbe3ad9b8` |
| `evidence/scratchpad/impB/run/meas/phone--exercise-17.json` | 24317 | `3d0490aa140adaa79a1b1f1079dd7d6b0a2a07ed848fbb5da8cf28523d2db2af` |
| `evidence/scratchpad/impB/run/meas/phone--exercises.json` | 1396 | `616d5dae812501126b99c6fa505716262ca9fcb279cae174f987a8a517ea713b` |
| `evidence/scratchpad/impB/run/meas/phone--history.json` | 3339 | `d681461047b3e3ebd18e31c456564ac745c080a997baec06bab5ddb8f6a6eb16` |
| `evidence/scratchpad/impB/run/meas/phone--home.json` | 9972 | `e45775c13b145cfc655a6955f41d1b5ab12e1b9fc5024457930c598ba2258b14` |
| `evidence/scratchpad/impB/run/meas/phone--log-1.json` | 118215 | `75e75c4ae3da0fb670fe968d49a559822d12b1e8758cc1d46f7d5fa17122d344` |
| `evidence/scratchpad/impB/run/meas/phone--log-7.json` | 45658 | `feaffcace0b16f35a7057f7aa6b9de3e59c1daaa7a4bf93e70543561462e7297` |
| `evidence/scratchpad/impB/run/meas/phone--month.json` | 3481 | `47971906448e9a5be231fbea1627a4d05bd88649a8a639430fcd865349cf9f8d` |
| `evidence/scratchpad/impB/run/meas/phone--signin.json` | 2956 | `7d0f5598fd2cf53e1536468971937daddaf863717395fc1eeff7acdc795d1050` |
| `evidence/scratchpad/impB/run/meas/phone--split-3.json` | 105303 | `b61f53a269d52f3e1605a2a5a2b79baefd15f9dfe9ac7be8ddc2f41d05d54b13` |
| `evidence/scratchpad/impB/run/meas/phone--splits.json` | 2147 | `1a1c2ae183c9e57a7a2b9dd12bd41745b7d15d8e511e70b11d4baf5b1ac5055e` |
| `evidence/scratchpad/impB/run/meas/phone--workout-day-11.json` | 28546 | `69d5bce099de572b0e428e917fce322ac6b42082f98c00cf7ff390bd645bc6c4` |
| `evidence/scratchpad/impB/run/png/desktop--exercise-17.png` | 73338 | `10de48b683191295e811aadb67f08a778a3c4b95e178f2db06f34ca93230756e` |
| `evidence/scratchpad/impB/run/png/desktop--home.png` | 98415 | `daf59982c9fc84f18093db52b9a925ece3b0e81e3a7e15b1b805431041788e49` |
| `evidence/scratchpad/impB/run/png/desktop--workout-day-11.png` | 61900 | `40a7a8fc7888df07e5ca042b38eb743d1cfd5db8f30fa3b4beecbd2a2180f450` |
| `evidence/scratchpad/impB/run/png/phone--account.png` | 117321 | `8e35aefa6bcb41d20be8458d38df16a651d86d6f73a78c191e26c91613eaf0a3` |
| `evidence/scratchpad/impB/run/png/phone--admin-equipment.png` | 95992 | `442103443db1a53072d8e990faa5f5cd76b14e3da28981473d3a409652561ffd` |
| `evidence/scratchpad/impB/run/png/phone--exercise-17.png` | 90933 | `162873894181285c8fc4d85b3f130cc2e851e71f68ce2fc87dd24db19d620a6c` |
| `evidence/scratchpad/impB/run/png/phone--exercises.png` | 101781 | `5c6ac9baa6fa7be60ccc48907f8274b7815e34e67426765f1066cfbd20dac544` |
| `evidence/scratchpad/impB/run/png/phone--history.png` | 140234 | `c716786af963ac73aadbb142b903280e66ce4da2f5cff6cdc991f63091fae70d` |
| `evidence/scratchpad/impB/run/png/phone--home.png` | 128241 | `9066edb9a96b422d59dd6f1af7cdd9dbccb6a491bb3a14c49e82ffc946385fa6` |
| `evidence/scratchpad/impB/run/png/phone--log-1.png` | 140926 | `54b2a95c0171fdfb9d0b09357d70c77c19ae60abf472fcd6d6070c921031f40c` |
| `evidence/scratchpad/impB/run/png/phone--log-7.png` | 119487 | `558124d6bf14856992e3cd0b77ea641c5b4a9b64201cd863a4bffbb6da74d4bf` |
| `evidence/scratchpad/impB/run/png/phone--month.png` | 111447 | `2cafac52eea6ae1ca02a584db73080afe1df104e1c8612fad8a4713a648fadbd` |
| `evidence/scratchpad/impB/run/png/phone--signin.png` | 45733 | `c54192144dde85a4ad0f9de32a6c6ef8f2dd052ea5c6813a19e1f9676b1c07ac` |
| `evidence/scratchpad/impB/run/png/phone--split-3.png` | 103636 | `7b44254f6fe4f31250d47ac907f51257cf2b7f46ea61b429966d2b2de1fac744` |
| `evidence/scratchpad/impB/run/png/phone--splits.png` | 110068 | `be8c572d4c316348cd60093168925d1fea691a519f2d2c17969f63505e97448d` |
| `evidence/scratchpad/impB/run/png/phone--workout-day-11.png` | 113343 | `a26a95bc4380958e8f82f4b83c1484e99e359a91467c27e451558dbcdc28616f` |
| `evidence/scratchpad/impB/scan.mjs` | 9708 | `b9e3889a12875b6ad19f21534f421a8d420026e049f3700860494bae7f6ccbad` |
| `evidence/scratchpad/impB/src-css.err` | 0 | `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` |
| `evidence/scratchpad/impB/src-css.json` | 3 | `37517e5f3dc66819f61f5a7bb8ace1921282415f10551d2defa5c3eb0985b570` |
| `evidence/scratchpad/impB/src-h.err` | 0 | `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` |
| `evidence/scratchpad/impB/src-helpers-files.json` | 3 | `37517e5f3dc66819f61f5a7bb8ace1921282415f10551d2defa5c3eb0985b570` |
| `evidence/scratchpad/impB/src-helpers.err` | 0 | `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` |
| `evidence/scratchpad/impB/src-helpers.json` | 3 | `37517e5f3dc66819f61f5a7bb8ace1921282415f10551d2defa5c3eb0985b570` |
| `evidence/scratchpad/impB/src-js-files.json` | 3 | `37517e5f3dc66819f61f5a7bb8ace1921282415f10551d2defa5c3eb0985b570` |
| `evidence/scratchpad/impB/src-js.err` | 0 | `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` |
| `evidence/scratchpad/impB/src-scss-files.json` | 3 | `37517e5f3dc66819f61f5a7bb8ace1921282415f10551d2defa5c3eb0985b570` |
| `evidence/scratchpad/impB/src-scss.err` | 0 | `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` |
| `evidence/scratchpad/impB/src-views-files.err` | 0 | `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` |
| `evidence/scratchpad/impB/src-views-files.json` | 591 | `c2196286929bdefdb430723139122ff95e21227e1fc6272db313463911495fe8` |
| `evidence/scratchpad/impB/src-views.err` | 0 | `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` |
| `evidence/scratchpad/impB/src-views.json` | 3 | `37517e5f3dc66819f61f5a7bb8ace1921282415f10551d2defa5c3eb0985b570` |
| `evidence/scratchpad/impB/tmp/addset.js` | 903 | `9ce037741928d81fefbdb596af694eabe46bf63ea120c3d808ba1a9bc803d034` |
| `evidence/scratchpad/impB/tmp/after-addset.png` | 102606 | `64adb799cac7ee7fa168a2383fdb28503ad54a1e47bc40cdc998911e1f8950a2` |
| `evidence/scratchpad/impB/tmp/card.js` | 544 | `c31f5a1c3ab2836ba23af79468537a9a5696d8b1d3b4164a3b28662ffcc4127f` |
| `evidence/scratchpad/impB/tmp/chip.js` | 285 | `f996ea95d3239f8e9632f04a41b7360d9403b50daa9f6e30340bd15633a2c7ab` |
| `evidence/scratchpad/impB/tmp/cs.js` | 1651 | `b33bded0fa432d056f8ba3efa91ee1427014e2de2b54826480e90e05ff4049ba` |
| `evidence/scratchpad/impB/tmp/home320-chip.png` | 50439 | `c44d8951bf4fd2499a482c7314f02b8977317717c844e1e7beec19fba512666b` |
| `evidence/scratchpad/impB/tmp/multi.js` | 1349 | `852eece4252920dcbd528f3a08bb70dbddfc62708a872620921263a809c63f24` |
| `evidence/scratchpad/impB/tmp/ov.js` | 415 | `6d24ea4fff33d4db0f428f0a8af70c9680cb28a85401d1c3ea0868621491e1ef` |
| `evidence/scratchpad/impB/tmp/ov.png` | 144703 | `e0bf8fee4554f7f647e030162eb2b0077d399bb2dd72c34583e969730669a71a` |
| `evidence/scratchpad/impB/tmp/ov320.js` | 716 | `2feb0abcb3c8afdbe18f1815fa4aeb5482c45ac21e72fb2b0e26d50207611bf5` |
| `evidence/scratchpad/impB/tmp/picker.js` | 1347 | `72cbef3067b5369d42ec903626e194c87a6d2507319ad8df159ab24f1b1c2273` |
| `evidence/scratchpad/impB/tmp/picker.png` | 74032 | `8d1a3b53723ae29d2483403d01ffea9639695d91fe8a3a7e4cc01f2dbac19a45` |
| `evidence/scratchpad/impB/tmp/pos.js` | 506 | `1edd1f4dc8db833f734c89a44e095c5a37b0fd041d94c9eeed970c825932c612` |
| `evidence/scratchpad/impeccable-a-scripts/lib.mjs` | 3796 | `d99961bfc4272398de26c338344e3ee99a70992fc44e0ee1ba90a819e9379284` |
| `evidence/scratchpad/impeccable-a-scripts/s1.mjs` | 2454 | `881404d8b12bcaaeb9eee4d07a2026d84d4f77be1bbc831412367148de2d3620` |
| `evidence/scratchpad/impeccable-a-scripts/s2.mjs` | 3355 | `73f2e50397f7e56f635c0f046b20468be7533f93e904295103866d095a355daa` |
| `evidence/scratchpad/impeccable-a-scripts/s3.mjs` | 1201 | `7976e102d5c3565a44a8f569186f538ed9e20e58f2263a575456b4fafbc3ee6a` |
| `evidence/scratchpad/impeccable-a-scripts/s4.mjs` | 905 | `7a6dd10fae92be96291414ed98fac24428cd3096135403656cf6f433283534d5` |
| `evidence/scratchpad/impeccable-a-scripts/styles.mjs` | 3034 | `100fad518dbcee2684d3f924e8aab07e4b19600d6a769196a216b010d788e222` |
| `evidence/scratchpad/new-look-shoot.mjs` | 4406 | `47e1aba7c4508795c36bc1b5937e889e627c1307bbe9cc13fbe8f4e6afaf23bc` |
| `evidence/scratchpad/new-look/DIRECTION.md` | 28916 | `9096d8c17615d03b1bea3220aaf760d626482019aea450b6634a8c92cbb0cd52` |
| `evidence/scratchpad/new-look/ds-dark.png` | 269482 | `bd6d7a3b6543a9c875a38f49dcae1440c7ca9d719522be66c1bf28c3c2059da6` |
| `evidence/scratchpad/new-look/ds-light.png` | 265989 | `218e54df0ddb09db987613427a5e31362787b77a743f935a07e1c845bdb29c30` |
| `evidence/scratchpad/new-look/frame-exercise-dark.png` | 195679 | `9ca584108c194b5831e98d12c15d757b0238778fbd7c1caa2d7de9481acd428c` |
| `evidence/scratchpad/new-look/frame-exercise-light.png` | 195334 | `4f783d9e9135b05f9e1ed18a551cc76429b528da4bed506e0ef08a0331e3d596` |
| `evidence/scratchpad/new-look/frame-history-dark.png` | 168354 | `951cd818356ea357bce114c65cf7ff60754d02e143cb48fae7c76500e5b25c8e` |
| `evidence/scratchpad/new-look/frame-home-dark.png` | 279206 | `494f520be68b21a2703a5e61041f47479eeeffd468f072416a28a5d27708de68` |
| `evidence/scratchpad/new-look/frame-home-light.png` | 278544 | `170e15e8b73d8b26f357f55d09ea88180c14dfb869bc0d88d4408eba23716ca3` |
| `evidence/scratchpad/new-look/frame-picker-dark.png` | 85939 | `b3a7a4d70265482a0056d7d6d6ca10b8f9e0efe80a38874fa5c57500fffff716` |
| `evidence/scratchpad/new-look/frame-picker-light.png` | 87703 | `14bc257bb7f6fd63874742d23d5ad4185635899573c13f9e355debf69e975617` |
| `evidence/scratchpad/new-look/frame-workout-dark.png` | 162860 | `f11d26924047fc5c38256173a54cb43c98019d9fb3e3d4f5d100663f92c66ee1` |
| `evidence/scratchpad/new-look/index.html` | 79983 | `7f8319a50336fa616a2d9442ff63914345dbc78c0a18a389e690c71b1a1a1629` |
| `evidence/scratchpad/new-look/m390-ds-dark.png` | 278836 | `ea02cc9ea333c7a34502432fa629a8ac44a082cb1c46216939070f8f3a009db3` |
| `evidence/scratchpad/new-look/m390-head-light.png` | 74859 | `5938383240b8aa7cd2bd22f155907f70962d0846041f45f0b5c6b987e9584d48` |
| `evidence/scratchpad/new-look/shot-1440-dark.png` | 709740 | `2ef6bd1abd2273ede90af35f1067c4f79682d6e22eda7310108e0c25be8eef6f` |
| `evidence/scratchpad/new-look/shot-1440-light.png` | 707964 | `08997f88010e46f23c05034ef299519b7303e56062e7604470718a69246d80ef` |
| `evidence/scratchpad/new-look/shot-390-dark.png` | 697340 | `70c4468c99e7dfad57caed745bd35a64b64f71aed930fc57a5d76b611e533d58` |
| `evidence/scratchpad/new-look/shot-390-light.png` | 692372 | `a81e783c6998426a13e856944dd5c7124fa932b2ba08d129d303d4c50f8f6f74` |
| `evidence/scratchpad/reports/emil.md` | 40747 | `73467bc66a4faf9acc8a761f45a60a0aaa12d16f5215c7905d073d9a3280a39d` |
| `evidence/scratchpad/reports/impeccable-A.md` | 76057 | `b8fe57173efcf86b5257fcf08a32417ac8d6a408a15da2251d15d2ade8bdb808` |
| `evidence/scratchpad/reports/impeccable-B.md` | 40064 | `819182ad88a2ff9443a32b3703cc535bdd1a7a98bcc8d3a8021ae7bea68bbe25` |
| `evidence/scratchpad/shots/emil/vp-exercise-addset.png` | 135482 | `c1322a46a18bf07c575a2910ad222b63cb0dfc8e5b8c20b15752d7c62747195b` |
| `evidence/scratchpad/shots/emil/vp-exercise-sets.png` | 135482 | `c1322a46a18bf07c575a2910ad222b63cb0dfc8e5b8c20b15752d7c62747195b` |
| `evidence/scratchpad/shots/emil/vp-exercise-top.png` | 135482 | `c1322a46a18bf07c575a2910ad222b63cb0dfc8e5b8c20b15752d7c62747195b` |
| `evidence/scratchpad/shots/emil/vp-history-top.png` | 143376 | `311824fe76d1b87b193080a23f190a3bc2c0ed0d70a95911f3548c2aa303a980` |
| `evidence/scratchpad/shots/emil/vp-home-recent.png` | 132378 | `1c88c0b0b51d6640c9d40f1055c8bd51b988e4dd69cfd74de9eac87af92b9a30` |
| `evidence/scratchpad/shots/emil/vp-home-week.png` | 132378 | `1c88c0b0b51d6640c9d40f1055c8bd51b988e4dd69cfd74de9eac87af92b9a30` |
| `evidence/scratchpad/shots/emil/vp-log-top.png` | 126089 | `610b0857aec9d0d7fa97c1fb58042c3f7bf6eb8b2cd052dc8cea93c8f3bddbd5` |
| `evidence/scratchpad/shots/emil/vp-month-exercises.png` | 108994 | `91bd20b85b26974de455c499f08cead20d084b4e8a0e955e1938d484d5bb9f19` |
| `evidence/scratchpad/shots/emil/vp-month-top.png` | 108994 | `91bd20b85b26974de455c499f08cead20d084b4e8a0e955e1938d484d5bb9f19` |
| `evidence/scratchpad/shots/emil/vp-workout-day-bike.png` | 119884 | `8c58e532fb826d83982882d3039a143a8ecdbbf870efe1f5d8ab2eb464f48444` |
| `evidence/scratchpad/shots/emil/vp-workout-day-longname.png` | 119873 | `bb8e8542cc623caa639602da9f2003b05ef0a581e937991410c5a47f2cd63490` |
| `evidence/scratchpad/shots/emil/vp320-exercise-editing.png` | 142584 | `c7df7d27d9aff63a20f660feb296166384afa041daa5b93ac44674c21c500b6c` |
| `evidence/scratchpad/shots/emil/vp320-exercise-sets.png` | 109126 | `1b05b5d37f0c2b4e011beef433478101f6bedf2a072e3e3f243f366620153766` |
| `evidence/scratchpad/shots/emil/wc-exercise-page--actions.png` | 129672 | `91c06fb2fad0e6dca88b80dd8efb80e823592b3d46ce8cf0457401364846642b` |
| `evidence/scratchpad/shots/emil/wc-exercise-page--editing-set1.png` | 143652 | `969cac1bfc909864a7f437c1e2f06af1e0b68f64f822c5e839e5a0d79d89e4db` |
| `evidence/scratchpad/shots/emil/wc-exercise-page--flash.png` | 142428 | `75e106aea19b5651d17e3d67e3584d33a0a08584cc6d5123c95b3edb1403718a` |
| `evidence/scratchpad/shots/emil/wc-exercise-page.png` | 434781 | `5f67daffbcf464efdd502616b2f747c366efe1e7b1a9ad12a3d297c83482c6ee` |
| `evidence/scratchpad/shots/emil/wc-exercises.png` | 101895 | `2362b99ed22fcb3fbc3d44e62f6796bf612a5b39cc5b33267b28b4be58209ac3` |
| `evidence/scratchpad/shots/emil/wc-history.png` | 196867 | `54a3d0f8533e2d936d7063dd6c0fd4daac4ca9ec8b49afe3553210c113d2a726` |
| `evidence/scratchpad/shots/emil/wc-home.png` | 287060 | `a40e601fb6ebb5dde8ad9a1f5c04e6cc2dd5105078a81b16b3a6fa6f3f0abd51` |
| `evidence/scratchpad/shots/emil/wc-log-exercise-edit.png` | 125334 | `8969a2cb78c0f57074372553b29bb3285c5d2aba3fabc59aeb928e07b4fac270` |
| `evidence/scratchpad/shots/emil/wc-log-show--expanded.png` | 1030043 | `6468afaf8e60100a9ad507679ea90cf312d2fc58e28ad12af5549f45a1219443` |
| `evidence/scratchpad/shots/emil/wc-log-show.png` | 456350 | `655c9a53277ed266b1321c9511886b9d97f893fae32c9be9aaffaf2dd03fad39` |
| `evidence/scratchpad/shots/emil/wc-month.png` | 301546 | `4eb2267a85f1365d3665582b9d316044e8d7f0aa9a2d4001b751b71876fe12fe` |
| `evidence/scratchpad/shots/emil/wc-split-show.png` | 125971 | `23e1aca3e4be6cdbff8538eece12ef0b85a19a53c145661ff39c48f346825eb1` |
| `evidence/scratchpad/shots/emil/wc-splits.png` | 128826 | `cabf1ad4181aa59c2c3ff0f7e2bb82a6e45cb2535b4e5707f54942fd9f22b027` |
| `evidence/scratchpad/shots/emil/wc-workout-day--confirm.png` | 241008 | `a9b950117fa9bfca1a16689baf5baaa0c484b36e8c74ab94feb59f5b92b3ea98` |
| `evidence/scratchpad/shots/emil/wc-workout-day.png` | 409537 | `c6e776d9a2c79c1b46c17f5588984a6abe921d23c99f6799dfa7f1c66c33517c` |
| `evidence/scratchpad/shots/emil/wc320-exercise-page.png` | 437286 | `95bcd3595fcdda7242c552352d1a722ceea13f79e8d6a66d8c3454e019ee8672` |
| `evidence/scratchpad/shots/emil/wc320-history.png` | 191265 | `e3b4b57a35d6347094c939b9b5e36da402a4d38480a6ba34607f6dba67aa7b94` |
| `evidence/scratchpad/shots/emil/wc320-log-show.png` | 505951 | `4cf577e96ad1cabedadd892f0495dbb9dc84933a1eee5f59facf7d12941b3684` |
| `evidence/scratchpad/shots/emil/wc320-workout-day.png` | 337475 | `49b7a7ac3d5d03c6939088800dcd2dbcb5f041edd7a98a74540612d1125be266` |
| `evidence/scratchpad/shots/emil/wcdesk-exercise-page.png` | 200295 | `7c5852406dcd396fa140b4da9d0106ac420b225651492eb658ce6bead83b5f3a` |
| `evidence/scratchpad/shots/emil/wcdesk-log-show.png` | 192674 | `fdb6040975b6441aa6ca837640cd790854546acc34827606079bcc8538bb07e8` |
| `evidence/scratchpad/shots/impeccable-a/after-add-set-flash.png` | 107514 | `3785155a16d816ddc03c8efbbcadea7d5553d594f2ee8d43793cfc8070809dec` |
| `evidence/scratchpad/shots/impeccable-a/after-add-with-date.png` | 94822 | `e4084179b3af3e61d61f4ea3f340540992d2e7598815a0734464c3b594f0354c` |
| `evidence/scratchpad/shots/impeccable-a/after-second-add.png` | 98086 | `fd058944c5494886bb6024dcf460b675fe02b6d0c5f56fcd7277719ac29173bf` |
| `evidence/scratchpad/shots/impeccable-a/crops/phone--account-0.png` | 108921 | `a8952a67dff79763c7627710dc16ed4277bd8122ce9af806324431070496b749` |
| `evidence/scratchpad/shots/impeccable-a/crops/phone--account-1.png` | 83709 | `5c8a5399a31d73b32a456ffa0858409e0b172c1f5a05ad14650bbd9557e8ca5d` |
| `evidence/scratchpad/shots/impeccable-a/crops/phone--admin-equipment-0.png` | 87829 | `5d4275c9fd06de6b5f2652972029047b4ed01bfd028be81d38cc295d24d12fbb` |
| `evidence/scratchpad/shots/impeccable-a/crops/phone--admin-equipment-1.png` | 46337 | `5e608a3b4ea16d3346b10ef963b42d31753efd011e5b5be5f01b200312e09124` |
| `evidence/scratchpad/shots/impeccable-a/crops/phone--admin-equipment-2.png` | 57648 | `e190c82107752f16cd2fb8037332232dd8dbe3731102938922900115ff5f14a6` |
| `evidence/scratchpad/shots/impeccable-a/crops/phone--empty--account-0.png` | 112410 | `e9a5c1757a9c72180678a8b11bf01a34d2243769f045e219628e2746f53863f8` |
| `evidence/scratchpad/shots/impeccable-a/crops/phone--empty--account-1.png` | 54873 | `9221187bd09c86fb7ea958624c687c0c8825324bceff17b2da0bd6e2cd85e866` |
| `evidence/scratchpad/shots/impeccable-a/crops/phone--empty--home-0.png` | 99022 | `3c6f9c7514499a228489b5cff05ab0267445cc3fd903ac156c89e28799b09073` |
| `evidence/scratchpad/shots/impeccable-a/crops/phone--empty--home-1.png` | 54336 | `cc577cabca599ed10d76fd70bc29dc49223cf3a55c6f5cad3facc398a29a7f18` |
| `evidence/scratchpad/shots/impeccable-a/crops/phone--exercise-new-0.png` | 119853 | `56a47ba351fb243f57f8e729f15c930773bf54a3c5bc7a27868bd2cd83f7e5ed` |
| `evidence/scratchpad/shots/impeccable-a/crops/phone--exercise-new-1.png` | 23601 | `d94dadab6952936ea9c445a33afa62a977953007284cd7e23d96fee959a2b84b` |
| `evidence/scratchpad/shots/impeccable-a/crops/phone--exercise-page-0.png` | 102628 | `a7fa1e5888e17cd0d13137ec1897d01f79393ab37dfd097d77feddb792459c50` |
| `evidence/scratchpad/shots/impeccable-a/crops/phone--exercise-page-1.png` | 32547 | `a6ef8cc636e2f4108799a3500402905f67195d7834b678970598c08469a8d20c` |
| `evidence/scratchpad/shots/impeccable-a/crops/phone--history-0.png` | 143682 | `76c53b4014945145bd29e97ceb9440ff35c42cc53642a639875956f07694143a` |
| `evidence/scratchpad/shots/impeccable-a/crops/phone--history-1.png` | 50342 | `77d3a568ed02c76fff30a93c7253da530164b118e095d50ec5c68c745f31b052` |
| `evidence/scratchpad/shots/impeccable-a/crops/phone--home-0.png` | 121227 | `0ef622d3c1786fec87430ddaf72f8e8c4223d5f7bb077172d783962faa4fe567` |
| `evidence/scratchpad/shots/impeccable-a/crops/phone--home-1.png` | 110113 | `e70022c9449bcc496e898f1959a4c8e09a3f95d680e74360f1b6cf4eb84f1319` |
| `evidence/scratchpad/shots/impeccable-a/crops/phone--home-2.png` | 47029 | `2a0d6ac1c64f415897fdd26ef6cf56853431087b918930e645a44e7d14901c4c` |
| `evidence/scratchpad/shots/impeccable-a/crops/phone--log-new-0.png` | 134499 | `6c98fd83e62c9a61689ceee3efc9b4ddd889ffed4def346cd981e63af0f49aa1` |
| `evidence/scratchpad/shots/impeccable-a/crops/phone--log-new-1.png` | 110113 | `d0b75f4cf8175f4b4d2c7bbe1d53c9e26862ae0409634dfde99dddeb0d3f3336` |
| `evidence/scratchpad/shots/impeccable-a/crops/phone--log-new-2.png` | 47029 | `94c4109a35b944e7cd25ce902d4b931e43c3075d84a1437b977b1846ecf7f52a` |
| `evidence/scratchpad/shots/impeccable-a/crops/phone--log-show-cardio-0.png` | 93645 | `c8433f65ce827b21594b588bbd289f9584d44108f60f30300246d029056af046` |
| `evidence/scratchpad/shots/impeccable-a/crops/phone--log-show-cardio-1.png` | 38721 | `bc98f4121321be0cb67f0c1a610da39f369b0d8bcf2b0f81924c375a0a59219f` |
| `evidence/scratchpad/shots/impeccable-a/crops/phone--log-show-lower-0.png` | 131266 | `2ff2c9701fe07264b69598a18d32ca02a7dfe62512104e41b4411e5f3b76f975` |
| `evidence/scratchpad/shots/impeccable-a/crops/phone--log-show-lower-1.png` | 80782 | `a892fd3276e278237e9d2541ef18172d258f510f6d6005fdd9be257a8ba9626e` |
| `evidence/scratchpad/shots/impeccable-a/crops/phone--log-show-restday-0.png` | 93389 | `3ea390421a0edab63450b1c0f0e6b9561bc956682f7404e07fe4b26084566c98` |
| `evidence/scratchpad/shots/impeccable-a/crops/phone--log-show-restday-1.png` | 20043 | `bb7cf1a147801a72d5400b3ba6e34f0d651c74c3616615e134f814f4ea8e23ce` |
| `evidence/scratchpad/shots/impeccable-a/crops/phone--log-show-upper-0.png` | 134034 | `f6846197126821d0160cd7384ecd94d6c5733ecdc7ba00fffc2c14f65ba6168c` |
| `evidence/scratchpad/shots/impeccable-a/crops/phone--log-show-upper-1.png` | 106832 | `c43bbbcccbe99c4bc00bdfa8ca23e3e854d6181555003443b47903280bdc34d3` |
| `evidence/scratchpad/shots/impeccable-a/crops/phone--log-show-upper-2.png` | 26225 | `359f079c3a3a015beff10c38cd787e3210f69e841d20f5e2ef11445e5a558099` |
| `evidence/scratchpad/shots/impeccable-a/crops/phone--month-0.png` | 102812 | `27358c3299cc3ce9a53674812d9327f4e93f6c6cb6c5d045d908118137273e21` |
| `evidence/scratchpad/shots/impeccable-a/crops/phone--month-1.png` | 129806 | `a0ae8b6360fba352a830654818c2316ab4dc62bed4bce135f1d6aa3bd416e751` |
| `evidence/scratchpad/shots/impeccable-a/crops/phone--month-2.png` | 31994 | `00e890196cc9d8227293c587e8a519b7d041ccdd785a7765dde13f87c3f38133` |
| `evidence/scratchpad/shots/impeccable-a/crops/phone--past-workout-upper-mon-0.png` | 109771 | `b4e8d94d89b6796671b8e3eda739f5f5de5f3ad6254dff0a00ae3aa953312982` |
| `evidence/scratchpad/shots/impeccable-a/crops/phone--past-workout-upper-mon-1.png` | 59744 | `d2ed6df1f30c27c0678c9c9eeca937677c8f24d3ce952f4c110910e6777dfb46` |
| `evidence/scratchpad/shots/impeccable-a/crops/phone--split-show-0.png` | 102247 | `7ec14f74e58b8a9cd2f0a28a6d3349e45350b7b1c4a80272cfd4a4958fd02e3e` |
| `evidence/scratchpad/shots/impeccable-a/crops/phone--split-show-1.png` | 39556 | `9599e531b4c4199969deebe1778ee8eac2ed766491400cba1e35d15623d8c1d2` |
| `evidence/scratchpad/shots/impeccable-a/crops/phone--timer-edit-0.png` | 154653 | `4e8b74ae8745b7fb045b87a63351e246d9545d8d980822f8627cbfeaa10055bc` |
| `evidence/scratchpad/shots/impeccable-a/crops/phone--timer-edit-1.png` | 50342 | `f0b60787e680f2019a7c2df272929bdecf8203d3ba09de4cf6e94b5966bab8c6` |
| `evidence/scratchpad/shots/impeccable-a/crops/phone--today-exercise-hip-thrust-0.png` | 84595 | `c5f227227aeca49adb17d0e711de9d46415541dd8e69d8dc424a7ed53910fdbe` |
| `evidence/scratchpad/shots/impeccable-a/crops/phone--today-exercise-hip-thrust-1.png` | 103271 | `5b02d1805fb9381b5f830886b0bb6257165c3641d1e99f51bbd1467492dffff9` |
| `evidence/scratchpad/shots/impeccable-a/crops/phone--today-exercise-hip-thrust-2.png` | 19369 | `40274ad07fac9af144b946d19ef0d6dc4797772378fb005345cbd894470e5244` |
| `evidence/scratchpad/shots/impeccable-a/crops/phone--today-log-0.png` | 113749 | `3bb15b0b1156b2d3a6548ef16553f2944cf75eac0ae7879b646ccc54972f0954` |
| `evidence/scratchpad/shots/impeccable-a/crops/phone--today-log-1.png` | 62187 | `f8bbbdd649a12434e56f7e2acdb21aae02f92005708def190049c9a1fffa2765` |
| `evidence/scratchpad/shots/impeccable-a/crops/phone--today-workout-lower-0.png` | 111949 | `52c50f4af87512e73417356fecf80c8ecc4444323a8cf750d1f12eb92d10654f` |
| `evidence/scratchpad/shots/impeccable-a/crops/phone--today-workout-lower-1.png` | 49470 | `e88625b2c145963c5a25696f9f3d5dd9c468f25d05d23978ffcc5335914ca0ef` |
| `evidence/scratchpad/shots/impeccable-a/crops/phone--workout-day-past-push-0.png` | 105592 | `cd12eae853a53448344508e823ae4cdc3b348c9d84a1dbc818da5472546d5952` |
| `evidence/scratchpad/shots/impeccable-a/crops/phone--workout-day-past-push-1.png` | 19244 | `d531669a51e3a3992d32ff4214ce815082b5f9a2b7559d4c527e99fbbdfe2cb3` |
| `evidence/scratchpad/shots/impeccable-a/crops/phone--workout-day-today-legs-0.png` | 109202 | `8247d5bab30b0b1edaff5776f55062faab9aff0a2d68c398f19a5929748f2417` |
| `evidence/scratchpad/shots/impeccable-a/crops/phone--workout-day-today-legs-1.png` | 14721 | `6ed703a5892fa9d0429875fac14bc052dc623f4f53ed2752dfb660479d0fe593` |
| `evidence/scratchpad/shots/impeccable-a/err-exercise-dup.png` | 121457 | `77c91702e7e354c784bb927be58337c2031261adf53d95f39294baf8f823e5fa` |
| `evidence/scratchpad/shots/impeccable-a/err-exercise-new.png` | 121417 | `bbcd9ddbeda28df98bdb6eabe26a2a8c355a5f7a80b4bd2e323644c35201ea49` |
| `evidence/scratchpad/shots/impeccable-a/err-row1.png` | 140694 | `66dba6a195db37f44e5e7d584235e249130f2f0570b8fd4bed724ebe9308f666` |
| `evidence/scratchpad/shots/impeccable-a/err-row2.png` | 220275 | `35aae1be1779a5a2c0d05767c72602bdbe597544c8c55a0e95ab5a4488c6bb86` |
| `evidence/scratchpad/shots/impeccable-a/err-set-empty.png` | 138944 | `617104f1978b36463f03dcfdfa722c9552913d9ea3114541d62c4f123d3ceff8` |
| `evidence/scratchpad/shots/impeccable-a/err-signin.png` | 59605 | `448193ed310987949073cdd7649245053e4085ebfca955c8463fcf4c3a8017a7` |
| `evidence/scratchpad/shots/impeccable-a/err-split-new.png` | 53898 | `10157ae9dab974c5c74742110611c0c84b827427c2c1db543fb67004722a0ffc` |
| `evidence/scratchpad/shots/impeccable-a/err-workout-day-new.png` | 89779 | `e37ed714d97e72572445eec6bda034d26621a60ada8f57ce5a32ff7330f6f33a` |
| `evidence/scratchpad/shots/impeccable-a/focus-actions-toggle.png` | 101388 | `51825f2ba6e7454c8efd653be62e357eb787f67c0a177ce08a05d8ebba18bfe9` |
| `evidence/scratchpad/shots/impeccable-a/focus-addset.png` | 108263 | `48a256779c2f31e53a970e9ad16a462de38b0238541607c88fdfdc833c19d190` |
| `evidence/scratchpad/shots/impeccable-a/focus-back.png` | 97887 | `11133a3c35cf6a93006e78fb089fc5276442994131133f1e50854539cffadd7a` |
| `evidence/scratchpad/shots/impeccable-a/focus-note.png` | 98424 | `5a3ea808ccc7e2747a78bb91686776a76cc58bd8d7410cd745c79093111b18d7` |
| `evidence/scratchpad/shots/impeccable-a/focus-reps.png` | 108381 | `9f92ae1d893ee672e1908877976c6dbf0c24f19c3999a026c85ada3e52611e94` |
| `evidence/scratchpad/shots/impeccable-a/focus-row1.png` | 175904 | `0e39f669c21aa5e5820a745dabf69c268f6ec1112f296dc0dfea320560ae18db` |
| `evidence/scratchpad/shots/impeccable-a/focus-row2.png` | 160181 | `a32cfe8fd2c879ea4648f7d700cfbe797e531de80e4d627c42014fd87636e758` |
| `evidence/scratchpad/shots/impeccable-a/focus-tag-pill.png` | 109614 | `efba5d3c4e4b0ae7d23f2f8ddfcea28614be5598c06be8033e22c32955ac7ef3` |
| `evidence/scratchpad/shots/impeccable-a/focus-tag-toggle.png` | 98424 | `3df86e578ff7ea54c8fd0d1d579aeb9490dd7b4e60bdbea85cf0ac6a3f095cb8` |
| `evidence/scratchpad/shots/impeccable-a/focus-weight.png` | 106768 | `1ee72628f51dae967f8314e4ec22a50f60422a112d9762db06b04b38c151156e` |
| `evidence/scratchpad/shots/impeccable-a/long-name-home.png` | 122704 | `e7c9277156ab650ddf9df7185c550822f9c7bd36c265eb9bd740a1c0503b618e` |
| `evidence/scratchpad/shots/impeccable-a/long-name-log.png` | 131848 | `ef51b585bd421823e42ca9d9b733121b03d0fb53d45f5710788a9f28cccbcf4e` |
| `evidence/scratchpad/shots/impeccable-a/long-name-workout.png` | 144978 | `2c5742aa7a2d0a4452a846c6ae0a3010a8b6a64078796253c362996c631357a8` |
| `evidence/scratchpad/shots/impeccable-a/long-row.png` | 329886 | `3f0c861c091f359edb24994658f92897da43136eee52a16c400ba57eaec7b32c` |
| `evidence/scratchpad/shots/impeccable-a/picker-group-open.png` | 72731 | `ed2ea5219c97cd5a8570d7bfb3bbef2cbded36dd3a04843ba3ac520f96c08813` |
| `evidence/scratchpad/shots/impeccable-a/rest-alert-on-add.png` | 200601 | `32e3b42485b894207650e5542522731c1eb0be7e18ff1eb6f2c8001baa2f7a64` |
| `evidence/scratchpad/shots/impeccable-a/rest-running.png` | 114340 | `a5c45c8807a6b54d7730bc375de2c14a667f4cfe861bcbbd5cad9bb028f88786` |
| `evidence/scratchpad/shots/impeccable-a/timer-after-resume.png` | 85332 | `a843c1b8948f2ee4c8cd526a854e9b77f1a03d3a430a0b2c962533f0db1c3c6a` |
| `evidence/scratchpad/shots/impeccable-a/timer-paused-alert-add.png` | 228980 | `298520be22e3fbd3785c5cbb64f35a86767a4e20d7f6a7e9c6866402669f0aa7` |
| `evidence/scratchpad/shots/impeccable-a/timer-paused.png` | 123788 | `ce281e009dd4532ab8e8b062ac965d3c7a38970e385b4830fd517e5e95bd53de` |
| `evidence/scratchpad/shots/impeccable-a/timer-row.png` | 344778 | `3bfa45c1266838b969388191d2c5502e56f50ed5df389c54b248aaf6d607fe9a` |
| `evidence/scratchpad/shots/impeccable-b/after-addset.png` | 102606 | `64adb799cac7ee7fa168a2383fdb28503ad54a1e47bc40cdc998911e1f8950a2` |
| `evidence/scratchpad/shots/impeccable-b/desktop--exercise-17.png` | 73338 | `10de48b683191295e811aadb67f08a778a3c4b95e178f2db06f34ca93230756e` |
| `evidence/scratchpad/shots/impeccable-b/desktop--home.png` | 98415 | `daf59982c9fc84f18093db52b9a925ece3b0e81e3a7e15b1b805431041788e49` |
| `evidence/scratchpad/shots/impeccable-b/desktop--workout-day-11.png` | 61900 | `40a7a8fc7888df07e5ca042b38eb743d1cfd5db8f30fa3b4beecbd2a2180f450` |
| `evidence/scratchpad/shots/impeccable-b/ov.png` | 144703 | `e0bf8fee4554f7f647e030162eb2b0077d399bb2dd72c34583e969730669a71a` |
| `evidence/scratchpad/shots/impeccable-b/phone--account.png` | 117321 | `8e35aefa6bcb41d20be8458d38df16a651d86d6f73a78c191e26c91613eaf0a3` |
| `evidence/scratchpad/shots/impeccable-b/phone--admin-equipment.png` | 95992 | `442103443db1a53072d8e990faa5f5cd76b14e3da28981473d3a409652561ffd` |
| `evidence/scratchpad/shots/impeccable-b/phone--exercise-17.png` | 90933 | `162873894181285c8fc4d85b3f130cc2e851e71f68ce2fc87dd24db19d620a6c` |
| `evidence/scratchpad/shots/impeccable-b/phone--exercises.png` | 101781 | `5c6ac9baa6fa7be60ccc48907f8274b7815e34e67426765f1066cfbd20dac544` |
| `evidence/scratchpad/shots/impeccable-b/phone--history.png` | 140234 | `c716786af963ac73aadbb142b903280e66ce4da2f5cff6cdc991f63091fae70d` |
| `evidence/scratchpad/shots/impeccable-b/phone--home.png` | 128241 | `9066edb9a96b422d59dd6f1af7cdd9dbccb6a491bb3a14c49e82ffc946385fa6` |
| `evidence/scratchpad/shots/impeccable-b/phone--log-1.png` | 140926 | `54b2a95c0171fdfb9d0b09357d70c77c19ae60abf472fcd6d6070c921031f40c` |
| `evidence/scratchpad/shots/impeccable-b/phone--log-7.png` | 119487 | `558124d6bf14856992e3cd0b77ea641c5b4a9b64201cd863a4bffbb6da74d4bf` |
| `evidence/scratchpad/shots/impeccable-b/phone--month.png` | 111447 | `2cafac52eea6ae1ca02a584db73080afe1df104e1c8612fad8a4713a648fadbd` |
| `evidence/scratchpad/shots/impeccable-b/phone--signin.png` | 45733 | `c54192144dde85a4ad0f9de32a6c6ef8f2dd052ea5c6813a19e1f9676b1c07ac` |
| `evidence/scratchpad/shots/impeccable-b/phone--split-3.png` | 103636 | `7b44254f6fe4f31250d47ac907f51257cf2b7f46ea61b429966d2b2de1fac744` |
| `evidence/scratchpad/shots/impeccable-b/phone--splits.png` | 110068 | `be8c572d4c316348cd60093168925d1fea691a519f2d2c17969f63505e97448d` |
| `evidence/scratchpad/shots/impeccable-b/phone--workout-day-11.png` | 113343 | `a26a95bc4380958e8f82f4b83c1484e99e359a91467c27e451558dbcdc28616f` |
| `evidence/scratchpad/shots/impeccable-b/picker.png` | 74032 | `8d1a3b53723ae29d2483403d01ffea9639695d91fe8a3a7e4cc01f2dbac19a45` |
| `evidence/scratchpad/shots/png/desktop--exercise-page.png` | 61496 | `81365ae666d20b38e118de645a21553391747c064b1d726fbf6ce7fc23cf5532` |
| `evidence/scratchpad/shots/png/desktop--exercises.png` | 48206 | `a1c518cb753776060c7631dcc79a3bba54e80e09fc6abb76650ff3fca34bec59` |
| `evidence/scratchpad/shots/png/desktop--history.png` | 80543 | `b171be8a2dbfacf6a4886058758cba575bad5ef86219c23901284b8e4f9c3afc` |
| `evidence/scratchpad/shots/png/desktop--home.png` | 131115 | `cd62ad7ad2d2305752f4ec4fd703a92da73871c531c774f80f45f9948e46c863` |
| `evidence/scratchpad/shots/png/desktop--log-show-upper.png` | 113276 | `1bfdc244f4db992f913dbcafe47135b5857e0a8966b7ce71cfe05d26ab5044e9` |
| `evidence/scratchpad/shots/png/desktop--month.png` | 124735 | `09daf269676e266a7e80366a6003ff7acee962d44453d4065c07d6c672d98626` |
| `evidence/scratchpad/shots/png/desktop--split-show.png` | 68059 | `664e38401ba65c0a12478e9de38244522bd4d8155432a815e81cdedd4150d88c` |
| `evidence/scratchpad/shots/png/desktop--today-exercise-hip-thrust.png` | 89361 | `4e81017bef3c37eab3eb668f78d2e592f0e850ca65e0ce88bd2a49f358a5f073` |
| `evidence/scratchpad/shots/png/desktop--today-workout-lower.png` | 77023 | `c1d200c97ea569c66dd3083cc6bcaf3be1341c895ac2721eab47869e7497b00e` |
| `evidence/scratchpad/shots/png/desktop--workout-day-today-legs.png` | 58631 | `c1c7d2155aa017362fa4fbc847bcdabc82ee19d13b0dd48e24384f44f59c8018` |
| `evidence/scratchpad/shots/png/phone--account.png` | 189243 | `0e82f072275da5672b3ab0ae11a36c35fb01ec363ac585fa207b3005ef5768a8` |
| `evidence/scratchpad/shots/png/phone--admin-equipment.png` | 188059 | `27dcfb18d91c1c433f4dd48b310bc28e7e7326f93a13e73facf88cde51c228a2` |
| `evidence/scratchpad/shots/png/phone--admin-tags.png` | 83175 | `ada15bc9b3cac196f63a746e2467211fe27edb075e245cc032cb918794afe89b` |
| `evidence/scratchpad/shots/png/phone--admin-users.png` | 70267 | `078c46f1d0f471bb7189d1ccc86dddec056293336c32978fef67ab83758f9414` |
| `evidence/scratchpad/shots/png/phone--empty--account.png` | 164341 | `a43fb080db2d01d8a2199547a09d30c999a942b5883c6919a9f4a01fb481a2bb` |
| `evidence/scratchpad/shots/png/phone--empty--exercises.png` | 95071 | `5b8d6494393b4a9abf0d1fb7143d5daa299b893ae1d3b05b0e0e28aaccce2b7d` |
| `evidence/scratchpad/shots/png/phone--empty--history.png` | 69140 | `8c341b78d0f4fa0474d4b941dc6fe25968e020cddd67610365e04e7b448b9e35` |
| `evidence/scratchpad/shots/png/phone--empty--home.png` | 150008 | `94c7fd25a9e5fc816a451f7b754a9bc70c97bc736310c407277104c03c764c70` |
| `evidence/scratchpad/shots/png/phone--empty--month.png` | 83269 | `5785de15a200fbf6efbd4c8cf2f6ca8a5943a0974f098b4911da792f97d46dc5` |
| `evidence/scratchpad/shots/png/phone--empty--splits.png` | 64903 | `466947829363dd7673263888991db5b95b7a29ad74b91c4f818ece337da0ba4c` |
| `evidence/scratchpad/shots/png/phone--exercise-edit.png` | 93320 | `2b2ec4488b4302004c17a72a49b2022f66a9b939386a34fdc180287386678c6d` |
| `evidence/scratchpad/shots/png/phone--exercise-new.png` | 141503 | `d23d26ea28c3edd5d5d2a3aec69649cf54c414feb64ac5f5df64194dee64b983` |
| `evidence/scratchpad/shots/png/phone--exercise-page--expanded.png` | 110414 | `86baa01d8e23b9f48446c1bb7bbe6f7e6cf5ddcb33da47466cd2a2ab3ff2d241` |
| `evidence/scratchpad/shots/png/phone--exercise-page.png` | 131845 | `85d274c2bd6c4fd1784c6a1c69e8b9adca4cf0983f0ea01dd030a0f84a082342` |
| `evidence/scratchpad/shots/png/phone--exercises.png` | 101729 | `bb7b1b7a22e0e0dd62f6f85ad0d147f8d9b6dbb3a7a9ece58010fd557641de41` |
| `evidence/scratchpad/shots/png/phone--history--confirm.png` | 151978 | `c0b778f1f4abaa121ffa4af45006035cb08ec3e846356f73f264848ba06ae8e6` |
| `evidence/scratchpad/shots/png/phone--history.png` | 190441 | `6e4fd77fd2befa66bbb877978bbddf7a63278f81b4dfbd21d5c2192795a0e3b4` |
| `evidence/scratchpad/shots/png/phone--home--expanded.png` | 127438 | `7209e9c06966751acc61866913df514bc7afa745dbc27721da214a46206f61e7` |
| `evidence/scratchpad/shots/png/phone--home--move-modal.png` | 74664 | `68d1c0710a88be7a351e6fcd494dc40a5f3501d9f129e4af3aaf7119d7f97392` |
| `evidence/scratchpad/shots/png/phone--home--user-menu.png` | 128241 | `9066edb9a96b422d59dd6f1af7cdd9dbccb6a491bb3a14c49e82ffc946385fa6` |
| `evidence/scratchpad/shots/png/phone--home.png` | 273054 | `7ab183438eccd23655f2210a7e7a8495cdc1ed1a4e7df98f4ee0a6fe62567f12` |
| `evidence/scratchpad/shots/png/phone--log-exercise-edit.png` | 83864 | `e8946bccbf833e70bcd701e009397d6e6eb86dc803a7b361ed4a51a3509cd1a7` |
| `evidence/scratchpad/shots/png/phone--log-new-cardio.png` | 66604 | `e2b0fd89438444879e6a03a4ab9b20deb3e351ed09f500a856eba13b775d286f` |
| `evidence/scratchpad/shots/png/phone--log-new.png` | 286430 | `d8c0691c5e4eca2191a96e5de58c5c665bfde67745d0d40330198071e46c56e4` |
| `evidence/scratchpad/shots/png/phone--log-show-cardio.png` | 129150 | `6ec725017692f7374870bd73cc71ef8f22d37dd7dc7d32f7248be12c4527ca57` |
| `evidence/scratchpad/shots/png/phone--log-show-lower.png` | 207421 | `e5c1fe0d3b330385b56420332dd5ae6ffb2e9ec6424cb1e2183364dd079b9868` |
| `evidence/scratchpad/shots/png/phone--log-show-restday.png` | 110865 | `2c11aa52e3dd8475e81df867d965a3fe70fa2547c8e65e3e9dd97137daed4f69` |
| `evidence/scratchpad/shots/png/phone--log-show-upper--expanded.png` | 122517 | `19197801c5a80d990bfb23b58435530561dca60814d15b7a14490134050116e9` |
| `evidence/scratchpad/shots/png/phone--log-show-upper.png` | 261187 | `e617fd75c7170d38be4db6346e86290b37aac23f1cfe9045207a7de16cbc9b51` |
| `evidence/scratchpad/shots/png/phone--loggedout--password-new.png` | 47259 | `21a3e93861fb6244784cad6cc5885d3849815ebb70fc6c77e79e4e5b356dbf34` |
| `evidence/scratchpad/shots/png/phone--loggedout--signin.png` | 45733 | `c54192144dde85a4ad0f9de32a6c6ef8f2dd052ea5c6813a19e1f9676b1c07ac` |
| `evidence/scratchpad/shots/png/phone--loggedout--signup.png` | 49442 | `79831684c72d86fe9637e0023257b65c223c00e829fb98e3bd192b46b8d58d6a` |
| `evidence/scratchpad/shots/png/phone--month.png` | 260137 | `9e483b4cd6c8db0a1dd1ae45e10e737543f7ecef30183d798e0120840bbaa052` |
| `evidence/scratchpad/shots/png/phone--past-workout-upper-mon.png` | 165175 | `4c5388996f85b0d84fa03bc0265cfd46099d211ebfeadbf2fc5aab1e695e13d1` |
| `evidence/scratchpad/shots/png/phone--split-edit.png` | 47978 | `aa6a1ff554cc3ef7246a913bcba4eb73c71a6c2efebb81964d4e5e406e069fe8` |
| `evidence/scratchpad/shots/png/phone--split-new.png` | 48091 | `53a116e88f7b69c84570336323331bc912af9e24cc20f04a0db57b9991a2efe9` |
| `evidence/scratchpad/shots/png/phone--split-show--picker.png` | 78659 | `d9a9a505739d73103a168aae059d999e6f9394b2674a4a9bc9ee930da55f0144` |
| `evidence/scratchpad/shots/png/phone--split-show.png` | 138943 | `5648c57829d0b686486d1ccf14f4eebc5626b666a928ff335b1059d15d4bd9a5` |
| `evidence/scratchpad/shots/png/phone--splits.png` | 98734 | `81733ba0c7d4ef4bea4843cf25489b9ebcc697419f354c53da8df336e047701c` |
| `evidence/scratchpad/shots/png/phone--timer-edit.png` | 201436 | `ee3e72074fa529ccaea5af3633e0a905e18dcb663d11a670a4f2ef979bce3a4f` |
| `evidence/scratchpad/shots/png/phone--today-exercise-hip-thrust--actions-menu.png` | 95105 | `b4b00658ce43b1c5ebce4f1d48489583e24f401998f72ce9b06186ae0a4d6061` |
| `evidence/scratchpad/shots/png/phone--today-exercise-hip-thrust--expanded.png` | 107355 | `2a1f20c0f6b8d0390050f59b0d0ca51be3f06d85aa3115125d82d22990e8b332` |
| `evidence/scratchpad/shots/png/phone--today-exercise-hip-thrust.png` | 201679 | `ac0f1a0320ee8ed64c839715bd3e9940353d706f4b4743d64cfcd8e1970bba89` |
| `evidence/scratchpad/shots/png/phone--today-exercise-todo-rdl.png` | 116919 | `c173a2d780a61f9b97e6e7a15b7e95af0ca1a9972ce7980fdad2e449f7c29642` |
| `evidence/scratchpad/shots/png/phone--today-log.png` | 170597 | `2a44471a6ae3052a3dcafeeddbb2d02e4608191576c23c2b42c509a95c13e2a5` |
| `evidence/scratchpad/shots/png/phone--today-workout-lower--picker.png` | 78659 | `d9a9a505739d73103a168aae059d999e6f9394b2674a4a9bc9ee930da55f0144` |
| `evidence/scratchpad/shots/png/phone--today-workout-lower.png` | 157302 | `b03f081b28ed26ac48808f846cdfd6c4804998635bfbe56293b282a05057e29b` |
| `evidence/scratchpad/shots/png/phone--workout-day-edit.png` | 74712 | `c456365486a0cbe95a91c1c8a06d2b22afcc99f630a5d727ef80aa3a6c24cfde` |
| `evidence/scratchpad/shots/png/phone--workout-day-future-upper.png` | 51988 | `103687e1a9cf113e90dd9895a500034d8f3314e92e0ff9f9211360f42365e2a7` |
| `evidence/scratchpad/shots/png/phone--workout-day-new.png` | 80194 | `4b5997288ab58bf151d702122d2097c3eb5914c40e48837b4bd902e5f6f6d2a3` |
| `evidence/scratchpad/shots/png/phone--workout-day-past-push.png` | 121657 | `5e1272cc1890fcb865aa403935c21ad54d2b0b686d78c035dd04069586dcdac2` |
| `evidence/scratchpad/shots/png/phone--workout-day-today-legs--picker.png` | 78659 | `d9a9a505739d73103a168aae059d999e6f9394b2674a4a9bc9ee930da55f0144` |
| `evidence/scratchpad/shots/png/phone--workout-day-today-legs.png` | 121005 | `2e0f050fa28eb2f364e1c4aa376caf630615923a3d4a91db75f97d97db602fa7` |
| `evidence/scratchpad/shots/shoot.mjs` | 7785 | `53f69541549e4209c0b81e58848424e503ff2db339f0281f632577295c2d6453` |
| `new-look/DIRECTION.md` | 28916 | `9096d8c17615d03b1bea3220aaf760d626482019aea450b6634a8c92cbb0cd52` |
| `new-look/ds-dark.png` | 269482 | `bd6d7a3b6543a9c875a38f49dcae1440c7ca9d719522be66c1bf28c3c2059da6` |
| `new-look/ds-light.png` | 265989 | `218e54df0ddb09db987613427a5e31362787b77a743f935a07e1c845bdb29c30` |
| `new-look/frame-exercise-dark.png` | 195679 | `9ca584108c194b5831e98d12c15d757b0238778fbd7c1caa2d7de9481acd428c` |
| `new-look/frame-exercise-light.png` | 195334 | `4f783d9e9135b05f9e1ed18a551cc76429b528da4bed506e0ef08a0331e3d596` |
| `new-look/frame-history-dark.png` | 168354 | `951cd818356ea357bce114c65cf7ff60754d02e143cb48fae7c76500e5b25c8e` |
| `new-look/frame-home-dark.png` | 279206 | `494f520be68b21a2703a5e61041f47479eeeffd468f072416a28a5d27708de68` |
| `new-look/frame-home-light.png` | 278544 | `170e15e8b73d8b26f357f55d09ea88180c14dfb869bc0d88d4408eba23716ca3` |
| `new-look/frame-picker-dark.png` | 85939 | `b3a7a4d70265482a0056d7d6d6ca10b8f9e0efe80a38874fa5c57500fffff716` |
| `new-look/frame-picker-light.png` | 87703 | `14bc257bb7f6fd63874742d23d5ad4185635899573c13f9e355debf69e975617` |
| `new-look/frame-workout-dark.png` | 162860 | `f11d26924047fc5c38256173a54cb43c98019d9fb3e3d4f5d100663f92c66ee1` |
| `new-look/m390-ds-dark.png` | 278836 | `ea02cc9ea333c7a34502432fa629a8ac44a082cb1c46216939070f8f3a009db3` |
| `new-look/m390-head-light.png` | 74859 | `5938383240b8aa7cd2bd22f155907f70962d0846041f45f0b5c6b987e9584d48` |
| `new-look/readout-concept.html` | 79983 | `7f8319a50336fa616a2d9442ff63914345dbc78c0a18a389e690c71b1a1a1629` |
| `new-look/shot-1440-dark.png` | 709740 | `2ef6bd1abd2273ede90af35f1067c4f79682d6e22eda7310108e0c25be8eef6f` |
| `new-look/shot-1440-light.png` | 707964 | `08997f88010e46f23c05034ef299519b7303e56062e7604470718a69246d80ef` |
| `new-look/shot-390-dark.png` | 697340 | `70c4468c99e7dfad57caed745bd35a64b64f71aed930fc57a5d76b611e533d58` |
| `new-look/shot-390-light.png` | 692372 | `a81e783c6998426a13e856944dd5c7124fa932b2ba08d129d303d4c50f8f6f74` |

## 9. The embedded files

In this order: the merged owner report, the brief, the reviewers' hand-backs, report A, report B, report E, the Readout direction doc. The concept HTML (`new-look/readout-concept.html`), screenshots, JSON and scripts are files only; their hashes are in the inventory.

<!-- BEGIN VERBATIM FILE: README.md | bytes: 15884 | sha256: bc024571a4213feb54e11d32d6a480d39d01868f05c582346bdb7c98e6a5b28f -->
# Design audit: the whole app (2026-11-25)

Four reviews of every page, at phone width (390 px, and 320 px for overflow) and desktop width (1280 px), on a copy of the development database. Nothing in the app's code or the development database was changed.

| Review | Skill | Result | Full report |
|---|---|---|---|
| Design review: hierarchy, type, spacing, colour, copy, page by page | Impeccable (critique) | **25/40, Acceptable** (P0 0 · P1 8 · P2 17 · P3 14) | [1-impeccable-design-review.md](1-impeccable-design-review.md) |
| Technical audit: detector, contrast, touch targets, a11y, performance, theming | Impeccable (audit) | **15/20, Good** (P0 0 · P1 3 · P2 12 · P3 7) | [2-impeccable-technical-audit.md](2-impeccable-technical-audit.md) |
| Polish, motion, mobile feel, worst-case data | Emil Kowalski (emil-design-eng, review-animations, mobile-native, break-ui) | No P0, 8 P1, 13 P2, 24 P3. All 29 animations reviewed one by one | [3-emil-polish-review.md](3-emil-polish-review.md) |
| New look: minimalist, futuristic, simple | taste-skill (design-taste-frontend + minimalist-ui) | Concept "Readout", light and dark | [new-look/readout-concept.html](new-look/readout-concept.html), [new-look/DIRECTION.md](new-look/DIRECTION.md) |

Screenshots of every page as it is today are in [evidence/scratchpad/shots/png/](evidence/scratchpad/shots/png/); every other file the reviewers made (their screenshots, scripts, detector JSON and measurements) is under [evidence/scratchpad/](evidence/scratchpad/). The precise handover for the next agent is [HANDOVER-PROMPT.md](HANDOVER-PROMPT.md).

## Verdict

The app is carefully built. Inputs are 16 px so iOS doesn't zoom, touch targets are 44 px, every number field has `inputmode`, safe areas are handled, the clocks use tabular figures, reduced motion is respected, every text colour passes AA, and the colour tokens are named by role. The detector found no "AI template" patterns: no gradient text, glows, nested cards or buzzwords.

What keeps it from looking professional and minimalist comes down to four things, which all three reviewers found independently:

1. **Too much on each item.** A logged set is three rows: the numbers, a 44 px "Tag" pill, and a note field with a blue arrow. An exercise row has a drag grip, a sets chip, a pencil and a second chevron button, which leaves the name about 70 to 110 px. With real data, names wrap one word per line or break mid-word ("Stationar/y bike"), and an exercise page with 14 sets is 3,500 px tall.
2. **Bootstrap defaults leak through the design.** Cards, inputs and modals are the same grey as the page, separated only by a 1.14:1 hairline. Checkbox borders are 1.14:1, the focus ring is 1.1 to 1.46:1, `.text-muted` is a second grey, and simple_form paints a green ✓ on every pre-filled field, even after a wrong password.
3. **Indigo is on everything.** `#4F46E5` marks primary buttons, pens, note arrows, set numbers, unset choices, the active split ring and the calendar, so nothing stands out as the next thing to press. The number a lifter actually reads (`60 kg`) is 15 px regular text.
4. **Built for mouse, not thumb.** Hover effects aren't limited to mouse devices, so a tag pill you untick still looks ticked. Android shows its blue tap flash everywhere except the tab bar. Only the timer, the back arrow and the tab bar react when pressed. Motion is Bootstrap's defaults: 350 ms folds, modals that drop in from 50 px above, and 500 ms flash cards.

## Priority issues (merged and ranked)

Most of these were found by more than one reviewer. Tags: **A** = Impeccable design review, **B** = Impeccable technical audit, **E** = Emil.

### P1: major (fix before anything else)

1. **The Add set button is below the fold and moves after every set** (A, B, E). Each set row is 171 to 197 px. With 3 sets, the weight field starts at y = 933 to 1,473 on an 844 px phone, and after each set it slides under the tab bar. Opened without `?date=`, the page jumps back to the top.
   - Fix: one 48 px row per set. Note and Tag go into the set's ⋯ menu, and a note shows as text only when there is one (`workout_sets/_set.html.erb:55-88`).
   - Fix: put the add-set form above the sets, or keep it pinned at the bottom.
   - Fix: redirect back to the page the form came from, so the page keeps its scroll.
   - This is the action you repeat 15 to 25 times a workout, one-handed, so it matters most.
2. **Exercise names squeezed to 70 to 110 px** (A, B, E). In `workout_days/_planned_exercise.html.erb:4-17` and `workout_logs/show.html.erb:55-71`:
   - Remove the boxed chevron button, since the row is already a link; leave a plain 12 px muted chevron.
   - Put the sets chip on the meta line.
   - Move the admin pen and × into ⋯.
3. **Surfaces are the page colour** (A, B). Add a `$surface: #FFFFFF` token and set `$card-bg`, `$input-bg`, `$modal-content-bg`, `$dropdown-bg` and `$list-group-bg` to it in `config/_bootstrap_variables.scss`. The 14 literal `white`s become the token.
4. **Controls you can't see** (A, B; WCAG 1.4.11).
   - Checkbox and radio borders are 1.14:1, including the picker's exercise checkboxes. Fix: `$form-check-input-border: 1.5px solid #8A919E`.
   - Input borders are 1.32:1. Fix: `$input-border-color: #B9BFC9` on white fields.
   - The focus ring is 1.1:1 on `btn-light` (44 uses) and 1.46:1 elsewhere. Fix: `$focus-ring-opacity: 1`, plus a 2 px ring with a 2 px white gap.
5. **Long names push the page sideways** (B, E; WCAG 1.4.10).
   - The split-name chip in Recent workouts is `white-space: nowrap` (`components/_lists.scss:36`). A 58-character name makes Home 410 px wide on a 390 px phone, and 377 px wide at 320 px. Fix: `max-width: 100%; overflow: hidden; text-overflow: ellipsis`.
   - Editing a set at 320 px overflows by 67 px, because the rest, Save and Cancel bar doesn't wrap (`_set.html.erb:93-113`).
6. **Green "valid" ✓ on fields nobody submitted** (A, B). It shows on every edit form and on Account, and after a wrong password it marks the email field as correct. Fix: remove `valid_class: 'is-valid'` from `config/initializers/simple_form_bootstrap.rb` (10 wrappers) and set `input_field_valid_class = nil`.
7. **Sticky hover and no press feedback on touch** (E, B).
   - Limit every hover to mouse devices with `@media (hover: hover) and (pointer: fine)`, including Bootstrap's button hovers.
   - Add `-webkit-tap-highlight-color: transparent` and `touch-action: manipulation`.
   - Give every button an `:active` press of `scale(.97)` over 160 ms with `cubic-bezier(.23,1,.32,1)`.
8. **The exercise picker has no search** (A, E). Its muscle groups are 12 px uppercase labels that don't look tappable, and an admin sees a red × beside every row.
   - Add a search field fixed at the top of the picker that filters as you type and opens the groups that match. When nothing matches, it fills "Create your own" with what you typed.
   - Style the groups like the catalogue page: 16 px, weight 600, not uppercase.
9. **Three taps per set when you use the rest timer** (A). The sequence is Add set, then "Save rest?", then Start rest. This one changes behaviour, so it's your call.
   - Save the measured rest without asking, and ask only when the rest is over 10 min (a forgotten timer).
   - Optionally add a setting, "Start rest after each set".
   - Show the rest clock at 36 px as m:ss, not `0:00:04` at 22 px.
10. **The confirm box always shows a trash can and says "Yes"**, even for "Stop the timer?" (E; `shared/_confirm.html.erb:5`, `confirm_dialog.js:24`). Fix: take the icon and the verb from the action ("Stop", "Delete").
11. **The full-screen picker's "Add selected" sits under the iPhone home indicator** (E). Fix: give the modal footer `padding-bottom: calc(1rem + env(safe-area-inset-bottom))`.
12. **Changing a preference asks for your current password** (A). The automatic timer and warm-up options live in Devise's account form. Fix: a separate Preferences card that saves when you tick a box, using the existing `auto_submit_controller.js`.

### P2: minor (next pass)

- **Type**:
  - The SCSS declares 21 font sizes, four of them within 1 px (12, 12.48, 12.8 and 13 px). Fix: an 8-step scale of `.75 / .8125 / .875 / 1 / 1.125 / 1.375 / 1.75 / 2.25rem` (A).
  - Inter weight 700 is never loaded, so 14 selectors and every `<strong>` get a browser-faked bold. Fix: load the 700 weight, or use 600 (A).
  - Logged weight and reps should be 20 px, weight 600, with a small muted `kg` (A).
- **Colour**:
  - Keep indigo for the one primary action per screen. Make pens, note arrows, set numbers and unset choices muted (A, E).
  - Use one grey for secondary text: `$secondary-color: $muted` (A, B).
  - Tags use Bootstrap's grey `#6C757D` and a third pill style; give them the `.choices` look (A).
- **Motion** (E):
  - Use one curve, `$ease-out: cubic-bezier(.23,1,.32,1)`.
  - Folds go to 220 ms (Bootstrap uses 350 ms `ease`).
  - Modals scale in from `.96` over 200 ms instead of dropping 50 px over 300 ms.
  - Flash cards take 320 ms in and 200 ms out (now 500 ms each way, with `ease-in-out` out).
  - Drag and drop takes 200 ms with the curve set.
  - Remove the card hover lift, the backdrop blur and the flash countdown bar.
  - Make Turbo's progress bar indigo, not its default blue `#0076ff`.
- **Spacing**:
  - The gap after the calendar and the timer card is 40 px, against 16 px everywhere else (`_dashboard_calendar.scss:2`, `_timer.scss:4`).
  - List rows use four different vertical paddings, labels come in two styles and toggle pills in three (A).
- **The flash card covers the back arrow for 5 s after every set** (A). On a phone, move it to the bottom, above the tab bar. Once the new set row lights up, the flash after Add set isn't needed at all (E).
- **Numbers**: 99,999.125 kg wraps in the middle of the number on Home and the Month page, and there's no thousands separator. Right-align weights in set tables with tabular figures (E).
- **Empty workouts count as "last time"** (A). "Last time · Nov 21 · 0 exercises · 0 sets", while the calendar says Nov 20 was missed.
- **The calendar has no legend on a phone** (A, E). Its tooltips never show on touch, and the "extra" ring is 2.6:1 and looks like "today".
- **The same workout uses different words on two pages** (A). "Still to do" vs "From this day, not in this workout", green vs grey sets chips, pen vs ⋯, chevron-right vs chevron-down. Use one row component and one set of words.
- **"Delete workout" sits in the header of every logged workout** (A). Move it to the end of the page.
- **Technical error messages** (A): "Reps completed can't be blank and Reps completed is not a number". Use one plain message per field.
- **The exercise page doesn't show last time's sets** (A). One muted line would do: "Last time Wed 18 Nov: 120×8 · 110×8 · 100×10".
- **The Equipment form is fully open on every exercise page during a workout** (A). Fold it to one row: "Equipment · Machine · Bull ›".
- **Admin pages** (A): Equipment and Set tags have no title, no back arrow and no active tab, and the Users row actions touch the card edge.
- **Not installable** (E):
  - There is no `theme-color` and no manifest, so the app can't open full screen from the home screen.
  - Every page is titled just "FitnessApp" (B).
- **Font Awesome** (B): it uses `font-display: block` and a 158 KB font, and the CSS carries 1,962 icon rules for the 26 icons used.
- **Account tab opens the keyboard every time** (B).
- **Text at 200% zoom overflows 5 pages** (B).

### P3: polish

There are 45 small items across the three reports, each with its exact value. The highlights:

- Remove the 12 uppercase "eyebrow" labels.
- Change Rails' button labels ("Update Split") to plain ones ("Save split").
- Use three radii instead of seven (10 for controls, 16 for cards and sheets, round for chips).
- Make borders semi-transparent (`rgba(#101828,.08)`), and use a border or a shadow on cards, not both.
- Balance heading wrap with `text-wrap: balance`.
- Make the active split ring thinner.
- Show dates with the weekday ("Wed 25 Nov").
- Show the split chip in Recent workouts only when it isn't the active split.
- Delete the dead tokens `$orange` and `$notice`.
- Remove the obsolete `shrink-to-fit=no`.

## The new look: "Readout"

Open [new-look/readout-concept.html](new-look/readout-concept.html) in a browser. It shows five phone screens with your real data: Home, today's workout with the timer running, the Hip thrust page while logging, History, and the Add exercises picker. It has light and dark themes and the full design system.

- **Idea:** the phone as a gym instrument. Surfaces are graphite and off-white, separated by 1 px lines instead of shadows. Every number (weight, reps, clock, stats, dates) is set in **Geist Mono**, like a display. Everything else is set in **Geist**.
- **One signal colour, orange** (`#FF5A1F` light, `#FF6A2B` dark). It marks only what is live (running timer, today) and the one button to press next (Start or Continue, Add set, Add exercise, Add selected). Everything else is monochrome.
- **Dark mode** follows the phone's setting through Bootstrap 5.3 colour modes, with no toggle and no JavaScript.
- **Big readouts:**
  - the workout clock is 56 px mono
  - weights and reps are 22 px mono
  - the add-set fields are 56 px tall, with `kg` inside the field
- **Fewer boxes:** rows are whole links, rest between sets is a dotted line, and the calendar keeps its four day states with a legend.
- **Every function and every text stays.** Only three things move:
  - the Exercises button goes into the top bar
  - the Today button becomes full width
  - boxed row buttons become whole-row links
- [DIRECTION.md](new-look/DIRECTION.md) has every token as SCSS, ready for `config/_fonts.scss`, `_colors.scss` and `_bootstrap_variables.scss`. It also has a table of what changes per component and a 9-step migration order. It keeps the security policy (Google Fonts are already allowed, and there are no inline styles) and adds no JavaScript libraries.

## Suggested order

1. **The P1 fixes, which hold whatever the look** (most of them are layout and Bootstrap variables). Start with the exercise page (one row per set, Add set in reach), the exercise rows, surfaces and control contrast, overflow, and the green ✓. Then touch feedback and the picker search. These are in `/impeccable layout`, `colorize`, `harden` and `distill`.
2. **Decide on Readout.** If you take it, do steps 1 and 2 of its migration together. On its own, step 1 turns every indigo accent orange, including links and calendar fills, which step 2 makes ink. Do the motion and type P2s inside it rather than on the current look.
3. **The P2 and P3 polish pass**, then run `/impeccable audit` and `critique` again to measure the change.

## How this was done

- **Server:** the app ran from this worktree on port 3001 against `fitness_app_design_audit`, a copy of `fitness_app_development`, with the password `auditpass123` set only in the copy.
- **Test data:** to have today's workout to look at, the copy got a workout logged today (Lower, with Hip thrust and Squat sets and the timer started). The reviewers also added worst-case data there: long names, 14 sets, 17 exercises, 99,999.125 kg and a 3-hour timer.
- **Screenshots:** headless Chrome over CDP, 63 base captures plus about 100 more from the reviewers.
- **Impeccable detector:** ran on 13 pages at 390×844 and 3 at 1280×800 while logged in. It found 1 real layout bug (`text-overflow`), 1 false positive (`pulsing-dot`, the real running-timer dot), and `overused-font` (Inter and Plus Jakarta Sans).
- **Not checked:** a real iPhone or Android phone (sticky hover, safe areas and the keyboard were emulated), a screen reader, the touch drag gesture, and the production CSS size. The Readout SCSS was not compiled against the app.

<!-- END VERBATIM FILE: README.md -->

<!-- BEGIN VERBATIM FILE: evidence/scratchpad/audit-brief.md | bytes: 3119 | sha256: f78d66018dec370fef16736a2ea4d52d52b48a3692b1c4b42d7d57b11d63bde4 -->
# Design audit brief (shared by every reviewer)

## The app
A Rails 8.1 workout tracker used on a phone at the gym. The owner: "I go to the gym, log my workouts and what I did for the day, and then that's it." Top priority: a very intuitive, simple UI: few taps and little typing to log a set on a phone.

- Repo (READ ONLY, never edit, never commit): `/home/pedro/code/pqdesu/fitness_app/.claude/worktrees/opus-plan-session-e72fa6`
- Read first: `CLAUDE.md` (product rules + code map) and `doc/Prompt/project-context.md` (product brief, page flows).
- Stack: Bootstrap 5 + SCSS (`app/assets/stylesheets/`: `config/` tokens, `components/`, `pages/`, order in `application.scss`), ERB views in `app/views/` (79 files), helpers in `app/helpers/`, Stimulus controllers in `app/javascript/controllers/`, layout `app/views/layouts/application.html.erb`.
- Constraints any recommendation must respect: content security policy forbids inline `style=` attributes and inline scripts; Hotwire (Turbo morphs, Stimulus), no React. Product rules in CLAUDE.md are fixed (planning layer, catalogue, admin role stay).

## Running app (for you to look at)
- URL: `http://127.0.0.1:3001` (a copy of the dev database: `fitness_app_design_audit`; you may click and add data there freely; it is disposable). Do NOT touch port 3000 (the owner's server) or the `fitness_app_development` database.
- Logins (password `auditpass123`): `admin@example.com` (admin, 3 splits, real history, active split U/R/L/U/L); `notadmin@example.com` (no data: use it for empty states).
- Today is Wednesday 2026-11-25. Today's workout is `/workout_days/11` (Lower), already started: timer running, Hip thrust (3 sets) and Squat (2 sets) logged, the rest still to do.

## Screenshots already taken (look at these first; phone ones are 390 CSS px wide at 2x)
Folder: `/tmp/claude-1000/-home-pedro-code-pqdesu-fitness-app--claude-worktrees-opus-plan-session-e72fa6/d91907ca-cfc9-418e-acc7-1a8504a66bda/scratchpad/shots/png/`
- `phone--<page>.png`: full-page phone captures of every GET page (admin user).
- `phone--<page>--<state>.png`: one viewport with a state open (picker modal, user menu, move modal, ⋯ menu, all folds expanded, confirm box).
- `phone--empty--*.png`: the no-data user. `phone--loggedout--*.png`: sign in, sign up, password reset.
- `desktop--*.png`: 1280 wide.
- Screenshot script (headless Chrome over CDP, Node 26): `.../scratchpad/shots/shoot.mjs`. To drive the app yourself, copy its approach (login, navigate, click, capture) with your own debugging port given in your task, and save extra screenshots under `.../scratchpad/shots/<your-name>/`. Node 26 is `~/.nvm/versions/node/v26.13.1/bin/node`; Chrome is `/usr/bin/google-chrome`.
- No horizontal overflow was found at 390 px on any page.

## Output
Write your full report as Markdown to the path given in your task. Cite every finding with file:line and/or the screenshot name. Be exhaustive: the owner asked for every small detail. Group by severity (P0 blocking, P1 major, P2 minor, P3 polish). Keep recommendations concrete (exact values: px/rem, colors, weights, durations).

<!-- END VERBATIM FILE: evidence/scratchpad/audit-brief.md -->

<!-- BEGIN VERBATIM FILE: evidence/reviewer-handbacks.md | bytes: 15138 | sha256: 277fcbb9161c4e21a20a64f9fa38727d74314de6f3bd67c68d73126f78d15528 -->
# Reviewer hand-backs (the final message each reviewer sent when it finished)

Copied as received, without the two-space indent the harness added. These are summaries; the full reports are the source of truth.

## Emil Kowalski review (emil.md)

The Emil-style review is finished. Full report: /tmp/claude-1000/-home-pedro-code-pqdesu-fitness-app--claude-worktrees-opus-plan-session-e72fa6/d91907ca-cfc9-418e-acc7-1a8504a66bda/scratchpad/reports/emil.md
My screenshots are in /tmp/claude-1000/-home-pedro-code-pqdesu-fitness-app--claude-worktrees-opus-plan-session-e72fa6/d91907ca-cfc9-418e-acc7-1a8504a66bda/scratchpad/shots/emil/ (names starting `wc-`, `vp-`, `wc320-`, `wcdesk-`). Nothing blocks use (no P0); there are 8 P1 findings.

Summary:
1. A long split name (58 characters) in a chip that never wraps (`_lists.scss:36`) makes Home 410 px wide on a 390 px phone and is cut off in History (`wc-home.png`, `wc-history.png`).
2. Editing a set on a 320 px phone makes the page 387 px wide, because the rest, Save and Cancel bar doesn't wrap (`_set.html.erb:93-113`, `vp320-exercise-editing.png`).
3. In exercise rows, the trailing chip, pencil and chevron button take about 55% of the width, so names get about 70 px. Words break mid-word: "Stationar/y bike" happens even with catalogue data. The chevron button repeats the row link (`_planned_exercise.html.erb:4-17`, `workout_logs/show.html.erb:55-71`).
4. Each set takes three rows: the numbers, a 44 px "Tag" pill, and a note input with a blue button. 14 sets make the page 3,534 px tall, and a 158-character note is unreadable in a one-line input (`_set.html.erb:55-87`).
5. On a phone, Bootstrap's hover stays after a tap, so a tag pill you untick still looks ticked. Many of the app's own hovers are not limited to mouse devices either: card lift, week circle, calendar fill, back arrow.
6. Android's blue tap flash shows everywhere except the tab bar. Press feedback (`scale(.97)`) exists only on the timer buttons, the back arrow and the tab bar.
7. The confirm box always shows a trash can and says "Yes", even for "Stop the timer?" (`_confirm.html.erb:5`, `confirm_dialog.js:24`).
8. The full-screen exercise picker has no safe-area padding, so on an iPhone the home indicator sits over "Add selected".
9. Motion is mostly Bootstrap defaults: folds take 350 ms with `ease`, modals drop 50 px over 300 ms, flash cards take 500 ms in and 500 ms out (`ease-in-out` on the way out), and drag and drop runs 150 ms with no curve set. Copy the confirm box's settings everywhere (`cubic-bezier(.23,1,.32,1)`, 200 ms, `scale(.96)`). Remove the card hover lift, the backdrop blur and the flash countdown bar.
10. The app has no theme-color tag and no manifest, so it can't run as a home-screen app without browser bars. Turbo's progress bar shows its default blue `#0076ff`, not the app's indigo.
11. 99,999.125 kg wraps inside the number ("99999. / 125") on Home and the Month page, and weights have no thousands separator.
12. Already correct: inputs are 16 px (checked in the browser), every number field has `inputmode`, there are no `vh` units, the navbar and tab bar use safe areas, the clocks use tabular figures, reduced motion is respected, and the breathing dot is justified.
13. The report has a table of all 29 transitions and animations with keep, retune or remove for each, four places where motion would help, a mobile-native checklist, and 17 worst-case results with their screenshots.
14. It ends with the 10 changes with the biggest effect, led by "one row per set" and "one tap target per exercise row".

Data and checks:
- All test data went into the disposable audit database through port 3001: split 4, workout day 14, workout log 8 (17 exercises, 14 sets on entry 21) and plan row 26. Two `rails runner` updates also ran against `fitness_app_design_audit` only: the timer was backdated 3 hours, and one set got a 3-hour rest and all three tags.
- That split is not active, so Home still follows the U/R/L/U/L split. However, its Full Body workout today now appears in Home's Recent workouts, "This week" and the calendar, and in History, so other reviewers will see it.
- Not checked: a real iPhone or Android phone (sticky hover, safe areas, the keyboard), RTL, 200% zoom, non-Latin text.
- My Chrome on port 9343 is stopped. The repo was not edited.

## taste-skill new look (DIRECTION.md, readout-concept.html)

I built "Readout", a standalone concept for the app's new look, checked it in headless Chrome at 1440 and 390 in both themes, and wrote the direction doc. Nothing in the repo was touched. The Chrome on port 9344 is closed.

**The concept in 10 lines**
1. The idea: the phone works like a gym instrument. Surfaces are graphite and bone, separated by 1px lines instead of shadows. Every number (weights, reps, clock, stats, dates) is set in Geist Mono, like a display. Everything else is set in Geist.
2. One colour carries meaning: signal orange (#FF5A1F light, #FF6A2B dark). It marks only what is live (running timer, today) and the one button to press next (Start workout / Continue, Add set, Add exercise, Add selected). Everything else is monochrome. Choices that are settings (muscle group, equipment) are filled in ink, not orange.
3. Dark mode is a true graphite (#0E0F10). In the app it follows the phone's setting through Bootstrap 5.3 colour modes, with no toggle and no JavaScript. The toggle on the concept page is only there to show both themes.
4. Big readouts: the workout clock is 56px mono with dimmed colons, a breathing ring on the live dot, and a thin line under the clock that fills once a minute. Weights and reps are 22px mono, and the add-set fields are 56px tall with the unit inside the field.
5. Fewer boxes: cards have no shadows. Rows are whole links with a quiet chevron, so the boxed "›" and "Open" buttons go. Rest between sets is a dotted line reading "Rest 2 min 5 s". The calendar keeps its four day states: planned is ink fill, missed is a dashed ring, extra is a thin ring with a dot, and today has an orange ring.
6. The five screens use real data from the audit database: Home, today's Lower workout (timer running, Hip thrust 3 sets, Squat 2 sets, 5 still to do), the Hip thrust page (60×12, 80×10, 90×8, rests of 2 min 5 s), History, and the Add exercises picker as a bottom sheet.
7. Every function and every text from the current app stays. I kept the admin pen and × and the rest-day, Deleted and split badges. Only three things move around: Home's Exercises button goes into the top bar, the Today box's button becomes full width, and boxed row buttons become whole-row links.
8. The system panel on the page shows the palette with hex for both themes (contrast noted), the type scale, a 4px spacing scale, radii (6/10/12/16/22, round only for small pills and day dots), borders and the one shadow (sheets only), motion curves and durations, the icon style, and all the asked states. Those are button rest, hover, pressed, focus and disabled, field focus, and the timer's idle, running, paused and finished. There is also an empty state and the Today box before the workout starts, with Start workout.
9. `DIRECTION.md` has the full token set as SCSS ready for `config/_fonts.scss`, `_colors.scss` and `_bootstrap_variables.scss`, a per-component table, and a 9-step migration order. Step 1 also fixes the 8 existing lines that pass colours through `rgba()`, which would break with the new tokens.
10. It respects the constraints: no inline styles or scripts, Turbo/Stimulus unchanged and no new JS libraries, and fonts stay on Google Fonts, which the security policy already allows. Swapping Font Awesome for an outline SVG sprite is an optional last step that only removes code.

Decision for you: on Home I showed the Today box after training started ("Logged today", Continue), because that matches the real data. The "Start workout" version of the box is in the states panel, not on the Home screen.

Not checked:
- I did not run the taste skill's gate or checker. They are built for marketing pages and would fail an app screen.
- I did not compile the SCSS against the app. In particular, Bootstrap's dark-mode variable names and the eight `rgba()` lines are only reviewed, not built.

Risk: in step 1, every indigo accent turns orange, and some of them (links, calendar fills, choice buttons) must become ink in steps 2 and 6. Don't ship step 1 on its own.

Files are in /tmp/claude-1000/-home-pedro-code-pqdesu-fitness-app--claude-worktrees-opus-plan-session-e72fa6/d91907ca-cfc9-418e-acc7-1a8504a66bda/scratchpad/new-look/: index.html, DIRECTION.md, shot-1440-light.png, shot-1440-dark.png, shot-390-light.png, shot-390-dark.png, frame-home-light.png, frame-home-dark.png, frame-workout-dark.png, frame-exercise-light.png, frame-exercise-dark.png, frame-history-dark.png, frame-picker-light.png, frame-picker-dark.png, ds-light.png, ds-dark.png, m390-ds-dark.png, m390-head-light.png. The screenshot script is .../scratchpad/new-look-shoot.mjs.

## Impeccable Assessment A, design review (impeccable-A.md)

## Assessment A (design review): Acceptable, 25/40

I scored the whole app at 25/40, in the "Acceptable" band. I found 0 P0, 8 P1, 17 P2 and 14 P3 issues. Every flow I drove works end to end.

**Design specificity:** the app is carefully engineered but reads as generic Bootstrap, not as a gym logger with its own look. The pre-filled Add set form and the workout timer are the authored parts. Indigo `#4F46E5` is used on almost everything, and the number a lifter reads (`60 kg`) is set at body size, 15px Inter 400.

**Heuristic scores:** Visibility of system status 3 · Match with the real world 3 · User control and freedom 3 · Consistency and standards 2 · Error prevention 3 · Recognition rather than recall 2 · Flexibility and efficiency 2 · Aesthetic and minimalist design 2 · Error recovery 2 · Help and documentation 3.

**Top 5 issues:**
1. P1: the Add set button is out of reach. Each logged set row is 171 to 197px tall, mostly an always-visible Tag pill and note field. With 3 sets, the form starts at y=933 on an 844px phone. After each set it slides under the tab bar (measured y=632 to 771, tab bar at 784). When the page URL has no `?date=`, the page jumps to the top instead. Fix: compact each set to one row and move Tag and Note into the set's ⋯ menu, or put the form above the list of sets.
2. P1: cards, inputs and modals are the same colour as the page (`#F6F7F9`). Bootstrap 5.3 takes their background from `$body-bg`. Surfaces are separated only by a 1.14:1 hairline. Fix: set `$card-bg`, `$input-bg` and `$modal-content-bg` to a new white `$surface` token.
3. P1: controls fail contrast. Checkbox and radio borders are 1.14:1, including the picker's exercise checkboxes. Input borders are 1.32:1 and the focus ring is 1.46:1.
4. P1: the exercise picker has no search. Its muscle groups are 12px uppercase labels that don't look tappable, and an admin sees a red × beside every row.
5. P1: logging a set costs three taps while the rest timer is used. The sequence is Add set, then a "Save rest" confirm, then Start rest. The rest clock is 22px and reads `0:00:04`.

Other P1 issues: exercise names in workout rows are squeezed to about 100px (long names wrap one word per line); fields show a green "valid" tick on pages nobody has submitted, and after a wrong password the email field and "Remember me" turn green; changing a preference (automatic timer, warm-up tag) requires your current password.

System findings: the SCSS declares 21 font sizes, four of them (12, 12.48, 12.8 and 13px) within 1px of each other. Inter weight 700 is never loaded, so 14 selectors and every `<strong>` get a browser-synthesised bold. Labels come in two styles and toggle pills in three. List rows use four different vertical paddings. The gap after the calendar and after the timer card is 40px, against 16px between other cards.

Not checked: a real phone, screen readers, the Edit timer page for a timed workout, the rest-day Today box, and the cardio timer running.

Data added to the audit database (3001 only): sets 4 and 5 on today's Hip thrust, a paused-then-resumed timer, and a long-named exercise in today's workout. Another reviewer's data (a 99999.125 kg set and a Full Body workout today) shows in my later screenshots.

Files: reports/impeccable-A.md (the full report), shots/impeccable-a/ (30 extra screenshots, plus crops of the tall phone shots in crops/), impeccable-a-scripts/ (the CDP scripts).

## Impeccable Assessment B, technical audit (impeccable-B.md)

Assessment B is done: the score is **15/20 (Good)**. Each dimension scored 3/4: Accessibility, Performance, Theming, Responsive and Implementation Integrity. The integrity verdict is PASS.

Counts by severity: P0 0 · P1 3 · P2 12 · P3 7.

Top 5 issues:
1. [P1] Checkboxes are nearly invisible. Their border is 1.14 to 1.23:1 (WCAG 1.4.11). It affects Account settings, Remember me, and the picker's Unilateral and Shared boxes. Fix: `$form-check-input-border: 1px solid $muted`.
2. [P1] Keyboard focus is hard to see. The ring on `btn-light` (44 uses) is about 1.1:1; other Bootstrap controls are 1.47:1. Fix: `$focus-ring-opacity: 1` plus a `btn-light` focus colour.
3. [P1] Home scrolls sideways at 320 px. A `white-space: nowrap` split-name chip in Recent workouts is 377 px wide (WCAG 1.4.10). The chip style is in `_lists.scss:36`.
4. [P2] Every pre-filled simple_form field shows a green "valid" ✓. Examples: Account email, Rename split. The cause is `valid_class: 'is-valid'` in `config/initializers/simple_form_bootstrap.rb`.
5. [P2] Add set is far below the fold on the exercise page. With 3 sets, the weight field is at y=1473 on an 844 px phone; each set row is 171 to 197 px tall. Once there, adding a set keeps the scroll.

Detector results: Source scan: `detect app/views` on a directory scans no `.erb` or `.scss` files; listing the files explicitly found only `overused-font` (Inter and Plus Jakarta Sans). Rendered scans: all 16 CDP scans worked (13 pages at 390×844, 3 at 1280×800), with no fallback needed. `text-overflow` on 2 logged-workout cards is a real bug: the name column is 110 px wide. `pulsing-dot` is a false positive: the dot marks a timer that is really running, and reduced motion turns it off. There was 1 advisory `straggler`.

Other things worth knowing: every text colour pair passes AA, and every control has an accessible name. One root cause, Bootstrap and simple_form defaults the colour tokens never overrode, explains 6 findings: cards and fields are the page grey, and `.text-muted` is not the `$muted` token. Every page is titled just "FitnessApp".

Data changed: while testing scroll after Add set, 2 sets (95 kg × 6) were added to Hip thrust (`/workout_exercises/17`) in the audit database. The repo was not touched, and the Chrome on port 9342 is closed.

Not checked: the touch drag gesture, the decimal comma on a real phone, and production CSS size (dev assets only were measured).

Files: reports/impeccable-B.md, shots/impeccable-b/ (screenshots), impB/run/ (detector JSON in `det/`, measurements in `meas/`).

<!-- END VERBATIM FILE: evidence/reviewer-handbacks.md -->

<!-- BEGIN VERBATIM FILE: evidence/scratchpad/reports/impeccable-A.md | bytes: 76057 | sha256: b8fe57173efcf86b5257fcf08a32417ac8d6a408a15da2251d15d2ade8bdb808 -->
# Impeccable critique, Assessment A (design review)

Method: design review only (Assessment A). The detector (`impeccable detect`) was not run or read; Assessment B covers it.

- App: `http://127.0.0.1:3001`, database `fitness_app_design_audit`, today Wednesday 2026-11-25. The repo was only read, never edited.
- Evidence: every screenshot in `.../scratchpad/shots/png/` (63 shots: phone first, then desktop), plus 30 of my own in `.../scratchpad/shots/impeccable-a/`. I drove those with headless Chrome over CDP on port 9341, using scripts in `.../scratchpad/impeccable-a-scripts/`.
- Measured: computed styles, WCAG contrast ratios (computed, not guessed), and where the Add set button sits before and after a set is added.
- Data I added to the audit database:
  - Sets 4 and 5 of Hip thrust today.
  - A paused and then resumed timer on today's Lower.
  - An exercise with a long name in today's workout: "Single-arm cable rear delt fly with rope attachment (slow eccentric)".
  - Another reviewer seems to have added a 99999.125 kg set and a Full Body workout today. Those show in my later shots.

Long folders are written as `.../scratchpad`. In full that is `/tmp/claude-1000/-home-pedro-code-pqdesu-fitness-app--claude-worktrees-opus-plan-session-e72fa6/d91907ca-cfc9-418e-acc7-1a8504a66bda/scratchpad`.

---

## 1. Design specificity verdict

**Verdict: this is a careful, well-engineered Bootstrap app, not a gym logger with its own visual identity.** If you swap the dumbbell logo for a different icon, it could be a task tracker or a CRM. The care is real but invisible:

- 44px touch targets everywhere.
- The paused-timer and rest alerts, a "breathing" Running pill and tabular numbers.
- Comments in the SCSS that give the reason for every value.

The visual layer is the category default:

- Inter and Plus Jakarta Sans.
- An indigo `#4F46E5` primary.
- 16px-radius cards with a hairline border and a 2%-opacity shadow.
- Lowercase muted eyebrows above every heading.
- Uppercase tracked group labels in the picker.
- Bootstrap's outline-secondary pills.

**What is authored for the gym:**

- The Add set form comes pre-filled with the last set, so repeating a set is one tap.
- The workout timer card: status pill, a 32px tabular clock, and a full-width Pause / Stop row on the phone.
- The week strip of seven circles, and the calendar with planned, missed and extra states.
- 16px fields, so an iPhone does not zoom into them.
- "Weight then reps" everywhere.

**What fights the gym moment:**

- The set table spends about 70% of each set's height on controls (a Tag pill, a full-width note field and a blue arrow). Those controls get used maybe once in twenty sets.
- The number the lifter cares about (the weight, `60 kg`) is set at body size, 15px Inter 400. It is the same size as "Add a note".
- The rest clock, the thing read "at arm's length from the bench" (the code's own comment, `_workout_log.scss:99`), is 22px and sits inline next to the word "Rest".

**Missed opportunities for product character:**

- Numbers as heroes: the weight × reps of the set just done, the rest countdown, and the session total.
- A visible "last time" for this exercise on the exercise page.
- One strong accent kept for the single action of each screen. Today indigo goes on everything: four blue note arrows, Add set, the chips, links, calendar fills and the Change and Month links.

**Surfaces are not separated.** Bootstrap 5.3 derives `$card-bg` and `$input-bg` from `$body-bg`, which the app sets to `$light-gray` (`config/_bootstrap_variables.scss:7`). So every card, input and modal is `#F6F7F9`, the same as the page (computed: `.card` and `.form-control` background are `rgb(246,247,249)`). The flash file's comment says "white cards like the rest of the app" (`components/_flash.scss:1`), so the intent was white. Only `.btn-light`, the choice rows and the bottom bar are white. The result:

- White buttons float on grey cards.
- The card and page read as one flat grey plane, separated only by a 1.14:1 hairline.

This one variable is the biggest single visual fix in the app.

---

## 2. Heuristic scores (Nielsen, 0 to 4)

| # | Heuristic | Score | Key issue |
|---|-----------|-------|-----------|
| 1 | Visibility of system status | 3 | Good: flash notices with a countdown bar, timer pills (Running, Paused, Finished), a live clock, "Set 4 added." The calendar calls Nov 20 "Upper missed", while History and Recent list that same Upper (0 exercises, 0 sets) as a workout. Fields show a green "valid" tick on pages nobody has submitted. |
| 2 | Match with the real world | 3 | Mostly gym language: Weight, Reps, Rest, Warm-up, Drop set. Leaks: "Rest ~min", "Reps completed can't be blank and Reps completed is not a number", "Day must be one of the listed workouts" (the field is "Workout"), "Deleted" (meaning the split), "Create Workout day". |
| 3 | User control and freedom | 3 | One back arrow, Cancel on forms, Esc and Cancel on set edits, confirms before deletes. There is no undo after a confirmed delete. "Delete workout" is a primary-position red button on every logged workout. |
| 4 | Consistency and standards | 2 | The same workout has two pages with different words and controls (`workout_days/11` vs `workout_logs/7`). Labels come in two systems, pills in three. Page headers lay out three ways. Admin Equipment and Set tags have no tab and no title ("FitnessApp"). Button labels: "Create Split" and "Update Workout day" next to "Save". |
| 5 | Error prevention | 3 | Last set pre-filled, numeric keypads, confirms. On the other side: a red × beside every catalogue row in the picker, right next to the checkbox you tap; a valid-green field after a failed login; an example placeholder ("Bench press") that looks like a value. |
| 6 | Recognition rather than recall | 2 | The picker has no search: you must know which muscle group holds "Hip thrust" and open that fold. The exercise page does not show last session's sets for that exercise. The calendar has no legend, so you must remember what filled, dotted and light ring mean. |
| 7 | Flexibility and efficiency | 2 | Pre-fill is a real accelerator. But: Start rest is a separate tap after every set, a confirm on every set while the rest runs, Add set drifts under the tab bar after each set, and changing a preference (automatic timer, warm-up tag) needs your current password. |
| 8 | Aesthetic and minimalist design | 2 | Each logged set is 171 to 197px tall, mostly a Tag pill and a note field (measured). Workout rows carry three or four trailing controls, squeezing names to a single word per line. The Equipment card sits on every exercise page during the workout. |
| 9 | Error recovery | 2 | Simple forms show red inline errors with an icon (good). The set form shows errors in a flash, with column names and duplicated. Devise hints are in lowercase ("leave it blank if you don't want to change it"). The workout-day error names the wrong field. |
| 10 | Help and documentation | 3 | Short inline help where it matters ("Legs and Lower are the same workout under two names", "For this week only…", empty states that teach the next step, calendar tooltips). There is no help page, which is fine for this scope. |
| **Total** | | **25/40** | **Acceptable** (20 to 27): significant improvements needed before the app is pleasant at the gym. |

---

## 3. System inventory and inconsistencies

### 3.1 Type

**Families:** Inter (body), Plus Jakarta Sans (headings, brand, clocks, stat numbers), Font Awesome 6 (solid and regular). They are loaded by `layouts/application.html.erb:12`.

**Faux bold.** Inter is loaded at **400, 500 and 600 only**, and Jakarta at 600, 700 and 800. Computed `document.fonts` shows exactly Inter 400/500/600 and Plus Jakarta Sans 700. Every Inter 700 is a browser-synthesised bold:

- `.exercise-group` (`_list_toggle.scss:51`)
- `.calendar-head` (`_dashboard_calendar.scss:34`)
- `.calendar-day.is-planned`, `.is-missed`, `.is-extra`, `.is-today` (`:60-66`)
- `.week-overview-name` (`_dashboard_week.scss:50`)
- `.picker-group` (`_exercise_picker.scss:9`)
- `.sign-toggle` (`_workout_log.scss:76`)
- `.rest-clock` (`_workout_log.scss:100`)
- every `<strong>` and `<b>` (for example "Signed in as **admin@example.com**", the rest clock, the timer's paused figure)

Fix: add `;700` to the Inter family in the font URL, or change these to 600.

**Base size.** `$font-size-base: .9375rem` (15px, `_bootstrap_variables.scss:8`). Inputs are 16px. Body text is below the 16px floor that `typeset.md` gives for ordinary web body text, and this is a phone read at arm's length.

Every font-size declared in the app's SCSS (rem at 16px):

| px | Where |
|----|-------|
| 11.0 | `.bottom-nav-item` `.6875rem` (`_bottom_nav.scss:21`) |
| 11.2 | `.chip-day` `.7rem` (`_timer.scss:139`); bottom-nav `.user-initial` `.7rem` (`_bottom_nav.scss:55`) |
| 12.0 | `.picker-group`, `.calendar-head`, `.timer-status`, `.week-label`, `.week-summary dt` and `small`, `.move-days small`, `.app-table th`, chevrons (`.75rem`) |
| 12.48 | `.chip`, `.inline-form .form-label`, `.inline-form .choices-field legend` (`.78rem`) |
| 12.8 | `.eyebrow`, `.order-badge`, `.user-initial`, `.history-counts`, `.recent-counts`, `.today-last`, `.week-moves-note`, `.today-moved`, `.set-rest-row`, badges (`.8rem` and `.8em`) |
| 13.0 | `.timer-meta` `.8125rem` |
| 13.6 | `.link-quiet`, `.toggle-days`, `.lift-sets`, `.btn i` (`.85rem` and `.85em`) |
| 14.0 | `.calendar-day`, `.recent-notes`, `.rest-picker` (`.875rem`) |
| 14.4 | `.flash-text`, `.confirm-detail`, `.lift-pill`, `.auth-card a`, `.brand-mark` (`.9rem`) |
| 15.0 | body |
| 16.0 | inputs, `.actions-toggle`, `.back-link`, `.auth h2` |
| 16.8 | `.card h2` `1.05rem` (`_cards.scss:5`) |
| 17.6 | `.confirm-title` `1.1rem`, `.hero p` |
| 18.0 | `.navbar-page-title` `1.125rem` |
| 18.4 | `.modal-title`, `.bottom-nav-icon`, `.confirm-icon` (`1.15rem`) |
| 20.0 | `.today-title`, `.week-summary dd` (`1.25rem`) |
| 22.0 | `.rest-clock` `1.375rem` |
| 24.0 | `.auth-card h1` `1.5rem` |
| 25.6 | `.empty-state > i` `1.6rem` |
| 28.0 | `.page-header h1` `1.75rem` |
| 32.0 | `.timer-clock` `2rem` |

**There are 21 sizes, with three clusters that cannot carry different jobs:**

- **12.0 / 12.48 / 12.8 / 13.0** (four sizes within 1px). Table heads, chips, form labels, eyebrows and timer meta all differ by fractions of a pixel. Collapse them to one 12px "label" role and one 13px "meta" role.
- **13.6 / 14.0 / 14.4.** Collapse to 14px.
- **16.8 / 17.6 / 18.0 / 18.4.** Card h2, confirm title, top-bar title and modal title. Collapse to 18px.

**Proposed fixed scale** (ratio about 1.2, per `operate.md`), with nine roles:

| px | Role |
|----|------|
| 12 | label, caps |
| 13 | meta |
| 14 | small |
| 16 | body (raise from 15) |
| 18 | card title |
| 22 | numeric |
| 28 | page title |
| 36 | rest and timer clock |
| 48 | the live rest clock while resting |

**Weights in use:** 400, 500 (10 declarations), 600 (26), 700 (14), 800 (3, Jakarta only), plus Bootstrap `fw-semibold` ×5 and `fw-normal` ×3, and `$headings-font-weight: 700`, `$btn-font-weight: 600`. Five weights is fine; the faux 700 is not.

**Headings:** 31 `h1`, 34 `h2`, 3 `h3` in views. The `h1` is always 28px with -0.02em tracking (computed -0.56px), with two exceptions:

- Devise pages: 24px (`_auth.scss:8`)
- Account: 28px inside a card, so the page has its h1 *inside* a card with a 2rem card padding. That is the only page laid out this way.

**Label systems (inconsistent).**

- simple_form labels are 15px, weight 400, near-black. Computed: "Name", "Muscle group", "Date", "Notes", "Email".
- inline-form labels are 12.48px, weight 600, `$muted`. Computed: "Weight kg", "Reps", "Exercise name", "Equipment", "Kind" (`_tables.scss:25-30`).

The same "Equipment" label is 15/400/dark on `exercises/new` (`phone--exercise-new-0`) and 12.5/600/muted on the exercise page (`phone--today-exercise-hip-thrust-1`). The same fold row "Free weight" is dark 16px on `exercises/new` and muted 600 13px on `workout_log_exercises/edit`.

**Placeholders.** The placeholder colour computes to `rgba(28,32,36,.75)`, the same as `.text-muted` text. Example placeholders therefore read as real values:

- "Bench press" (picker, `exercises/new`)
- "Push / Pull / Legs" (`splits/new`)
- "Dumbbell" (`admin/equipment`)
- "Warm-up" (`admin/tags`)
- "Add a note" ×N
- "How did it go?"

See `phone--split-new`, `phone--today-workout-lower--picker`, `phone--admin-equipment-0`.

**Two muted greys.** Bootstrap 5.3's `.text-muted` uses `--bs-secondary-color` = `rgba(body, .75)` (computed). `$text-muted: $muted` (`_bootstrap_variables.scss:22`) is therefore dead. Custom CSS uses `$muted #646B78`, while 49 `text-muted` uses in views get `#5C5F64`-ish. Set `$secondary-color: $muted` (5.3 name) or `--bs-secondary-color`.

**Numerals.** `tabular-nums` is applied in tables, the calendar, the timer, the week summary and `.top-set` (good). It is not applied to the set weight cell when it is a `span` outside `.app-table` (it inherits there, fine), and not to `.month-list` numbers (`_dashboard_month.scss`) or `.history-counts`.

### 3.2 Spacing

Values in use: `.125, .1875, .2em, .25, .3, .375, .4, .5, .625, .7 (pointer:coarse btn-sm), .75, .875, 1, 1.125, 1.25, 1.5, 1.75, 2, 2.5, 3, 3.25, 4rem`. That is 22 values.

Off any 4px grid: `.1875` (3px), `.3rem` (4.8px, `_dashboard_recent.scss:72`), `.4rem` (6.4px, `.order-badge` padding `_lists.scss:50`, `.week-overview-days li` `_dashboard_week.scss:41`, `.chip-day` `_timer.scss:138`), `.7rem` (11.2px, `_layout.scss:90`). Also `.375 / .625 / .875 / 1.125`: 6, 10, 14 and 18px are a 2px scale mixed with a 4px one.

**List row vertical padding: four values for the same "row in a card" job.**

| Padding | Where |
|---------|-------|
| `.875rem` | `.list-rows li` (`_lists.scss:12`), `.recent-toggle` (`_dashboard_recent.scss:16`) |
| `.75rem` | `.exercise-group` (`_list_toggle.scss:49`), `td` (`_tables.scss:14`), `.rest-start-days li` (`_dashboard_moves.scss:38`) |
| `.625rem` | `.month-list li` (`_dashboard_month.scss:12`), `.picker-row` (`_exercise_picker.scss:21`), `th` (`_tables.scss:7`) |
| `.4rem` | `.week-overview-days li` (`_dashboard_week.scss:41`) |

**Card body padding: five values.**

| Padding | Where |
|---------|-------|
| `1rem 1.25rem` | Bootstrap default with `$card-spacer-x: 1.25rem`; `.timer-body` (`_timer.scss:11`) |
| `1.125rem 1.25rem .5rem` | `.today-header` (`_dashboard_today.scss:8`) |
| `2rem` | `.auth-card .card-body` (`_auth.scss:6`) |
| `2.5rem 1.5rem` | `.empty-state`, and `1.5rem` for `.compact` (`_empty_state.scss:3,10`). The horizontal 1.5rem breaks the 1.25rem card gutter. |
| `1.5rem 1.25rem 1.25rem` | confirm modal (`_confirm.scss:19`) |

**Uneven gaps between cards.** `.calendar-card { margin-bottom: 1rem }` (`_dashboard_calendar.scss:2`) stacks with `.card + .card { margin-top: 1rem }` (`_cards.scss:7`). That gives 2rem (about 40px measured) above Recent workouts and above Totals, against 16px between every other pair of cards. See `phone--home-1` and `phone--month-0`. `.timer-card { margin-bottom: 1rem }` (`_timer.scss:4`) does the same before the first card under it.

**Inner right edges are not aligned in the set table.** On a phone the last cell's padding is `.75rem` (`_workout_log.scss:62`), so the note field and its blue arrow end 8px further right than the header date, the ⋯ and the Add set button, which sit on the card's 1.25rem gutter. See `phone--today-exercise-hip-thrust-0`, right edge x=365 vs 357 CSS px.

**Big gap after the drag handle.** In workout rows the handle is 44px wide with a -14px margin, then a 16px gap, so the name starts about 54px from the handle's glyph. That wastes about 30px of a 342px row on the narrowest column. See `phone--today-workout-lower-0`.

### 3.3 Colour

Tokens: `config/_colors.scss` (good discipline: every colour named by role, AA notes in comments).

**Hard-coded and leaked values:**

- `#fff` at `_lists.scss:87`, and the literal `white` at 13 places (`_bottom_nav.scss:10`, `_confirm.scss:13`, `_layout.scss:53,80`, `_choices.scss:38`, `_dashboard_recent.scss:54`, `_split_week.scss:28,51,59,64`, `_dashboard_calendar.scss:60,67,74,79,85`, `_navbar.scss:2,61`, `_flash.scss:29`). These should become a `$surface` token, and that token is exactly what the cards are missing.
- **Bootstrap's own grey `#6C757D` leaks** through `btn-outline-secondary`, used on the tag pills, the Tag toggle and the ± sign (`workout_sets/_set.html.erb:22,62,73`, `_form.html.erb:139,170`). It is not in the palette. Text contrast is 4.37:1 on the page, which fails AA at 13px.
- **Valid green.** simple_form uses `valid_class: 'is-valid'` (`config/initializers/simple_form_bootstrap.rb:44,59,69,…`), so `$success` teal `#12A594` paints borders, ticks and labels. That includes "Remember me" after a *failed* login (`impeccable-a/err-signin.png`): 2.87:1 as text, and the wrong message.
- **Unused tokens:** `$orange` / `$warning`, `$notice` / `$info`. `$notice #3E63DD` is a second blue close to `$blue #4F46E5`.

**Contrast (computed on page `#F6F7F9`):**

| Pair | Ratio | Verdict |
|------|-------|---------|
| Checkbox and radio border `#E6E8EC` (`$line`) | 1.14:1 | **Fails 3:1** (1.4.11). Picker checkboxes, Remember me, Unilateral, "Add to the shared catalogue", account settings, Move modal radios. |
| Input border `#D5D9E0` with input bg = page bg | 1.32:1 | **Fails 3:1**. The field edge is the only thing that marks a field. |
| Focus ring `rgba(79,70,229,.25)` (Bootstrap box-shadow) | 1.46:1 | **Fails 3:1** for a focus indicator. See `impeccable-a/focus-row1.png`. |
| `$extra-ring #8C93F0` (off-plan day ring) | 2.60:1 (2.46 on this week's tint) | Fails 3:1. It is the only thing that marks an extra workout. |
| Outline-secondary `#6C757D` text | 4.37:1 | Fails 4.5 at 13px. |
| Valid green `#12A594` text | 2.87:1 | Fails. |
| `$muted` on page / on `$primary-soft` | 5.00 / 4.74 | Pass. |
| Done chip, rest chip, chip, blue on page, white on blue | 5.52 / 5.31 / 8.34 / 5.87 / 6.29 | Pass. |

**Colour dosage.** Indigo marks every one of these at once:

- the primary CTA, links, the active tab, chip-tag, order badges, `badge-soft`
- calendar fills, the week fills, the active split ring
- the pen icons, the choice-current values ("Not set" in blue)
- the note-save arrows, one per set

On the exercise page with 3 sets there are **five solid indigo blocks** (three note arrows, one exercise-note arrow, Add set) competing for the thumb. Add set should be the only solid indigo on that screen.

### 3.4 Radii

| Radius | Where |
|--------|-------|
| `.25rem` | focus, `.toggle-days` |
| `.5rem` | `sm`, `.nav-link`, `.order-badge` |
| `.625rem` | base, `.brand-mark` |
| `.75rem` | `.choice-summary` (`_choices.scss:37`), `.sortable-drag`, bottom-nav focus. **Not a token.** |
| `.875rem` | `lg` |
| `1rem` | cards, flash, `xl` |
| `1.5rem` | confirm, `xxl` |
| `999px` | pills |
| `50%` | circles |

Nine steps where five would do: 8 / 12 / 16 / 24 / pill. The choice rows (`.75rem`) sit next to fields (`.625rem`) and buttons (`.625rem`) on the same form, with a visibly different radius (`phone--today-exercise-hip-thrust-1`: "Type of machine" row vs the "Bull" field).

**History and Users tables:** the card's top corners render square because the `thead` background is not clipped. `.app-table` sits in a `.card` without `overflow: hidden`. See `phone--history-0` (y about 357) and `phone--admin-users`. Fix: `.card > .table-responsive:first-child, .card > .app-table:first-child { border-top-left-radius: inherit; border-top-right-radius: inherit; overflow: hidden }`, or `overflow: hidden` on those cards.

### 3.5 Shadows

| Shadow | Where |
|--------|-------|
| `0 1px 2px rgba($shadow,.04)` | cards (`_cards.scss:3`), back link |
| `0 6px 20px rgba($blue,.12)` | card-link hover |
| `0 10px 30px .14, 0 2px 6px .06` | flash |
| `0 20px 50px .25` | confirm |
| `0 .75rem 1.75rem .18` | drag copy |
| `0 0 0 2px $blue` | active split ring |

These are five unscaled elevations, which is acceptable, but the card shadow at 4% is invisible. With cards the same colour as the page, the cards have no depth at all.

### 3.6 Borders

`$line #E6E8EC` (1.14:1) on cards, rows, the table, the nav and the toggles. `$line-strong #D5D9E0` on fields. The active split card uses a 2px ring plus a border, which reads as a 3px blue frame, the heaviest border in the app. It is also on an empty-state "Active split" card for a user with no splits (`phone--empty--home-0`).

### 3.7 Icons

Font Awesome 6 Free, solid, with two regular icons mixed in (`fa-regular fa-clock` in History, `fa-regular fa-note-sticky`). Sizes:

- inherit
- `.85em` inside buttons (`_layout.scss:75`)
- `1rem` (actions)
- `1.15rem` (bottom nav)
- `1.6rem` (empty states)
- `.75rem` (chevrons)

**Pen icons that are not ⋯ menus.** The pen in workout-day rows is an admin-only "rename catalogue exercise" (`workout_days/_planned_exercise.html.erb:13-16`). Placed there, it reads as "edit this exercise in my workout" on a page where everything else is about the workout (`phone--today-workout-lower-0`). The History pen means "edit timer". The same glyph does two different jobs.

**Icon accessibility:** `<i class="fa-solid fa-plus">` in Add set has no `aria-hidden` (`workout_sets/_form.html.erb:161`). Neither do the chevron and pen in `_planned_exercise.html.erb:15,17`, nor the brand mark (`shared/_navbar.html.erb:25`).

### 3.8 Buttons

Variants in views:

| Variant | Count |
|---------|-------|
| `btn-light` | 44 |
| `btn-sm` | 40 |
| `btn-primary` | 32 |
| `btn-link` | 6 |
| `btn-outline-secondary` | 5 |
| `btn-outline-primary` | 3 |
| `btn-outline-danger` | 3 |
| `btn-lg` | 2 |
| `btn-danger` | 1 |

There are three visual languages for "pill-ish choice":

1. **Choices** (`shared/_choices`): indigo outline, 44px, `.625rem` radius rectangles (muscle group, equipment, Kind).
2. **Tag pills:** `btn-outline-secondary rounded-pill`, Bootstrap grey.
3. **Chips:** soft-fill, 999px (display only).

Tags and choices are the same interaction (tap to toggle) but look unrelated. The Tag toggle's focus state is a *filled dark grey pill* (`focus-row2.png`, panels 2 and 3), which looks exactly like a selected tag.

Primary labels mix Rails defaults ("Create Split", "Update Split", "Create Workout day", "Update Workout day", "Update Exercise") with plain verbs ("Save", "Add", "Add set", "Update" on Account). Make them sentence case and specific: "Create split", "Save split", "Add workout day", "Save exercise".

### 3.9 Cards and rows

The **workout row pattern** (`workout_days/_planned_exercise.html.erb`) is: handle (44px), name and meta link, sets chip, pen (admin) or × (extra), and a bordered chevron button. That is five elements. The name link and the chevron button go to the same URL (`:6` and `:17`), so the chevron is a duplicate target.

The **logged-exercise card** (`workout_logs/show`) is: handle, name, meta and top set, a grey sets chip (not the green one), ⋯, and a bordered chevron fold button. The two pages show the same object with different chips (green "3 sets" vs grey "3 sets"), a different action (pen vs ⋯) and a different chevron meaning (right = open vs down = fold).

**Fold toggles as bordered white 44px boxes** (split days, logged exercises) carry more visual weight than the card title. A bare chevron in a 44px hit area would do.

---

## 4. Page-by-page findings

### Home (`phone--home-0/1/2`, `phone--home--expanded`, `desktop--home`)

- **Eyebrow "Today" above an h1 that is the date** (`pages/dashboard.html.erb:10`). `craft-floor.md` bans eyebrows outright. The top bar already says "Home", and the h1 says the date. Drop the eyebrow everywhere (12 views, listed in §3.1), or fold it into the h1 ("Today, Wednesday 25 Nov").
- **The "Exercises" button sits under the date**, before the Today box (`dashboard.html.erb:14`). On a phone it is the first tappable thing in the content and has nothing to do with today. Move it into the Account tab or the History page, or make the catalogue a fifth tab.
- **The Today box:**
  - "Lower day" (18px) with Continue at top right, 44px tall, `btn-primary` default width (`phone--home-0`).
  - Continue is the single most important action of the whole app and is a small button at the top right, out of thumb reach. Make it full width (`d-grid`) under the summary, 52px tall, 17px/600.
  - "5 sets" is an underlined link in the middle of a muted sentence. It is the only underlined link in the app (other links are bare blue), so it looks like a different control.
- **"Last time · Saturday, November 21 · 0 exercises · 0 sets · Lower in U/R/L/U/L".** "Last time" points to an empty workout whose timer was started (7:57 to 7:58 AM, 2 s). It tells the lifter nothing and hides the real last Lower, Nov 18, with 7 exercises and 19 sets. A log with no sets should not count as "last time" for lifts.
- **Active split card:**
  - The 3px indigo frame is the strongest element on the page, stronger than the Today box. The active split is context, not the action. Reduce it to the standard card, with a "U/R/L/U/L · Active" header.
  - "Move a workout" is right-aligned on its own row, leaving a 200px empty strip.
  - The ↔ icon is FA `arrows-left-right` at text size.
- **Week strip:** "S" Sunday has a light ring (extra) but no label under it. Off-plan days show no workout name, so you can't tell what was done. Labels are 12px/600.
- **"This week" tiles:**
  - "Top weight 110 kg" uses an 800-weight Jakarta number with a 12px muted "kg". That is fine, but with a large value it wraps mid-number ("99999." / "125 kg", `impeccable-a/long-row.png` panel 2). Add `white-space: nowrap` on `dd` and `font-size: clamp()`, or let the tile span two columns.
  - "Cardio 45 min 50 s" sits on its own row, breaking the four-across grid.
- **Calendar (`phone--home-1`):**
  - Four visual states (filled, dotted, light ring, ring around today), plus the current-week tint, plus greyed other-month days. There is **no legend**; meaning lives in `title` tooltips, which touch screens never show.
  - The light ring is 2.6:1.
  - Days are 36px circles (known gap, below 44px).
  - A missed day is a link (good), but a dotted circle does not read as tappable.
  - Fix: add a one-line legend under the grid (four mini swatches, 12px: "Planned · Missed (tap to log) · Extra · Today"), and raise `$extra-ring` to at least `#6E76EA` (3.4:1).
- **Recent workouts:** each row shows the name, the date in "November 25, 2026" format (no weekday), sets, and a chip on its own line. On a phone the chip row makes each item 100px tall, and five items about 500px. The split chip "U/R/L/U/L" is repeated on every row: show it only when it differs from the active split.
- **Gap rhythm:** 40px above Recent workouts vs 16px elsewhere (§3.2).
- **Desktop (`desktop--home`):** the calendar takes the left column, so reading order starts with the calendar, not today. The Today box is in the right column with a 28px-tall Continue button (no coarse pointer). Swap them: Today plus Active split on the left (primary), calendar on the right.

### Move a workout modal (`phone--home--move-modal`)

- Full-screen on a phone, with a footer CTA in the thumb zone (good).
- The radio circles are almost invisible (1.14:1).
- "WHICH WORKOUT" and "MOVE TO" are uppercase tracked labels, a third label style.
- Day buttons: "Today / Lower", "Thu / Free", "Fri / Upper", "Sat / Lower". It is unclear whether the second line is what is there now or what will be there. Use "Thu · empty" / "Fri · has Upper".
- The modal is grey (`#F6F7F9`) because of the card/modal-bg issue, while the confirm modal is white. Two modal colours.

### Today's workout (`phone--today-workout-lower-0/1`, `desktop--today-workout-lower`, `impeccable-a/timer-row.png`)

- **Header:** h1 "Lower", then "Today · Wednesday, November 25", then a bold "2 exercises · 5 sets" line. The "Plan" button (white, 44px) is vertically centred on the three lines, so it floats beside the date, not the title. What "Plan" does is unclear. It goes to the split page; call it "Edit plan" or move it into a ⋯ menu.
- **Timer card:** the best-designed component. Pill, clock, Pause and Stop full-width row. Notes:
  - Stop is an `outline-danger`, the same weight as Pause. Fine, since it is confirmed.
  - "Started 10:28 PM · paused 4 s" is 13px muted.
  - Paused state (`timer-row` panel 2): a "Paused" amber pill, an amber "for 0:00:02" (`rest-text`, 600), and the clock dimmed to `$muted`. Clear.
  - The clock is `0:46:31` with an hours digit. For a gym session that is fine.
- **"In this workout · 2" with "+ Add exercise"** (primary) in the header. Good placement for discoverability, but it is a top-of-card button. On a long workout it scrolls away; a duplicate full-width "Add exercise" at the end of the list (as `workout_logs/show` has) would help.
- **Rows are squeezed** by the trailing controls: the green "3 sets" chip, the pen (admin) and a 44px bordered chevron. The meta "Machine · Bull · Legs" wraps to three lines ("Machine ·" / "Bull · Legs"). On the Legs day (`phone--workout-day-today-legs-0`) "Machine · Bull · Added to this workout" wraps to five lines, about 18 characters per line. The long-name test (`impeccable-a/long-row.png` panel 1) wraps one word per line over seven lines.
- Fix:
  - Drop the chevron button (the whole row is already the link `row-link`, `_planned_exercise.html.erb:6`). Show a 12px `fa-chevron-right` in `$muted` as an affordance at the end of the row.
  - Move the sets chip under the name, on the meta line.
  - Move the admin pen into a ⋯ or the exercise page.
  - Reduce the handle's gap (margin-right 0, gap .25rem).
- **"No sets"** is plain muted text in a row that elsewhere has a chip. Use a neutral chip, "0 sets", for rhythm.
- **The red × on "Added to this workout" rows** sits 40px from the chevron and 90px from the sets chip. A red destructive glyph inline in a list you tap to open things is a slip hazard, even with the confirm. Put it into ⋯ with "Remove from workout".
- **"Still to do · 5":** same row pattern, without the chip. Good. Dragging a to-do row in is clever but undiscoverable; the 44px grip is the only hint, with `title` only.
- **"Everything planned is in this workout."** is shown as a card with a single centred line. Fine.
- **Picker (`phone--today-workout-lower--picker`, `impeccable-a/picker-group-open`):**
  - **No search field.** Nine groups are folded by default, and you must know which group holds the exercise.
  - The groups are **UPPERCASE 12px/700 tracked letters**, which read as section labels, not as rows you can open.
  - In an open group (panel 1 of `timer-row.png`), the row checkbox has a 1.14:1 border, so the rows look like plain text.
  - An admin sees a red × at the end of every row, five in a column.
  - "Create your own" asks for name and muscle group. "Other" is preselected and filled indigo, so the most prominent element in the form is a default nobody chose.
  - Fix: a sticky search input at the top of the modal body. It filters across groups and shows matches flat; typing a name that does not exist offers "Create 'xyz'". Show the groups as 16px/600 sentence-case rows with a count chip (like `exercises/index`). Move the admin × into the exercise's edit page or a long-press ⋯.

### Exercise page (today, `phone--today-exercise-hip-thrust-0/1/2`, `--expanded`, `--actions-menu`, `desktop--today-exercise-hip-thrust`, `impeccable-a/rest-running`, `after-add-set-flash`, `after-add-with-date`)

This is the peak screen of the app. Findings in the order of the thumb's path:

1. **Each logged set is 171 to 197px tall** (measured tbody heights 171, 197, 196). Of that, the numbers row is about 50px. The rest is the rest line (about 22px), a 44px Tag pill on its own line, and a 44px note field with a blue 44px arrow. With 3 sets, Add set starts at y=933 on an 844px screen (measured), so the first view of a resumed exercise **does not show the Add set button**. Fix:
   - Make each set one 48px row: `#`, weight, reps, tag chips inline, ⋯.
   - Move "Add a note" and "Tag" into the ⋯ menu ("Add note", "Tag…").
   - Show a note only when one exists (as a 13px muted line under the row).
   - Set height then drops to 48px, or 70px with a note, and 5 sets fit above the fold with the form.
2. **The Add set button drifts down after each set.** When the page is opened from the workout (URL with `?date=`), scroll is preserved but the new 196px set is inserted above the form. Add set moved from y=632 to y=771, under the tab bar that starts at 784 (measured, `after-add-with-date.png`). Opened without `?date=` (a bookmark, or the shoot script), the redirect URL differs and the page **jumps to the top** with Add set at y=1301 (`after-second-add.png`). Fix:
   - Put the Add set form *above* the list of today's sets (newest first), directly under the card header. It then never moves.
   - Or make the form `position: sticky; bottom: calc(3.75rem + env(safe-area-inset-bottom))` in the card footer on phones.
   - The redirect to `back` in `WorkoutSetsController#create` should keep the URL the page was opened with.
3. **The weight is the hero and is set like body text.** "60 kg" and "12" are 15px/400. Make the weight and reps 20px/600 Jakarta with tabular numbers, and keep "kg" 13px muted. The set number badge (12.8px indigo on soft indigo, 26px) is a third indigo element per row; make it a plain muted `1` in 13px.
4. **Rest timer:**
   - "Start rest" is a separate `btn-light` above the form, so every set costs Add set, then Start rest.
   - While it runs the clock is 22px inline with "Rest", with a Stop button (`rest-running.png`).
   - Pressing Add set while it runs opens a modal, "Your rest timer is running: No rest / Save rest" (`rest-alert-on-add.png`). That is a third tap on the most common path (you rested, now you log the set).
   - Recommendation (a question for the owner, since it changes behaviour):
     - Save the rest by default without asking.
     - Start the rest automatically when a set is added (an account setting, as `auto_warm_up` already is).
     - Show the running rest as a large 36 to 48px clock in a sticky strip above Add set.
   - The clock reads "0:00:04". For a rest under an hour show "0:04".
5. **The form:** "Weight kg" and "Reps" labels are 12.48px muted 600, and the inputs are pre-filled (great). Below the fields:
   - Tag pills "Assisted / Drop set / Warm-up" are Bootstrap grey outline pills, 44px tall, a full row.
   - On an earlier day there is a "Rest ~min" select with "–" options "~1…~30" (`phone--exercise-page-0`). The "~" in the label and the options is jargon. Use "Rest (min)" with options "1 … 30".
   - The weight placeholder "–" on an empty weight makes it look disabled.
6. **Two flashes cover the top bar.** "Set 4 added." sits over the back arrow and the title for 5 s after every set (`after-add-set-flash.png`, `focus-row2` panel 4). At the gym you add a set and often want to go back right after; the back button is under the toast. Fix: on phones place notices at the bottom, above the tab bar (`bottom: calc(3.75rem + .75rem + env(safe-area-inset-bottom))`). Or, for "Set N added." only, skip the toast: the new row already lights up with `.just-moved`, so give the new set that highlight instead.
7. **The Note card** (exercise note for today) is a second note concept on the same screen as per-set notes, with the same placeholder style and arrow. "Note / Today" header. Fine on desktop, where it is in the side column; on a phone it is one more card between the sets and the equipment.
8. **The Equipment card on every exercise page:**
   - A full form (choices, two fold rows "Type of machine: Not set", "Machine: Not set", "Machine brand", and a "Save equipment" button).
   - This is set-up, not logging. On a phone it is 600px of the page.
   - Fold it behind a single row "Equipment · Machine · Bull ›" that opens the form.
   - "Not set" in indigo `choice-current` looks like a link or a value, not an empty state. Use muted.
9. **The ⋯ menu** (`--actions-menu`) is a 176px-wide dropdown with Edit (pen) and Delete (red ×), 44px items (good). It covers the next set's Tag and note.
10. **Expanded tag state** (`--expanded`): the tag choices open as a second row of grey pills under "Tag", so the set grows to about 290px.
11. **The weight/reps alignment:** the "Weight" column header sits at x=155 and the values at x=155 (good). The "Reps" column is wide (about 140px) because the actions column is narrow, so the reps sit 210px from the right edge with empty space after.
12. **Desktop:** the sets table and form are in the left 2/3, Note and Equipment on the right (good). The tag pills there are Bootstrap `sm` (about 26px tall, fine for a mouse).

### Exercise to do, no sets (`phone--today-exercise-todo-rdl`)

- "No sets yet today. Add your first set below." The empty state is centred 15px muted and points to the form underneath. Good.
- The form is pre-filled with "120 / 8" from last time (good). There is **no label** saying where 120 comes from. Add a 13px muted line, "Last time (Wed 18 Nov): 120 kg × 8, 110 × 8, 100 × 10", above the fields. That is the single most useful number in a gym logger, and it is missing from this page.

### Logged workout (today: `phone--today-log-0/1`; past: `phone--log-show-upper`, `--expanded`, `phone--log-show-lower`, `-restday`, `-cardio`, `desktop--log-show-upper`)

- **"Delete workout"** is a red outline button in the page header. It sits beside the title when there is room (`log-show-upper`), and on its own row under the date when a badge is present (`log-show-restday`, `log-show-cardio`). It is the most prominent action on a page about *viewing* the workout. Move it to the bottom of the Details card as a `btn-link text-danger`, or into a header ⋯.
- **Exercise cards:**
  - The name column is about 110px wide (handle, chip, ⋯, chevron box), so "Seated / Lateral Raise", "Upper back / row" and "Incline / dumbbell / press" wrap to two or three lines at 20px.
  - The meta "Free weights ·" ends with a dangling "·" at the end of the line, then "Top 14 kg × 8 reps" (`phone--log-show-upper-0`). `time_parts` keeps separators with their part for times; the equipment line needs the same `nowrap` treatment, or drop the trailing separator when the top set wraps.
- **Sets chip** is grey here, green on the workout day. Pick one meaning: green = done today.
- **"From this day, not in this workout"** (today's log) lists the plan's exercises with an "Add" `btn-light` per row. The workout day page shows the same thing as "Still to do · 5" with drag and open. Same data, two names, two controls (§3.9). Name it "Still to do" on both pages.
- **"+ Add exercise"** is a full-width `btn-light` between the exercises and Details (on the workout day it is a primary in the card header).
- **Details card:**
  - Date and Notes use simple_form labels (15/400), while the exercise forms use inline labels.
  - The date input is the browser default "11/25/2026" (US) while the page shows "November 25, 2026".
  - "Save details" is a full-width `btn-light`.
- **Cardio:**
  - The table header uses "#" where lifts use "Set".
  - Time "0:05" and "45:45" sit in the table, but the chip says "45 min 50 s". Two formats on one card.
  - The values are "5 %" and "10 km/h" with a space before %.
  - The form labels "Incline %", "Speed km/h", "Min", "Sec" and the "+ Add" button are fine.
- **Rest-day log:** "Rest day, trained anyway" chip (amber). The copy is friendly. The amber is the same as "Paused", so two meanings share one colour.

### Past and future workout days (`phone--past-workout-upper-mon`, `phone--workout-day-past-push`, `phone--workout-day-future-upper`)

- **Past:** "In this workout · 0" with "Drag an exercise here, or open one and add a set." (good teaching). But on a phone, dragging between cards is a hidden gesture.
- **Future (Friday):** a single "Exercises" card, "No exercises planned for Upper." There is no hint that sets will open on Friday, and no "Train it today instead" route. Move is on Home only. At minimum say "Sets open on Friday, Nov 27."
- **Active tab differs:** today's workout shows Home active, while past and future workout days show Splits active (`application_helper.rb:92-102`). One page type, two tabs.

### Splits (`phone--splits`, `phone--empty--splits`, `phone--split-show-0/1`, `--picker`, `desktop--split-show`)

- **Index:**
  - The eyebrow "Programs" plus the h1 "Your splits".
  - The subtitle says "the one your **dashboard** follows" (`splits/index.html.erb:6`). The dashboard is now "Home".
  - "+ New split" sits under the subtitle when there is one, and beside the title when there is not (`phone--empty--splits`). Two header layouts.
  - The empty state has "+ New split" in the header **and** "Create your first split" in the card: two primaries for one action. Drop the header one when empty.
- **Split cards:** "PPL/UL / 5 workout days" with chip pills "Push Pull Legs Upper Lower", then "Set as active" as a white button. The active card gets the 3px ring and an "Active ✓" badge (two signals). The whole card is a link, and "Set as active" sits above it (`split-activate z-index`).
- **Show:**
  - The header puts "Set as active" (primary) and a ⋯ beside h1 "PPL/UL". The button is top-aligned with the eyebrow-less title, so the title sits about 20px lower than the button (`phone--split-show-0`).
  - "Your week" circles: an empty day is a white circle with a light border, a planned day solid indigo. The hint "Tap an empty day to add a workout, then plan its exercises below." is good.
  - Day cards: name and weekday, an "N exercises" chip, ⋯, and a bordered chevron box. The folded state is good. "Legs · Wednesday · Today" opened shows "No exercises planned yet." and a full-width "+ Plan exercises".
- **Picker:** the same as the workout picker, the same issues.

### Split and workout-day forms (`phone--split-new`, `--split-edit`, `--workout-day-new`, `--workout-day-edit`, `impeccable-a/err-row1.png`)

- **Fields are green with a tick on first view:**
  - "Sunday" on `workout_days/new`.
  - Every field on the edit pages: "PPL/UL", "Push", "Monday", "Bench press" on `exercises/edit`, the Email on Account.
  - Green means "validated OK", but nothing was submitted.
  - Fix: `config.input_field_valid_class = nil` and drop `valid_class: 'is-valid'` from the wrappers (`config/initializers/simple_form_bootstrap.rb:44,59,69,83,95,108,118,129,142,161`).
- **Required marker:** "Name *". The `<abbr title="required">*</abbr>` gets Bootstrap's dotted underline and reads as ".:". Fix: `abbr[title] { text-decoration: none; cursor: default }`, or `config.required_by_default = false` and mark optional fields instead.
- **Errors:** red border, a ⓘ icon, and a 13px red message under the field (good).
  - "Day must be one of the listed workouts" sits under a field labelled "Workout". The attribute is `day`; the message should say "Choose a workout."
  - On the same failed submit, "Day of the week" stays green. A green field next to a red one on a failed form reads as "half saved".
- **Buttons:** "Create Split / Cancel" are side by side, left-aligned, auto width. On a phone, make the primary full width (as on the auth pages) and put Cancel as a link under it.
- These pages are 80% empty below the form. That is fine.

### History (`phone--history-0/1`, `--confirm`, `desktop--history`, `phone--empty--history`)

- **A one-column table with a "Workout" `th`** on the phone. The `th` row adds a 44px grey strip that labels nothing. Use a list (`list-rows`) on the phone, or hide the `thead` below `md`.
- **Each item:**
  - The date is the link (indigo 16px/600, "November 25, 2026", no weekday).
  - Then "Lower" and the split chip; "2 exercises · 5 sets"; the clock line with a pen.
  - A bordered "Open" button at the right, a duplicate of the date link.
  - The pen floats in the gap between the text and Open, unrelated to the line it edits.
  - Drop Open (the row is the link), lead with "Lower" as the title (16px/600 dark), and make the date muted meta with the weekday: "Wed 25 Nov · 2 exercises · 5 sets".
- **"Deleted"** (muted) after the Rest day chip means "split deleted". It reads as "this workout is deleted". Use "No split" (the Month page already says "No split").
- **Empty logs are listed:** Nov 20 Upper "0 exercises · 0 sets" and Nov 21 Lower "0 exercises · 0 sets" (timer only). The calendar calls Nov 20 "Upper missed. Add it." History and the calendar disagree.
- **Confirm state:** `phone--history--confirm` shows no confirm box. History has no delete on the row (the state script found no `[data-turbo-confirm]` to open), so that shot is the plain page. Not a defect.
- **Desktop:**
  - The table is good, with columns Date, Workout, Split, Exercises, Sets.
  - The Cardio row shows "0 · 45 min 50 s" in the Sets column.
  - The card's top corners are square (§3.4).

### Edit timer (`phone--timer-edit`)

The shot captured a redirect: "This workout has no timer." (alert, red) over History, because log 1 has no timer. That is not a defect of the page. The page itself was not reachable for this log, and I did not open it for a timed log. **Not verified.**

### Month (`phone--month-0/1/2`, `phone--empty--month`, `desktop--month`)

- **"November 2026" twice:** the h1 and the calendar card header. The eyebrow "Month" makes three labels for one fact. The top bar says "Home".
- **No previous/next month navigation**, so the Month page can only show this month. A ‹ › pair in the card header is the expected control.
- **Totals:** the four-tile grid plus Cardio on its own row (as on Home).
- **Splits and Exercises lists** (`.month-list`): names at 16px/600 left, "6 sets · 230 kg" muted right. Clean. The heaviest weight should say "top 230 kg". "6 sets · 230 kg" can be read as total volume.
- **Rhythm:** 40px gap after the calendar, 16px elsewhere.

### Exercises catalogue (`phone--exercises`, `phone--empty--exercises`, `desktop--exercises`)

- **The eyebrow "Catalogue"** plus h1 "Exercises" plus a 3-line paragraph of 15px muted explanation.
  - The admin copy is "As an admin you can add, edit and delete its exercises. Exercises you keep for yourself are marked "Yours"".
  - The other copy is "managed by an admin…".
  - That is long for a list page; one line is enough: "Shared by everyone. Yours are marked 'Yours'."
- **Group rows** (16px/600 dark, count chip, chevron) are the right pattern, unlike the picker's uppercase labels. Use this same row in the picker.
- **A stray 1px line under the card's bottom edge.** `.exercise-group-list { border-bottom }` on the last group sits outside the rounded corner (`phone--exercises` y about 1517, `phone--empty--exercises` y about 1350). Fix: `.exercise-group-list:last-child, .exercise-group:last-of-type { border-bottom: 0 }`.
- **Bottom nav:** the Home tab is active on Exercises (`application_helper.rb:95`, by design, since it is reached from Home). That still confuses: you are on "Exercises", and the tab says Home.

### Exercise forms (`phone--exercise-new-0/1`, `phone--exercise-edit`, `impeccable-a/err-row2.png`)

- **Muscle group:** 10 choices in a 3-column grid, plus a lone "Cardio" on a fourth row, with "Other" first and preselected. The choices are 44px indigo outlines, and the selected one is solid indigo. Fine, but with 10 options use the folded `choice-summary` pattern already used for "Free weight" ("Muscle group · Other ⌄").
- **Equipment:** "Free weights" wraps to two lines in its third ("Free / weights"), while "Machine" and "Bodyweight" stay on one. The row height then grows to 58px. Use "Free weight" (singular, it fits), or `font-size: .875rem` in `.choices .btn`.
- **Checkboxes:** "Unilateral: one arm or one leg at a time" and "Add to the shared catalogue". The unchecked box is invisible (1.14:1).
- **Errors:** "Name has already been taken" for a duplicate. Clearer: "You already have 'Squat'. Pick it from the list."

### Log exercise edit (`phone--log-exercise-edit`)

- Equipment choices plus a "Free weight: Not set" fold, and a Note textarea with the placeholder "Anything to remember about this exercise today (optional)". Then Save (primary) and Cancel. The h1 is the exercise name.
- Labels here are 12.5px muted (inline-form), while the same "Note" is a card header on the exercise page. A third Note surface.

### Account (`phone--account-0/1`, `phone--empty--account`)

- **The page h1 "Account" is inside a card** (`.auth-card`, because it is a Devise page, `layouts/application.html.erb:25-30`), with a 2rem card padding. The top bar also says "Account". On every other page the h1 is outside the cards.
- **The admin links** "Users", "Equipment" and "Set tags" are white buttons with icons, plus "Log out" in the same row style. Log out is an account action and sits with admin tools, and it wraps alone to the second row. Make them a list (`list-rows`) of navigation rows with chevrons, and put Log out at the bottom as a separate `btn-link text-danger`.
- **Preferences need your current password.** "Start the workout timer automatically" and "Tag the first set of each exercise as a warm-up" are checkboxes in the Devise registration form, which requires "Current password *" (`phone--account-1`). Changing a gym preference should not need a password. Move preferences to their own small form (`PATCH /settings`) that saves on toggle.
- **Devise hints** "leave it blank if you don't want to change it" and "we need your current password to confirm your changes" are lowercase and unpunctuated, unlike the rest of the app. Rewrite them in sentence case.
- **"Cancel my account"** with explanatory copy, then a blue "Back" link at the bottom, which duplicates the tab bar.
- The checkbox borders are invisible here too.

### Admin: Users, Equipment, Set tags (`phone--admin-users`, `phone--admin-equipment-0/1/2`, `phone--admin-tags`)

- **The top bar says "FitnessApp"** on Equipment and Set tags (no `PAGE_TITLES` entry), and "Users" on Users. There is no back arrow on any of them, though they are sub-pages of Account. On Equipment and Set tags no tab is active (`bottom_nav.html.erb:7` covers only `users/registrations` and `admin/users`).
- **Users:**
  - A table with an "Email" header.
  - The row "notadmin@example.com": "Make admin" wraps to two lines, and the red "Delete" button touches the card's right edge (x=749 of 755 at 2x, so 3px from the border).
  - The actions should stack under the email on a phone, or go into a ⋯ menu (the app's own pattern).
- **Equipment and Set tags:**
  - An "Add equipment" card (Name, "Kind" choices, a small "Add" primary), then one card per kind with ⋯ rows. Consistent with each other.
  - Placeholders "Dumbbell" and "Warm-up" read as values (they are the names of items already in the list below, which makes it worse).
  - Equipment is 2349 CSS px long on the phone, with one row per item at 78px each. The rows could be 48px.

### Logged out (`phone--loggedout--signin`, `--signup`, `--password-new`, `impeccable-a/err-signin`)

- **"Log in" and "Sign up" appear twice:** in the top bar (link and primary button) and in the card (primary button and link). On a phone the top-bar "Sign up" primary competes with the form's "Log in" primary.
- **After a wrong password:** the error is a red flash (good, it stays until closed), but the email field and the "Remember me" label turn **green with a tick** (`err-signin.png`).
- The auth h1 is 24px; the app h1 is 28px.
- The bottom links "Sign up / Forgot your password?" are 14.4px with no spacing between them. Fine.

### Flash and confirm (`impeccable-a/after-add-set-flash`, `rest-alert-on-add`, `timer-row` panel 3)

- **Flash card:** white, 16px radius, a soft shadow, an icon in a tinted circle, and a 3px countdown bar. Polished. On a phone it covers the top bar (see the exercise page, item 6).
- **Error flash for the set form:** "Set not added: Reps completed can't be blank and Reps completed is not a number." That is technical and says the same thing twice. Use field-level messages, or a custom message: "Type the reps."
- **Confirm and alert boxes:** a white 24px-radius card, an icon in a tinted circle, a bold title, a muted detail, and two equal buttons. Consistent across delete, paused-timer and rest-timer. The paused-timer alert is indigo; the delete confirm is red. Good.

---

## 5. Priority issues

Counts: **P0: 0 · P1: 8 · P2: 17 · P3: 14**

Nothing blocks completing a task (no P0). Every flow I drove works end to end.

### P1 (major)

**P1-1. The Add set button is below the fold and drifts after every set.**

- What: each set row is 171 to 197px tall (Tag pill and note field always shown). With 3 sets the form starts at y=933 on an 844px phone. After each set it moves about 140 to 200px down, under the tab bar (y=632 to 771, tab bar at 784). Opened without `?date=`, the page jumps to the top (Add set at y=1301).
- Why it matters: this is the core action, repeated 15 to 25 times a session, mid-rest, one-handed.
- Fix:
  1. Compact each set to one row. In `workout_sets/_set.html.erb:55-88`, move Tag and Note into the ⋯ menu (`menu_link "Add note"`, "Tag…") and render the note row only `if set.notes.present? || set.set_tags.any?`. Row height target: 48px.
  2. Render the Add set form *above* the sets (`workout_exercises/show.html.erb:34-50`: move the `card-footer` before the table, and list the sets newest first, or keep them oldest first with the form on top).
  3. In `WorkoutSetsController#create`, redirect to the URL the form came from (`request.referer` when it is the same exercise page) so the morph keeps the scroll.
- Command: `/impeccable layout` (exercise page), then `/impeccable distill`.

**P1-2. Cards, inputs and modals are the page colour (`#F6F7F9`).**

- What: Bootstrap 5.3 takes `$card-bg`, `$input-bg` and the modal background from `$body-bg`. Surfaces separate only by a 1.14:1 hairline, and white `btn-light` buttons float on grey cards.
- Fix: in `config/_bootstrap_variables.scss` add:
  - `$card-bg: $surface; $input-bg: $surface; $modal-content-bg: $surface; $dropdown-bg: $surface; $list-group-bg: $surface;`
  - with `$surface: #FFFFFF` in `_colors.scss`, and replace the 14 literal `white`s with it.
  - Keep `$body-bg: $light-gray`.
  - Raise the card shadow to `0 1px 2px rgba($shadow,.06), 0 1px 1px rgba($shadow,.04)`.
- Command: `/impeccable colorize`, then `/impeccable polish`.

**P1-3. Checkbox and radio borders are invisible (1.14:1), and input borders fail (1.32:1).**

- Where: picker exercise rows (the core "Add exercises" choice), Remember me, Unilateral, "Add to the shared catalogue", account preferences, Move-modal radios.
- Fix:
  - `$form-check-input-border: 1.5px solid #8A919E` (3.2:1 on white). That needs a new token, `$control-border: #8A919E`.
  - `$input-border-color: #B9BFC9` with white inputs (after P1-2), which gives at least 1.9:1 for the field edge. Field identification also comes from the white fill on the grey page.
  - For WCAG 1.4.11, use `#8A919E` for checkboxes and radios.
- Command: `/impeccable colorize` (audit of states).

**P1-4. The exercise picker has no search, and the groups look like labels.**

- What: you must know which muscle group holds the exercise and open its fold. The group rows are 12px uppercase tracked text. In the catalogue page the same groups are 16px/600 rows.
- Fix:
  - Add `<input type="search" placeholder="Search exercises" class="form-control">` sticky at the top of `.modal-body` in `shared/_exercise_picker.html.erb`. A small Stimulus filter hides rows that do not match and opens the groups that have matches.
  - When nothing matches, prefill "Create your own" with the query.
  - Restyle `.picker-group` as `.exercise-group`: `font-size: 1rem; font-weight: 600; text-transform: none; letter-spacing: 0; color: $gray`, with the count chip.
- Command: `/impeccable layout` and `/impeccable clarify`.

**P1-5. Three taps per set while using the rest timer.**

- What: Add set, then a confirm ("Save rest" / "No rest"), then Start rest. The confirm guards the expected path.
- Fix (behaviour change, so ask the owner):
  - Save the measured rest by default without the dialog. Keep the dialog only if the rest is over 10 min (a forgotten timer).
  - Add an account setting, "Start rest after each set", like `auto_warm_up`.
  - While resting, show the clock at 36px (`.rest-clock { font-size: 2.25rem; font-family: $headers-font }`), formatted m:ss.
- Command: `/impeccable distill`.

**P1-6. The workout rows squeeze the exercise name to 18 to 110px.**

- What: the handle gap, the sets chip, the pen or ×, and the bordered chevron leave the name column about 95 to 110px. Names and meta wrap to three to seven lines (`phone--workout-day-today-legs-0`, `impeccable-a/long-row.png`, `phone--log-show-upper-0`).
- Fix (`workout_days/_planned_exercise.html.erb`, `workout_logs/show.html.erb`):
  - Remove the chevron `btn-light` (the row is already the link). Add a trailing `fa-chevron-right` 12px `$muted`, with no box.
  - Put the sets chip on the meta line.
  - Move the admin pen and the red × into a ⋯ (`actions_menu`).
  - `.drag-handle { width: 2.75rem; margin-left: -1rem; margin-right: -.5rem }`.
- Command: `/impeccable layout`.

**P1-7. Fields show a green "valid" state on pages nobody submitted, and after a failed login.**

- What: `is-valid` paints the border, a tick and the label in `$success` teal (2.87:1). It shows on `workout_days/new` (Sunday), every edit form, Account, and the sign-in after a wrong password (`impeccable-a/err-signin.png`).
- Why it matters: false status; on a failed login it says the opposite of what happened.
- Fix: in `config/initializers/simple_form_bootstrap.rb` set `config.input_field_valid_class = nil` and remove `valid_class: 'is-valid'` from all wrapper definitions (lines 44, 59, 69, 83, 95, 108, 118, 129, 142, 161).
- Command: `/impeccable harden`.

**P1-8. Changing a preference needs your current password.**

- What: "Start the workout timer automatically" and "Tag the first set as a warm-up" live in Devise's registration form (`devise/registrations/edit.html.erb`), which requires the current password.
- Fix: a separate preferences card on Account with its own form (`PATCH /settings`, `users.timer_auto_start` and `auto_warm_up`), checkboxes that submit on change (the `auto_submit_controller.js` that already exists), and the "Saved." flash.
- Command: `/impeccable clarify`.

### P2 (minor)

**P2-1. A 21-size type scale with sub-pixel clusters.**

- Fix: define `$fs-label: .75rem; $fs-meta: .8125rem; $fs-small: .875rem; $fs-body: 1rem; $fs-title: 1.125rem; $fs-num: 1.375rem; $fs-h1: 1.75rem; $fs-clock: 2.25rem` in `config/_type.scss`, and map each declaration in §3.1 onto these.
- Set `$font-size-base: 1rem`.
- Command: `/impeccable typeset`.

**P2-2. Inter 700 is synthesised (faux bold).**

- Fix: change the font URL to `Inter:wght@400;500;600;700` (`layouts/application.html.erb:12`), or replace the 14 `font-weight: 700` on Inter elements with 600.
- Command: `/impeccable typeset`.

**P2-3. The logged weight and reps are body-sized.**

- Fix: `.set-table td:nth-child(2), .set-table td:nth-child(3) { font-family: $headers-font; font-size: 1.25rem; font-weight: 600 }`, and the unit `kg` in a `<span class="unit">` at `.8125rem $muted`.
- `.order-badge` becomes plain `$muted` 13px, no fill.
- Command: `/impeccable typeset`.

**P2-4. The focus ring is 1.46:1.**

- Fix: `$focus-ring-opacity: 1; $focus-ring-width: 2px; $focus-ring-color: $blue; $input-btn-focus-box-shadow: 0 0 0 2px $surface, 0 0 0 4px $blue`.
- `btn-outline-secondary:focus-visible` must not fill. Better, replace the tag pills (P2-6).
- Command: `/impeccable harden`.

**P2-5. Indigo on everything; five solid indigo blocks on the exercise page.**

- Fix:
  - Note save arrows become `btn-light` with a `$muted` icon, or are removed (P1-1).
  - `.choice-current` becomes `$muted` when "Not set".
  - Pens become `$muted` and turn `$blue` on hover.
  - The active split ring becomes `1px $blue` plus the "Active" badge.
- Command: `/impeccable quieter`.

**P2-6. Three pill languages; tags use Bootstrap grey `#6C757D` (4.37:1).**

- Fix: tags use the `.choices` look at pill radius. Unchecked: `border: 1px solid $line-strong; color: $gray; background: $surface`. Checked: `$primary-soft` background, `$blue` text and border.
- Drop `btn-outline-secondary` from the views (`workout_sets/_set.html.erb:22,62,73`, `_form.html.erb:139,170`).
- Command: `/impeccable polish`.

**P2-7. "Last time" and History count empty logs.**

- What: "Last time · Nov 21 · 0 exercises · 0 sets"; History lists Nov 20 and Nov 21 as "0 exercises · 0 sets" while the calendar says Nov 20 was missed.
- Fix: the Today box's "last time" skips logs with no sets. History marks a timer-only log "Timer only, no sets", or hides empty logs behind "Show empty".
- Command: `/impeccable clarify`.

**P2-8. The calendar has no legend; the extra ring is 2.6:1.**

- Fix: a legend row under the calendar grid (four 10px swatches plus 12px labels). Change `$extra-ring` to `#6E76EA`.
- Command: `/impeccable clarify`.

**P2-9. The flash covers the top bar's back arrow for 5 s after every set.**

- Fix: on phones, `.flash-stack { top: auto; bottom: calc(3.75rem + .75rem + env(safe-area-inset-bottom)) }` below `md`, with the `flash-in` keyframe moving from `translateY(.375rem)`.
- Command: `/impeccable adapt`.

**P2-10. "Delete workout" in the header of every logged workout.**

- Fix: move it to the end of the page (after Details) as `btn btn-link text-danger`, or put it in a header ⋯.
- Command: `/impeccable layout`.

**P2-11. The same workout on two pages with different words and controls.**

- What: "Still to do" vs "From this day, not in this workout"; green vs grey sets chips; pen vs ⋯; chevron-right vs chevron-down; "Add exercise" primary in the header vs `btn-light` full width.
- Fix: one row component and one vocabulary.
- Command: `/impeccable polish`.

**P2-12. Technical error copy.**

- What:
  - "Set not added: Reps completed can't be blank and Reps completed is not a number."
  - "Day must be one of the listed workouts" (field "Workout")
  - "Name has already been taken"
- Fix: custom model messages (`message:`) and `human_attribute_name` ("Reps"), and one message per field.
- Command: `/impeccable clarify`.

**P2-13. Example placeholders read as values; the "–" placeholder looks disabled.**

- Fix: prefix the examples with "e.g." ("e.g. Bench press"). For the weight use `placeholder="kg"`. `$input-placeholder-color: #8A919E` (3.2:1, acceptable for an example placeholder because a label is always present).
- Command: `/impeccable clarify`.

**P2-14. Uneven gaps between cards (40px after the calendar and timer vs 16px).**

- Fix: remove `margin-bottom` from `.calendar-card` (`_dashboard_calendar.scss:2`) and `.timer-card` (`_timer.scss:4`). Let `.card + .card` own the rhythm, or use a `.stack > * + * { margin-top: 1rem }` wrapper.
- Command: `/impeccable layout`.

**P2-15. The exercise page shows no previous session for this exercise.**

- Fix: one muted line above the form, "Last time Wed 18 Nov: 120×8 · 110×8 · 100×10" (13px, tabular). The data is already loaded for the Today box (`pages/_lifts`).
- Command: `/impeccable clarify`.

**P2-16. Admin sub-pages (Equipment, Set tags) have no title, no back arrow and no active tab; the Users row actions touch the card edge.**

- Fix: add `PAGE_TITLES` entries, `back_to edit_user_registration_path`, include `admin/*` in the Account tab's active check (`_bottom_nav.html.erb:7`), and put Users actions in `actions_menu`.
- Command: `/impeccable polish`.

**P2-17. The Equipment form on every exercise page during a workout.**

- Fix: fold it to one row ("Equipment · Machine · Bull ›") with `shared/_list_toggle`, open on demand.
- Command: `/impeccable distill`.

### P3 (polish)

**P3-1. Eyebrows above headings.** There are 12, which `craft-floor.md` bans.
- Fix: remove the `<p class="eyebrow">` lines (§3.1 list), and delete `.eyebrow` (`_layout.scss:32-40`) after moving "This week"'s use to a 13px/600 subheading.
- Command: `/impeccable quieter`.

**P3-2. Rails button labels.**
- Fix: "Create Split", "Update Split", "Create Workout day", "Update Workout day", "Update Exercise" become "Create split", "Save split", "Add workout day", "Save", "Save exercise". Use `f.button :submit, "…"` in `splits/_form`, `workout_days/_form`, `exercises/_form`.
- Command: `/impeccable clarify`.

**P3-3. The required-field `<abbr>` underline renders as ".:".**
- Fix: `abbr[title] { text-decoration: none }`.

**P3-4. Square top corners on table cards (History, Users).**
- Fix: `.card:has(> .app-table), .card:has(> .table-responsive) { overflow: hidden }`.

**P3-5. A stray bottom line under the Exercises card.**
- Fix: no border on the last `.exercise-group-list`.

**P3-6. Inner right edge 8px off in the set table on a phone.**
- Fix: `.set-table td:last-child, .set-table th:last-child { padding-right: 1.25rem }` in `_workout_log.scss:62`, or make the note cell `padding-right: 1.25rem`.

**P3-7. A dangling "·" at line ends in logged-exercise meta.**
- Fix: wrap each meta part in `.time-part`-style `nowrap` spans (the `time_parts` helper already does this for times).

**P3-8. Dates without a weekday in History and Recent ("November 25, 2026").**
- Fix: `"%a %-d %b"` ("Wed 25 Nov"), with the year only when it is not this year.

**P3-9. Recent workouts repeat the active split chip on every row.**
- Fix: show the chip only when the log's split is not the active split.

**P3-10. The two-muted-greys issue.**
- Fix: `$secondary-color: $muted` (or set `--bs-secondary-color` on `:root`).

**P3-11. Dead tokens `$orange` and `$notice`, and a second blue.**
- Fix: delete them, or map `$info` to `$blue`.

**P3-12. "Free weights" wraps in the three-up choices.**
- Fix: label it "Free weight", or `.choices .btn { font-size: .875rem }`.

**P3-13. The Home "Exercises" button sits above today's workout.**
- Fix: move it below Recent workouts, or into Account.

**P3-14. `<title>` is "FitnessApp" on every page, and there is no `theme-color` meta.**
- Fix: `<title><%= [page_title, "FitnessApp"].compact.join(" · ") %></title>` and `<meta name="theme-color" content="#FFFFFF">`.

---

## 6. Cognitive load

Checklist, scored per key screen (a failed item counts 1):

| Item | Home | Workout day | Exercise page |
|------|------|-------------|---------------|
| Single focus | Fail: Exercises button, Today box, active split frame and calendar compete | Pass | **Fail**: sets, tags, notes, rest, note card and equipment |
| Chunking (≤4 per group) | Pass | Pass | Fail: each set row is a group of 5 controls |
| Grouping | Pass (cards) | Pass | Pass |
| Visual hierarchy | Fail: the active-split frame outweighs Continue | Pass: Add exercise is clear | **Fail**: five solid indigo blocks; Add set is not the strongest |
| One thing at a time | Pass | Pass | Pass |
| Minimal choices (≤4) | Fail: about 12 actions above the calendar | Pass, but rows carry 3 to 4 controls | Fail: per set ⋯, Tag, note and arrow, plus Start rest, Add set and 3 tags |
| Working memory | Pass ("last time" shown) | Pass | **Fail**: last session's sets are not on this page; only the last set is pre-filled, with no source label |
| Progressive disclosure | Pass (folds) | Pass | Fail: tag and note controls always open |
| **Failures** | **3, moderate** | **0 to 1, low** | **6, high (critical)** |

**Working-memory rule at the peak moment:** at the exercise page's decision point (log the next set) the lifter sees, in the first viewport:

- 3 sets × (number row, ⋯, Tag, note, arrow)
- the rest line
- the header and date

That is about 17 interactive targets before Add set is even visible. The target is: the last set, the pre-filled form and Add set, with at most 4 items.

---

## 7. Emotional journey

| Moment | What happens | Feeling | Note |
|--------|--------------|---------|------|
| Open app at the gym | Home: big date and "Lower day · Continue" | Oriented, confident | Continue is small and at the top right, 44px |
| Tap Continue | Workout page: Running timer, "In this workout · 2", "Still to do · 5" | Good: a clear map of the session | Rows are crowded; names wrap |
| Open an exercise | Hip thrust: sets table | **Dip**: three tall blocks of Tag and Add a note, no Add set in view | Must scroll about 300px |
| **Log a set (peak)** | Pre-filled 90 / 8 → Add set → flash "Set 4 added." | **High point**: one tap repeats the set; the flash confirms | The flash covers back; Add set slides under the tab bar; next time must scroll again |
| Rest | Start rest → 22px clock "0:00:04" | Neutral | Small clock; an extra tap |
| Next set while resting | Add set → "Your rest timer is running: No rest / Save rest" | **Friction**: a question for the expected case | Third tap |
| Finish | Back to the workout → Stop → confirm | Satisfied: the Finished pill and the total time | No session summary moment (total sets, top set, vs last time) |
| Later, History | List of dates, "Open" | Flat | Empty logs mixed in; "Deleted" confuses |

**Peak-end:** the peak (adding a set) is genuinely good, thanks to pre-fill and instant confirmation. It is surrounded by scroll and confirm friction. The end (Stop) has no payoff: no "Lower done: 6 exercises, 22 sets, top 110 kg, 1 h 3 min" moment. The data exists (`WorkoutSummary`), and a one-card summary after Stop would close the session warmly. That is a suggestion for the owner to accept or decline, since product rules forbid unrequested features.

---

## 8. Persona red flags

### Project persona: "Pedro mid-set". The owner at the gym.

Profile:

- Between sets with 60 to 90 s of rest, sweaty fingers, one hand (the other on a bottle or towel).
- Glancing at the phone from a bench at arm's length.
- Knows the app well, has no patience for dialogs.

Behaviours: repeats the last set, sometimes +2.5 kg; checks what he lifted last time; starts and ignores the rest timer; leaves the app mid-workout and comes back.

Red flags:

- **Add set is not where the thumb is.** It starts below the fold (y=933), slides under the tab bar after each set (632 to 771), and jumps to the top if the URL lacks `?date=`. That is a scroll on most sets, with sweaty thumbs on a scrolling page next to 44px "Tag" and "note" targets.
- **Three taps per set** with rest tracking (Add set, Save rest, Start rest).
- **Numbers too small to read from the bench:** the weight is 15px/400, the rest clock 22px.
- **No "last time" on the exercise page:** he must remember, or go back to Home and expand "Show exercises".
- **A toast over the back button** for 5 s after every set.
- **The tag pills (Assisted, Drop set, Warm-up) sit right under Add set,** 8px below it, also 44px. A slip toggles a tag on the next set without notice. Tagged state is a subtle grey fill.
- **The red × on extra-exercise rows** next to the open chevron on the workout page. The confirm saves him, but it is a scare.

### Casey (distracted mobile)

- Primary actions sit at the top of the screen on Home (Continue, top right), the workout day ("Add exercise", top right of a card) and Splits ("Set as active", top right). Only the modals put the CTA at the bottom (good).
- Coming back mid-workout works: the timer and sets are server state. Good.
- The 36px calendar circles and the pen in History (a 44px target pulled into the line with negative margins) are fine, but the History pen sits 24px from "Open".

### Jordan (first-timer)

- "Split", "U/R/L/U/L", "Plan", "Still to do", "Rest ~min", "Deleted" and "Rest day, trained anyway" need context. The empty Home says "A split is your training program, made of workout days" (good), but the first-run path is: create a split, add workout days one by one via the week circles, plan exercises, then train. Nothing shows that sequence.
- The calendar states are explained only in tooltips, which never show on touch.
- No icon-only nav (good: tabs have labels).

### Sam (accessibility)

- Checkbox and radio borders are 1.14:1, the focus ring 1.46:1, and the extra-day ring 2.6:1.
- The drag handles are `aria-hidden`. On the workout day there is no keyboard alternative to drag between "Still to do" and "In this workout" (opening the exercise and adding a set works, so it is not blocking). Logged workouts have Move up/down in ⋯ (good).
- The calendar meaning is in `title` only (screen readers may read it; sighted touch users cannot).
- Decorative `<i>` icons without `aria-hidden` in `_form.html.erb:161` and `_planned_exercise.html.erb:15,17`.
- Good: real labels on all inputs (including visually hidden ones), `aria-label`s on icon buttons, `role="timer"`, and `aria-current` on tabs.

### Alex (power user)

- Esc cancels a set edit (good). There are no keyboard shortcuts for Add set (Enter in the reps field submits, fine).
- Batch: "Add selected" in the picker (good).
- The dialogs that guard expected paths (rest, paused timer on every add) will annoy.

---

## 9. Strengths

1. **Pre-filled Add set.** Weight and reps come from the last set, so repeating is one tap, with 16px numeric keypads (`inputmode="decimal"` and `"numeric"`) that do not zoom. This is the single best decision in the UI.
2. **The workout timer component.** A status pill (Running with a breathing dot, Paused in amber, Finished in grey), a 32px tabular clock, exact times, Pause / Resume / Stop full width on a phone, and a reduced-motion fallback. It is clear in every state (`timer-row.png`).
3. **Engineering discipline in the styles:**
   - Every colour named by role, with AA notes.
   - Every value commented with its reason.
   - 44px targets under `(pointer: coarse)` only, so desktop stays compact.
   - Safe-area insets.
   - Fixed-strategy dropdowns.
   - Morph with scroll preserve.
   - Its own confirm dialog instead of `confirm()`.
   - This is a strong foundation to restyle on.
4. **Teaching empty states and inline hints:** "Drag an exercise here, or open one and add a set.", "Tap an empty day to add a workout…", "Legs and Lower are the same workout under two names."
5. **Modals done right on a phone:** full-screen with a sticky footer CTA in the thumb zone (Move a workout, Add exercises).

---

## 10. Questions for the owner

1. Should Add set sit *above* today's sets (it never moves), or stay below with the sets made compact? The first is the bigger win for one-handed use.
2. Can the rest be saved automatically when a set is added while the rest timer runs, without asking? And should the rest start by itself after each set (as a setting, like Warm-up)?
3. Should per-set notes and tags move into the set's ⋯ menu (shown only when used), or must they stay one tap away on every set?
4. Is a plain white card on the grey page what you intended? The code comments say "white cards", but cards currently render grey.
5. Should the exercise page show last session's sets for that exercise (the data is already loaded for Home)?
6. A Stop summary card ("Lower done: 22 sets, top 110 kg, 1 h 3 min") is a new feature. Do you want it, or not?
7. Should workouts with no sets (timer only, or opened and left) appear in History and "Last time"?
8. Is Inter staying (the earlier audit left it to you)? If the type scale is reworked (P2-1), it is the moment to decide; adding Inter 700 is needed either way.

---

What I did not check:

- No real phone. Touch was emulated in headless Chrome 390×844 @2x. Native `title` tooltips cannot be seen headless; I read them from the DOM.
- The Edit timer page for a timed log.
- The rest-day state of the Today box (today is not a rest day).
- The cardio timer running.
- Dark mode: the app has none.
- Screen readers.

<!-- END VERBATIM FILE: evidence/scratchpad/reports/impeccable-A.md -->

<!-- BEGIN VERBATIM FILE: evidence/scratchpad/reports/impeccable-B.md | bytes: 40064 | sha256: 819182ad88a2ff9443a32b3703cc535bdd1a7a98bcc8d3a8021ae7bea68bbe25 -->
# Impeccable audit, Assessment B: detector, browser evidence, technical audit

Scope: the whole web app, served at `http://127.0.0.1:3001` (the disposable `fitness_app_design_audit` database), logged in as `admin@example.com`. The repo was only read: no file in it was edited.
Evidence folder: `.../scratchpad/impB/` (detector JSON in `run/det/`, DOM measurements in `run/meas/`, scripts `scan.mjs`, `probe*.mjs`). Screenshots: `.../scratchpad/shots/impeccable-b/`.

One thing changed in the audit database: while testing scroll after "Add set", I added **2 sets (95 kg × 6) to Hip thrust** in today's Lower workout (`/workout_exercises/17`, now 8 sets). Nothing else was written.

---

## Audit Health Score

| # | Dimension | Score | Key finding |
|---|-----------|-------|-------------|
| 1 | Accessibility | **3** | All text passes AA, but some controls are hard to see: checkbox edges measure 1.14 to 1.23:1, and the keyboard focus ring on `btn-light` is about 1.1:1 (WCAG 1.4.11) |
| 2 | Performance | **3** | Lean, with no images. Font Awesome uses `font-display: block` and a 158 KB solid woff2, and the CSS carries all 1,962 icon rules for the 26 icons the app uses |
| 3 | Theming | **3** | Tokens are named by purpose and used almost everywhere. Some Bootstrap defaults leak through: cards and fields are page grey, `.text-muted` is not `$muted`, and `btn-light` text is #000. There is no dark mode |
| 4 | Responsive Design | **3** | A 44 px `pointer: coarse` system, safe areas and 16 px inputs. But Home overflows by 90 px at 320 px, and text at 200% overflows 5 pages |
| 5 | Implementation Integrity | **3** | A coherent, product-specific system. The detector found 1 rule from its "AI-default" (slop) list (font choice) and 1 real layout overflow. Drift comes from Bootstrap and simple_form defaults |
| **Total** | | **15/20** | **Good**: work on the weak spots |

## Implementation integrity verdict: **PASS**

The app is a coherent, purpose-built system, not a generic template:
- The colour tokens in `config/_colors.scss` are named by role (`$done-*`, `$rest-*`, `$extra-ring`, `$hover-halo`). Each one has a comment that gives its contrast ratio, and those ratios are correct when recomputed.
- One touch-size system: `components/_layout.scss:85-92` applies `@media (pointer: coarse)` everywhere.
- The timer, the calendar states and the set tables come from the product's own rules in CLAUDE.md.

On the rendered pages, the detector found:
- 1 rule from its slop list: `overused-font`, for Inter and Plus Jakarta Sans.
- 2 real layout bugs: the `text-overflow` finding, on two pages.
- 1 false positive: `pulsing-dot`.

None of the other 50+ rules fired: side-tab, nested cards, gradient text, glow, kicker labels, buzzwords and so on.

The drift I found is not "AI slop". It is defaults from Bootstrap 5.3 and simple_form that the token layer never overrode:
- cards, inputs, dropdowns and table cells take `$body-bg` (page grey)
- `.text-muted` uses `--bs-secondary-color`
- `btn-light` text is `#000`
- `btn-outline-secondary` has a #6C757D border
- simple_form gives every pre-filled field the `is-valid` class, so it shows a green ✓

A stale comment shows the drift. `components/_flash.scss:1` says "white cards like the rest of the app", but the cards render `#F6F7F9`, the page colour.

## Executive summary

- **Score 15/20 (Good).**
- **Issues: P0 0 · P1 3 · P2 12 · P3 7.**
- Top issues:
  1. **[P1]** Checkboxes are nearly invisible: their border is 1.14:1 on grey cards. This hits Account settings, "Remember me" and the picker's "Unilateral" and "Add to the shared catalogue".
  2. **[P1]** The keyboard focus ring on `btn-light` (44 uses) is about 1.1:1. On other Bootstrap controls it is 1.47:1.
  3. **[P1]** Home scrolls sideways at 320 px. The cause is a `white-space: nowrap` split-name chip 377 px wide in Recent workouts.
  4. **[P2]** The green "valid" ✓ appears on every pre-filled simple_form field: Account email, Rename split, edit forms.
  5. **[P2]** Once an exercise has sets, the Add set form is below the fold. With 3 sets its weight field is at y = 1473 px on an 844 px phone, because each set row is 171 to 197 px tall.
- Next steps, in order:
  - `/impeccable harden`: non-text contrast, focus rings, valid state, page titles
  - `/impeccable adapt`: 320 px reflow, 200% text, small targets, the card header
  - `/impeccable layout`: Add set position
  - `/impeccable optimize`: icon font
  - `/impeccable polish`

---

## Detector results

### What was scanned

| Pass | Command | Target | Result |
|---|---|---|---|
| Rule catalogue | `impeccable detect --list-rules` | n/a | 62 rules (slop, layout and type rules, plus the advisory rules) |
| Source, directory | `detect --json app/views` (and `app/helpers`, `app/assets/stylesheets`) | directories | `[]`. **The directory walk skips `.erb`, `.scss` and `.rb` files**, so this pass checked nothing |
| Source, explicit files | `find app/views -name '*.erb' \| xargs detect --json` | 79 ERB files | 1 finding. The detector runs regex-only on `.erb`: the element rules (contrast, tiny-text and so on) do not run, so the count is an undercount |
| Source, explicit files | same for `app/assets/stylesheets/**/*.scss` (29), `app/helpers/*.rb`, `app/javascript/**/*.js` | each file | 0 findings |
| Rendered (CDP) | headless Chrome `--remote-debugging-port=9342`; logged in through the form; `Emulation.setDeviceMetricsOverride` held open in the driving session while `detect --cdp 9342 --target <url> --json` ran (viewport after each scan checked: unchanged) | 13 pages at **390×844** mobile (DPR 2, touch on): `/users/sign_in` (logged out), `/`, `/workout_days/11`, `/workout_exercises/17`, `/workout_logs/7`, `/workout_logs`, `/workout_logs/1`, `/splits`, `/splits/3`, `/dashboard/month`, `/exercises`, `/users/edit`, `/admin/equipment`. 3 pages at **1280×800**: `/`, `/workout_days/11`, `/workout_exercises/17` | 16 scans, all exited cleanly (exit 0 or 2) with empty stderr. **No step failed**, and no fallback was needed |

### Findings by rule

| Rule | Count | Where | Verdict |
|---|---|---|---|
| `overused-font` | 1 source + 15 rendered (every page except sign-in) | `app/views/layouts/application.html.erb:12` (Google Fonts `Inter` + `Plus Jakarta Sans`); rendered: "Primary font: inter (88% of text)" | **True, low priority (P3).** Both faces are on the detector's list. This is a brand-voice judgment, not a defect. |
| `text-overflow` | 2 | `/workout_logs/1` `#entry-4 > .card-header p.text-muted.small` (Pec Fly); `/workout_logs/7` `#entry-20 …` | **True (P2).** I verified it in the DOM: the column is 110 px wide and the text needs 127 px (scrollWidth). The text "Top 100 kg × 7 reps" is in a `.text-nowrap` span and runs 17 px under the "4 sets" chip. Screenshot: `shots/impeccable-b/ov.png`. |
| `pulsing-dot` | 3 (`/workout_days/11` ×2 viewports, `/workout_logs/7`) | `.is-running .timer-status::before`, `components/_timer.scss:46-61` | **False positive.** The dot belongs to a timer that is really running, which is live data. It animates opacity only, and `prefers-reduced-motion` turns it off (`_timer.scss:125-126`). |
| `straggler` (advisory) | 1 | `/exercises` `p.text-muted.mb-0`: the word "Yours". sits alone on the last line | True, cosmetic (P3). |

The detector reported **no** `low-contrast`, `tiny-text`, `skipped-heading`, `cramped-padding`, `body-text-viewport-edge`, `clipped-overflow-container` or `first-viewport-column-overflow` on any of the 16 scans.

---

## Contrast table

These ratios are computed from the tokens with the WCAG 2.x formula. The computed values were checked against `getComputedStyle` in the browser. AA thresholds: 4.5:1 for text, 3:1 for large text and non-text.

### Text

| Pair | Where | Ratio | AA |
|---|---|---|---|
| `$gray` #1C2024 on white / on `$light-gray` #F6F7F9 | body text | 16.39 / 15.29 | Pass |
| `$muted` #646B78 on white | eyebrow, table heads, bottom-nav labels (11 px), timer meta | 5.36 | Pass |
| `$muted` on `$light-gray` | meta on cards, which are page grey | 5.00 | Pass |
| `$muted` on `$surface-subtle` #FAFBFC | `.app-table th` (12 px) | 5.18 | Pass |
| `$muted` on `$primary-soft` #EEF0FF | outside-month days on this week's tinted row | 4.74 | Pass (tight) |
| `$muted` on `$chip-bg` #EEF0F3 | | 4.70 | Pass (tight) |
| `.text-muted` as rendered: rgba(28,32,36,.75) on white / on grey | 49 uses | 7.16 / 6.91 | Pass. **It is not the `$muted` token** (see the theming finding) |
| Placeholder rgba(28,32,36,.75) | all fields | 7.16 | Passes, but it is **too dark**: it reads as a typed value |
| `$chip-text` on `$chip-bg` | chips | 8.34 | Pass |
| `$done-text` #0B6B60 on `$done-bg` | "3 sets" chip, Running pill | 5.52 | Pass |
| `$rest-text` #8A5A00 on `$rest-bg` | Rest day chip, Paused pill | 5.31 | Pass |
| white on `$blue` #4F46E5 | primary buttons, planned calendar day | 6.29 | Pass |
| `$blue` on white / on grey / on `$primary-soft` | links, badge-soft (12 px), order badge | 6.29 / 5.87 / 5.55 | Pass |
| `$red` #CE2C31 on white / on grey; white on `$red` | danger text, `btn-danger` | 5.21 / 4.86 / 5.21 | Pass |
| `$red` on its 12% tint | flash-alert and confirm icons | 4.34 | Pass as non-text |
| `btn-light` text #000 on white | 44 uses | 21.0 | Pass. Off-token (should be `$gray`) |
| `btn-outline-secondary` text `$muted` on grey | Tag buttons | 5.00 | Pass |
| `$green` #12A594 / `$orange` #F76B15 as text on white | not used as text today | 3.07 / 2.97 | Would fail. Keep them as fills only |
| Disabled buttons | none rendered on the scanned pages; Bootstrap uses `opacity:.65` | n/a | Exempt (inactive control) |

### Non-text (WCAG 1.4.11, needs 3:1)

| Element | Pair | Ratio | AA |
|---|---|---|---|
| **Checkbox border** (`.form-check-input`, takes `$line`) | #E6E8EC on white / on grey card | **1.23 / 1.14** | **Fail** |
| **Text field border** (`$input-border-color: $line-strong`) | #D5D9E0 on white / on grey card | **1.42 / 1.32** | **Fail** |
| **Bootstrap focus ring** (`--bs-focus-ring-color` rgba(79,70,229,.25)) | on white | **1.47** | **Fail** |
| **`btn-light` focus ring** (rgba(211,212,213,.5), measured by tabbing) | on grey | **≈1.1** | **Fail** |
| Calendar "extra" ring `$extra-ring` #8C93F0 | on white | **2.78** | **Fail** |
| Calendar "extra" ring vs "today" ring `$blue` | ring against ring | 2.26 | The two states differ only by ring shade |
| Week-strip empty circle border `$line` | on white | 1.23 | Decorative, since the label carries the meaning |
| Card border `$line` on page | #E6E8EC on #F6F7F9 | 1.14 | Not required for static cards, but it is the only edge of the clickable `a.card-link` split cards |
| Hover halo `$hover-halo` | on white | 1.76 | Hover only. Acceptable |
| Flash success icon `$green` on its 12% tint | | 2.70 | Supplementary, since the text says it. P3 |
| Empty-state icon `$icon-faint` | on white | 1.95 | Decorative |
| Calendar planned / missed / today | `$blue` fill, dotted border and ring on white | 6.29 | Pass |
| Custom focus outlines (bottom nav, list toggle, calendar, back link) | 2px `$blue` | 6.29 | Pass |

---

## Touch target table (390×844, touch emulated, so `pointer: coarse` applies)

How I measured: `getBoundingClientRect` on every visible `a[href]`, `button`, `input`, `select`, `textarea`, `summary`, `[role=button]` and `label.btn`. The WCAG 2.5.8 spacing test uses a 24 px circle at each target's centre, checked against every other target. Raw data: `impB/run/meas/*.json`.

Phone pages with **no target under 44×44**:
- `/workout_logs/1` and `/workout_logs/7` (0 of 28 and 0 of 21)
- `/workout_days/11`: its 5 "still to do" `row-link`s are 158×42.2, and the row is taller
- `/exercises`
- `/admin/equipment`, apart from the hidden `.btn-check` inputs

| Target | Page(s) | Size (px) | <24? | 2.5.8 AA | Note |
|---|---|---|---|---|---|
| `.btn-check` radios and checkboxes (equipment, tags, muscle group) | exercise-17, admin-equipment, picker | 13×13 | yes | n/a | **False positive.** The input is visually hidden; the target is its `label.btn`, ≥44 tall on touch |
| `.form-check-input` checkboxes (Start timer automatically, Warm-up, Remember me, Unilateral, Add to shared catalogue) | /users/edit, /users/sign_in, picker | 15×15 (label 274×23 or 200×23 in the picker) | yes | Pass (label clickable, spaced) | The checkbox and label together are only about 23 px tall |
| Modal close `.btn-close` | exercise picker (`/workout_days/11`, `/splits/:id`), move modal | **31×31** | no | Pass | Under 44. It is the only visible way to close the picker |
| `a.link-quiet` "Change", "Month", "History" | `/` | 51×20.4, 42×20.4, 48×20.4 | **yes** | Pass by spacing | Under the app's own 44 px rule |
| `button.calendar-toggle` "November 2026" (folds the calendar) | `/` | 151×20.2 | **yes** | Pass by spacing | |
| `a.row-title` "U/R/L/U/L" (active split) | `/`, `/dashboard/month` | 85×21, 70×19 | **yes** | Pass on `/`; **spacing fails on /dashboard/month** | |
| `a.calendar-day` (logged or missed days) | `/`, `/dashboard/month` | **36×36** (8 per page) | no | Pass | Under 44 on the screen used to log a forgotten workout |
| `a.week-day` | `/`, `/splits/3` | 42.9×67.6 | no | Pass | Effectively fine |
| `a.stretched-link` split names | `/splits` | 21×21 to 87×21 | yes | **False positive**: the link stretches over the whole card | |
| Inline text links ("5 sets", "Saturday, November 21", History dates, "Sign up", "Forgot your password?", "Back") | `/`, `/workout_logs`, sign-in, account | about 15 to 19 tall | yes | Exempt (inline in a sentence) | The History date links (146×19) are the main link of each row. On `/workout_logs` the November 20 row (two workouts that day) fails the spacing test |
| Logged-out navbar "Log in" | `/users/sign_in` | 68×34.5 | no | Pass | |
| Navbar brand | most pages | 34×44.4 | no | Pass | |

At 1280×800 with a mouse, Bootstrap's compact sizes apply on purpose (`btn-sm` 29.7 tall, icon buttons 25 to 30 wide). That is acceptable for `pointer: fine`.

---

## Accessibility

- **Names:** I read the full accessibility tree in all 16 scans (`Accessibility.getFullAXTree`). **No button, link, textbox, combobox, checkbox or spinbutton is without an accessible name.** Every icon-only control has an `aria-label` that names its object: ×, ⋯, ›, the pen, ±, "Actions for set 1", "Remove Squat from this workout", "Edit the timer of Upper on November 16, 2026".
- **Decorative icons:** 36 of the 73 Font Awesome `<i>` tags have no `aria-hidden` (examples: `workout_days/show.html.erb:28,63,64`, `shared/_pagination.html.erb:5,11`, `shared/_confirm.html.erb:9`). Their buttons are already named, so this is P3.
- **Headings:** every page has exactly one `h1`, with `h2`s under it and no skipped levels. On `/dashboard/month` the h1 and the first h2 are both "November 2026" (P3).
- **Landmarks:** `nav[aria-label=Main]`, `main`, `nav[aria-label=Sections]` (the bottom tabs, after `main`, so keyboard users reach the content first), and `section[aria-label="Workout timer"]`. There is no skip link, but the landmarks satisfy 2.4.1.
- **Page titles:** **every page is titled "FitnessApp"** (2.4.2): the tab, history and screen-reader announcements never say which page is open.
- **Forms:** every visible field has a `<label>` or an `aria-label`. The add-set fields are labelled "Weight kg" and "Reps". Per-set edit fields have `aria-label` "Weight in kg of set 1" and so on. The login fields set `autocomplete` correctly. On `/users/edit` the email field has no `autocomplete="email"` but does have `autofocus` (P2).
- **Weight and reps inputs:**
  - `type="number"`, with `inputmode="decimal"` for weight and `"numeric"` for reps.
  - `step="any"`, so three decimals are accepted.
  - 16 px text, so iOS does not zoom in.
  - Weight and reps are pre-filled from the last set.
  - Not verified on a real device: a phone keyboard set to a comma-decimal locale (pt-BR) offers "," on the decimal pad, and whether `type=number` accepts "1,125" depends on the browser. Test this on the owner's phone.
- **Live regions:** flash messages use `role="status"` (notice) or `role="alert"` (alert). The clocks use `role="timer"` (implicitly `aria-live=off`, so it is not noisy). The calendar is `role="table"` with rows, cells and column headers.
- **Modals:** `role=dialog`, `aria-modal=true`, `aria-labelledby` pointing at the title. The app's own confirm box replaces `confirm()`.
- **Focus:**
  - Custom `:focus-visible` styles: bottom nav (`_bottom_nav.scss:30`), list toggles (`_list_toggle.scss:20`), calendar (`_dashboard_calendar.scss:74-92`), back link (`_layout.scss:59`), note box (`_workout_log.scss:91`).
  - Other links use the browser default ring, which is visible.
  - Bootstrap buttons, nav links and fields use translucent box-shadow rings: 1.47:1, and about 1.1:1 on `btn-light`. I confirmed this by tabbing 45 times with CDP key events on `/` at 1280.
- **Motion:**
  - `prefers-reduced-motion` is handled on purpose, not by a global kill: flash (`_flash.scss:107`), confirm (`_confirm.scss:66`), timer dot and press (`_timer.scss:125`). Bootstrap's `$enable-reduced-motion` (default true) covers collapse and modal.
  - Not guarded, all small and not vestibular: `a.card-link:hover` `translateY(-1px)` (`_cards.scss:33-38`), `:active scale(.94)` on the bottom nav and back link, chevron rotations, and the `.just-moved` background fade.
- **Drag and drop:** the `.drag-handle` is 44×44 with `touch-action: none` (`_lists.scss:67-77`). The ⋯ menu's Move up / Move down gives a non-drag alternative (2.5.7). I did not exercise the touch drag gesture: the evidence is from an emulated viewport only.

## Performance

| Asset | Size | Note |
|---|---|---|
| `application.css` (dev, not minified) | 392 KB raw / 58 KB gzip | All of Bootstrap is imported. Font Awesome `_icons.scss` adds **1,962 icon rules (~71 KB raw) for 26 icons used** (`application.scss:13`) |
| Font Awesome solid woff2 | **158 KB** | Plus regular, 25 KB, used for 2 icons (`fa-clock`, `fa-note-sticky`). **`font-display: block`** (`$fa-font-display` default), so ×, ⋯, › and the pen are blank for up to 3 s on a slow gym connection |
| Google Fonts | Inter 400/500/600 and Plus Jakarta Sans 600/700/800 (all six load on `/`), `display=swap`, `preconnect` on both hosts | Third-party fonts. Allowed in the CSP (`font-src fonts.gstatic.com`, `style-src fonts.googleapis.com`) |
| JS (modulepreloaded on every page, sign-in included) | turbo 28 KB gz, stimulus 11, bootstrap 16, popper 7 (**not minified**, 20 KB raw), sortablejs 17 (**not minified**, 52 KB raw), plus 15 small controllers | About 80 KB gzip. Sortable is only needed on 3 pages |
| Images | none (`<img>` 0, `<svg>` 0) | |

Other performance points:
- **Layout reads:** none in loops. `timer_controller.js` runs one `setInterval` per second and clears it in `disconnect()`.
- **Animations:** they run on `opacity` and `transform` only, except one-shot colour fades. No `will-change` anywhere.
- **Blur:** `backdrop-filter: blur(8px)` on the sticky navbar (`_navbar.scss:3`) and `blur(2px)` on modal backdrops (`_confirm.scss:71`). These repaint on scroll on low-end Android (P3).

## Theming

- **Tokens:** `config/_colors.scss` has 28 named colour tokens, and `config/_bootstrap_variables.scss` maps them onto Bootstrap. Hard-coded colours outside `config/`:
  - **1 hex**: `#fff` in `_lists.scss:87`
  - **19 literal `white`** declarations, e.g. `_bottom_nav.scss:10`, `_layout.scss:53,80`, `_split_week.scss:28,51,59,64`, `_dashboard_calendar.scss:60,67,74,79,85`, `_confirm.scss:13`, `_choices.scss:38`, `_dashboard_recent.scss:54`, `_flash.scss:29`
  - 10 `rgba()` / `color-mix()` calls, all built from tokens

  The tokens are Sass variables only, compiled in. The runtime CSS variables come from Bootstrap.
- **Drift from Bootstrap defaults** (verified with `getComputedStyle`):
  - `.card`, `.form-control`, `.dropdown-menu` and `.app-table td` are `#F6F7F9`, the same as the page (`$card-bg`, `$input-bg` and `$dropdown-bg` all default to `var(--bs-body-bg)`). Meanwhile `btn-light`, the back link, the bottom nav, flash cards and the dragged item are white, so buttons sit lighter than the cards they are in.
  - `.text-muted` is `rgba(28,32,36,.75)` (about #55585B), while custom components use `$muted` #646B78: two greys for one role. In 5.3, `$text-muted` (`_bootstrap_variables.scss:28`) no longer feeds `.text-muted`.
  - `btn-light` text is `#000`, not `$gray`.
  - `btn-outline-secondary` border is Bootstrap's #6C757D, not a token.
- **Dark mode:** none. There is no `prefers-color-scheme`, no `data-bs-theme` and no `<meta name="color-scheme">`. The app is light-only. The owner has not asked for dark mode, so this is not recommended as a feature, but it caps this dimension at 3.

## Responsive

- **390 px:** no horizontal overflow on any of the 13 phone pages.
- **320 px** (1.4.10 Reflow; desktop mode with touch, so the layout viewport stays fixed):
  - **`/` is 410 px wide.** The cause is `.recent-chips .chip` "Push/Pull/Legs + Upper/Lower hybrid (winter cut, 12 weeks)", 377 px wide, because `.chip { white-space: nowrap }` (`_lists.scss:36`).
  - `/workout_logs`: the history table is 477 px but scrolls inside its own box (data tables are exempt).
  - `/workout_days/11`, `/workout_exercises/17`, `/workout_logs/7`, `/dashboard/month` and `/splits/3` fit.
- **Text at 200%** (root font size, 320 px):
  - Overflows on `/` (chip, 820 px), `/workout_days/11` (row buttons, 542), `/workout_exercises/17` (set table, 455), `/workout_logs/7` and `/workout_logs/1` (`.entry-meta`, 494), `/splits/3` (`.entry-meta`, 609) and `/dashboard/month` (492).
  - Fine on `/splits`, `/exercises`, `/users/edit` and `/admin/equipment`.
- **Phone details:**
  - Good: safe areas (`viewport-fit=cover` + `env()`), inputs at 16 px, a bottom tab bar with its own padding (`_bottom_nav.scss:58-60`), and no `user-scalable=no`.
  - Sticky hover: `a.card-link:hover` (`_cards.scss:35`) is not inside `@media (hover: hover)`, so a tapped split card keeps its blue border and lift on touch.
- **Logged workout card header at 390:** the name column is 110 px. Names wrap to 3 lines ("Incline / dumbbell / press") and the Top line overflows by 17 px (see the detector finding). The grip column (about 60 px), chip, ⋯ and fold button take the rest.

---

## Findings

### P1: Major

**[P1] Checkboxes are nearly invisible**
- **Location:**
  - `/users/edit` ("Start the workout timer automatically", "Tag the first set… warm-up")
  - `/users/sign_in` ("Remember me")
  - exercise picker modal ("Unilateral", "Add to the shared catalogue")
  - Bootstrap's `.form-check-input` uses `--bs-border-color` = `$line` (`config/_bootstrap_variables.scss:29`)
  - Screenshot: `shots/impeccable-b/phone--account.png`
- **Category:** Accessibility
- **Impact:** At the gym, on a phone in daylight, an unchecked setting looks like empty space: border #E6E8EC on #F6F7F9 is 1.14:1. Users can miss that the option exists.
- **Standard:** WCAG 2.2 SC 1.4.11 Non-text Contrast (AA).
- **Fix:** in `_bootstrap_variables.scss` add `$form-check-input-border: 1px solid $muted;` (5.0:1 on grey). Optionally also `$form-check-input-width: 1.25em;` (about 19 px) so the box and label row reaches 24 px.
- **Command:** `/impeccable harden`

**[P1] Keyboard focus ring is invisible on light buttons and weak on all Bootstrap controls**
- **Location:**
  - every `.btn-light` (44 uses), measured ring rgba(211,212,213,.5), about 1.1:1
  - `.btn`, `.nav-link`, `.form-control`, `.form-select`: rgba(79,70,229,.25), 1.47:1
  - source: Bootstrap defaults; no override in `_bootstrap_variables.scss`
- **Category:** Accessibility
- **Impact:** A keyboard or switch user (or a Bluetooth keyboard on an iPad) cannot see which button is focused on most screens.
- **Standard:** WCAG 2.4.7 Focus Visible (AA), with 1.4.11 applied to the indicator.
- **Fix:**
  - In `_bootstrap_variables.scss` set `$focus-ring-opacity: 1; $focus-ring-width: .1875rem;` (3 px, $blue, 6.29:1). That also fixes `--bs-focus-ring-color`.
  - Add `.btn-light { --bs-btn-focus-shadow-rgb: #{to-rgb($blue)}; }` inside the `.btn-light` block in `components/_layout.scss:78`.
  - Or use one rule, `.btn:focus-visible, .form-control:focus, .form-select:focus, .nav-link:focus-visible { box-shadow: 0 0 0 3px $blue; }`, with a 2 px white gap (`0 0 0 2px white, 0 0 0 4px $blue`) on blue buttons.
- **Command:** `/impeccable harden`

**[P1] Home scrolls sideways at 320 px**
- **Location:** `/`, Recent workouts, `.recent-chips .chip` (`pages/_recent_workout.html.erb`). The style comes from `.chip { white-space: nowrap }` in `components/_lists.scss:36`. Measured: chip 377 px, page 410 px at a 320 px viewport.
- **Category:** Responsive
- **Impact:** Any split with a long name pushes the whole Home page sideways on small phones, and at 200% zoom on any phone. The bottom nav and every card then sit off-centre.
- **Standard:** WCAG 1.4.10 Reflow (AA, 320 CSS px).
- **Fix:** in `_lists.scss` give the chip `max-width: 100%; overflow: hidden; text-overflow: ellipsis;` and keep `white-space: nowrap`. Also set `min-width: 0` on `.recent-chips`. Or, for split-name chips only, use `white-space: normal; overflow-wrap: anywhere;`.
- **Command:** `/impeccable adapt`

### P2: Minor

**[P2] Text field borders too faint**
- **Location:** `$input-border-color: $line-strong` #D5D9E0 (`_bootstrap_variables.scss:39`): 1.42:1 on white, 1.32:1 on the grey cards (all fields, e.g. `phone--account.png`).
- **Category:** Accessibility
- **Impact:** Empty fields (Password, Note) are hard to find on a phone in bright light.
- **Standard:** WCAG 1.4.11.
- **Fix:** `$input-border-color: #8B929E;` (3.3:1 on white, 3.1:1 on #F6F7F9). Add it as a new token `$field-border` in `_colors.scss`, and keep `$line-strong` for hover.
- **Command:** `/impeccable harden`

**[P2] Green "valid" ✓ on every pre-filled field**
- **Location:**
  - `config/initializers/simple_form_bootstrap.rb:44` (`config.input_field_valid_class = 'is-valid'`) and the `valid_class: 'is-valid'` wrappers at lines 59, 69, 83, 95, 108, 118
  - simple_form marks any field with a value and no errors as valid
  - Seen on `/users/edit` (email), Rename split, Edit exercise, Edit workout day
  - Screenshots: `shots/png/phone--split-edit.png`, `impeccable-b/phone--account.png`
- **Category:** Implementation Integrity
- **Impact:** Feedback appears for validation that never ran. Green borders also make the one field that matters look different for no reason.
- **Fix:** set `config.input_field_valid_class = nil` and change each `valid_class: 'is-valid'` to `valid_class: nil`. Keep `error_class: 'is-invalid'`.
- **Command:** `/impeccable harden`

**[P2] Cards, fields and dropdowns are page-coloured**
- **Location:** `$body-bg: $light-gray` (`_bootstrap_variables.scss:7`) feeds `--bs-card-bg`, `--bs-body-bg` for `.form-control`, and `.dropdown-menu`. The stale comment is at `components/_flash.scss:1`.
- **Category:** Theming / Implementation Integrity
- **Impact:** A card is only a 1.14:1 hairline on the same grey. White `btn-light` buttons and chevron buttons sit *lighter* than the card they are in, so the elevation order is upside down. Fields are grey on grey.
- **Fix:** add a `$surface: white;` token and set `$card-bg: $surface; $input-bg: $surface; $dropdown-bg: $surface; $modal-content-bg: $surface; $table-bg: transparent;`. Then replace the 19 literal `white`s and `#fff` (`_lists.scss:87`) with `$surface`.
- **Command:** `/impeccable colorize`, then `/impeccable polish`

**[P2] Two greys for secondary text; placeholders look like typed values**
- **Location:**
  - `.text-muted` (49 uses) renders `--bs-secondary-color` = rgba(28,32,36,.75), about #55585B. Custom components use `$muted` #646B78. The line `$text-muted: $muted` (`_bootstrap_variables.scss:28`) has no effect in Bootstrap 5.3.
  - Placeholders use the same 7.16:1 grey: "Bench press" in the picker (`shots/impeccable-b/picker.png`) and "Brand name".
- **Category:** Theming / Accessibility (3.3.2 clarity)
- **Impact:**
  - Meta text is inconsistent: the eyebrow and table heads differ from card meta.
  - A placeholder that dark reads as a pre-filled exercise name, so users may think "Bench press" is already entered.
- **Fix:**
  - `$body-secondary-color: $muted;` (5.36:1 on white).
  - `$input-placeholder-color: $muted;`
  - Change the placeholders to examples: `"e.g. Bench press"`, `"e.g. Technogym"`.
- **Command:** `/impeccable typeset`

**[P2] Every page is titled "FitnessApp"**
- **Location:** `app/views/layouts/application.html.erb:4`
- **Category:** Accessibility
- **Impact:** Tabs, history entries, the iOS app switcher and screen readers cannot tell Home, the workout and History apart.
- **Standard:** WCAG 2.4.2 Page Titled (A).
- **Fix:** `<title><%= [page_title, "FitnessApp"].compact.join(" · ") %></title>`. `page_title` already exists (`shared/_navbar.html.erb:5`); prefer the record's name where there is one ("Hip thrust · FitnessApp").
- **Command:** `/impeccable harden`

**[P2] Logged workout card header overflows; names wrap to 3 lines**
- **Location:** `workout_logs/show.html.erb` `.card-header` (detector `text-overflow`: `#entry-4` on `/workout_logs/1`, `#entry-20` on `/workout_logs/7`). Screenshot: `shots/impeccable-b/ov.png`.
- **Category:** Responsive
- **Impact:** "Top 100 kg × 7 reps" runs under the "4 sets" chip. The name column is 110 px of a 342 px card, so "Incline dumbbell press" takes 3 lines.
- **Fix:** at `max-width: 575.98px`:
  - make `.drag-handle` 2.75rem wide with a negative left margin (`margin-left: -.75rem`) so it overlaps the card padding instead of adding to it
  - move `.entry-meta`'s chip under the name (`flex-wrap: wrap`, chip `order: 3; flex-basis: 100%`)
  - drop `.text-nowrap` on the Top span, or let it wrap as a whole
- **Command:** `/impeccable adapt`

**[P2] Add set is below the fold once an exercise has sets**
- **Location:** `workout_exercises/show.html.erb` with `workout_sets/_table` and `_form`.
- **Category:** Responsive / Implementation Integrity
- **Measured:**
  - With 3 sets, the weight field is at **y = 1473 px** on an 844 px viewport. Each set `<tbody>` is 171 to 197 px tall because the Tag button and the note field are always shown.
  - After adding a set from the dated URL (`?date=`), the morph keeps the scroll, so the form stays in view (verified).
  - Opened fresh (from the workout page), the user has to scroll about 700 px before every next set.
- **Impact:** Every exercise opened mid-workout costs a long scroll before the main action. This works against the product's first rule (few taps, little effort).
- **Fix:** keep it Hotwire-only:
  - put the add-set form above the set list, or pin it with `position: sticky; bottom: calc(3.75rem + env(safe-area-inset-bottom))`
  - fold each set's note field behind its Tag/⋯ until used, which brings rows down to about 60 px
- **Command:** `/impeccable layout`

**[P2] Small targets on Home and in modals**
- **Location:**
  - `/` "Change", "Month", "History" (`a.link-quiet`, 20.4 px tall)
  - the "November 2026" calendar toggle (20.2 px)
  - the active split title (21 px)
  - calendar days, 36×36 (`_dashboard_calendar.scss:42-49`)
  - modal `.btn-close`, 31×31
- **Category:** Responsive
- **Impact:** These pass AA 2.5.8 through spacing, but the app's own rule is 44 px (`_layout.scss:85`), and these are tapped at the gym. A missed day is the way to log a forgotten workout.
- **Fix:** inside the existing `@media (pointer: coarse)`:
  - `.link-quiet, .calendar-toggle, .row-title { display: inline-flex; align-items: center; min-height: 2.75rem; }`
  - `.btn-close { width: 2.75rem; height: 2.75rem; padding: 0; }`
  - `.calendar-day { width: 2.75rem; }` (a 7-column grid at 390 gives about 46 px per column)
- **Command:** `/impeccable adapt`

**[P2] The calendar "extra" ring is too faint and looks like "today"**
- **Location:** `$extra-ring: #8C93F0` (`_colors.scss:42`), used in `_dashboard_calendar.scss:64` and `_split_week.scss:58`.
- **Category:** Accessibility
- **Impact:** At 2.78:1 on white, the ring fails 3:1. A workout off the plan and today differ only by ring shade (2.26:1 between them).
- **Standard:** WCAG 1.4.11 and 1.4.1.
- **Fix:** make extra a **dashed** 2 px ring in `$blue` (`border: 2px dashed $blue`), which matches how the app already marks a missed day as dotted. Or darken it to `#6E76EC` (3.9:1) and also mark today with a dot under the number.
- **Command:** `/impeccable colorize`

**[P2] Font Awesome blocks icon rendering and ships 1,962 icons for 26**
- **Location:** `application.scss:13` (`font-awesome/icons`), `$fa-font-display: block` (default), and the 158 KB solid woff2.
- **Category:** Performance
- **Impact:** On a slow gym network, the icon-only buttons (×, ⋯, ›, pen, ±) are blank for up to 3 s.
- **Fix:**
  - Before the imports, set `$fa-font-display: swap;`.
  - Replace `@import "font-awesome/icons"` with only the 26 classes used (`@include fa-icon-solid($fa-var-xmark)` and so on, or a hand-written list of `.fa-xmark { --fa: "\f00d"; }`). That saves about 70 KB of CSS.
  - Longer term: an inline SVG sprite for the 26 icons, served from 'self', so the CSP is unchanged.
- **Command:** `/impeccable optimize`

**[P2] Account tab opens the keyboard every time**
- **Location:** `devise/registrations/edit.html.erb:21` (`autofocus: true` on email).
- **Category:** Responsive
- **Impact:** Account is a bottom-nav tab, and also the hub for Users, Equipment and Log out. Opening it pops the phone keyboard, which covers half the page.
- **Fix:** remove `autofocus: true` there. Keep it on the sign-in and sign-up forms. Add `autocomplete: "email"`.
- **Command:** `/impeccable harden`

**[P2] Text at 200% overflows**
- **Location:**
  - `/workout_days/11`: row action buttons, 542 px at a 320 viewport
  - `/workout_exercises/17`: set table, 455
  - `/workout_logs/:id`: `.entry-meta`, 494
  - `/splits/3`: 609
  - `/dashboard/month`: 492
- **Category:** Responsive
- **Impact:** Android users who raise the font size get sideways scrolling on the core logging pages.
- **Standard:** WCAG 1.4.4 Resize Text (AA).
- **Fix:**
  - `flex-wrap: wrap` on `.entry-meta` and the row action groups
  - `.set-table` columns at `min-width: 0` with `overflow-wrap: anywhere`
  - month list `li > :last-child { white-space: normal }` below 360 px
- **Command:** `/impeccable adapt`

### P3: Polish

**[P3] Overused fonts**
- **Location:** `layouts/application.html.erb:12`, `config/_fonts.scss`
- **Note:** the detector flags Inter and Plus Jakarta Sans. Keep them unless the owner wants a more distinctive voice. If changing, use one family for both roles to save three font files.
- **Command:** `/impeccable typeset`

**[P3] Sticky hover on split cards (touch)**
- **Location:** `_cards.scss:35`
- **Fix:** wrap `&:hover` in `@media (hover: hover)`, and add `@media (prefers-reduced-motion: reduce) { a.card-link:hover { transform: none; } }`.
- **Command:** `/impeccable polish`

**[P3] Blur on the sticky navbar and modal backdrops**
- **Location:** `_navbar.scss:3`, `_confirm.scss:71`
- **Note:** the blur repaints while scrolling on low-end Android.
- **Fix:** use `background: rgba(white, .97)` with no blur, or keep the blur only under `@media (min-width: 768px)`.
- **Command:** `/impeccable optimize`

**[P3] Unminified Popper and SortableJS preloaded on every page**
- **Location:** `config/importmap.rb` (`popper.js` 20 KB raw, `sortablejs` 52 KB raw). Sortable is only used on the split, workout day and logged workout pages.
- **Fix:** pin the `.min.js` builds, and import Sortable lazily inside `sortable_controller.js` (`await import("sortablejs")` in `connect`).
- **Command:** `/impeccable optimize`

**[P3] Decorative icons not hidden**
- **Location:** 36 of 73 `<i class="fa-…">` tags, e.g. `workout_days/show.html.erb:28,63,64`, `shared/_pagination.html.erb:5,11`, `shared/_flashes.html.erb:17,21`
- **Fix:** add `aria-hidden="true"`, or set it in one place with a helper.
- **Command:** `/impeccable harden`

**[P3] Off-token colours from Bootstrap**
- **Location:** `btn-light` text `#000` (fix: `--bs-btn-color: #{$gray}` in `_layout.scss:78`); the `btn-outline-secondary` border #6C757D (fix: `$secondary: $muted;`); 19 `white` and 1 `#fff` literals.
- **Command:** `/impeccable colorize`

**[P3] Small copy and structure nits**
- `/dashboard/month`: h1 and h2 are both "November 2026". Drop the card's h2 or make it "Calendar".
- `/exercises`: the straggler "Yours". (fix: `text-wrap: pretty`).
- The flash success icon is 2.70:1 (`$green` on its tint). Use `$done-text` #0B6B60 for the icon (5.5:1).
- No `<meta name="color-scheme" content="light">`. Add it so iOS form controls and scrollbars never switch to dark on a light page.
- **Command:** `/impeccable polish`

---

## Patterns and systemic issues

- **Bootstrap and simple_form defaults leak past the token layer.** This is one root cause for 6 findings: grey cards and fields, `.text-muted`, placeholder, `btn-light` colour, focus rings, and the green valid state. The fix is about 10 lines in `config/_bootstrap_variables.scss` and `config/initializers/simple_form_bootstrap.rb`.
- **Non-text contrast is the app's one accessibility gap.** Every text pair passes AA. Every failure is a boundary or indicator: checkbox, field, focus ring, extra ring.
- **`white-space: nowrap` on user-typed names** (`.chip`, `.top-set`, `.text-nowrap`) causes both the overflows found: Home at 320 px and the logged card header.

## Positive findings

- A real 44 px touch system through `@media (pointer: coarse)` (`_layout.scss:85-92`), with documented exceptions. On the logging pages (`/workout_days/11`, `/workout_logs/:id`, `/workout_exercises/17`) no visible control is under 44 px on a phone.
- Every interactive element in 16 accessibility-tree scans has an accessible name, and icon-only controls name their object.
- Number inputs are right for the gym: `inputmode` decimal or numeric, `step="any"`, 16 px, and pre-filled from the last set. Adding a set from the dated page keeps the scroll (Turbo morph `scroll: :preserve`).
- Motion is deliberate and accessible: opacity and transform only, no `will-change`, and reduced-motion alternatives on the flash, confirm and timer.
- Safe-area insets, `viewport-fit=cover`, and a strict CSP (no inline styles or scripts; the fonts are allowed).
- The colour tokens document their own contrast ratios, and those ratios are correct.

## Recommended actions

1. **[P1] `/impeccable harden`**: checkbox border `$muted`, focus ring at `$focus-ring-opacity: 1`, a `btn-light` focus colour, field border #8B929E, simple_form `valid_class: nil`, per-page `<title>`, no autofocus on Account.
2. **[P1] `/impeccable adapt`**: ellipsis on chips (320 px reflow), wrap `.entry-meta`, 44 px quiet links, calendar toggle and modal close, 200% text.
3. **[P2] `/impeccable layout`**: bring Add set into the first viewport on the exercise page (sticky or above the list; fold set notes).
4. **[P2] `/impeccable colorize`**: a `$surface` white token for cards, fields and dropdowns; one grey (`$body-secondary-color: $muted`); a dashed "extra" calendar ring.
5. **[P2] `/impeccable optimize`**: Font Awesome `font-display: swap` and the 26-icon subset; minified, lazily loaded Sortable; no navbar blur on phones.
6. **[P3] `/impeccable typeset`**: placeholders as "e.g. …"; decide whether to keep Inter and Plus Jakarta Sans.
7. **`/impeccable polish`**: the final pass (hover guard, `aria-hidden` on icons, month heading, `color-scheme` meta).

Not checked:
- the touch drag gesture itself (no synthesized touch)
- real-device behaviour of the decimal comma
- production-compiled CSS size (dev assets only)
- pages beyond the 13 listed, at the detector level (those are covered by the shared screenshots)

Chrome on port 9342 was killed after each run, and no Chrome process is left.

<!-- END VERBATIM FILE: evidence/scratchpad/reports/impeccable-B.md -->

<!-- BEGIN VERBATIM FILE: evidence/scratchpad/reports/emil.md | bytes: 40747 | sha256: 73467bc66a4faf9acc8a761f45a60a0aaa12d16f5215c7905d073d9a3280a39d -->
# Emil-style review: interaction polish, motion, mobile feel and worst-case data

Lens: emil-design-eng (main), review-animations + STANDARDS, mobile-native, break-ui (report only), remove-animations / find-animation-opportunities (read-only), apple-design (touch feel).
Repo read only. Paths are relative to the worktree `/home/pedro/code/pqdesu/fitness_app/.claude/worktrees/opus-plan-session-e72fa6`.
Screenshots: the brief's set in `.../scratchpad/shots/png/`, plus mine in `.../scratchpad/shots/emil/` (all 390 CSS px at 2x unless named `wc320-*`, `vp320-*` (320 px) or `wcdesk-*` (1280 px)).

## Overall verdict

The app is careful: 16px inputs, 44px targets, `inputmode` on every number, `viewport-fit=cover` with insets on the navbar and tab bar, tabular-nums on the clocks and tables, a confirm box with a strong ease-out curve, reduced-motion handled for the motion it adds. That part is better than most.

What keeps it from feeling professional and minimalist is mostly three things:
1. **Too much chrome per item.** Each set is three rows (numbers, a 44px "Tag" pill, a full note input with a blue arrow button). Each exercise row has a drag grip, a status chip, a pencil and a separate chevron button. With real data (long names, 14 sets, 17 exercises) that chrome pushes content into a 70px column, words break mid-word, and the page grows to 3,500 to 6,600 px.
2. **Hover and press states are not built for touch.** Ungated `:hover` everywhere (Bootstrap's and the app's), a blue Android tap flash everywhere except the tab bar, and almost no `:active` press feedback outside the timer card, back arrow and tab bar.
3. **Motion is Bootstrap's defaults.** 350ms `ease` collapses, a 300ms modal that drops 50px from above, 500ms flash cards with an `ease-in-out` exit, a 150ms SortableJS slide with no curve. None of it is wrong enough to block; all of it is slower and softer than the confirm box, which is the one piece tuned properly.

---

## P0: blocking

None. Nothing loses data or becomes unreachable at 390 px with realistic data. (Two overflows below come close: P1-1 and P1-2.)

---

## P1: major

### P1-1. A long split name widens the Home page past the phone (horizontal overflow)
- **Where:** `app/assets/stylesheets/components/_lists.scss:36` (`.chip { white-space: nowrap }`), used for the split name chip in Recent workouts (`pages/_recent_workout`) and History (`app/views/workout_logs/index.html.erb:48`).
- **Seen:** `wc-home.png`, `vp-home-recent.png`: the layout viewport becomes 410 px on a 390 px phone (the shot came out 410 wide), so the whole page can be panned sideways. `wc-history.png`: the chip "Push/Pull/Legs + Upper/Lower hybrid (winter cut, 12 we…" is cut off by the table edge with no ellipsis.
- **Data:** split name of 58 characters (limit is 60, `app/models/split.rb:6`).
- **Why:** a nowrap chip with no `max-width` is an unbreakable string.
- **Fix:**
  ```scss
  .chip { max-width: 100%; overflow: hidden; text-overflow: ellipsis; vertical-align: middle; }
  ```
  and add `title="<%= split.name %>"` on the split chip so the full name is reachable. The split name is secondary metadata here: truncate at the end.

### P1-2. Editing a set on a 320 px phone overflows the page by 67 px
- **Where:** `app/views/workout_sets/_set.html.erb:93-113` (the edit bar: Rest select, "min", select, "s", Save, Cancel on one flex row), `app/assets/stylesheets/pages/_workout_log.scss:11,104`.
- **Seen:** `vp320-exercise-editing.png`: the layout viewport jumps to 387 px; Cancel hangs over the card edge, and the card header no longer reaches the right edge. 390 px is fine.
- **Fix:** let the edit bar wrap, with the rest picker on its own line:
  ```scss
  .set-edit-bar { flex-wrap: wrap; row-gap: .5rem; }
  .rest-picker { flex: 1 1 100%; }
  ```
  On 360+ phones it stays on one line in practice; on 320 it wraps instead of overflowing.

### P1-3. Exercise rows squeeze the name into a ~70 px column; words break mid-word
- **Where:** `app/views/workout_days/_planned_exercise.html.erb:4-17` (grip, `.row-link`, status chip, pencil, chevron button) and the logged workout card header `app/views/workout_logs/show.html.erb:55-71` (grip, title, chip, ⋯, chevron). Bootstrap's `.card { word-wrap: break-word }` plus `.row-link { min-width: 0 }` (`components/_row_link.scss:6`) lets the browser break inside words.
- **Seen:** `wc-workout-day.png` and `vp-workout-day-longname.png`: the 74-character name takes 8 lines and the brand 7 more; "Stationar / y bike" breaks mid-word with ordinary catalogue data (no worst case needed). `wc-log-show.png`: the same, and the 300-character exercise note runs 20 lines in that column. `wc320-workout-day.png` is worse.
- **Why:** the trailing controls (chip 70px + pencil 44px + chevron button 44px + gaps 48px) take about 55% of the row. Two of them repeat what the row already does: the whole row is a link to the exercise (`row-link`), and the chevron button links to the same URL (`_planned_exercise.html.erb:17`).
- **Fix (subtract, do not add):**
  1. Remove the chevron button on `_planned_exercise.html.erb:17` (the row is the link; add a 12px muted `fa-chevron-right` inside `.row-link`'s end instead, `aria-hidden`).
  2. Move the admin pencil into the row's ⋯ menu (`actions_menu`), as the logged workout already does.
  3. Put the status ("3 sets", "No sets") under the name in the meta line instead of as a right-hand chip, or keep it right but `flex-shrink: 0` and drop "No sets" (absence already says it).
  4. On `.row-title`: `overflow-wrap: break-word; hyphens: auto;` (not `anywhere`), and on the meta line `display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden;` so a long brand never runs 7 lines.
  Result: the name gets ~270 px instead of ~70 px.

### P1-4. A set is three rows of chrome; notes are unreadable in a one-line input
- **Where:** `app/views/workout_sets/_set.html.erb:55-87`: every set renders a "Tag" pill button (44px tall on touch, `_layout.scss:90`) and a full-width note input with a primary blue submit button.
- **Seen:** `phone--today-exercise-hip-thrust.png` (3 sets ≈ 1,000 px), `wc-exercise-page.png` (14 sets = 3,534 px), `vp-exercise-top.png`: the 158-character note shows "Left knee felt off on the last two reps" and the rest is hidden inside a single-line `<input>`; there is no way to read it without tapping into the field and scrolling text.
- **Why (Emil):** at the gym the set row is the most-seen surface in the app. Fourteen blue arrow buttons and fourteen outlined pills are noise; the data (weight × reps) is the smallest thing on screen.
- **Fix:**
  - Show the note as text when it exists (`<p class="set-note-text">`, `font-size: .875rem; color: $muted; overflow-wrap: break-word`), and put "Note" and "Tag" as items in the set's existing ⋯ menu. Editing a note opens the row-edit state that already exists (`row_edit_controller.js`).
  - Tag chips stay as they are (they are data); the "Tag" button goes into the ⋯ menu.
  - If the owner wants the note field always there, at least make it a `<textarea rows="1">` with `field-sizing: content` (Chrome 123+, Safari 18.4+; falls back to one line) and a quiet ghost submit (`btn-link`, muted arrow) instead of `btn-primary`.
  Expected effect: a set becomes one 48px row (two with a note), 14 sets ≈ 700 px instead of 3,500.

### P1-5. Sticky hover on touch: a tag pill you untick still looks ticked
- **Where:** Bootstrap `.btn-outline-secondary:hover` (filled grey, white text) used for the tag pills (`workout_sets/_form.html.erb:55`, `_set.html.erb:73`) and `.btn-outline-primary:hover` for the choice pills (`components/_choices.scss`). Bootstrap's hover rules are not gated.
- **Why:** on a phone the first tap applies `:hover` and leaves it there. Ticking a tag fills it (checked), unticking it leaves it filled (hover), so the pill lies about its state until the user taps elsewhere. Same for "Free weights / Machine / Bodyweight".
- **Fix:** turn Bootstrap's hover off on touch, once, after `@import "bootstrap"`:
  ```scss
  @media (hover: none) {
    .btn:hover { color: var(--bs-btn-color); background-color: var(--bs-btn-bg); border-color: var(--bs-btn-border-color); }
    .btn-check:checked + .btn:hover { color: var(--bs-btn-active-color); background-color: var(--bs-btn-active-bg); border-color: var(--bs-btn-active-border-color); }
  }
  ```
  and gate the app's own hovers (list in P2-1).

### P1-6. No press feedback on almost anything; Android paints a blue tap flash instead
- **Where:** `-webkit-tap-highlight-color: transparent` exists only on `.bottom-nav-item` (`components/_bottom_nav.scss:25`). Computed on `<html>`: `rgba(51,181,229,.4)` (the default flash). `:active` scale exists only on `.back-link` (`_layout.scss:60`), `.bottom-nav-item` (`_bottom_nav.scss:28`) and `.timer-card .btn` (`_timer.scss:118-123`). Every other button (Add set, Continue, Add exercise, Save, ⋯, pills, chevrons, row links) only changes colour on `:active`, on Bootstrap's 150ms `ease-in-out`.
- **Why:** feedback must land on pointer-down (apple-design §1). The timer card shows the pattern is already known; it is just not global.
- **Fix** (one block, `components/_layout.scss`):
  ```scss
  html { -webkit-tap-highlight-color: transparent; }
  .btn, .bottom-nav-item, .back-link, .lift-pill, .recent-toggle, .choice-summary, .row-link {
    touch-action: manipulation;
    transition: color .15s ease, background-color .15s ease, border-color .15s ease, box-shadow .15s ease,
                transform .16s cubic-bezier(.23, 1, .32, 1);
  }
  .btn:active, .lift-pill:active, .choice-summary:active { transform: scale(.97); }
  .row-link:active, .recent-toggle:active { background: rgba($blue, .04); } // rows: tint, not scale
  @media (prefers-reduced-motion: reduce) { .btn:active, .lift-pill:active, .choice-summary:active { transform: none; } }
  ```
  Then delete the timer-specific copy (`_timer.scss:116-128`). Do not scale `.btn-check + .btn` pills inside a grid by more than .97.

### P1-7. The confirm box always shows a trash can, even for "Stop the timer?"
- **Where:** `app/views/shared/_confirm.html.erb:5` (fixed `fa-trash-can`), `app/javascript/confirm_dialog.js:24` (button says "Yes" for anything not Delete/Remove).
- **Seen:** `wc-workout-day--confirm.png`: "Stop the timer? It can't be resumed after." with a red trash icon and a red "Yes".
- **Why:** the icon is the first thing read; a bin says "something gets deleted". "Yes" is the weakest possible verb.
- **Fix:** let the message carry the verb and icon: in `confirm_dialog.js`, map the first word (`Delete|Remove` → trash, `Stop` → `fa-stop`, else `fa-circle-question`) and use that word as the button label ("Stop", "Delete", "Remove"); only fall back to "Yes" when the first word is not a verb. Swap the icon class on `[data-confirm-icon]`.

### P1-8. Full-screen picker modal: footer button sits in the home-indicator zone
- **Where:** `app/views/shared/_exercise_picker.html.erb:12` (`modal-fullscreen-sm-down`), no safe-area padding on `.modal-footer`.
- **Seen:** `phone--today-workout-lower--picker.png`: "Add selected" is flush with the bottom edge. With `viewport-fit=cover` (layout line 5) an iPhone draws the home indicator over it when Safari's toolbar is collapsed, and always in standalone.
- **Fix:**
  ```scss
  .modal-fullscreen-sm-down .modal-footer { padding-bottom: calc(.75rem + env(safe-area-inset-bottom, 0px)); }
  .modal-fullscreen-sm-down .modal-header { padding-top: calc(1rem + env(safe-area-inset-top, 0px)); }
  .modal-body { overscroll-behavior: contain; } // the page behind does not scroll when the list ends
  ```
  Needs a real iPhone to confirm.

---

## P2: minor

### P2-1. Ungated hover rules (sticky on touch)
| Before | After | Why |
| --- | --- | --- |
| `a.card-link:hover { border-color; box-shadow 0 6px 20px; transform: translateY(-1px) }` (`components/_cards.scss:33-39`) | Inside `@media (hover: hover) and (pointer: fine)`, and drop the lift and shadow: `border-color: rgba($blue,.4)` only, `transition: border-color .15s ease` | A tapped split card stays lifted and blue-shadowed on a phone; lift-on-hover is decoration on a tens/day surface |
| `div.card-link:hover` (`pages/_splits_cards.scss:15-18`) | Same gate | Sticky blue border |
| `.week-day:hover .week-circle { border-color: $blue }` (`pages/_split_week.scss:48`) | Move into the existing `@media (hover: hover)` on line 49, and make it `(hover: hover) and (pointer: fine)` | The halo is gated, the border is not: tapping a grey day leaves it blue-ringed |
| `.has-workout:hover { background: $blue; color: white }` (`pages/_dashboard_calendar.scss:74,85`) | Gate `:hover` (keep `:focus-visible` ungated) | Fills the day blue on tap, before navigation |
| `.recent-toggle:hover { background: $primary-soft }` (`pages/_dashboard_recent.scss:22`) | Gate | Row stays tinted after it is opened and closed |
| `button.lift-pill:hover`, `a.chip:hover`, `a.row-title:hover`, `.row-link:hover .row-title`, `.eyebrow a:hover`, `.back-link:hover`, `.btn-light:hover`, `.flash-close:hover`, `.actions-toggle:hover`, `.nav-link:hover` | One gate per file: `@media (hover: hover) and (pointer: fine) { … }` | The back arrow in particular stays tinted indigo after a tap, then Turbo restores the page from cache with it still tinted |
| `.calendar-day` halo `@media (hover: hover)` (`_dashboard_calendar.scss:55`) | `(hover: hover) and (pointer: fine)` | Some Android phones report `hover: hover` with a coarse pointer |

### P2-2. Bootstrap collapse: 350ms `ease`, used on every fold
- **Where:** Bootstrap default `$transition-collapse: height .35s ease`, used by fold cards, list toggles, the calendar, Recent workouts, tag lists, choice folds.
- **Why:** over the 300ms budget, a weak curve, and these folds are opened tens of times per session.
- **Fix:** in `config/_bootstrap_variables.scss`: `$transition-collapse: height .22s cubic-bezier(.23, 1, .32, 1);` (height animation of an accordion is the documented exception to "compositor-only"). Bootstrap's reduced-motion already sets it to none (verified: `.collapsing` computes `transition: none` under reduce).
- The chevrons (`_list_toggle.scss:22,43,58`, `_dashboard_calendar.scss:15`, `_dashboard_recent.scss:23,59`, `_choices.scss:42`) rotate in `.2s ease`: make them `transform .22s cubic-bezier(.23,1,.32,1)` so the arrow lands with the panel. Define once: `$ease-out: cubic-bezier(.23, 1, .32, 1); $dur-fold: .22s;` in `config/` and reuse (today the confirm box and timer each hard-code the curve).

### P2-3. Modals drop 50px from above in 300ms
- **Where:** Bootstrap default `$modal-fade-transform: translate(0, -50px)`, `$modal-transition: transform .3s ease-out`; used by the picker, Move a workout, rest-day pop-ups, timer alerts. The confirm box already overrides it well (`components/_confirm.scss:59-62`).
- **Fix:** centred dialogs match the confirm box: `$modal-fade-transform: scale(.96); $modal-transition: transform .2s cubic-bezier(.23, 1, .32, 1);` (then delete the confirm-specific override, it becomes the default). The full-screen picker on a phone should rise as a sheet: 
  ```scss
  @include media-breakpoint-down(sm) {
    .modal.fade .modal-fullscreen-sm-down { transform: translateY(1.5rem); transition: transform .3s cubic-bezier(.32, .72, 0, 1); }
    .modal.show .modal-fullscreen-sm-down { transform: none; }
  }
  ```
- `.modal-backdrop.show { backdrop-filter: blur(2px) }` (`_confirm.scss:71`): a full-viewport blur is the most expensive thing in the app on an older phone and adds little at 2px over a .45 tint. Remove it.

### P2-4. Flash cards: 500ms in, 500ms `ease-in-out` out, keyframes
- **Where:** `components/_flash.scss:34,36,95-101`; `flash_controller.js:53` waits 600ms.
- **Fix:**
  | Before | After | Why |
  | --- | --- | --- |
  | `animation: flash-in .5s ease-out` | `animation: flash-in .32s cubic-bezier(.23,1,.32,1)` | Toast budget is ~400ms; this one carries a status the user is waiting for |
  | `&.is-leaving { animation: flash-out .5s ease-in-out forwards }` | `animation: flash-out .2s ease-out forwards` | Exit faster than enter; ease-in-out delays the start |
  | `translateY(-.375rem)` | `translateY(-.75rem)` (from above, the edge it lives on) | 6px reads as a fade with a wobble, not a drop from the top |
  | `setTimeout(remove, 600)` | `setTimeout(remove, 250)` | Keep in step with the shorter exit |
  | Reduced motion: `animation: none` | Keep a 150ms opacity fade (`@keyframes flash-fade { from { opacity: 0 } }`) | Reduced motion means gentler, not none |
- `.flash-timer` (3px bar, `_flash.scss:78-89`): decorative on a 5s notice that already pauses on hover/focus. For minimalism, delete it (the controller's pause logic stays).
- **Placement:** `wc-exercise-page--flash.png` shows the card covering the back arrow for 5 seconds (`.flash-stack top: .75rem` over the sticky navbar). Either start the stack under the navbar on phones (`top: calc(4rem + env(safe-area-inset-top))`) or keep it but shorten notices to 3s; the back button is the most-tapped control after a save.

### P2-5. Drag and drop: 150ms with the default curve, no "picked up" state
- **Where:** `app/javascript/controllers/sortable_controller.js:18`, `components/_lists.scss:82-91`.
- **Fix:** `animation: 200, easing: "cubic-bezier(0.23, 1, 0.32, 1)"` (siblings make room in an ease-out). Add `.sortable-chosen .drag-handle { color: $blue }` so the grip reacts on press before the drag starts (pointer-down feedback). The lifted copy (`.sortable-drag` shadow `0 .75rem 1.75rem rgba($shadow,.18)`) is right; add `transform: scale(1.02)` to it for the "lifted" read. `delayOnTouchOnly` is not needed: the handle already owns the gesture (`touch-action: none`, `_lists.scss:77`), which is correct.
- `.just-moved` (`_lists.scss:61-62`): 1.6s background fade. Keep (it has a purpose: the eye follows the row), shorten to 1.2s `ease-out`. It is a colour fade, so it is fine under reduced motion.

### P2-6. No theme-color, no manifest: the app cannot feel installed
- **Where:** `app/views/layouts/application.html.erb:3-14`. Probed: no `meta[name=theme-color]`, no `link[rel=manifest]`, no `apple-mobile-web-app-*`. `public/apple-touch-icon.png` exists (iOS finds it by path).
- **Why:** used at the gym every day from the home screen, this app is the textbook case for standalone mode: no URL bar, the bottom tab bar where the thumb is, and the navbar colour in the status bar.
- **Fix:**
  ```html
  <meta name="theme-color" content="#ffffff">
  <meta name="apple-mobile-web-app-capable" content="yes">
  <meta name="apple-mobile-web-app-status-bar-style" content="default">
  <link rel="manifest" href="/manifest.json">
  ```
  Rails 8 ships `app/views/pwa/manifest.json.erb` and the route (`get "manifest" => "rails/pwa#manifest"`); enable it with `display: "standalone"`, `theme_color: "#ffffff"`, `background_color: "#F6F7F9"`. Also drop `shrink-to-fit=no` from the viewport (iOS 9 only). The app has no dark mode, so one theme-color is enough.

### P2-7. Turbo's progress bar is the wrong blue
- Probed `.turbo-progress-bar` computes `rgb(0,118,255)` (Turbo's default), not the app's indigo `#4F46E5`.
- **Fix:** `.turbo-progress-bar { height: 2px; background: $blue; }`.

### P2-8. Numbers break mid-figure and have no separators
- **Seen:** `wc-home.png` / `vp-home-week.png`: "Top weight 99999. / 125 kg" wraps inside the number (`pages/_dashboard_week.scss:19-27`, a quarter of a 4-column grid); same in `wc-month.png` totals. `vp-exercise-top.png`: "1234.125 kg", "99999.125 kg" with no thousands separator.
- **Data:** weight 99999.125 is accepted by the model (`workout_set.rb:23`, < 100,000).
- **Fix:** `.week-summary dd { white-space: nowrap; }` and let the figure shrink instead: `font-size: clamp(1rem, 5vw, 1.25rem)`. Format weights with `number_with_delimiter` / `number_with_precision(strip_insignificant_zeros: true, delimiter: ",")` in `format_weight` so it reads "1,234.125 kg". Never truncate numbers.

### P2-9. The Tag pill and the tag chips sit on one line at two heights
- **Seen:** `vp-exercise-top.png`: chips "Assisted / Drop set / Warm-up" are 22px tall, the "Tag" button beside them is 44px (coarse-pointer `btn-sm` padding, `_layout.scss:90`), an outlined grey pill. The row looks misaligned and the button is the loudest thing on it.
- **Fix:** if it stays (see P1-4), make it a chip-height ghost: `.set-tag-toggle { min-width: 0; padding: .125rem .625rem; border-style: dashed; border-color: $line-strong; }` with a 44px hit area through `::before { content:""; position:absolute; inset:-11px 0; }`.

### P2-10. Paused-timer and rest alerts, confirm: button verbs and icons
- Covered for the confirm box in P1-7. The paused-timer alert (`workout_logs/_timer_alert`) uses the blue icon well (`_timer.scss:145-148`). Keep.

### P2-11. Disabled state during Turbo submits
- Turbo disables the submitter while the request runs; Bootstrap then paints it at `opacity: .65`. On a fast LAN that is a one-frame grey flash on every Add set, which reads as a glitch, not a state. On a slow gym connection there is no other sign.
- **Fix:** `form[aria-busy="true"] .btn:disabled { opacity: 1; cursor: progress; }` (Turbo sets `aria-busy` on the form) plus the themed progress bar (P2-7) for anything over 500ms. Optional, nice: `data-turbo-submits-with="Adding…"` on Add set only. (Moderate confidence on Turbo's exact disable timing; verify in DevTools with network throttling.)

### P2-12. The workout day page header and the exercise page repeat counts and dates
- `phone--today-workout-lower.png`: "Today · Wednesday, November 25 / 2 exercises · 5 sets" under the title, then "In this workout · 2". `wc-workout-day.png`: "1 exercise · 14 sets" above a list headed "In this workout · 17": the two counts disagree in meaning (exercises with sets vs exercises in the workout). Drop the header count line; the card heading carries it.
- `phone--today-exercise-hip-thrust.png`: "Today / November 25, 2026" card header on a page reached from today's workout. Drop the date (the back trail already says where you are) or keep "Today" only.

### P2-13. Picker modal: nine outlined blue pills and no search
- `phone--today-workout-lower--picker.png`: the muscle-group pills are 9 blue outlined buttons with a filled one; this is the loudest block in the app. Make unselected pills neutral (`btn-light`, `$chip-text`), only the checked one blue. A search field at the top of the list (filtering rows client-side, `type="search" enterkeyhint="search"`) would cut taps more than any motion change; flagging, not proposing as motion.

---

## P3: polish

| # | Before | After | Why |
| --- | --- | --- | --- |
| 1 | `.back-link:active { transform: scale(.94) }` with no `transform` in its `transition` (`_layout.scss:57,60`) | add `transform .16s cubic-bezier(.23,1,.32,1)`; scale `.96` | It snaps in and out; it should give and release |
| 2 | `.bottom-nav-item { transition: color .15s, transform .1s }`, `:active scale(.94)` (`_bottom_nav.scss:26,28`) | `transform .12s cubic-bezier(.23,1,.32,1)`, `scale(.96)`; add `-webkit-touch-callout: none; user-select: none` | Tab bar is tapped 100+ times a day: subtle and fast; long-press should not open the link callout |
| 3 | No active indicator motion on the tab bar | Leave it instant | 100+/day navigation: no animation, correct as is |
| 4 | `.timer-status::before` breathing dot, `2s ease-in-out infinite`, opacity (`_timer.scss:53`) | Keep; it is state indication, opacity only, and reduced motion stops it (`:126`) | Passes the gate |
| 5 | `.timer-clock` font-variant-numeric: tabular-nums (`_timer.scss:71`), `.rest-clock` (`_workout_log.scss:100`) | Keep; also add `tabular-nums` to `.timer-meta` (paused time counts up in it, `.timer-paused` has it but "Started" line does not) and `.history-counts` | No jitter while counting |
| 6 | Set table numbers left-aligned (`td` computes `text-align: start`) | Right-align Weight with `tabular-nums`, header too: `.set-table td:nth-child(2), th:nth-child(2) { text-align: end; padding-right: 1.5rem }` | 0.5 kg, 35 kg and 1,234.125 kg line up on the decimal side |
| 7 | `.order-badge` set numbers in indigo on indigo-soft (`_lists.scss:45-56`) | Plain muted numerals, no badge: `color: $muted; font-weight: 600; background: none` | Set numbers are an index, not a status; one less tinted shape per row |
| 8 | Borders `$line: #E6E8EC` opaque everywhere (`config/_colors.scss:14`) | `rgba(#101828, .08)` | A semi-transparent border reads the same on white cards, the `#F6F7F9` page, the tinted current-week row and `.just-moved` |
| 9 | Radii: 8 (inputs sm), 10 (btn, input), 12 (choice-summary, sortable-drag), 14 (lg), 16 (card, flash), 24 (confirm), pill | 3 steps: 10 controls, 16 cards and sheets, pill only for chips/status | Fewer radii read as one system |
| 10 | Card shadow `0 1px 2px rgba(.04)` + 1px border (`_cards.scss:3`) | Keep one of them: border only on the gray page, or shadow `0 0 0 1px rgba(16,24,40,.06), 0 1px 2px rgba(16,24,40,.04)` and no border | Border + shadow doubles the edge |
| 11 | Active split card: `border-color: $blue; box-shadow: 0 0 0 2px $blue` (`_splits_cards.scss:6-9`), and on Home the same 2px indigo ring (`phone--home.png`) | `box-shadow: 0 0 0 1.5px rgba($blue,.5)` or just the "Active" badge | The thick ring is the loudest frame on Home and the split list |
| 12 | `h1` no `text-wrap` (computed `wrap`) | `h1, h2, .row-title { text-wrap: balance } p, .entry-note { text-wrap: pretty }` | The 74-char exercise title breaks "…with rope and / a pause at the top" unevenly (`vp-exercise-top.png`) |
| 13 | `.picker-group` uppercase `.04em` (`_exercise_picker.scss:10`) | `.06em` and `font-size: .7rem` | Uppercase at 12px wants a touch more tracking |
| 14 | `.page-header h1 { letter-spacing: -.02em }` at 28px | `-.025em` at 28px, and `-.01em` on h2 1.05rem | Plus Jakarta tightens well at display sizes |
| 15 | Icons in buttons at `.85em` with `margin-right: .25rem` (`_layout.scss:75`) | `.875em`, `margin-right: .375rem`, `vertical-align: -.0625em` | Font Awesome solid glyphs sit high next to Inter caps |
| 16 | The pencil (`fa-pen`, solid, blue) per row (`_planned_exercise.html.erb:15`) | Move to ⋯ (P1-3); if kept, muted colour | Blue is for the primary action |
| 17 | `.calendar-day` `title` tooltip only | Fine on desktop; on touch the dotted/filled states need the legend: one muted line under the calendar | Native `title` never shows on a phone |
| 18 | Viewport `shrink-to-fit=no` | Remove | Obsolete (iOS 9) |
| 19 | `html` `overscroll-behavior: auto` | Keep on the page (pull-to-refresh is useful in a document app); `contain` on `.modal-body` and `.dropdown-menu` | Stops the page scrolling behind a list that ended |
| 20 | Dropdown (⋯ menu) opens with no motion (`ActionsMenuHelper#actions_menu`, Popper fixed) | Keep instant | Tens/day; an animated menu here would only slow the edit |
| 21 | `.week-circle` `transition: border-color .15s, background-color .15s, outline-color .15s` (`_split_week.scss:34`) | `.15s ease` explicitly; fine | Hover/colour → `ease` |
| 22 | `transition: background .15s` on `.recent-toggle` (`_dashboard_recent.scss:20`) | `background-color .15s ease` | Name the property |
| 23 | Empty states (`components/_empty_state.scss`) | Fine: muted icon `$icon-faint`, short copy. No skeletons needed: pages are server-rendered | — |
| 24 | `.flash-close`, ⋯, pencil: 44px targets | Keep | Correct |

---

## Motion inventory (every transition, animation and keyframes)

| # | Where | What | Property | Duration / easing | Verdict |
| --- | --- | --- | --- | --- | --- |
| 1 | `_layout.scss:57` `.back-link` | hover/focus tint | color, bg, border | .15s ease | Gate hover; add transform (P3-1) |
| 2 | `_layout.scss:60` `.back-link:active` | press | transform scale(.94) | none (snaps) | Retune: .16s strong ease-out, .96 |
| 3 | `_bottom_nav.scss:26,28` | tab press | color, transform | .15s / .1s ease | Retune to .12s strong ease-out, .96 |
| 4 | `_bottom_nav.scss:53` | active pill bg | background-color | .15s ease | Keep (or remove: tab changes are page loads, it never animates in practice) |
| 5 | `_cards.scss:33` `a.card-link` | hover lift | border, box-shadow, transform | .15s ease | Remove lift and shadow, gate (P2-1) |
| 6 | `_splits_cards.scss:16` `div.card-link` | hover border | border, shadow | .15s | Gate |
| 7 | `_flash.scss:34` | flash in | opacity + translateY (keyframes) | .5s ease-out | Retune .32s strong ease-out (P2-4) |
| 8 | `_flash.scss:36` | flash out | opacity + translateY | .5s ease-in-out | Retune .2s ease-out |
| 9 | `_flash.scss:88` | 5s countdown bar | transform scaleX | 5s linear | Remove (decoration) or keep; linear is right for progress |
| 10 | `_confirm.scss:59-62` | confirm box in/out | transform scale(.96) | .2s cubic-bezier(.23,1,.32,1) | The model to copy; make it the Bootstrap default |
| 11 | `_confirm.scss:71` | backdrop blur | backdrop-filter | (Bootstrap fade .15s linear) | Remove the blur |
| 12 | `_timer.scss:53` | live dot | opacity keyframes | 2s ease-in-out infinite | Keep (state), reduced-motion handled |
| 13 | `_timer.scss:118-123` | timer buttons press | transform scale(.97) | .16s strong ease-out | Correct; make global (P1-6) |
| 14 | `_lists.scss:61` `.just-moved` | moved-row highlight | background-color keyframes | 1.6s ease-out | Keep, 1.2s |
| 15 | `_list_toggle.scss:22,43,58` | chevron rotate | transform | .2s ease | Retune .22s strong ease-out |
| 16 | `_dashboard_calendar.scss:15` | chevron | transform | .2s ease | Same |
| 17 | `_dashboard_calendar.scss:54` | day halo | outline-color | .15s ease | Keep, gate `pointer: fine` |
| 18 | `_dashboard_calendar.scss:72` | logged day fill on hover | background, color | .15s ease | Gate hover |
| 19 | `_dashboard_recent.scss:20,23,59` | row tint, chevrons | background, transform | .15s / .2s | Gate hover; chevrons retune |
| 20 | `_choices.scss:42` | chevron | transform | .2s | Retune |
| 21 | `_split_week.scss:34` | week circle | border, bg, outline | .15s | Keep, gate the border hover |
| 22 | Bootstrap `.collapsing` | every fold | height | .35s ease | Retune .22s strong ease-out (P2-2) |
| 23 | Bootstrap `.modal.fade .modal-dialog` | every modal | transform translateY(-50px) | .3s ease-out | Retune scale(.96) .2s; picker as sheet (P2-3) |
| 24 | Bootstrap `.fade` | modal/backdrop opacity | opacity | .15s linear | Keep |
| 25 | Bootstrap `.btn` | colour states | color, bg, border, shadow | .15s ease-in-out | Add transform; `ease` for colour |
| 26 | Bootstrap `.form-control` | focus ring | border, box-shadow | .15s ease-in-out | Keep |
| 27 | `sortable_controller.js:18` | siblings make room | transform (SortableJS) | 150ms, no easing set | 200ms strong ease-out (P2-5) |
| 28 | `flash_controller.js:53` | removal wait | setTimeout 600 | — | 250 with the shorter exit |
| 29 | `timer_controller.js:12` | clock tick | textContent, 1s interval | — | Not motion; fine. Note `setInterval(1000)` drifts and can skip a second when the tab is throttled: align to the next whole second with `setTimeout(tick, 1000 - (Date.now() % 1000))` |

Prefers-reduced-motion: handled for flash, confirm box, timer dot and button press, and by Bootstrap for collapse, modal and fade (verified: `.collapsing` and `.modal-dialog` compute `transition: none` under reduce). Missing: card lift (`_cards.scss:38`) and back/tab-bar scale; both become moot with P1-6 and P2-1.

### What to remove (remove-animations gate)
1. Card hover lift and shadow growth (`_cards.scss:35-39`): tens/day, decoration, sticky on touch.
2. Backdrop blur (`_confirm.scss:71`): cost with no purpose.
3. The flash countdown bar (`_flash.scss:78-92`): decoration; the pause-on-hover logic is the useful part.

### Where motion would genuinely help (find-animation-opportunities, few on purpose)
| # | Location | Today | Purpose | Frequency | Suggested motion |
| --- | --- | --- | --- | --- | --- |
| 1 | New set row after Add set (`workout_sets/_set`, page morph) | The row appears with no sign it is new; the flash says "Set 4 added" at the top of the screen, far from the thumb | Feedback, preventing a jarring change | Tens per workout | Reuse `.just-moved`: give the new set's `tbody` the class via `flash[:moved]`-style id, a 600ms `background-color` fade from `$primary-soft` (colour only, no slide). Then the "Set n added" notice can go: the row itself confirms it |
| 2 | Timer Start → Running (`workout_logs/_timer`) | The card swaps state on reload | State indication | Once per workout | `@starting-style` on `.is-running .timer-status`: `opacity: 0; transform: scale(.96)` → settled, `transition: opacity .2s ease-out, transform .2s cubic-bezier(.23,1,.32,1)` |
| 3 | Rest timer Start/Stop (`workout_sets/_rest_timer`) | Swap | State indication | Tens per workout | Nothing beyond the global press scale: frequency too high |
| 4 | Full-screen picker on phone | Drops from above | Spatial consistency | Few per workout | Rise 1.5rem with the drawer curve (P2-3) |

Rejected: animating the ⋯ menu, tab bar changes, calendar month fold beyond the collapse retune, chips, counts ticking up, the week strip. All are frequent or functional.

---

## Mobile-native checklist

| Item | State | Evidence | Action |
| --- | --- | --- | --- |
| viewport meta | `width=device-width, initial-scale=1, shrink-to-fit=no, viewport-fit=cover` | layout:5 | Drop `shrink-to-fit=no`; consider `interactive-widget=resizes-content` so Android's keyboard does not cover Add set |
| Zoom allowed | Yes (no `maximum-scale`) | layout:5 | Good |
| Input font ≥ 16px | Yes, all `.form-control`/`.form-select` incl. `-sm` compute 16px | `_bootstrap_variables.scss:12-13`, probed | Good |
| inputmode | `decimal` on weights/incline/speed, `numeric` on reps/minutes/seconds | `_form.html.erb:26,31,37`, `_set.html.erb:24,30,38`, cardio forms | Good. Add `enterkeyhint="done"` on reps and `enterkeyhint="send"` on notes |
| 100vh vs dvh | No `vh` anywhere | grep | Good |
| Safe areas | Navbar top, tab bar bottom, body left/right, back arrow, flash top | `_navbar.scss:5`, `_bottom_nav.scss:8-9`, `_layout.scss:4-7,67-68`, `_flash.scss:6` | Missing on full-screen modal header/footer (P1-8) |
| Tap highlight | Only the tab bar | `_bottom_nav.scss:25` | Global (P1-6) |
| touch-action | `none` on drag handles only; buttons `auto` | `_lists.scss:77`, probed | `manipulation` on controls (P1-6) |
| user-select | Bootstrap `.btn` none; drag handle none; links-as-controls (tab bar, row links) selectable | probed | Add to `.bottom-nav-item` (P3-2) |
| Sticky hover | Many ungated (P1-5, P2-1) | — | Gate |
| overscroll | `auto` | probed | `contain` in modal bodies (P1-8) |
| theme-color | Missing | probed | Add (P2-6) |
| Manifest / standalone | Missing | probed | Add (P2-6) |
| Real device | Not tested | — | Sticky hover, tap flash, safe areas and the keyboard over Add set need an iPhone and an Android phone |

---

## Worst-case data (break-ui, report only)

Created through the running app on port 3001 (requests from the logged-in page, plus two `rails runner` updates on the audit database only: timer backdated 3 h 4 min with 12 min 34 s paused, one set given a 3 h 2 min rest and all three tags, and the long logged exercise linked to its plan row so the exercise page shows its sets).

| Field | Limit (source) | Worst case used |
| --- | --- | --- |
| Exercise name | 80 (`exercise.rb:29`) | "Single-arm cable rear delt fly, kneeling, with rope and a pause at the top" (74) |
| Machine brand | 60 (`equipped.rb:19`) | "Hammer Strength by Life Fitness, Plate-Loaded Iso-Lateral" (57) |
| Split name | 60 (`split.rb:6`) | "Push/Pull/Legs + Upper/Lower hybrid (winter cut, 12 weeks)" (58) |
| Weight | ±100,000 (`workout_set.rb:23`) | 1234.125, 99999.125, 0.5, empty |
| Reps | none found | 999, 1 |
| Set note | 200 (`workout_set.rb:32`) | 158-char sentence |
| Logged exercise note | 500 | 300-char paragraph |
| Sets on one exercise | none | 14 |
| Exercises in a workout | none | 17 (incl. 4 cardio) |
| Timer | — | running 2 h 52 min, paused 12 min 34 s; rest 3 h 2 min 5 s |
| Flash message | none | "Barbell curl, Barbell row, … and Upper back row added to this workout." (16 names) |

| # | Severity | Field | What happens | Screenshot | Fix |
| --- | --- | --- | --- | --- | --- |
| 1 | Broken | split name chip | Home page 410 px wide on a 390 phone; History chip clipped with no ellipsis | `wc-home.png`, `vp-home-recent.png`, `wc-history.png` | P1-1 |
| 2 | Broken | set edit bar at 320 px | Page widens to 387 px | `vp320-exercise-editing.png` | P1-2 |
| 3 | Ugly | exercise name + brand in rows | 8 + 7 lines in a 70 px column; "Stationar/y bike" breaks mid-word even with catalogue data | `wc-workout-day.png`, `vp-workout-day-longname.png`, `wc-log-show.png`, `wc320-workout-day.png` | P1-3 |
| 4 | Broken (content unreadable) | set note | 158-char note hidden in a one-line input | `vp-exercise-top.png` | P1-4 |
| 5 | Ugly | logged exercise note | 20-line column in the card header | `wc-log-show.png` | P1-3; clamp to 2 lines with "more" in the open card |
| 6 | Ugly | top weight 99999.125 | "99999. / 125 kg" wraps inside the figure | `wc-home.png`, `wc-month.png` | P2-8 |
| 7 | Ugly | weights ≥ 1000 | "1234.125 kg" with no separator | `vp-exercise-top.png` | P2-8 |
| 8 | Ugly | 14 sets | Exercise page 3,534 px tall; 14 blue arrow buttons | `wc-exercise-page.png` | P1-4 |
| 9 | Ugly | 17 exercises | Workout page 6,000 px; log page 6,642 px | `wc-workout-day.png`, `wc-log-show.png`, `wc-log-show--expanded.png` | P1-3 (rows shrink to ~64 px each) |
| 10 | Fragile | header counts | "1 exercise · 14 sets" above "In this workout · 17" | `vp-workout-day-longname.png` | P2-12 |
| 11 | Fragile | rest picker | 3 h rest makes the minutes select list 0-182 | `vp320-exercise-editing.png` | Cap display at 30 + "longer" or show the value as text |
| 12 | Fine | long exercise name as page title | Wraps on 3 lines, readable; balance would help | `vp-exercise-top.png` | P3-12 |
| 13 | Fine | long split name on Splits and Month | Wraps cleanly in the card title and the month list | `wc-splits.png`, `wc-month.png` | — |
| 14 | Fine | long flash message | `overflow-wrap: anywhere` on `.flash-text`, card grows | (seen in the seed responses; the flash card wraps) | — |
| 15 | Fine | 3-hour timer | "2:52:20" and "paused 12 min 34 s" fit; clock is tabular | `wc-workout-day.png` | — |
| 16 | Fine | 1 rep, 0.5 kg | Render fine | `wc-exercise-page.png` | — |
| 17 | Fine | 999 reps, 1234.125 kg in the set row | Fits at 390 and 320 | `vp-exercise-top.png`, `wc320-exercise-page.png` | Right-align (P3-6) |

Not checked: RTL, dark mode (the app has neither), 200% browser zoom, non-Latin names.

---

## The 10 changes that would make it feel professional and minimalist

1. **One row per set.** Note as text when present; Note and Tag move into the set's ⋯ menu (P1-4). Biggest single cut in visual noise and page length.
2. **One tap target per exercise row.** Drop the duplicate chevron button and the inline pencil; the row is the link (P1-3). Names get 4x the width and stop breaking mid-word.
3. **Global press feedback and no tap flash:** `-webkit-tap-highlight-color: transparent`, `touch-action: manipulation`, `:active { scale(.97) }` at 160ms `cubic-bezier(.23,1,.32,1)` on every button (P1-6).
4. **Gate every hover** behind `(hover: hover) and (pointer: fine)`, including Bootstrap's button hovers, so ticked/unticked pills tell the truth (P1-5, P2-1).
5. **One motion vocabulary:** `$ease-out: cubic-bezier(.23,1,.32,1)`; folds 220ms, modals `scale(.96)` 200ms, flash in 320ms / out 200ms, Sortable 200ms; delete the card lift and the backdrop blur (P2-2 to P2-5).
6. **Quiet the blue.** Blue for the one primary action per screen; muted for pencils, set numbers, note arrows, unselected pills; a lighter ring on the active split (P2-13, P3-7, P3-11, P3-16).
7. **Truncate metadata, never numbers:** ellipsis on chips with `max-width: 100%`, clamp meta lines to 2, `nowrap` + separators on weights (P1-1, P2-8).
8. **Make it installable:** theme-color, manifest with `display: standalone`, safe-area padding on full-screen modals (P2-6, P1-8).
9. **Right verbs in the confirm box:** icon and button from the message ("Stop", "Delete"), never a bin on a non-delete and never a bare "Yes" (P1-7).
10. **Cut repeated information:** header counts that restate the card, the "Today / date" header on the exercise page, the flash after Add set once the new row lights up (P2-12, motion opportunity 1).

<!-- END VERBATIM FILE: evidence/scratchpad/reports/emil.md -->

<!-- BEGIN VERBATIM FILE: evidence/scratchpad/new-look/DIRECTION.md | bytes: 28916 | sha256: 9096d8c17615d03b1bea3220aaf760d626482019aea450b6634a8c92cbb0cd52 -->
# Readout: a new look for the fitness app

**Idea.** The phone becomes a gym instrument: graphite and bone surfaces, 1px hairlines in place of shadows, and every number (weights, reps, clock, stats, dates) set in a monospaced face like a display. One signal orange marks what is live (running timer, today) and the one thing to press next (Start workout, Continue, Add set, Add exercise, Add selected). Everything else stays monochrome.

Concept page: `index.html` in this folder (open it in a browser and use the Light / Dark / Auto switch). Screenshots: `shot-1440-light.png`, `shot-1440-dark.png`, `shot-390-light.png`, `shot-390-dark.png`, `frame-*.png` (each phone at 2x), `ds-*.png` (the system panel).

## Why it fits a gym logger

- **Read at arm's length, between sets.** Mono numerals do not shift width while the clock ticks or weights change (tabular). Weights and reps go up to 22px, the clock to 56px. You can read "90 kg × 8" from a bench.
- **One colour means "do this".** Today the app uses indigo for links, chips, calendar days, buttons, borders and the active split card. You cannot tell the main action from decoration. In Readout orange is only for the main action and for live state. On any screen your thumb finds the orange button.
- **Fewer boxes.** The app now puts a boxed chevron button, a pen and a chip on every row, a white card around every list and a shadow on every card. Readout keeps cards but drops the shadows. A row is one link with a quiet chevron, and the admin pen is a small ghost icon.
- **Dark mode that is actually dark.** Gyms are dim and screens get checked mid-set. A true graphite dark theme (#0E0F10) follows the phone's setting through `prefers-color-scheme`, with no toggle and no JavaScript.
- **Futuristic without effects.** No gradients, glow or glass. The future look comes from mono uppercase micro labels, hairlines, square-capped line icons, a breathing ring on the live dot and a one-minute seconds sweep under the clock.

## Product truth kept (nothing added, nothing removed)

Every screen keeps its content and actions: the Today box (Start workout, then Continue; the stats line; Show/Hide exercises; Last time), the active split card (week strip with planned, missed, extra and today; Move a workout; This week: Workouts, Exercises, Sets, Top weight, Cardio; Show days; Change), the calendar (fold, Month link, the same four day states, the current week band), Recent workouts, the workout page (Plan, the timer with Running/Paused/Finished and Pause/Resume/Stop, In this workout with drag handles and set counts, Still to do, Add exercise, the admin pen), the exercise page (set table, Tag and note per set, rest between sets, Start rest, weight + reps, tag pills, Add set, Note, Equipment), History (date, workout, split badge, Rest day, Deleted, counts, timer line with its pen), and the Add exercises picker (groups, Added, Yours, the admin ×, Create your own, muscle group choices, Add selected). Texts stay word for word.

Three layout moves (no new behaviour):
1. The Home "Exercises" button moves from under the date into the top bar, on the right.
2. The Today box's main button becomes full width at the bottom of its stats, not a small button beside the title.
3. Rows in "In this workout", "Still to do" and History lose their boxed "›" / "Open" button: the whole row is the link (it already is, through `row_link`), with a quiet chevron at the end.

## Tokens

Bootstrap 5.3.8 is already in the app, and it has colour modes. Readout uses `$color-mode-type: media-query`: Bootstrap writes its own dark `--bs-*` values under `@media (prefers-color-scheme: dark)`, and the app's own tokens are CSS custom properties (`--rd-*`) that switch the same way. Bootstrap's Sass functions (`shade-color`, `color-contrast`, `rgba($x, .25)`) need real hex values, so each colour exists twice: a Sass hex for Bootstrap and a `var(--rd-*)` for the app's own components.

### `config/_fonts.scss`

```scss
// Fonts come from Google Fonts, linked in the layout's <head>:
// https://fonts.googleapis.com/css2?family=Geist:wght@400;500;600;700&family=Geist+Mono:wght@400;500;600&display=swap
// (fonts.googleapis.com and fonts.gstatic.com are already allowed by the content security policy)
$body-font: "Geist", ui-sans-serif, system-ui, -apple-system, "Segoe UI", sans-serif;
$headers-font: $body-font;
$mono-font: "Geist Mono", ui-monospace, "SF Mono", Menlo, monospace;

// Type scale: size / line-height / weight / tracking
$type-readout: 500 3.5rem/1 $mono-font;      // 56/56, -0.04em: the workout clock only
$type-title:   600 1.75rem/2rem $body-font;  // 28/32, -0.03em: one per page
$type-number:  500 1.375rem/1.75rem $mono-font; // 22/28, -0.02em: weights, reps, stats
$type-heading: 600 1.0625rem/1.5rem $body-font; // 17/24, -0.01em: card titles (row names 16/22)
$type-body:    400 .9375rem/1.375rem $body-font; // 15/22
$type-meta:    400 .8125rem/1.125rem $body-font; // 13/18, muted
$type-micro:   500 .6875rem/1rem $mono-font;  // 11/16, +0.08em, uppercase: labels, eyebrows, column heads
```

### `config/_colors.scss`

```scss
// Readout: graphite and bone, one signal orange. Each colour is named for what it does.
// The $…-light / $…-dark hex values feed Bootstrap (its Sass needs real colours); the app's own
// components use the CSS variables below, which follow the phone's light or dark setting.

$bg-light: #EDEDEA;          $bg-dark: #0E0F10;           // page
$surface-light: #F8F8F6;     $surface-dark: #17181A;      // cards, bars, sheet
$surface-2-light: #E3E4E0;   $surface-2-dark: #202124;    // sunk: chips, add-set panel, pressed rows
$line-light: #D8D9D4;        $line-dark: #2A2C2F;         // hairlines
$line-strong-light: #B9BAB4; $line-strong-dark: #3C3F43;  // field and outline-button borders
$ink-light: #121314;         $ink-dark: #EDEDE9;          // text, planned days, checked choices
$muted-light: #5F6166;       $muted-dark: #A0A2A6;        // secondary text (5.6:1 and 6.6:1 on surface)
$faint-light: #9A9C9F;       $faint-dark: #63666A;        // decoration only, never text
$signal-light: #FF5A1F;      $signal-dark: #FF6A2B;       // live, today, the main action
$signal-press-light: #E84A10; $signal-press-dark: #FF8452;
$signal-ink-light: #B83D0B;  $signal-ink-dark: #FF8148;   // signal as text (4.8:1 on surface)
$signal-soft-light: #FFE5DA; $signal-soft-dark: #3A1C0F;  // running pill, done chip, field ring
$on-signal: #0B0B0B;                                      // text on signal (6.6:1)
$danger-light: #C81E3A;      $danger-dark: #FF6170;       // Delete, ×, errors
$danger-soft-light: #FBE3E7; $danger-soft-dark: #3A1418;

:root {
  --rd-bg: #{$bg-light}; --rd-surface: #{$surface-light}; --rd-surface-2: #{$surface-2-light};
  --rd-line: #{$line-light}; --rd-line-strong: #{$line-strong-light};
  --rd-ink: #{$ink-light}; --rd-muted: #{$muted-light}; --rd-faint: #{$faint-light};
  --rd-signal: #{$signal-light}; --rd-signal-press: #{$signal-press-light};
  --rd-signal-ink: #{$signal-ink-light}; --rd-signal-soft: #{$signal-soft-light};
  --rd-on-signal: #{$on-signal};
  --rd-danger: #{$danger-light}; --rd-danger-soft: #{$danger-soft-light};
  --rd-sheet-shadow: 0 -1px 0 #{$line-light}, 0 -18px 48px rgba(18, 19, 20, .14);

  --rd-ease: cubic-bezier(.2, .8, .2, 1);        // press, hover, folds
  --rd-ease-enter: cubic-bezier(.22, 1, .36, 1); // sheet and flash coming in
  --rd-ease-exit: cubic-bezier(.4, 0, 1, 1);     // sheet and flash leaving
  --rd-t-press: 90ms; --rd-t-hover: 150ms; --rd-t-panel: 200ms; --rd-t-sheet: 280ms; --rd-t-breathe: 2.4s;
}

@media (prefers-color-scheme: dark) {
  :root {
    color-scheme: dark;
    --rd-bg: #{$bg-dark}; --rd-surface: #{$surface-dark}; --rd-surface-2: #{$surface-2-dark};
    --rd-line: #{$line-dark}; --rd-line-strong: #{$line-strong-dark};
    --rd-ink: #{$ink-dark}; --rd-muted: #{$muted-dark}; --rd-faint: #{$faint-dark};
    --rd-signal: #{$signal-dark}; --rd-signal-press: #{$signal-press-dark};
    --rd-signal-ink: #{$signal-ink-dark}; --rd-signal-soft: #{$signal-soft-dark};
    --rd-danger: #{$danger-dark}; --rd-danger-soft: #{$danger-soft-dark};
    --rd-sheet-shadow: 0 -1px 0 #{$line-strong-dark}, 0 -18px 48px rgba(0, 0, 0, .5);
  }
}

// What the app's own stylesheets use (components/, pages/). The old names stay, so the
// first step changes no other file; each one now points at a Readout token.
$gray: var(--rd-ink);            // body text
$light-gray: var(--rd-bg);
$muted: var(--rd-muted);
$line: var(--rd-line);
$line-strong: var(--rd-line-strong);
$surface-subtle: var(--rd-surface-2);
$icon-faint: var(--rd-faint);
$blue: var(--rd-signal);         // was the primary indigo
$primary-soft: var(--rd-signal-soft);
$red: var(--rd-danger);
$chip-bg: var(--rd-surface-2);   $chip-text: var(--rd-ink);
$done-bg: var(--rd-signal-soft); $done-text: var(--rd-signal-ink);
$rest-bg: transparent;           $rest-text: var(--rd-muted); // Rest day: a dashed outline, see Pills
$outside-day: var(--rd-muted);
$extra-ring: var(--rd-line-strong);
$hover-halo: color-mix(in srgb, var(--rd-signal) 30%, transparent);
```

Before this works, these lines must stop putting a `var()` into a Sass function (the only ones in the app):
`components/_cards.scss:3` and `:37`, `components/_layout.scss:56` and `:59`, `components/_flash.scss:32`, `components/_confirm.scss:16` and `:30`, `components/_lists.scss:89`. Delete the card shadows (`_cards.scss:3`, `_layout.scss:56`). Change the rest to `color-mix(in srgb, var(--rd-…) N%, transparent)`, or to `var(--rd-sheet-shadow)` for the flash, confirm and drag-ghost shadows.

### `config/_bootstrap_variables.scss`

```scss
// Colour modes: Bootstrap writes its dark values under prefers-color-scheme, with no toggle and no JS.
$color-mode-type: media-query;

// Type
$font-family-sans-serif: $body-font;
$font-family-monospace:  $mono-font;
$headings-font-family:   $headers-font;
$headings-font-weight:   600;
$font-size-base:         .9375rem;   // 15px
$line-height-base:       1.4667;     // 22px
$input-font-size:        1rem;       // keeps iOS from zooming into fields
$input-font-size-sm:     1rem;

// Colours (light: Sass hex; dark: the *-dark maps below)
$primary:   $signal-light;
$danger:    $danger-light;
$success:   $ink-light;      // "done" is never green any more: ink, or the signal tick
$info:      $ink-light;
$warning:   $signal-light;
$body-bg:            $bg-light;
$body-color:         $ink-light;
$body-secondary-color: $muted-light;
$body-tertiary-bg:   $surface-2-light;
$text-muted:         $muted-light;
$border-color:       $line-light;
$link-color:         $ink-light;
$link-decoration:    underline;
$link-underline-offset: .25em;
$min-contrast-ratio: 4.5;    // white loses on #FF5A1F, so .btn-primary text is black (6.6:1)

$body-bg-dark:              $bg-dark;
$body-color-dark:           $ink-dark;
$body-secondary-color-dark: $muted-dark;
$body-tertiary-bg-dark:     $surface-2-dark;
$border-color-dark:         $line-dark;
$link-color-dark:           $ink-dark;
$primary-text-emphasis-dark: $signal-ink-dark;
$danger-text-emphasis-dark:  $danger-dark;

// Spacing (4px base): s1 4, s2 8, s3 12, s4 16, s5 20, s6 24, s8 32, s12 48
// Keep Bootstrap's own $spacers map (the views' mb-4, gap-3 … already depend on it). The
// scale above is for the app's own SCSS: 4px .25rem, 8px .5rem, 12px .75rem, 16px 1rem, 20px 1.25rem,
// 24px 1.5rem, 32px 2rem, 48px 3rem. Only the gutter changes, to the 16px phone edge.
$grid-gutter-width: 1rem;

// Radii: 6 chips · 10 fields · 12 buttons · 16 cards · 22 sheet top · pill only for day dots and status
$border-radius-sm:  .375rem;  // 6
$border-radius:     .625rem;  // 10
$border-radius-lg:  .75rem;   // 12
$border-radius-xl:  1rem;     // 16
$border-radius-xxl: 1.375rem; // 22

// Elevation: none, except sheets and modals
$enable-shadows: false;
$box-shadow: none; $box-shadow-sm: none; $box-shadow-lg: none;

// Focus: a 2px signal ring 2px off the control; fields add a soft 3px halo
$focus-ring-width:   2px;
$focus-ring-color:   $signal-light;
$focus-ring-opacity: 1;
$input-btn-focus-width: 3px;
$input-btn-focus-color: rgba($signal-light, .22);
$input-focus-border-color: $signal-light;

// Buttons: 48px tall, 12px radius, 600
$btn-font-weight:    600;
$btn-padding-y:      .8125rem;
$btn-padding-x:      1.125rem;
$btn-line-height:    1.25;
$btn-border-radius:  $border-radius-lg;
$btn-padding-y-sm:   .5rem;     // 36px
$btn-border-radius-sm: $border-radius;
$btn-transition: transform 90ms cubic-bezier(.2, .8, .2, 1), background-color 150ms cubic-bezier(.2, .8, .2, 1), border-color 150ms cubic-bezier(.2, .8, .2, 1);

// Fields: 56px for weight and reps (set in components), 48px for text
$input-padding-y:      .75rem;
$input-padding-x:      .875rem;
$input-bg:             var(--rd-surface);
$input-border-color:   var(--rd-line-strong);
$input-border-radius:  $border-radius;
$form-label-font-size: .6875rem;
$form-label-font-weight: 500;
$form-label-color:     var(--rd-muted);
$form-check-input-checked-bg-color:     $signal-light;
$form-check-input-checked-border-color: $signal-light;
$form-check-input-border-radius:        .375rem;

// Cards: hairline, no shadow
$card-bg:            var(--rd-surface);
$card-border-color:  var(--rd-line);
$card-border-radius: $border-radius-xl;
$card-inner-border-radius: calc(#{$border-radius-xl} - 1px);
$card-cap-bg:        transparent;
$card-spacer-x:      1rem;
$card-spacer-y:      1rem;
$card-box-shadow:    none;

// Tables
$table-bg:            transparent;
$table-border-color:  var(--rd-line);
$table-cell-padding-y: .625rem;

// Badges and chips
$badge-font-size:    .75rem;
$badge-font-weight:  500;
$badge-border-radius: .375rem;

// Dropdowns (⋯ menus)
$dropdown-bg:            var(--rd-surface);
$dropdown-border-color:  var(--rd-line);
$dropdown-border-radius: $border-radius-lg;
$dropdown-box-shadow:    var(--rd-sheet-shadow);
$dropdown-link-active-bg: var(--rd-surface-2);
$dropdown-link-active-color: var(--rd-ink);

// Modals become sheets on a phone (see Modals)
$modal-content-bg:            var(--rd-surface);
$modal-content-border-color:  var(--rd-line);
$modal-content-border-radius: $border-radius-xxl;
$modal-content-box-shadow-xs: var(--rd-sheet-shadow);
$modal-backdrop-bg:           #000;
$modal-backdrop-opacity:      .45;
$modal-header-border-color:   var(--rd-line);
$modal-footer-border-color:   var(--rd-line);
$modal-fade-transform:        translate(0, 100%);
$modal-transition:            transform 280ms cubic-bezier(.22, 1, .36, 1);

// Pagination
$pagination-bg: transparent;
$pagination-border-color: var(--rd-line);
$pagination-active-bg: $ink-light;
$pagination-active-border-color: $ink-light;
```

Note on `$primary` in dark: Bootstrap builds `.btn-primary` once, from the Sass value. The dark signal (#FF6A2B) is only 4% lighter. Either keep #FF5A1F in both modes (it reads 6.2:1 against #0E0F10) or set `.btn-primary { --bs-btn-bg: var(--rd-signal); --bs-btn-border-color: var(--rd-signal); --bs-btn-hover-bg: var(--rd-signal-press); --bs-btn-active-bg: var(--rd-signal-press); --bs-btn-color: var(--rd-on-signal); }` in `components/_buttons.scss`. The concept does the latter.

## Component by component

| Component | Today | Readout | Where |
|---|---|---|---|
| **Buttons** | Indigo fill, white text; white light buttons with a border; Stop in red outline | **Primary**: signal fill, #0B0B0B text, 48px, radius 12, 600 15px. Only for Start workout / Continue, Add set, Add exercise, Add selected, Create your first split. **Secondary**: transparent, 1px `line-strong`, ink text (Pause, Stop, Plan, Move a workout, Save equipment). **Icon**: 40px, no border, muted, `surface-2` on press. Stop keeps its square glyph in `danger`, its label in ink (stopping is not deleting). Press: `translateY(1px) scale(.98)` in 90ms, background one step darker. Hover (fine pointer only): the border goes ink. Disabled: `surface-2` fill and `faint` text, never a faded orange. | `$btn-*` above; a new `components/_buttons.scss` for `.btn:active` and `.btn-icon` |
| **Cards** | White, 16px radius, 1px line + shadow; the active split card has an indigo 2px border | `surface`, 1px `line`, radius 16, **no shadow**. Header 14px/16px padding, title 17/24 600, count in mono muted after it ("In this workout 2"). The active split card loses its indigo border; "Active split" becomes a micro label above the split name set in mono 22px. | `_cards.scss`, `_splits_cards.scss` |
| **Inputs** | 16px text, `line-strong` border, Bootstrap focus glow | Weight and reps: 56px tall, mono 500 24px, the unit ("kg", "reps") inside the field on the right in mono 13px muted (a positioned `<span>` sibling, no inline style). Text fields 48px, Geist 16px. Focus: `signal` border plus a 3px `signal-soft` ring, 150ms. Labels: micro (mono 11px uppercase, +0.08em). | `workout_sets/_form`, `.set-field` in `_workout_log.scss` |
| **Set table** | Rows with "1" badge, "60 kg 12", a Tag pill, then a full note field with an indigo save arrow under every set | Grid `32px 1fr 1fr 40px`: set number in a 28px `surface-2` square (radius 6, mono 13); weight and reps in mono 22px, units 12px muted; ⋯ icon button. Below, one 32px line: the Tag button (outline, radius 6; ink fill when tagged, e.g. "Warm-up") and the note as a dashed ghost field "Add a note" that becomes the real field with the save arrow on focus. **Rest** sits between two sets as a mono 12px muted line with a timer icon and a dotted rule: "Rest 2 min 5 s" (exact, never rounded). Keep one `<tbody>` per set. | `workout_sets/_set`, `_table`, `_tables.scss` |
| **Add-set form** | Start rest button, then two fields and the Add set button in one row, then tag pills | A `surface-2` panel (radius 12, 14px padding) inside the card: a header row with the micro label "Set 4" and "Start rest" (secondary, small) on the right; weight and reps side by side; the tag pills; then **Add set** full width (primary, 48px). Running rest: the button gets a signal border and reads "Stop rest · 1:12". | `workout_sets/_form`, `_rest_timer` |
| **Timer** | Green "Running" pill, 32px clock, Pause and Stop side by side | Status pill: signal-soft background, signal-ink mono uppercase 11px, the 8px dot with a ring that grows from 1× to 2.6× and fades every 2.4s (replaces `timer-live`). Paused: `surface-2` pill, hollow muted dot, still, the clock in `muted`. Finished: `surface-2`, ink dot. Idle: outline pill. Clock: Geist Mono 500 56px, -0.04em, the colons in `faint` with -0.14em margins. Under it a 2px track that fills once a minute (the seconds sweep). Pause and Stop: two equal secondary buttons, full width. | `workout_logs/_timer`, `_timer.scss`, `timer_controller.js` |
| **Bottom nav** | White bar, active tab in an indigo pill with indigo label | `surface` bar, 1px top hairline, four equal tabs, 22px outline icons, 11px 500 labels. Inactive: muted. Active: ink, plus a 24×2px signal bar on the bar's top edge above the icon (no pill). The Account avatar becomes a 22px outlined circle with the initial in mono. Keep the safe-area bottom padding. | `shared/_bottom_nav`, `_bottom_nav.scss` |
| **Top bar** | Logo tile, page name | 56px, no bottom border. Left: the 32px ink logo tile, or the round 40px back button and the page name (17/24 600). Right: page actions as small secondary buttons (Exercises, Plan). | `shared/_navbar`, `_navbar.scss` |
| **Calendar and week strip** | Indigo filled days, indigo rings, dotted indigo for missed, a lavender band for this week | 40px circles in mono 14px. **Planned/trained**: ink fill, bg text. **Missed**: 1.5px dashed `muted` border (still a link). **Extra**: 1.5px `line-strong` ring plus a 4px muted dot at the bottom. **Today**: a 2px `signal` ring 2px outside (`box-shadow: 0 0 0 2px surface, 0 0 0 4px signal`). This week: a `surface-2` pill band. Outside days: muted 400. Day-of-week heads and week-strip names: mono 10px uppercase. Today's name in the strip in signal-ink. Add a one-line legend under the calendar (planned · missed · extra · today) in mono 11px. The tooltip and the halo stay; the halo is 30% signal. | `pages/_calendar`, `splits/_week`, `_dashboard_calendar.scss`, `_split_week.scss` |
| **Stats (This week, Month)** | Label over number, loose | A 4-column grid split by hairlines: micro label, mono 22px number, unit in 12px muted. Cardio takes a full row of its own, label left, value right ("45 min 50 s"). | `pages/_summary_tiles`, `_week_overview` |
| **Pills and chips** | Rounded grey chips, green done chip, amber rest-day chip, indigo outline choice buttons | **Chip** (split name, Yours): `surface-2`, radius 6, mono 12px 500. **Done** ("3 sets", "Logged today"): signal-soft with a signal-ink check. **Rest day**: transparent with a 1px dashed `line-strong` border, muted. **Deleted**: plain muted text, struck through in `faint`. **Tag pills** (Assisted, Drop set, Warm-up): 34px, radius 999, outline; on = ink fill. **Choices** (muscle group, equipment): 40px, radius 10, outline; on = ink fill (never signal: they are settings, not the action). Equipment becomes a segmented control on `surface-2` with the chosen segment raised to `surface`. | `_choices.scss`, `.chip*` in `_lists.scss`, `.set-tag*` |
| **Rows and lists** | Drag handle, name, meta, chip, pen, boxed chevron | 64px minimum, 1px hairline between rows. Drag handle in `faint`, name 16/22 600, meta 13/18 muted, then the done chip, the admin pen as a 36px ghost icon, and a muted chevron. The whole row is the link. Pressed: `surface-2`. | `_row_link.scss`, `_lists.scss`, `workout_days/show` |
| **History** | Indigo date, name + chip, counts, timer line, pen, boxed "Open" | Date as a micro line ("WED · NOV 25, 2026"), today's in signal-ink; name 17/24 600 with its chips; counts 13px muted; the timer line in 13px with the times as whole parts (`time_parts` stays) and the length in ink 500. Pen and chevron on the right. A running workout shows the Running pill in place of the clock icon. | `workout_logs/index`, `_history` styles in `_workout_log.scss` |
| **Modals** | Full-screen white modal on a phone, indigo Add selected | Under 576px, a **bottom sheet**: `modal-dialog` pinned to the bottom with a 64px top gap, radius 22 at the top only, a 36×4px grabber, the scrim at 45% black. It slides up in 280ms `ease-enter` and leaves in 200ms `ease-exit` (`$modal-fade-transform`, `$modal-transition`). Group headings are micro labels in ink with their count and chevron. Rows are 48px with a 22px square checkbox (radius 6; checked = signal fill, black tick; Added = `surface-2` with a muted tick). Yours chip, admin × in `faint`. Add selected is a full-width primary in a footer with a hairline above. The confirm box (`shared/_confirm`) is the same sheet, its destructive button in `danger` fill with white text. | `shared/_exercise_picker`, `shared/_confirm`, `_exercise_picker.scss`, `_confirm.scss` |
| **Flash** | Cards with shadow | A `surface` card with a 1px `line-strong` border and `--rd-sheet-shadow`. Notice: an ink icon. Alert: a danger icon and a 3px danger bar on the left. It enters with a 12px drop in 200ms `ease-enter`. | `_flash.scss` |
| **Empty state** | Grey icon, grey text, indigo button | A 48px dashed square with an outline icon, the sentence in 14/20 muted (max 280px), and at most one primary button. | `_empty_state.scss` |
| **Icons** | Font Awesome solid (filled), mixed weights | Outline on a 24 grid, 1.75 stroke, square caps, mitred joins, 20px (16 small, 22 nav). Until the swap, Font Awesome icons go to 16–18px, `muted`, never indigo. | see step 9 |

## Motion

| Token | Value | Used for |
|---|---|---|
| `--rd-ease` | cubic-bezier(.2,.8,.2,1) | press, hover, folds, fields |
| `--rd-ease-enter` | cubic-bezier(.22,1,.36,1) | sheet and flash in |
| `--rd-ease-exit` | cubic-bezier(.4,0,1,1) | sheet and flash out |
| `--rd-t-press` | 90ms | button press |
| `--rd-t-hover` | 150ms | hover, field focus |
| `--rd-t-panel` | 200ms | folds, ⋯ menus, sheet out |
| `--rd-t-sheet` | 280ms | sheet in |
| `--rd-t-breathe` | 2.4s | live dot ring (loop) |

Only transform and opacity move (plus colours on hover). Nothing animates on scroll. Under `prefers-reduced-motion: reduce` the dot ring and the seconds sweep stop, and the sheet appears without sliding. The existing `.just-moved` highlight after a drag stays: a 600ms fade from `signal-soft` to transparent.

## Constraints check

- **Bootstrap 5 SCSS**: everything is variables, Bootstrap 5.3 colour modes and plain component SCSS. No framework change.
- **CSP**: no `style=` attributes and no inline scripts. Units inside fields are sibling `<span>`s. The dark theme is a media query. The fonts stay on fonts.googleapis.com and fonts.gstatic.com, which are already allowed. The seconds sweep's phase is set from `timer_controller.js` with `element.style.setProperty('--sweep-delay', …)`, which is CSSOM and allowed under `style-src`, not an attribute. It is optional: without it the sweep simply starts at 0.
- **Turbo and Stimulus**: no new controllers. `timer_controller.js` writes the clock: to dim the colons it writes three text nodes and two `<span class="colon">` elements instead of one string (optional). The breathing dot and the sweep are CSS keyframes, so they keep running across Turbo morphs.
- **No new JS libraries.** The concept page's theme switch exists only to show both themes. The app follows the phone's setting.

## Migration order

Each step is CSS and markup only. The tests don't look at styles, so they stay green, but check every step in Chrome at 390px in both light and dark (DevTools > Rendering > `prefers-color-scheme`).

1. **Tokens.** Replace `config/_fonts.scss`, `_colors.scss` and `_bootstrap_variables.scss` with the blocks above. Swap the Google Fonts link in `layouts/application.html.erb` to Geist + Geist Mono. Fix the eight `rgba($var, …)` / `#{$red}` lines listed under `_colors.scss`. Result: the whole app turns graphite and orange, with dark mode, using the old layouts.
2. **Base components.** Add `components/_buttons.scss` (primary from CSS variables, press, icon button, disabled). Then cards without shadows, fields with micro labels and the signal focus, links in ink with a hairline underline, chips and pills. Remove leftover indigo (`$primary-soft` hovers in `_layout.scss`).
3. **Chrome.** Top bar (`shared/_navbar`): back button, title, actions on the right; move Home's Exercises button into it. Bottom nav: the signal bar, outline icons.
4. **The workout page** (`workout_days/show`, `workout_logs/show`): the timer card (status pill, 56px mono clock, sweep, two buttons), the "In this workout" / "Still to do" rows with whole-row links.
5. **The exercise page** (`workout_exercises/show`, `workout_sets/_table`, `_set`, `_form`, `_rest_timer`, `cardio_entries/*`): the set grid, rest lines, the add-set panel, big mono fields with units. Cardio rows use the same grid: incline, speed, time.
6. **Home** (`pages/dashboard`, `_today_box`, `_lifts`, `splits/_week`, `_week_overview`, `_calendar`, `_recent_workout`, `_rest_day_start`): Today box with the full-width button, the split card, the stats grid, the calendar states and legend, the recent rows.
7. **History, Month, Splits, admin pages, account, sign in**: rows, stats tiles, forms. These are mostly done by steps 1–2.
8. **Modals as sheets**: picker, confirm box, move-a-workout, rest-day start, timer alert, set-tag menus. Use the Bootstrap modal variables plus a `@media (max-width: 575.98px)` block in `_exercise_picker.scss` / `_confirm.scss` for the bottom position, the grabber and the top-only radius.
9. **Icons (optional, last).** Replace Font Awesome with an SVG sprite: one partial `shared/_icons.html.erb` rendered once in the layout, holding ~25 `<symbol>`s (home, splits, history, back, chevrons, plus, pause, stop, play, pen, grip, dumbbell, check, ×, timer, tag, arrow, swap, ⋯, note, list), and a helper `icon(name, size: 20)` that returns `<svg class="icon"><use href="#i-name"/></svg>`. Then drop `font-awesome-sass` from the Gemfile and its eight `@import`s. This is pure deletion with no new library, and the symbols are in the concept page.

Risks to watch:
- Bootstrap utility classes that the views use with theme colours (`text-danger`, `btn-light`, `bg-light`) need a pass in dark mode. `btn-light` especially should become the secondary style.
- The `$blue` → signal alias turns every indigo accent orange in step 1. Some of those must become ink instead (links, choice buttons, calendar fills), and steps 2 and 6 handle that. Do not ship step 1 alone.
- Geist Mono's zero has a slash ("0"). It reads as an instrument and is fine for the clock and the weights. If the owner dislikes it, set the numbers in Geist with `font-variant-numeric: tabular-nums` and keep mono only for the clock and micro labels.

<!-- END VERBATIM FILE: evidence/scratchpad/new-look/DIRECTION.md -->

<!-- END OF HANDOVER -->
