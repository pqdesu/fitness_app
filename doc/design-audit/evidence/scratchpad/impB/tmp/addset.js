(async () => {
  const before = scrollY;
  const w = document.querySelector('#weight_workout_exercise_17'); w.scrollIntoView({ block: 'center' }); await new Promise((r) => setTimeout(r, 300));
  const s1 = scrollY;
  w.value = '95'; document.querySelector('#reps_workout_exercise_17').value = '6';
  document.querySelector('.set-form [type=submit]').click();
  await new Promise((r) => setTimeout(r, 2500));
  const f = document.querySelector('#weight_workout_exercise_17'); const r = f.getBoundingClientRect();
  return 'scroll before submit=' + s1 + ' after=' + scrollY + ' url=' + location.href + ' addform top in viewport=' + Math.round(r.top) + ' (viewport ' + innerHeight + ') focused=' + document.activeElement.id + ' sets now=' + document.querySelectorAll('.set-table tbody').length + ' flash=' + (document.querySelector('.flash-text')?.innerText || 'none') + ' weight prefill=' + f.value;
})()
