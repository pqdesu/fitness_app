import * as L from './lib.mjs';
await L.start();
await L.viewport(390, 844, true);
// wrong password
await L.send('Network.clearBrowserCookies');
await L.go('/users/sign_in');
await L.ev(`(() => { document.querySelector('#user_email').value='admin@example.com'; document.querySelector('#user_password').value='nope'; document.querySelector('form').requestSubmit(); })()`);
await L.sleep(2500); await L.shot('err-signin');
await L.login('admin@example.com');
// empty split
await L.go('/splits/new');
await L.ev(`(() => { const f=document.querySelector('main form'); f.noValidate=true; f.requestSubmit(); })()`);
await L.sleep(2000); await L.shot('err-split-new');
await L.go('/splits/1/workout_days/new');
await L.ev(`(() => { const f=document.querySelector('main form'); f.noValidate=true; f.requestSubmit(); })()`);
await L.sleep(2000); await L.shot('err-workout-day-new');
await L.go('/exercises/new');
await L.ev(`(() => { const f=document.querySelector('main form'); f.noValidate=true; f.requestSubmit(); })()`);
await L.sleep(2000); await L.shot('err-exercise-new');
// duplicate name
await L.go('/exercises/new');
await L.ev(`(() => { document.querySelector('#exercise_name').value='Squat'; const f=document.querySelector('main form'); f.requestSubmit(); })()`);
await L.sleep(2000); await L.shot('err-exercise-dup');
// empty reps on exercise page (native validation) - submit empty with novalidate
await L.go('/workout_exercises/19');
await L.ev(`(() => { const f=document.querySelector('.set-form'); f.querySelector('[name*=reps]').value=''; f.noValidate=true; f.requestSubmit(); })()`);
await L.sleep(2500); await L.shot('err-set-empty');
console.log('flash:', await L.ev(`[...document.querySelectorAll('.flash')].map(f=>f.innerText).join(' | ')`));
// picker with group open
await L.go('/workout_days/11');
await L.ev(`document.querySelector('[data-bs-toggle="modal"]').click()`); await L.sleep(800);
await L.ev(`document.querySelector('.modal.show .group-toggle, .modal.show [data-bs-toggle=collapse]').click()`); await L.sleep(800);
await L.shot('picker-group-open');
console.log('picker search?', await L.ev(`!!document.querySelector('.modal.show input[type=search]')`));
await L.ev(`document.querySelector('.modal.show .btn-close').click()`); await L.sleep(600);
// pause timer
await L.ev(`(() => { const b=[...document.querySelectorAll('.timer-card button')].find(b=>/Pause/.test(b.textContent)); b && b.click(); })()`);
await L.sleep(2500); await L.shot('timer-paused');
await L.ev(`document.querySelector('[data-bs-toggle="modal"]').click()`); await L.sleep(900);
await L.shot('timer-paused-alert-add');
console.log(await L.ev(`[...document.querySelectorAll('.modal.show')].map(m=>m.innerText.replace(/\\s+/g,' ')).join(' | ')`));
await L.ev(`(() => { const m=document.querySelector('.modal.show'); const b=[...m.querySelectorAll('button')].find(b=>/Resume/.test(b.textContent)); b && b.click(); })()`);
await L.sleep(2500); await L.shot('timer-after-resume');
// calendar titles
await L.go('/');
console.log(await L.ev(`[...document.querySelectorAll('.calendar-day[title]')].slice(14,30).map(d=>d.textContent.trim()+': '+d.title).join('\\n')`));
console.log(await L.ev(`[...document.querySelectorAll('.week-day')].map(d=>d.textContent.trim().replace(/\\s+/g,' ')+': '+(d.title||d.getAttribute('aria-label'))).join('\\n')`));
L.stop();
