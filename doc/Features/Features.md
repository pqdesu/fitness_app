# Features

### Home page

- Add a weekly overview under the week of the slipt and remoe the splits, workout logged and sets recorded boxes.
- On Recent Workouts tab make the whole block clickable not only the name

### Calendar

- Make possible to open the Month of the calendar by clicking the name of the month to open a page of the month with the data of the splits, sets, weight, exercises done etc.

### Exercise page

- When adding a exercise, in the equipment box, currently I can only choose between Free weight or machine. I want to be able to add what type of machine and Brand. If it is Free Weight you can have options like Dumbbell, Barbell, Kettlebell etc. Machine it can be Smith, Chest Press, Leg extension etc. Also what type of Machine like Plate loaded, Pin etc. So when creating a exercise it can be very detailed like: Plate Loaded Pec Deck from MTorture. "Plate loaded" being type of machine, "Pec Deck" being what machine and "MTorture" being the brand.
  Make those options possible when adding the equipment. Also Admin can add to the catalog of Equipments and a normal user can not.
  Also add a option for the exercise that it can be unilateral or not (both hands or legs)
- Admins are also able to delete excercises already created with a small button on the side of the name in the modal.
- Also add notes of the exercise and notes for the set. So add a small text field for personal notes.
- Also add tags for each set. For example: warm-up, assisted etc. Admin can create and edit tags
- Add the amount of exercises and sets on the top of the exercises pages of the day. Also with that add this data to the weekly overview with the amount of set and exercises done on the week and when someone opens the weekly overview

---

# Near Future

### AI integration

- Have an AI API to summarize how was the days workout based on the notes, weight, sets, reps and time spent on the gym.

---

# Issues Resolved

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
  - /home/pedro/code/pqdesu/fitness_app/doc/Issues/Pics/Screenshot 2026-11-15 200616.png
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
