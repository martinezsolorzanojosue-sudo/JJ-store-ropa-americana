-- JJ Store: configuración de Supabase
-- Pega todo este texto en Supabase → SQL Editor → New query y toca "Run".
-- Antes, crea tu usuario de dueño en Authentication → Users → Add user.
-- Se puede ejecutar más de una vez sin duplicar nada.

-- 1. Tablas -------------------------------------------------------------
create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(name) between 1 and 120),
  section text not null check (section in ('h', 'm')),
  category text not null check (char_length(category) between 1 and 60),
  size text not null check (char_length(size) between 1 and 30),
  price numeric(10, 2) not null default 0 check (price >= 0),
  condition text not null default 'Buen estado',
  sold boolean not null default false,
  image_path text,
  art jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.settings (
  id int primary key default 1 check (id = 1),
  whatsapp text not null default '',
  currency text not null default '$',
  link text not null default ''
);
insert into public.settings (id) values (1) on conflict do nothing;

create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  customer_name text not null check (char_length(customer_name) between 1 and 80),
  phone text not null check (char_length(phone) between 4 and 30),
  delivery text not null default '' check (char_length(delivery) <= 40),
  address text not null default '' check (char_length(address) <= 200),
  wish text not null default '' check (char_length(wish) <= 600),
  notes text not null default '' check (char_length(notes) <= 300),
  items jsonb not null default '[]'::jsonb check (jsonb_typeof(items) = 'array' and jsonb_array_length(items) <= 30),
  total numeric(10, 2) not null default 0,
  status text not null default 'nuevo' check (status in ('nuevo', 'atendido'))
);

-- 2. Dueños: todos los usuarios que existan al ejecutar este texto --------
create table if not exists public.owners (
  user_id uuid primary key references auth.users (id) on delete cascade
);
insert into public.owners (user_id) select id from auth.users on conflict do nothing;

create or replace function public.is_owner() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.owners where user_id = auth.uid());
$$;
grant execute on function public.is_owner() to anon, authenticated;

-- 3. Reglas de seguridad (RLS) ------------------------------------------
alter table public.products enable row level security;
alter table public.settings enable row level security;
alter table public.orders enable row level security;
alter table public.owners enable row level security;

grant select on public.products, public.settings to anon, authenticated;
grant insert, update, delete on public.products, public.settings to authenticated;
grant insert on public.orders to anon, authenticated;
grant select, update, delete on public.orders to authenticated;

drop policy if exists "catalogo publico" on public.products;
create policy "catalogo publico" on public.products for select to anon, authenticated using (true);
drop policy if exists "dueno edita prendas" on public.products;
create policy "dueno edita prendas" on public.products for all to authenticated using (public.is_owner()) with check (public.is_owner());

drop policy if exists "ajustes publicos" on public.settings;
create policy "ajustes publicos" on public.settings for select to anon, authenticated using (true);
drop policy if exists "dueno edita ajustes" on public.settings;
create policy "dueno edita ajustes" on public.settings for update to authenticated using (public.is_owner()) with check (public.is_owner());

drop policy if exists "clientes crean pedidos" on public.orders;
create policy "clientes crean pedidos" on public.orders for insert to anon, authenticated with check (status = 'nuevo');
drop policy if exists "dueno ve pedidos" on public.orders;
create policy "dueno ve pedidos" on public.orders for select to authenticated using (public.is_owner());
drop policy if exists "dueno actualiza pedidos" on public.orders;
create policy "dueno actualiza pedidos" on public.orders for update to authenticated using (public.is_owner()) with check (public.is_owner());
drop policy if exists "dueno borra pedidos" on public.orders;
create policy "dueno borra pedidos" on public.orders for delete to authenticated using (public.is_owner());

-- 4. Fotos (bucket público "prendas") -----------------------------------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('prendas', 'prendas', true, 5242880, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do nothing;

drop policy if exists "dueno sube fotos" on storage.objects;
create policy "dueno sube fotos" on storage.objects for insert to authenticated with check (bucket_id = 'prendas' and public.is_owner());
drop policy if exists "dueno cambia fotos" on storage.objects;
create policy "dueno cambia fotos" on storage.objects for update to authenticated using (bucket_id = 'prendas' and public.is_owner());
drop policy if exists "dueno borra fotos" on storage.objects;
create policy "dueno borra fotos" on storage.objects for delete to authenticated using (bucket_id = 'prendas' and public.is_owner());

-- 5. Prendas de muestra (solo si el catálogo está vacío) -----------------
insert into public.products (name, section, category, size, price, condition, sold, art, created_at)
select * from (values
  ('Camiseta Nike vintage', 'h', 'Camisetas', 'M', 180, 'Buen estado', false, '{"k":"tee","c":"#2f5d8a"}'::jsonb, now() - interval '52 minutes'),
  ('Camiseta Champion gris', 'h', 'Camisetas', 'L', 160, 'Como nuevo', false, '{"k":"tee","c":"#8a8f98"}'::jsonb, now() - interval '51 minutes'),
  ('Camiseta Harley-Davidson', 'h', 'Camisetas', 'XL', 220, 'Con etiqueta', false, '{"k":"tee","c":"#1d1f24"}'::jsonb, now() - interval '50 minutes'),
  ('Camiseta Gap básica', 'h', 'Camisetas', 'S', 120, 'Buen estado', false, '{"k":"tee","c":"#c8322b"}'::jsonb, now() - interval '49 minutes'),
  ('Camiseta Hanes blanca', 'h', 'Camisetas', 'M', 100, 'Como nuevo', false, '{"k":"tee","c":"#eef0f2"}'::jsonb, now() - interval '48 minutes'),
  ('Camisa Ralph Lauren Oxford', 'h', 'Camisas', 'L', 320, 'Buen estado', false, '{"k":"shirt","c":"#9bb7d4"}'::jsonb, now() - interval '47 minutes'),
  ('Camisa Tommy Hilfiger a cuadros', 'h', 'Camisas', 'M', 300, 'Como nuevo', false, '{"k":"shirt","c":"#b8463d"}'::jsonb, now() - interval '46 minutes'),
  ('Camisa Columbia de pesca', 'h', 'Camisas', 'XL', 280, 'Con etiqueta', false, '{"k":"shirt","c":"#c9b48a"}'::jsonb, now() - interval '45 minutes'),
  ('Camisa Levi''s de mezclilla', 'h', 'Camisas', 'M', 350, 'Buen estado', false, '{"k":"shirt","c":"#4a6c94"}'::jsonb, now() - interval '44 minutes'),
  ('Camisa Dockers manga larga', 'h', 'Camisas', 'L', 240, 'Como nuevo', false, '{"k":"shirt","c":"#e3e6ea"}'::jsonb, now() - interval '43 minutes'),
  ('Sudadera Champion con capucha', 'h', 'Sudaderas', 'L', 380, 'Buen estado', true, '{"k":"hoodie","c":"#3b4f7a"}'::jsonb, now() - interval '42 minutes'),
  ('Sudadera Nike Club', 'h', 'Sudaderas', 'M', 400, 'Como nuevo', false, '{"k":"hoodie","c":"#2b2d33"}'::jsonb, now() - interval '41 minutes'),
  ('Sudadera universitaria Michigan', 'h', 'Sudaderas', 'XL', 420, 'Con etiqueta', false, '{"k":"hoodie","c":"#1f3a5f"}'::jsonb, now() - interval '40 minutes'),
  ('Sudadera Carhartt', 'h', 'Sudaderas', 'L', 450, 'Buen estado', false, '{"k":"hoodie","c":"#8a6a3b"}'::jsonb, now() - interval '39 minutes'),
  ('Chaqueta Carhartt Detroit', 'h', 'Chaquetas', 'L', 750, 'Como nuevo', false, '{"k":"jacket","c":"#9b7440"}'::jsonb, now() - interval '38 minutes'),
  ('Chaqueta Levi''s Trucker', 'h', 'Chaquetas', 'M', 680, 'Buen estado', false, '{"k":"jacket","c":"#46658f"}'::jsonb, now() - interval '37 minutes'),
  ('Chaqueta The North Face', 'h', 'Chaquetas', 'XL', 900, 'Como nuevo', false, '{"k":"jacket","c":"#262a30"}'::jsonb, now() - interval '36 minutes'),
  ('Chaqueta bomber Alpha', 'h', 'Chaquetas', 'M', 620, 'Con etiqueta', false, '{"k":"jacket","c":"#4d5a3c"}'::jsonb, now() - interval '35 minutes'),
  ('Jeans Levi''s 501', 'h', 'Pantalones', '32x32', 450, 'Buen estado', false, '{"k":"jeans","c":"#3d5f8c"}'::jsonb, now() - interval '34 minutes'),
  ('Jeans Wrangler Cowboy Cut', 'h', 'Pantalones', '34x30', 400, 'Como nuevo', false, '{"k":"jeans","c":"#2f4b73"}'::jsonb, now() - interval '33 minutes'),
  ('Pantalón Dickies 874', 'h', 'Pantalones', '32x30', 380, 'Buen estado', false, '{"k":"jeans","c":"#5b5d4a"}'::jsonb, now() - interval '32 minutes'),
  ('Pantalón cargo Old Navy', 'h', 'Pantalones', '30x32', 340, 'Como nuevo', true, '{"k":"jeans","c":"#7a6f55"}'::jsonb, now() - interval '31 minutes'),
  ('Short Nike deportivo', 'h', 'Shorts', 'M', 180, 'Con etiqueta', false, '{"k":"shorts","c":"#2b2d33"}'::jsonb, now() - interval '30 minutes'),
  ('Short Levi''s de mezclilla', 'h', 'Shorts', '32', 220, 'Buen estado', false, '{"k":"shorts","c":"#5a7aa3"}'::jsonb, now() - interval '29 minutes'),
  ('Short cargo Columbia', 'h', 'Shorts', '34', 200, 'Como nuevo', false, '{"k":"shorts","c":"#b5a37d"}'::jsonb, now() - interval '28 minutes'),
  ('Suéter Polo de algodón', 'h', 'Suéteres', 'L', 360, 'Buen estado', false, '{"k":"sweater","c":"#2e5b46"}'::jsonb, now() - interval '27 minutes'),
  ('Blusa Ann Taylor de seda', 'm', 'Blusas', 'S', 220, 'Como nuevo', false, '{"k":"blouse","c":"#e8c7c8"}'::jsonb, now() - interval '26 minutes'),
  ('Blusa Old Navy floral', 'm', 'Blusas', 'M', 160, 'Con etiqueta', false, '{"k":"blouse","c":"#d98f6f"}'::jsonb, now() - interval '25 minutes'),
  ('Blusa Loft blanca', 'm', 'Blusas', 'M', 180, 'Buen estado', false, '{"k":"blouse","c":"#f1f1ee"}'::jsonb, now() - interval '24 minutes'),
  ('Blusa Calvin Klein negra', 'm', 'Blusas', 'L', 240, 'Como nuevo', false, '{"k":"blouse","c":"#22242a"}'::jsonb, now() - interval '23 minutes'),
  ('Blusa American Eagle rayas', 'm', 'Blusas', 'S', 170, 'Buen estado', false, '{"k":"blouse","c":"#7c9cc4"}'::jsonb, now() - interval '22 minutes'),
  ('Camiseta Gap rosa', 'm', 'Camisetas', 'S', 110, 'Como nuevo', false, '{"k":"tee","c":"#e79bb0"}'::jsonb, now() - interval '21 minutes'),
  ('Camiseta Disney vintage', 'm', 'Camisetas', 'M', 200, 'Con etiqueta', true, '{"k":"tee","c":"#c8322b"}'::jsonb, now() - interval '20 minutes'),
  ('Camiseta Nike Dri-FIT', 'm', 'Camisetas', 'M', 170, 'Buen estado', false, '{"k":"tee","c":"#6b4f9a"}'::jsonb, now() - interval '19 minutes'),
  ('Vestido Forever 21 de verano', 'm', 'Vestidos', 'S', 280, 'Como nuevo', false, '{"k":"dress","c":"#f0b45a"}'::jsonb, now() - interval '18 minutes'),
  ('Vestido Michael Kors negro', 'm', 'Vestidos', 'M', 450, 'Buen estado', false, '{"k":"dress","c":"#1d1f24"}'::jsonb, now() - interval '17 minutes'),
  ('Vestido floral Old Navy', 'm', 'Vestidos', 'M', 300, 'Como nuevo', false, '{"k":"dress","c":"#c96f8a"}'::jsonb, now() - interval '16 minutes'),
  ('Vestido de mezclilla Levi''s', 'm', 'Vestidos', 'L', 380, 'Con etiqueta', false, '{"k":"dress","c":"#4a6c94"}'::jsonb, now() - interval '15 minutes'),
  ('Vestido Banana Republic', 'm', 'Vestidos', 'S', 420, 'Buen estado', false, '{"k":"dress","c":"#2e5b46"}'::jsonb, now() - interval '14 minutes'),
  ('Falda plisada J.Crew', 'm', 'Faldas', 'S', 240, 'Como nuevo', false, '{"k":"skirt","c":"#c9b48a"}'::jsonb, now() - interval '13 minutes'),
  ('Falda de mezclilla Gap', 'm', 'Faldas', 'M', 220, 'Buen estado', false, '{"k":"skirt","c":"#5a7aa3"}'::jsonb, now() - interval '12 minutes'),
  ('Falda midi Ann Taylor', 'm', 'Faldas', 'M', 260, 'Como nuevo', false, '{"k":"skirt","c":"#8f2f3a"}'::jsonb, now() - interval '11 minutes'),
  ('Jeans Levi''s Mom Fit', 'm', 'Pantalones', '28', 450, 'Con etiqueta', false, '{"k":"jeans","c":"#6f8fb8"}'::jsonb, now() - interval '10 minutes'),
  ('Jeans American Eagle skinny', 'm', 'Pantalones', '30', 400, 'Buen estado', true, '{"k":"jeans","c":"#2f4b73"}'::jsonb, now() - interval '9 minutes'),
  ('Pantalón Gap de vestir', 'm', 'Pantalones', '8', 320, 'Como nuevo', false, '{"k":"jeans","c":"#3a3d45"}'::jsonb, now() - interval '8 minutes'),
  ('Short Levi''s high rise', 'm', 'Shorts', '27', 220, 'Buen estado', false, '{"k":"shorts","c":"#86a5cb"}'::jsonb, now() - interval '7 minutes'),
  ('Short Nike running', 'm', 'Shorts', 'S', 160, 'Como nuevo', false, '{"k":"shorts","c":"#e2557a"}'::jsonb, now() - interval '6 minutes'),
  ('Sudadera Champion crop', 'm', 'Sudaderas', 'S', 340, 'Con etiqueta', false, '{"k":"hoodie","c":"#b9a6d6"}'::jsonb, now() - interval '5 minutes'),
  ('Sudadera Victoria''s Secret PINK', 'm', 'Sudaderas', 'M', 380, 'Buen estado', false, '{"k":"hoodie","c":"#ec9bb5"}'::jsonb, now() - interval '4 minutes'),
  ('Chaqueta Levi''s de mezclilla', 'm', 'Chaquetas', 'S', 620, 'Como nuevo', false, '{"k":"jacket","c":"#5a7aa3"}'::jsonb, now() - interval '3 minutes'),
  ('Chaqueta Columbia impermeable', 'm', 'Chaquetas', 'M', 700, 'Buen estado', false, '{"k":"jacket","c":"#2f6f78"}'::jsonb, now() - interval '2 minutes'),
  ('Cárdigan Gap tejido', 'm', 'Suéteres', 'M', 300, 'Como nuevo', false, '{"k":"sweater","c":"#d8c3a5"}'::jsonb, now() - interval '1 minutes')
) as v(name, section, category, size, price, condition, sold, art, created_at)
where not exists (select 1 from public.products);
