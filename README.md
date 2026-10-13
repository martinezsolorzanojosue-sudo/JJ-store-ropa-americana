# JJ Store

Tienda en línea de ropa americana: catálogo de hombre y mujer, pedidos por WhatsApp, código QR para compartir y panel del dueño.

Versión en vivo: https://claude.ai/artifact/VwSX11XCT5XUiHj973Nkta

## Archivos

- `jj-store.html` — la app completa (HTML, CSS y JavaScript en un solo archivo).
- `build/seed.js` — genera las 52 prendas de muestra y las inserta en `jj-store.html`.
  Uso: `node build/seed.js <enlace-de-la-tienda>`

## Nota

El panel del dueño (subir fotos, marcar vendidas, eliminar y publicar) usa las funciones de los Artifacts de claude.ai.
Fuera de claude.ai, el catálogo, los pedidos y el QR se ven, pero el panel del dueño no funciona.
