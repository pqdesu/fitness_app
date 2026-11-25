import * as L from './lib.mjs';
await L.start();
await L.viewport(390, 844, true);
await L.login('admin@example.com');
await L.go('/workout_exercises/17?date=2026-11-25');
const pos = () => L.ev(`(() => { const b=document.querySelector('.set-form .btn-primary'); const r=b.getBoundingClientRect(); return JSON.stringify({btnTop: Math.round(r.top), scrollY: Math.round(scrollY), navTop: Math.round(document.querySelector('.bottom-nav').getBoundingClientRect().top)}); })()`);
// scroll so Add set is just above the nav, like a user would
await L.ev(`(() => { const b=document.querySelector('.set-form .btn-primary'); scrollBy(0, b.getBoundingClientRect().top - 600); })()`);
await L.sleep(300);
console.log('before', await pos());
await L.ev(`document.querySelector('.set-form .btn-primary').click()`);
await L.sleep(2500);
console.log('after', await pos());
await L.shot('after-add-with-date');
L.stop();
