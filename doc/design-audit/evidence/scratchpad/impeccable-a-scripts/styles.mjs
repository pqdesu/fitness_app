import * as L from './lib.mjs';
await L.start();
await L.viewport(390, 844, true);
await L.login('admin@example.com');
await L.go('/workout_exercises/17');
const out = await L.ev(`(() => {
 const cs = (sel, props) => { const e = document.querySelector(sel); if (!e) return sel + ': none'; const s = getComputedStyle(e); return sel + ' => ' + props.map(p => p + ':' + s.getPropertyValue(p)).join('; '); };
 return [
  cs('body', ['background-color','color','font-family','font-size','line-height']),
  cs('.card', ['background-color','border-color','border-radius','box-shadow']),
  cs('.card-header', ['background-color','padding']),
  cs('.card-footer', ['background-color']),
  cs('.form-control', ['background-color','border-color','color','font-size','min-height']),
  cs('.form-control::placeholder', ['color']),
  cs('.set-form .form-label', ['font-size','font-weight','color']),
  cs('.set-tag-toggle', ['border-color','color','font-size','min-height','height']),
  cs('.set-tag-choices .btn', ['border-color','color','height']),
  cs('.order-badge', ['font-size']),
  cs('.app-table th', ['font-size','background-color']),
  cs('.app-table td', ['font-size','padding']),
  cs('.actions-toggle', ['width','height','font-size']),
  cs('.btn-primary', ['background-color','font-size','font-weight','padding','border-radius']),
  cs('.page-header h1', ['font-family','font-size','font-weight','letter-spacing','line-height']),
  cs('.card h2', ['font-size','font-family','font-weight']),
  cs('.text-muted', ['color']),
  cs('.rest-clock', ['font-family','font-weight']),
  cs('.navbar-page-title', ['font-size']),
 ].join('\\n');
})()`);
console.log(out);
// heights of set tbodys and position of Add set
console.log(await L.ev(`JSON.stringify({tbodies:[...document.querySelectorAll('.set-table tbody')].map(t=>Math.round(t.getBoundingClientRect().height)), addSetTop: Math.round(document.querySelector('.set-form button[type=submit], .set-form .btn-primary').getBoundingClientRect().top + scrollY), vh: innerHeight})`));
// placeholder colour
console.log(await L.ev(`(() => { const i=document.querySelector('.set-note input'); return getComputedStyle(i,'::placeholder').color })()`));
// check box/radio styles
await L.go('/exercises/new');
console.log(await L.ev(`(() => { const i=document.querySelector('.form-check-input:not(:checked)'); const s=getComputedStyle(i); return 'checkbox border '+s.borderColor+' bg '+s.backgroundColor+' size '+s.width; })()`));
console.log(await L.ev(`(() => { const l=document.querySelector('label'); const s=getComputedStyle(l); return 'form label '+s.fontSize+' '+s.fontWeight+' '+s.color; })()`));
console.log(await L.ev(`(() => { const i=document.querySelector('input[type=text]'); return 'placeholder '+getComputedStyle(i,'::placeholder').color+' opacity '+getComputedStyle(i,'::placeholder').opacity; })()`));
// fonts loaded
console.log(await L.ev(`document.fonts.ready.then(()=>[...document.fonts].filter(f=>f.status==='loaded').map(f=>f.family+' '+f.weight).join(', '))`));
L.stop();
