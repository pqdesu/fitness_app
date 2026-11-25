import * as L from './lib.mjs';
await L.start();
await L.viewport(390, 844, true);
await L.login('admin@example.com');
await L.go('/workout_days/11');
await L.ev(`document.querySelector('[data-bs-toggle="modal"]').click()`); await L.sleep(800);
console.log(await L.ev(`(() => { const m=document.querySelector('.modal.show'); const i=m.querySelector('input[type=text]'); i.value='Single-arm cable rear delt fly with rope attachment (slow eccentric)'; const f=i.form; f.requestSubmit(); return f.action; })()`));
await L.sleep(3000);
await L.shot('long-name-workout');
console.log('url', await L.ev('location.href'));
console.log('flash:', await L.ev(`[...document.querySelectorAll('.flash')].map(f=>f.innerText).join(' | ')`));
await L.go('/');
await L.ev(`document.querySelectorAll('[data-bs-toggle="collapse"].collapsed').forEach(b=>b.click())`); await L.sleep(800);
await L.shot('long-name-home');
// overflow check
for (const p of ['/', '/workout_days/11', '/workout_logs/7', '/dashboard/month', '/workout_logs']) { await L.go(p); console.log(p, 'overflow', await L.ev('document.documentElement.scrollWidth > innerWidth')); }
await L.go('/workout_logs/7'); await L.shot('long-name-log');
L.stop();
