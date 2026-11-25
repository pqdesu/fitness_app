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
