-- KENZZ STORE MEMBER SYSTEM
-- Jalankan di Supabase SQL Editor.
-- Password tidak disimpan di tabel members. Supabase Auth yang menangani kredensial.

create table if not exists public.members (
  id uuid primary key default gen_random_uuid(),
  user_id uuid,
  name text,
  email text,
  phone text,
  provider text,
  created_at timestamptz default now()
);

alter table public.members add column if not exists user_id uuid;
alter table public.members add column if not exists name text;
alter table public.members add column if not exists email text;
alter table public.members add column if not exists phone text;
alter table public.members add column if not exists provider text;
alter table public.members add column if not exists created_at timestamptz default now();

create unique index if not exists members_user_id_unique
on public.members(user_id)
where user_id is not null;

alter table public.members enable row level security;

drop policy if exists "Members can view own profile" on public.members;
create policy "Members can view own profile"
on public.members for select to authenticated
using (auth.uid() = user_id);

drop policy if exists "Members can insert own profile" on public.members;
create policy "Members can insert own profile"
on public.members for insert to authenticated
with check (auth.uid() = user_id);

drop policy if exists "Members can update own profile" on public.members;
create policy "Members can update own profile"
on public.members for update to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "Owner can view all members" on public.members;
create policy "Owner can view all members"
on public.members for select to authenticated
using (
  exists (
    select 1 from public.admins
    where admins.user_id = auth.uid()
      and admins.role = 'owner'
  )
  or auth.uid() = user_id
);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.members(user_id,name,email,phone,provider)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'name', new.raw_user_meta_data->>'full_name', ''),
    new.email,
    new.phone,
    coalesce(new.raw_app_meta_data->>'provider', 'email')
  )
  on conflict (user_id) do update set
    email = excluded.email,
    phone = excluded.phone,
    provider = excluded.provider;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

-- Notifikasi owner saat member baru mendaftar.
create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz default now(),
  user_id uuid,
  title text,
  message text,
  type text default 'member',
  is_read boolean default false
);

alter table public.notifications enable row level security;

drop policy if exists "Owner can view notifications" on public.notifications;
create policy "Owner can view notifications"
on public.notifications for select to authenticated
using (exists (select 1 from public.admins where admins.user_id = auth.uid() and admins.role = 'owner'));

drop policy if exists "Owner can update notifications" on public.notifications;
create policy "Owner can update notifications"
on public.notifications for update to authenticated
using (exists (select 1 from public.admins where admins.user_id = auth.uid() and admins.role = 'owner'))
with check (exists (select 1 from public.admins where admins.user_id = auth.uid() and admins.role = 'owner'));

create or replace function public.notify_new_member()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.notifications(user_id,title,message,type,is_read)
  select a.user_id,
         'Member baru',
         coalesce(new.name,'Member baru') || ' baru mendaftar di Kenzz Store.',
         'member',
         false
  from public.admins a
  where a.role = 'owner';
  return new;
end;
$$;

drop trigger if exists after_member_insert on public.members;
create trigger after_member_insert
after insert on public.members
for each row execute function public.notify_new_member();

create or replace function public.get_member_count()
returns bigint
language sql
security definer
set search_path = public
as $$ select count(*) from public.members; $$;

grant execute on function public.get_member_count() to anon, authenticated;
\n\n-- Pengurangan stok saat pelanggan menekan Beli/Checkout.\n-- Promo/katalog tetap terpisah; fungsi ini hanya mengurangi stok produk yang dibeli.\ncreate or replace function public.decrement_product_stock(p_product_id text, p_qty integer default 1)\nreturns boolean\nlanguage plpgsql\nsecurity definer\nset search_path = public\nas $$\ndeclare\n  affected integer;\nbegin\n  if p_product_id is null or p_qty is null or p_qty < 1 then\n    return false;\n  end if;\n\n  update public.products\n  set stock = greatest(coalesce(stock, 0) - p_qty, 0)\n  where id::text = p_product_id\n    and coalesce(stock, 0) >= p_qty;\n\n  get diagnostics affected = row_count;\n  return affected = 1;\nend;\n$$;\n\ngrant execute on function public.decrement_product_stock(text, integer) to anon, authenticated;\n\ncreate or replace function public.decrement_product_stocks(p_items jsonb)\nreturns boolean\nlanguage plpgsql\nsecurity definer\nset search_path = public\nas $$\ndeclare\n  item jsonb;\n  affected integer;\n  pid text;\n  qty integer;\nbegin\n  if p_items is null or jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then\n    return false;\n  end if;\n\n  for item in select value from jsonb_array_elements(p_items) loop\n    pid := item->>'id';\n    qty := greatest(coalesce((item->>'qty')::integer, 1), 1);\n\n    if pid is null or pid = '' then\n      raise exception 'Product ID tidak valid';\n    end if;\n\n    update public.products\n    set stock = greatest(coalesce(stock, 0) - qty, 0)\n    where id::text = pid\n      and coalesce(stock, 0) >= qty;\n\n    get diagnostics affected = row_count;\n    if affected <> 1 then\n      raise exception 'Stok produk tidak mencukupi';\n    end if;\n  end loop;\n\n  return true;\nexception when others then\n  raise;\nend;\n$$;\n\ngrant execute on function public.decrement_product_stocks(jsonb) to anon, authenticated;\n