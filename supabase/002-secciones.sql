-- JJ Store: mejora 2 — secciones libres (no solo Hombre/Mujer) y talla opcional.
-- Pega este texto en Supabase → SQL Editor → New query y toca "Run". Se puede ejecutar más de una vez.
alter table public.products drop constraint if exists products_section_check;
alter table public.products add constraint products_section_check check (char_length(section) between 1 and 40);
alter table public.products alter column size drop not null;
alter table public.settings add column if not exists sections jsonb not null default
  '[{"id":"h","name":"Hombre"},{"id":"m","name":"Mujer"},{"id":"ninos","name":"Niños"},{"id":"calzado","name":"Calzado"},{"id":"accesorios","name":"Accesorios"},{"id":"hogar","name":"Hogar"},{"id":"otros","name":"Otros"}]'::jsonb;
