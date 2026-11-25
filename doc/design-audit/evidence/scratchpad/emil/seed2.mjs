import { start, stop, go, post, login, viewport } from './cdp.mjs';
const NOTE = 'Left knee felt off on the last two reps, so I went slower on the way down and held the pause; next time try a narrower stance and add 2.5 kg if it feels fine.';
const ENTRY_NOTE = 'Seat on 4, handles on the second notch. Rope slipped twice, so swap to the D-handle next time. Shoulder clicked on the first warm-up set but was fine after. Keep the elbows soft and lead with the pinkies; the last three sets were a drop set from the top weight down to the lightest plate on the stack.';
await start();
try {
  await viewport(390, 844, true);
  await login('admin@example.com');
  await go('/workout_days/14');
  const sets = [['1234.125', '999', NOTE], ['1234.125', '999', ''], ['0.5', '1', ''], ['99999.125', '12', ''], ['20', '10', 'ok'], ['22.5', '10', ''], ['25', '8', ''], ['27.5', '8', ''], ['30', '6', ''], ['32.5', '6', ''], ['35', '5', ''], ['', '15', 'bodyweight only, no plate'], ['1234.125', '999', NOTE]];
  for (const [w, r, n] of sets) {
    const res = await post('/workout_log_exercises/21/workout_sets', [['workout_set[weight_used]', w], ['workout_set[reps_completed]', r], ['workout_set[notes]', n]]);
    console.log(w, r, res.status, res.flash);
  }
  console.log(await post('/workout_log_exercises/21?date=2026-11-25&workout_day_id=14', [['_method', 'patch'], ['workout_log_exercise[notes]', ENTRY_NOTE]]));
  console.log(await post('/workout_days/14/timer?date=2026-11-25', []));
  // plan the long exercise on the split day too
  console.log(await post('/workout_days/14/workout_exercises', [['exercise[name]', 'Single-arm cable rear delt fly, kneeling, with rope and a pause at the top']]));
} finally { stop(); }
