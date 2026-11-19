# Features

### General

- Add a timer of when workout started and then ended, the timer can be set to start automatically when you start a workout or start when I press the timer start button. Then the data shoould be displayed with the day, show how long it was and from what time to the end time.

- Make a bottom navigation bar instead of the hamburger menu on the top left for Mobile. I want a navigation with icons and small text underneath them just like a mobile app. FOr example Instagram's bottom NAV bar

### Home page

### Calendar

- Make possible to open the Month of the calendar by clicking the name of the month to open a page of the month with the data of the splits, sets, weight, exercises done etc.
- Have the month be a dropdown as well, expand it when you click the month.

### Exercise page

- When adding a exercise, in the equipment box, currently I can only choose between Free weight or machine. I want to be able to add what type of machine and Brand. If it is Free Weight you can have options like Dumbbell, Barbell, Kettlebell etc. Machine it can be Smith, Chest Press, Leg extension etc. Also what type of Machine like Plate loaded, Pin etc. So when creating a exercise it can be very detailed like: Plate Loaded Pec Deck from MTorture. "Plate loaded" being type of machine, "Pec Deck" being what machine and "MTorture" being the brand.
  Make those options possible when adding the equipment. Also Admin can add to the catalog of Equipments and a normal user can not.
  Also add a option for the exercise that it can be unilateral or not (both hands or legs)
- Admins are also able to delete exercises already created with a small button on the side of the name in the modal.
- Also add notes of the exercise and notes for the set. So add a small text field for personal notes.
- Also add tags for each set. For example: warm-up, assisted etc. Admin can create and edit tags
- Add the amount of exercises and sets on the top of the exercises pages of the day. Also with that add this data to the weekly overview with the amount of set and exercises done on the week and when someone opens the weekly overview
- Make the exercises movable, so I can move around the order of the exercises done.
- Add Cardio as a exercise as well with inputs for incline, speed and time, for now. Also since it is Cardio it has to be a completly different thing then the weight training exercises.
- I want a button to add cardio if the day is rest day, instead of weight lifiting I will do cardio and that needs to be different, a new button only for Cardio.
- Bodyweight to as weight selection
- Workout logs should have the ame of exercise amount of sets and top weight, also add a 3 dots button to either edit or delete the exercise. and to show the sets and stuff expand it with a arrow down button. Image for reference - /home/pedro/code/pqdesu/fitness_app/doc/Features/Pics/Screenshot 2026-11-19 220155.png

Multiple selections of the days

Progression Chain so the user so what to do next
Auto suggestion - Change it or not? Progressing
Routine instead of sets with breaks in between
Make extendable the adding set of a exercise
Timer for exercise
Interval training

---

# Near Future

### AI integration

- Have an AI API to summarize how was the days workout based on the notes, weight, sets, reps and time spent on the gym.

---

# Features added (DONE)

### Calendar

- Should only have the day highlighted if workout was resgistered that day
- The highlighted day should be interactive. I can click on it to see the recorded exercises and workout

### Split Page

- Each split should not have the exercises recorded. It should only be a page of the splis programmed
- When adding a exercise go to the page of said exercise so I can already add the reps and weight I did for the exercise.
- Have a quick button on the exercise box to delete the exercise if I add the wrong exercise
- Remove the today form "N reps today" and just have "N reps"
- Change the position of reps - weight to be weight - reps
- Add a function to edit the number on the already registered reps or weight, need to be able to edit it if I make a mistake but don't want to delete the wh
  ole exercise.
- Also create a mock data with exercises for each split already recorded now from last week. I want to compare and see how does the app handle it.

### Split creation

- Instead of this UI:
  - [screenshot](Pics/screenshot-2026-11-15-200616.png)
    Have a list of the already created exercises and if no exercise has been created then have a Add exercise button instead. Then loads a modal with the UI to create an exercise
- Only have the exercise, remove the target sets and reps. When the user opens the exercise he can put his sets and reps with their own weight. This section will be entirely based on the user. He can add per Set, add the weight and the reps he has done. When adding have a button to add a new set.
- Add a UI of a week instead of floating boxes. I want a week starting with Sunday and ending Saturday with each date as a circle with the initial letter and mark it with a color and if not marked with a workout day leave it blank
- If the exervises for the day are empty have a button to add a exercise and it opens the catalogue that is divided by muscle groups. Like Chest, Back, Legs etc. And the user can then choose the ones he created or the ones already in the catalog

### General

- No back button to the previous page. Only the back button of the browser which goes back to the previous page the user interacted. I want a back button to the page he was in, for example:
  - User create a exercise, he goes back to the list of exercise.

### Home page

- Instead of having Splits on the home page I want them to be a separate page. I want the week from the 3rd issue to be on the dashboard page with which day is today highlighted and what Workout from the split it is.
- Have the a calendar of the month on the home page and the week highlighted on the calendar on the left of the page on top of the Splits, Workout logged and Sets recorded boxes. Also add a Text saying what day of the Split will it be, use the name of workout to be displayed and what last weeks exercises were done with the heaviest set and amount of reps.
- Add a weekly overview under the week of the slipt and remoe the splits, workout logged and sets recorded boxes.
- On Recent Workouts tab make the whole block clickable not only the name
- Make the Recent workout a dropdown, extend it to show it in more details and keep a summary of it at first.
- Also do the same for the Active split to extend and show the weeksdays.
- Have a today check as well not only the weekly but another box with todays workout and if none then have a button to start the workout so I can start adding the exercises done to be added to my workout. Like a simple quick button to start it
