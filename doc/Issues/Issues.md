# Issues

## Home page

### Calendar and week

- Currently on calendar the workout days appeared to be missed (white color on calendar) and week appears to be done (filled with blue), but yesterday I missed the workoutday and still is colored as if I did the workout - Check /home/pedro/code/pqdesu/fitness_app/doc/Features/Pics/Screenshot 2026-11-21 074724.png and /home/pedro/code/pqdesu/fitness_app/doc/Features/Pics/Screenshot 2026-11-21 074728.png. I want on calendat to be filled wtih blue if a workout was logged and white like it is now if the workout has no logs. ON the week do the same. Also have a different way to show whihc day of the week it is by having a circle around the day.
- Small UI issue on calendar. The numbers appeared to be slight off center. Check /home/pedro/code/pqdesu/fitness_app/doc/Features/Pics/Screenshot 2026-11-21 080640.png

# Potential issues

Risks a branch knowingly left behind: not seen as a bug yet, but they could become one. Each says which branch it comes from. When one is seen for real it moves up to the open issues; when it is fixed it moves to "Issues resolved".

## Exercise page

### Saving a set or a note can still jump to the top

- From `set-notes-removed-exercises`: the exercise page and the logged workout page keep their scroll when a set or note is saved, because Turbo morphs the page in place (`turbo_refreshes_with method: :morph, scroll: :preserve`). That only happens when the save comes back to the exact same address. An exercise page opened without `?date=` comes back with the date added, so that first save reloads the page and jumps to the top. The links in the app always add the date, so this needs a typed or old link. Likely too, not verified: a logged workout page opened with an anchor (`#entry-…`, as "Added to this workout" on a workout day's page links) may jump once on its first save, since the address differs by the anchor.

### Bodyweight sets switched back to free weights show a minus

- From `exercise-page-features`: a bodyweight lift with sets below zero (an assisted pull-up, "Bodyweight − 15.5 kg") that is switched back to free weights shows those sets as "-15.5 kg".

### A second set tag takes another tap

- From `exercise-page-features`: ticking a tag on a recorded set saves the set at once, and the page refresh closes the tag row, so a second tag needs the Tag button again.

### Drag and drop not tried on a real phone

- From `exercise-page-features`: dragging (the split page's plan, a logged workout's cards, the workout day's two cards) was only tried with emulated touch and mouse in headless Chrome. Long drags that need the screen to scroll at its edge were not fully checked.

### Moving exercises without dragging

- From `exercise-page-features`: the plan on the split page and the workout day's two cards can only be reordered or moved between cards by dragging (the ↑ ↓ arrows were removed by the owner's choice). A keyboard or screen reader cannot do it there. A logged workout keeps Move up / Move down in each card's ⋯ menu. On a workout day's page, a planned exercise leaves the workout only by dragging it back.

### The moved-row highlight does not flash twice

- From `exercise-page-features`: moving the same row twice in a row does not light it up again the second time (`.just-moved`).

### Exercise order relies on PostgreSQL

- From `exercise-page-features`: `position` is nullable and a row is numbered only once its list is reordered; new rows go last because PostgreSQL sorts NULL last. Another database would put them first.

### Rest timer edges

- From `exercise-page-features`:
  - The rest clock shows an hour digit ("0:00:42"), because it reuses the workout timer's clock.
  - The "Did you forget to stop your rest timer?" box only catches the app's own links. Swiping back, the browser's back button or closing the tab leave with the rest running; the next Add set on that exercise still asks.
  - "Save rest" (Add set while the rest runs) counts the time of the set itself as rest.
  - The minute and second lists in a set's Edit were never tried on an iPhone (where they open as the wheel). Not verified.

### Long exercise names on a workout day

- From `exercise-page-features`: next to the "3 sets" chip and the buttons, a long name ("Seated Lateral Raise") wraps to three lines on a 390 px phone.

### A Cardio exercise edited from master is refused

- From `exercise-page-features` (feature 7): "Cardio" is a muscle group on this branch only. On `master`, which shares the development database, editing a Cardio exercise fails its muscle-group check until this branch is merged.

### An empty Cardio workout reads "0 sets"

- From `exercise-page-features` (features 7 and 8): a Cardio workout with an exercise but no time yet reads "0 sets" in Recent workouts and History, while the Today box says "no time yet".

### A cardio machine just added starts folded

- From `exercise-page-features` (features 7 and 8): after "Add selected", the new machine's card on the logged workout is folded like every card, so typing its first time takes one more tap (the arrow).

### The Cardio tile of the week comes and goes

- From `exercise-page-features` (feature 7): the week overview's Cardio tile shows only in a week with cardio, and sits alone on a second row under the four others, so the box is taller that week.

## General

### Muscle group and equipment pills not tried on a real phone

- From `dropdowns-off-screen`: the muscle group and equipment fields are now pills to tap instead of dropdowns. They were checked only in headless Chrome at 390 px, not on a phone. Not verified: how a tap feels, whether a pill keeps a focus ring after it is tapped on iOS, and that the 44 px pills are easy to hit with a thumb. If more muscle groups are added later, the "Add exercises" pop-up grows one row of pills for every three.

### Workout timer not tried on a real phone

- From `workout-timer`: the timer box, its live clock and paused counter, the paused-timer alert and Edit timer were checked only in headless Chrome at 390 px and 1280 px, not on a phone. Not verified: the clock after the phone sleeps for a long time, the press and pop-up motion on a device, and the alert reopening "Add exercises" after Resume in a private window (it uses sessionStorage; if blocked, the list does not reopen, but the timer still resumes).

### Opening today's workout logs it when the automatic timer is on

- From `workout-timer`: with "Start the workout timer automatically" on, opening today's workout (even just to look at it) logs it with no exercises and starts its timer. It stays in History, as an empty workout, until it is deleted.

### A forgotten timer keeps counting

- From `workout-timer`: a timer left running or paused keeps counting until it is stopped, even days later; History then shows a very long workout until it is corrected with Edit timer. Edit timer changes only the finish (not the start or the pauses) and refuses a finish that leaves less time than the paused total.

### Times to the minute beside a length to the second

- From `workout-timer`: the start and end on a time line show hours and minutes, while the length is to the second, so "11:09 PM ~ 11:50 PM" can sit next to "30 min 10 s" and not add up at a glance.

### The paused-timer alert only covers the app's own links

- From `workout-timer`: leaving the workout with the browser's back button, a swipe back or by closing the tab does not ask about a paused timer; only the app's links (the back arrow, the menu, Plan) do.

### Deleting a workout opened from Today goes to the dashboard

- From `bottom-navbar-mobile`: the Today page's box shares its links with the dashboard's, and they carry `?from=dashboard`. Opening a logged workout from Today and deleting it returns to the dashboard (`/dashboard`), not to Today. Its back arrow follows the pages visited, so it still returns to Today.

### Bottom bar not tried on a real phone

- From `bottom-navbar-mobile`: the bottom tab bar, the back arrow in the top bar's corner and the iPhone safe-area padding (`viewport-fit=cover`) were checked only in desktop Chrome inside a 390 px frame. Not verified: that the tabs clear the iPhone home indicator, that a phone turned sideways keeps the page clear of the notch, the tap feel, and the fixed back arrow while Safari's toolbar slides. A flash card can also cover the back arrow for up to 5 seconds.

### A week move without a Referer lands on Today

- From `bottom-navbar-mobile`: "Move a workout" and "Back to the plan" return to the page they were sent from by its Referer. A browser that sends none (a strict privacy setting) lands on Today even when the move was made on the dashboard. The move is still saved. Not verified on such a browser.

### Exercises page pages a big muscle group

- From `exercise-page-features`: the Exercises page folds by muscle group but still pages 30 exercises, so a big group can continue on page 2.

### Exercise page features not tried on a real phone

- From `exercise-page-features`: everything on this branch (equipment pills, tags, notes, folds, ⋯ menus, drag and drop, the rest timer, cardio rows and the Cardio button) was checked in headless Chrome at 390 px only, never on a real phone.

# Issues resolved (DONE)

## Dropdowns

### Dropdowns past visible screen

- The dropdowns only go down which is an issue when the dropdown is at the end of the bottom of the page. for example here - /home/pedro_hosonode/personal-projects/fitness_app/doc/Features/Pics/Screenshot 2026-11-19 133850.png. I want the dropdowns to go up if the field they are showing go beyond past visible screen. This issue is only on Mobile with browser testing no actual Mobile device
- Fixed on `dropdowns-off-screen`. Cause: the fields were native `<select>`s, whose option list the browser draws itself; a page cannot make it open upward. On a real phone it opens the system picker, but desktop Chrome's device mode draws its desktop list, which ran past the screen. The muscle group (the "Add exercises" modal and the exercise form) and the equipment (the exercise page and the logged exercise's edit page) are now pills to tap (`shared/_choices`), with no list to open. The workout and weekday selects on the workout day form, at the top of the page, and the user menu, which already flips up, are unchanged.

## Exercises

### No notes per set

- on the workout_exercises page, each set has no note text field only when you edit it. I want the text field to always be present to add a quick note and have it saved when the text is added
- Fixed on `set-notes-removed-exercises`: every set has its note field under it, always visible. Leaving the field or pressing Enter saves it. The pen now only edits weight and reps.

### Deleted exercise shows up in workout page

- I added and delete one exercise as a test and the exercise appaeared under "From this day, not in this workout" why? When I delete an exercise I want it to be removed that's all
- Fixed on `set-notes-removed-exercises`. Cause: the workout day page was both the workout and the plan, and its "Add exercise" put the exercise on the day's plan (`WorkoutExercisesController#create`), so Triceps pushdown became a planned Lower exercise and was offered under "From this day, not in this workout". Now the split page is the plan (each workout day's card plans its exercises), and "Add exercise" on a workout day's page adds to that day's workout only. Removing an exercise from a workout keeps it on the plan if it was planned; one added while training is gone. Triceps pushdown is still on Lower's plan in the existing data: remove it with the × on the split page.

### Future workout logs have present days logged

- I just added a exercise on a future workout and the logs showed it as added on the day added but not the day it was supposed to happend. For example: added curl to Friday but it is Wednesday, and the logs saved it as added November 18th (Wednesday). Now here is the issue, I want to be able to add to the past wprkput as well since I might forget to add a exercise but remember the next day. Also if I workout between 11pm and 1am the workout will be split into 2 days which is not really ideal. So I need help to brainstorm a solution, specially the future logs. For the past midnight I thought about adding a small tags or ntoe saying it the exercise was logged past midnight, day after the first logs, so it stays in the day started but shows the time you worked out which it is the next day. What you think could be a solutioni for these issues. - /home/pedro_hosonode/personal-projects/fitness_app/doc/Features/Pics/Screenshot 2026-11-19 134940.png
- Fixed on `workout-logs-date` (first bullet): a workout day's pages log sets on the date that workout falls on this week, so Wednesday's workout opened on Thursday fills in Wednesday, and a workout later in the week shows its day with no Add set form (the server refuses it too). "Start workout" and "Train as extra" log today. The pages carry their date, so a session started before midnight stays on its day. The Lower workout of 19 Nov was moved to 18 Nov. The note-field bullet of the same heading stays open under Issues. See [doc/workout-logs-date.md](../workout-logs-date.md).

## General

### Alerts

- Alerts do not look appropriate to the UI of the app, please change it to match the style of the app and make it disappear after coupld of seconds, like 5 seconds is fine
- Fixed on `alerts-and-back-button`: a white card at the top of the screen that fades in and out in 0.5 s and leaves after 5 s; delete confirmations are an in-app box over a tinted page instead of the browser pop-up. See [doc/alerts-and-back-button.md](../alerts-and-back-button.md).

### Back button

- Back button does not work the way I intended, I want the back button to always go back to the page the user was in before. For example I clicked on the workout circle inside the Active split box on home page but the back button goes to the split page. The back button should go back to the previously visited page. Since this will mostly be a Mobile App and those apps do not have browser back buttons that will be useful.
- Fixed on `alerts-and-back-button`: the back button is a round arrow that returns to the page visited before, skipping form pages and deleted records, and falls back to the parent page when the tab has no earlier page. See [doc/alerts-and-back-button.md](../alerts-and-back-button.md).

## Home page

### Only Split workout are selectable on rest day

- I want to be able to either add the split day or create a new one.

### Days on the split names and repetitive workout names

- Since the workout is static and only Admin can edit, I believe, change the way it is now to only display the workout name wihtout the date and incase it is the same as on one of the say, for example: I do Lower on Tuesday and there is Lower on Wednesday and Saturday. Have a option to move either one, like a info pop up. Make this possible for all splits.

### Deleting workout

- Issue happends when deleting workout coming from home page. When I click on the workout and it opens I then delete it I get redirected to the logged exercises page. Please make sure I go back to the home page.

### No add workout on rest day button

- No button to start a workout on Rest days. If I go to the gym to do something I want to be able to add it. And when it is recorded make sure it shows it was a rest day but I when to the gym. Also it does not change the split but adds a info saying this day I did this.

### Back to the plan left a trained workout on the calendar

- When I remove the workout move from Saturday to Sunday it stayed on the calendar. If I remove the workout from the week on the Today page it should update everywhere. (owner, 2026-11-23)
- Cause: "Back to the plan" deleted every move of the week, including Lower's move to Sunday after Lower had been trained on Sunday. "This week" then put Lower back on Saturday, while the calendar still showed the workout logged on Sunday. Moving a workout already refused once it was logged that week; going back to the plan did not.
- Fixed on `back-to-plan-keeps-trained`: "Back to the plan" undoes only the moves of workouts not trained yet this week, and keeps the one a trained workout swapped with. It says which stayed ("Lower stays on Sunday: a trained workout keeps its day"), and it is hidden when nothing can go back (`Split#undoable_week_moves`). The logged workout is never touched.

### Split override

- Currently because I logged 2 workouts for the day I can only see the previously set on. Please delete the old one from the db also check if it is still possible to log workouts on the same day. It should only be possible if the split changes.

## Exercise page

### Exercise name edit

- I can not edit the name of the exercise after adding it. Make it possible on this page: [screenshot](../Features/Pics/screenshot-2026-11-16-221022.png). Only Admins

### Muscle group typed when editing an exercise

- When editing the name of the exercise I can also edit the muscle group by typing which should not be the case it should be via dropdown

## History page

### Table columns off-screen on a phone

- At phone width (390 px) the History table (`/workout_logs`) is wider than the screen (about 595 px in a 364 px box). It scrolls sideways inside its own box, so the Exercises and Sets columns start off-screen and only Date, Workout and part of Split show until you swipe the table. Found in the phone-width browser check on 2026-11-17.
- Fixed on `history-table-mobile-columns`: on a phone each workout is one cell (date, then workout with its Rest day and split chips, then "9 exercises · 27 sets") next to the Open button, so the table fits the screen; from tablet width up the six columns show as before. See [doc/history-table-mobile-columns.md](../history-table-mobile-columns.md).
