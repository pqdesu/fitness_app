(async () => {
  const paths = ['/', '/workout_days/11', '/workout_exercises/17', '/workout_logs/7', '/workout_logs', '/workout_logs/1', '/splits', '/splits/3', '/dashboard/month', '/exercises', '/users/edit', '/admin/equipment'];
  const res = [];
  for (const p of paths) {
    const f = document.createElement('iframe'); f.style.cssText = 'position:absolute;left:0;top:0;border:0;width:' + innerWidth + 'px;height:800px'; f.src = p; document.body.appendChild(f);
    await new Promise((r) => f.onload = r); await new Promise((r) => setTimeout(r, 400));
    const d = f.contentDocument; const w = f.contentWindow;
    const over = (doc) => { const vw = doc.documentElement.clientWidth; const els = [...doc.querySelectorAll('main *')].filter((e) => { const r = e.getBoundingClientRect(); return r.width > 0 && r.right > vw + 1; }).slice(0, 4).map((e) => e.tagName + '.' + [...e.classList].slice(0,2).join('.') + ' r=' + Math.round(e.getBoundingClientRect().right)); return { sw: doc.documentElement.scrollWidth, vw, els }; };
    const a = over(d);
    d.documentElement.style.fontSize = '200%'; await new Promise((r) => setTimeout(r, 300));
    const b = over(d);
    res.push(p + ' | normal sw=' + a.sw + ' vw=' + a.vw + ' ' + a.els.join(',') + ' | text200% sw=' + b.sw + ' ' + b.els.join(','));
    f.remove();
  }
  return res.join('\n');
})()
