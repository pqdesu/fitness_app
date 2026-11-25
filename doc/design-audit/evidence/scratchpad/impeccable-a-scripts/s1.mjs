import * as L from './lib.mjs';
await L.start();
await L.viewport(390, 844, true);
await L.login('admin@example.com');
// rest timer running
await L.go('/workout_exercises/17');
await L.ev(`(() => { const b=[...document.querySelectorAll('.rest-timer button')].find(b=>/Start rest/.test(b.textContent)); b && b.click(); })()`);
await L.sleep(4000);
await L.ev(`document.querySelector('.rest-timer').scrollIntoView({block:'center'})`);
await L.sleep(500);
await L.shot('rest-running');
// add set while rest running -> alert?
await L.ev(`document.querySelector('.set-form button[type=submit], .set-form .btn-primary').click()`);
await L.sleep(1200);
await L.shot('rest-alert-on-add');
console.log(await L.ev(`[...document.querySelectorAll('.modal.show')].map(m=>m.innerText.replace(/\\s+/g,' ')).join(' | ')`));
// choose first primary in modal
await L.ev(`(() => { const m=document.querySelector('.modal.show'); if(!m) return; const b=m.querySelector('.btn-primary'); b && b.click(); })()`);
await L.sleep(2500);
await L.shot('after-add-set-flash');
console.log('flash:', await L.ev(`[...document.querySelectorAll('.flash')].map(f=>f.innerText).join(' | ')`));
console.log('scrollY', await L.ev('scrollY'));
// focus states: tab through from the weight field
await L.ev(`document.querySelector('.set-form input[type=number]').focus()`);
await L.sleep(300);
await L.ev(`document.querySelector('.set-form').scrollIntoView({block:'center'})`);
await L.shot('focus-weight');
await L.tab(); await L.shot('focus-reps');
await L.tab(); await L.shot('focus-addset');
await L.tab(); await L.shot('focus-tag-pill');
// focus on actions menu and tag button in table
await L.ev(`document.querySelector('.actions-toggle').focus(); document.querySelector('.actions-toggle').scrollIntoView({block:'center'})`);
await L.sleep(200); await L.shot('focus-actions-toggle');
await L.ev(`document.querySelector('.set-tag-toggle').focus()`); await L.sleep(200); await L.shot('focus-tag-toggle');
await L.ev(`document.querySelector('.set-note input').focus()`); await L.sleep(200); await L.shot('focus-note');
// back link focus
await L.ev(`scrollTo(0,0); document.querySelector('.back-link').focus()`); await L.sleep(200); await L.shot('focus-back');
console.log('focus outline of btn-light:', await L.ev(`(() => { const b=document.querySelector('.rest-timer .btn, .set-form .btn'); b.focus(); const s=getComputedStyle(b); return s.outline+' | '+s.boxShadow; })()`));
L.stop();
