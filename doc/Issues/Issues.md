# Issues

## Dropdowns

### Dropdowns past visible screen

- The dropdowns only go down which is an issue when the dropdown is at the end of the bottom of the page. for example here - /home/pedro_hosonode/personal-projects/fitness_app/doc/Features/Pics/Screenshot 2026-11-19 133850.png. I want the dropdowns to go up if the field they are showing go beyond past visible screen. This issue is only on Mobile with browser testing no actual Mobile device

# Potential issues

Risks a branch knowingly left behind: not seen as a bug yet, but they could become one. Each says which branch it comes from. When one is seen for real it moves up to the open issues; when it is fixed it moves to "Issues resolved".

## Exercise page

### Saving a set or a note can still jump to the top

- From `set-notes-removed-exercises`: the exercise page and the logged workout page keep their scroll when a set or note is saved, because Turbo morphs the page in place (`turbo_refreshes_with method: :morph, scroll: :preserve`). That only happens when the save comes back to the exact same address. An exercise page opened without `?date=` comes back with the date added, so that first save reloads the page and jumps to the top. The links in the app always add the date, so this needs a typed or old link. Likely too, not verified: a logged workout page opened with an anchor (`#entry-…`, as "Added to this workout" on a workout day's page links) may jump once on its first save, since the address differs by the anchor.

# Issues resolved (DONE)

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
