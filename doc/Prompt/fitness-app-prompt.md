# Fitness app prompt

## What the app is

A simple, UI-friendly fitness app that helps you keep track of your workouts.
The app needs to be very intuitive, easy to use and user friendly.

The core use is: I go to the gym, log my workouts and what I did for the day, and then that's it.

## What the user records

- **Exercise** — the user either selects an exercise from the catalogue, or types the name of the exercise themselves. It is their choice; they are not limited to the catalogue.
- **Sets** — the amount of sets done for the lift.
- **Weight** — the weight used for the lift.
- **Equipment** — either free weights, or a machine. For a machine, the user types the name of the machine's brand themselves.

## Architecture

- Logging a workout is simple POST and GET: record what was done, and read it back.
- Deleting a logged set or exercise is allowed, so a mistake can be removed.
- Keep the existing planning layer (splits, workout days, planned exercises) as it is. Do not remove it.
- Keep the exercise catalogue. It is there so users can quickly select a common exercise instead of typing it.
- Only an admin can add to the catalogue (and edit or delete its entries). An exercise name typed by a user is used for that user's own plan or log; it is not added to the catalogue.

## Change to make in the current app

Today the app does not match two points above:

1. **Typed exercise names.** Exercises can only be picked from a shared catalogue that only admins manage. Keep the catalogue and the admin-only rule, and add the option for any user to type their own exercise name instead, when planning or logging.
2. **Typed machine brand.** Equipment is a single field fixed on the catalogue exercise. Change this so that, for each lift, the user chooses free weights or machine, and for a machine types the brand name.

## Design bar

- Favour the simplest, most obvious screen and flow.
- Few taps and little typing to log a set at the gym, on a phone.
- Do not add features beyond what is described here.
