// Genera supabase/setup.sql con las tablas, reglas de seguridad y las 52 prendas de muestra
const fs = require('fs');
const path = require('path');

const root = path.join(__dirname, '..');
const html = fs.readFileSync(path.join(root, 'jj-store.html'), 'utf8');
const state = JSON.parse(html.match(/<script type="application\/json" id="jj-state">([\s\S]*?)<\/script>/)[1]);
const q = (s) => "'" + String(s).replace(/'/g, "''") + "'";

const rows = state.items.map((i, n) =>
  `  (${q(i.name)}, ${q(i.sec)}, ${q(i.cat)}, ${q(i.size)}, ${i.price}, ${q(i.cond)}, ${i.sold}, ${q(JSON.stringify(i.art))}::jsonb, now() - interval '${state.items.length - n} minutes')`
).join(',\n');

const sql = `-- JJ Store: configuración de Supabase
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
${rows}
) as v(name, section, category, size, price, condition, sold, art, created_at)
where not exists (select 1 from public.products);
`;

fs.mkdirSync(path.join(root, 'supabase'), { recursive: true });
fs.writeFileSync(path.join(root, 'supabase', 'setup.sql'), sql);
console.log('setup.sql listo,', state.items.length, 'prendas');
