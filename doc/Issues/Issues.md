# Issues

## Exercises

### Future workout logs have present days logged

- I just added a exercise on a future workout and the logs showed it as added on the day added but not the day it was supposed to happend. For example: added curl to Friday but it is Wednesday, and the logs saved it as added November 18th (Wednesday). Now here is the issue, I want to be able to add to the past wprkput as well since I might forget to add a exercise but remember the next day. Also if I workout between 11pm and 1am the workout will be split into 2 days which is not really ideal. So I need help to brainstorm a solution, specially the future logs. For the past midnight I thought about adding a small tags or ntoe saying it the exercise was logged past midnight, day after the first logs, so it stays in the day started but shows the time you worked out which it is the next day. What you think could be a solutioni for these issues. - /home/pedro_hosonode/personal-projects/fitness_app/doc/Features/Pics/Screenshot 2026-11-19 134940.png

- on the workout_exercises page, each set has no note text field only when you edit it. I want the text field to always be present to add a quick note and have it saved when the text is added

## History page

### Table columns off-screen on a phone

- At phone width (390 px) the History table (`/workout_logs`) is wider than the screen (about 595 px in a 364 px box). It scrolls sideways inside its own box, so the Exercises and Sets columns start off-screen and only Date, Workout and part of Split show until you swipe the table. Found in the phone-width browser check on 2026-11-17.

## Dropdowns

### Dropdowns past visible screen

- The dropdowns only go down which is an issue when the dropdown is at the end of the bottom of the page. for example here - /home/pedro_hosonode/personal-projects/fitness_app/doc/Features/Pics/Screenshot 2026-11-19 133850.png. I want the dropdowns to go up if the field they are showing go beyond past visible screen. This issue is only on Mobile with browser testing no actual Mobile device

# Issues resolved (DONE)

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
