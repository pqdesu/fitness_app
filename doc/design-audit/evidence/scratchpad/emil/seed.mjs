import { start, stop, go, post, login, evaluate, viewport } from './cdp.mjs';
const NAME = 'Single-arm cable rear delt fly, kneeling, with rope and a pause at the top';
const BRAND = 'Hammer Strength by Life Fitness, Plate-Loaded Iso-Lateral';
const SPLIT = 'Push/Pull/Legs + Upper/Lower hybrid (winter cut, 12 weeks)';
const NOTE = 'Left knee felt off on the last two reps, so I went slower on the way down and held the pause; next time try a narrower stance and add 2.5 kg if it feels fine.';
console.log(NAME.length, BRAND.length, SPLIT.length, NOTE.length);
await start();
try {
  await viewport(390, 844, true);
  await login('admin@example.com');
  await go('/splits');
  let r = await post('/splits', [['split[name]', SPLIT]]); console.log('split', r);
  const splitId = r.url.match(/splits\/(\d+)/)[1];
  r = await post(`/splits/${splitId}/workout_days`, [['workout_day[day]', 'Full Body'], ['workout_day[weekday]', '3']]); console.log('day', r);
  await go(`/splits/${splitId}`);
  const wd = await evaluate(`[...document.querySelectorAll('a[href^="/workout_days/"]')].map(a => a.getAttribute('href'))[0]`);
  const wdId = wd.match(/workout_days\/(\d+)/)[1]; console.log('wd', wdId);
  r = await post(`/workout_days/${wdId}/workout_log_exercises`, [['date', '2026-11-25'], ['exercise[name]', NAME], ['exercise[muscle_group]', 'Shoulders'], ['exercise[equipment]', 'machine'], ['exercise[machine_brand]', BRAND]]); console.log('long ex', r);
  await go(`/workout_days/${wdId}`);
  const ids = await evaluate(`[...document.querySelectorAll('input[name="exercise_ids[]"]')].filter(i => !i.disabled).map(i => i.value)`);
  console.log('catalogue', ids.length);
  r = await post(`/workout_days/${wdId}/workout_log_exercises`, [['date', '2026-11-25'], ...ids.slice(0, 16).map((v) => ['exercise_ids[]', v])]); console.log('many', r);
  await go(`/workout_days/${wdId}`);
  const entryLink = await evaluate(`(() => { const a = [...document.querySelectorAll('a')].find(a => a.textContent.includes('Single-arm cable')); return a && a.getAttribute('href'); })()`);
  console.log('entry link', entryLink);
  const info = await evaluate(`[...new Set([...document.querySelectorAll('[action]')].map(f => f.getAttribute('action')))].slice(0,40)`);
  console.log(info);
  console.log(JSON.stringify({ splitId, wdId }));
} finally { stop(); }
