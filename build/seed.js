// Genera el estado inicial (52 prendas de muestra) y lo inserta en jj-store.html
const fs = require('fs');
const path = require('path');

const H = [
  ['Camiseta Nike vintage', 'Camisetas', 'tee', '#2f5d8a', 'M', 180],
  ['Camiseta Champion gris', 'Camisetas', 'tee', '#8a8f98', 'L', 160],
  ['Camiseta Harley-Davidson', 'Camisetas', 'tee', '#1d1f24', 'XL', 220],
  ['Camiseta Gap básica', 'Camisetas', 'tee', '#c8322b', 'S', 120],
  ['Camiseta Hanes blanca', 'Camisetas', 'tee', '#eef0f2', 'M', 100],
  ['Camisa Ralph Lauren Oxford', 'Camisas', 'shirt', '#9bb7d4', 'L', 320],
  ['Camisa Tommy Hilfiger a cuadros', 'Camisas', 'shirt', '#b8463d', 'M', 300],
  ['Camisa Columbia de pesca', 'Camisas', 'shirt', '#c9b48a', 'XL', 280],
  ['Camisa Levi\'s de mezclilla', 'Camisas', 'shirt', '#4a6c94', 'M', 350],
  ['Camisa Dockers manga larga', 'Camisas', 'shirt', '#e3e6ea', 'L', 240],
  ['Sudadera Champion con capucha', 'Sudaderas', 'hoodie', '#3b4f7a', 'L', 380],
  ['Sudadera Nike Club', 'Sudaderas', 'hoodie', '#2b2d33', 'M', 400],
  ['Sudadera universitaria Michigan', 'Sudaderas', 'hoodie', '#1f3a5f', 'XL', 420],
  ['Sudadera Carhartt', 'Sudaderas', 'hoodie', '#8a6a3b', 'L', 450],
  ['Chaqueta Carhartt Detroit', 'Chaquetas', 'jacket', '#9b7440', 'L', 750],
  ['Chaqueta Levi\'s Trucker', 'Chaquetas', 'jacket', '#46658f', 'M', 680],
  ['Chaqueta The North Face', 'Chaquetas', 'jacket', '#262a30', 'XL', 900],
  ['Chaqueta bomber Alpha', 'Chaquetas', 'jacket', '#4d5a3c', 'M', 620],
  ['Jeans Levi\'s 501', 'Pantalones', 'jeans', '#3d5f8c', '32x32', 450],
  ['Jeans Wrangler Cowboy Cut', 'Pantalones', 'jeans', '#2f4b73', '34x30', 400],
  ['Pantalón Dickies 874', 'Pantalones', 'jeans', '#5b5d4a', '32x30', 380],
  ['Pantalón cargo Old Navy', 'Pantalones', 'jeans', '#7a6f55', '30x32', 340],
  ['Short Nike deportivo', 'Shorts', 'shorts', '#2b2d33', 'M', 180],
  ['Short Levi\'s de mezclilla', 'Shorts', 'shorts', '#5a7aa3', '32', 220],
  ['Short cargo Columbia', 'Shorts', 'shorts', '#b5a37d', '34', 200],
  ['Suéter Polo de algodón', 'Suéteres', 'sweater', '#2e5b46', 'L', 360],
];
const M = [
  ['Blusa Ann Taylor de seda', 'Blusas', 'blouse', '#e8c7c8', 'S', 220],
  ['Blusa Old Navy floral', 'Blusas', 'blouse', '#d98f6f', 'M', 160],
  ['Blusa Loft blanca', 'Blusas', 'blouse', '#f1f1ee', 'M', 180],
  ['Blusa Calvin Klein negra', 'Blusas', 'blouse', '#22242a', 'L', 240],
  ['Blusa American Eagle rayas', 'Blusas', 'blouse', '#7c9cc4', 'S', 170],
  ['Camiseta Gap rosa', 'Camisetas', 'tee', '#e79bb0', 'S', 110],
  ['Camiseta Disney vintage', 'Camisetas', 'tee', '#c8322b', 'M', 200],
  ['Camiseta Nike Dri-FIT', 'Camisetas', 'tee', '#6b4f9a', 'M', 170],
  ['Vestido Forever 21 de verano', 'Vestidos', 'dress', '#f0b45a', 'S', 280],
  ['Vestido Michael Kors negro', 'Vestidos', 'dress', '#1d1f24', 'M', 450],
  ['Vestido floral Old Navy', 'Vestidos', 'dress', '#c96f8a', 'M', 300],
  ['Vestido de mezclilla Levi\'s', 'Vestidos', 'dress', '#4a6c94', 'L', 380],
  ['Vestido Banana Republic', 'Vestidos', 'dress', '#2e5b46', 'S', 420],
  ['Falda plisada J.Crew', 'Faldas', 'skirt', '#c9b48a', 'S', 240],
  ['Falda de mezclilla Gap', 'Faldas', 'skirt', '#5a7aa3', 'M', 220],
  ['Falda midi Ann Taylor', 'Faldas', 'skirt', '#8f2f3a', 'M', 260],
  ['Jeans Levi\'s Mom Fit', 'Pantalones', 'jeans', '#6f8fb8', '28', 450],
  ['Jeans American Eagle skinny', 'Pantalones', 'jeans', '#2f4b73', '30', 400],
  ['Pantalón Gap de vestir', 'Pantalones', 'jeans', '#3a3d45', '8', 320],
  ['Short Levi\'s high rise', 'Shorts', 'shorts', '#86a5cb', '27', 220],
  ['Short Nike running', 'Shorts', 'shorts', '#e2557a', 'S', 160],
  ['Sudadera Champion crop', 'Sudaderas', 'hoodie', '#b9a6d6', 'S', 340],
  ['Sudadera Victoria\'s Secret PINK', 'Sudaderas', 'hoodie', '#ec9bb5', 'M', 380],
  ['Chaqueta Levi\'s de mezclilla', 'Chaquetas', 'jacket', '#5a7aa3', 'S', 620],
  ['Chaqueta Columbia impermeable', 'Chaquetas', 'jacket', '#2f6f78', 'M', 700],
  ['Cárdigan Gap tejido', 'Suéteres', 'sweater', '#d8c3a5', 'M', 300],
];
const conds = ['Como nuevo', 'Buen estado', 'Como nuevo', 'Con etiqueta', 'Buen estado'];

let n = 0;
const mk = (sec) => ([name, cat, k, c, size, price]) => {
  n++;
  return { id: 'p' + String(n).padStart(3, '0'), name, sec, cat, size, price, cond: conds[n % conds.length],
    sold: n % 11 === 0, art: { k, c }, img: null, t: n };
};
const items = [...H.map(mk('h')), ...M.map(mk('m'))];

const state = {
  v: 1,
  settings: { whatsapp: '', currency: '$', link: process.argv[2] || '' },
  items,
};

const file = path.join(__dirname, '..', 'jj-store.html');
let html = fs.readFileSync(file, 'utf8');
const json = JSON.stringify(state).replace(/</g, '\\u003c');
html = html.replace(/(<script type="application\/json" id="jj-state">)[\s\S]*?(<\/script>)/, (_, a, b) => a + json + b);
fs.writeFileSync(file, html);
console.log('items:', items.length, 'hombre:', H.length, 'mujer:', M.length);
