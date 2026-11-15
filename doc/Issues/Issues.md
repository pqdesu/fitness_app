# Issues

### Split Page

1. Each split should not have the exercises recorded. It should only be a page of the splis programmed
2. When adding a exercise go to the page of said exercise so I can already add the reps and weight I did for the exercise.
3. Have a quick button on the exercise box to delete the exercise if I add the wrong exercise
4. Remove the today form "N reps today" and just have "N reps"
5. Change the position of reps - weight to be weight - reps
6. Add a function to edit the number on the already registered reps or weight, need to be able to edit it if I make a mistake but don't want to delete the whole exercise.
7. Also create a mock data with exercises for each split already recorded now from last week. I want to compare and see how does the app handle it.

---

# Issues Resolved

### Split creation

1. Instead of this UI:
   - /home/pedro/code/pqdesu/fitness_app/doc/Issues/Pics/Screenshot 2026-11-15 200616.png
     Have a list of the already created exercises and if no exercise has been created then have a Add exercise button instead. Then loads a modal with the UI to create an exercise
2. Only have the exercise, remove the target sets and reps. When the user opens the exercise he can put his sets and reps with their own weight. This section will be entirely based on the user. He can add per Set, add the weight and the reps he has done. When adding have a button to add a new set.
3. Add a UI of a week instead of floating boxes. I want a week starting with Sunday and ending Saturday with each date as a circle with the initial letter and mark it with a color and if not marked with a workout day leave it blank
4. If the exervises for the day are empty have a button to add a exercise and it opens the catalogue that is divided by muscle groups. Like Chest, Back, Legs etc. And the user can then choose the ones he created or the ones already in the catalog

### General

1. No back button to the previous page. Only the back button of the browser which goes back to the previous page the user interacted. I want a back button to the page he was in, for example:
   - User create a exercise, he goes back to the list of exercise.

### Home page

1. Instead of having Splits on the home page I want them to be a separate page. I want the week from the 3rd issue to be on the dashboard page with which day is today highlighted and what Workout from the split it is.
2. Have the a calendar of the month on the home page and the week highlighted on the calendar on the left of the page on top of the Splits, Workout logged and Sets recorded boxes. Also add a Text saying what day of the Split will it be, use the name of workout to be displayed and what last weeks exercises were done with the heaviest set and amount of reps.
