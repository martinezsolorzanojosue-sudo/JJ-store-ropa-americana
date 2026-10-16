// Arma index.html (versión GitHub Pages + Supabase) reutilizando estilos e ilustraciones de jj-store.html
const fs = require('fs');
const path = require('path');
const root = path.join(__dirname, '..');
const src = fs.readFileSync(path.join(root, 'jj-store.html'), 'utf8');
const css = src.match(/<style id="app-style">([\s\S]*?)<\/style>/)[1];
const js = src.match(/<script id="app-js">([\s\S]*?)<\/script>/)[1];
const cut = (a, b) => { const i = js.indexOf(a), j = js.indexOf(b, i); if (i < 0 || j < 0) throw new Error('No encontré: ' + a); return js.slice(i, j); };
let shared = cut('/* ---------- Garment illustrations', '/* ---------- Render');
shared = shared.replace('var src = tempUrls[it.img] || ("/_blob/" + it.img);', 'var src = imgUrl(it.img);');
if (shared.includes('tempUrls')) throw new Error('media() sin adaptar');
let out = fs.readFileSync(path.join(__dirname, 'index.template.html'), 'utf8');
out = out.replace('/*@CSS@*/', () => css.trim()).replace('/*@SHARED@*/', () => shared.trim());
fs.writeFileSync(path.join(root, 'index.html'), out);
console.log('index.html listo', out.length);
