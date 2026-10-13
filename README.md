# JJ Store

Tienda en línea de ropa americana: catálogo de hombre y mujer, pedidos (guardados y por WhatsApp), código QR para compartir y panel del dueño con login.

Tienda: https://martinezsolorzanojosue-sudo.github.io/JJ-store-ropa-americana/

## Archivos

- `index.html` — la tienda (GitHub Pages). Usa Supabase para prendas, fotos, pedidos y el login del dueño.
- `supabase/setup.sql` — crea las tablas, las reglas de seguridad, el espacio de fotos y 52 prendas de muestra. Se pega en Supabase → SQL Editor.
- `jj-store.html` — versión original hecha como Artifact de claude.ai.
- `build/` — scripts que generan `index.html` y `setup.sql` (`node build/make-index.js`, `node build/make-sql.js`).

## Seguridad

La clave `sb_publishable_...` que va dentro de `index.html` es pública por diseño. Lo que protege la tienda son las reglas de `setup.sql`: los clientes solo ven el catálogo y crean pedidos; solo los usuarios registrados como dueño pueden editar prendas, subir fotos y ver pedidos.
