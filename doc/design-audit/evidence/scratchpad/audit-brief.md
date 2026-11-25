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
