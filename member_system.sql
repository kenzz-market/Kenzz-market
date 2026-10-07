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


-- Pengurangan stok saat pelanggan menekan Beli/Checkout.
-- Promo/katalog tetap terpisah; fungsi ini hanya mengurangi stok produk yang dibeli.
create or replace function public.decrement_product_stock(p_product_id text, p_qty integer default 1)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  affected integer;
begin
  if p_product_id is null or p_qty is null or p_qty < 1 then
    return false;
  end if;

  update public.products
  set stock = greatest(coalesce(stock, 0) - p_qty, 0)
  where id::text = p_product_id
    and coalesce(stock, 0) >= p_qty;

  get diagnostics affected = row_count;
  return affected = 1;
end;
$$;

grant execute on function public.decrement_product_stock(text, integer) to anon, authenticated;

create or replace function public.decrement_product_stocks(p_items jsonb)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  item jsonb;
  affected integer;
  pid text;
  qty integer;
begin
  if p_items is null or jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then
    return false;
  end if;

  for item in select value from jsonb_array_elements(p_items) loop
    pid := item->>'id';
    qty := greatest(coalesce((item->>'qty')::integer, 1), 1);

    if pid is null or pid = '' then
      raise exception 'Product ID tidak valid';
    end if;

    update public.products
    set stock = greatest(coalesce(stock, 0) - qty, 0)
    where id::text = pid
      and coalesce(stock, 0) >= qty;

    get diagnostics affected = row_count;
    if affected <> 1 then
      raise exception 'Stok produk tidak mencukupi';
    end if;
  end loop;

  return true;
exception when others then
  raise;
end;
$$;

grant execute on function public.decrement_product_stocks(jsonb) to anon, authenticated;


-- =====================================================
-- KATALOG PRODUK PROMO
-- =====================================================
-- Promo disimpan terpisah dari katalog biasa.
-- expires_at menentukan kapan promo otomatis tidak lagi tampil.

create table if not exists public.promo_products (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz default now(),
  name text not null,
  price numeric not null default 0,
  category text,
  image text,
  stock integer not null default 0,
  is_active boolean not null default true,
  expires_at timestamptz not null
);

alter table public.promo_products enable row level security;

drop policy if exists "Anyone can view active promos" on public.promo_products;
create policy "Anyone can view active promos"
on public.promo_products for select
to anon, authenticated
using (is_active = true and expires_at > now());

drop policy if exists "Owner can insert promos" on public.promo_products;
create policy "Owner can insert promos"
on public.promo_products for insert to authenticated
with check (exists (select 1 from public.admins where admins.user_id=auth.uid() and admins.role='owner'));

drop policy if exists "Owner can update promos" on public.promo_products;
create policy "Owner can update promos"
on public.promo_products for update to authenticated
using (exists (select 1 from public.admins where admins.user_id=auth.uid() and admins.role='owner'))
with check (exists (select 1 from public.admins where admins.user_id=auth.uid() and admins.role='owner'));

drop policy if exists "Owner can delete promos" on public.promo_products;
create policy "Owner can delete promos"
on public.promo_products for delete to authenticated
using (exists (select 1 from public.admins where admins.user_id=auth.uid() and admins.role='owner'));

create or replace function public.decrement_promo_stock(p_promo_id text, p_qty integer default 1)
returns boolean
language plpgsql
security definer
set search_path=public
as $$
declare affected integer;
begin
  if p_promo_id is null or p_qty is null or p_qty < 1 then return false; end if;
  update public.promo_products
  set stock=greatest(coalesce(stock,0)-p_qty,0)
  where id::text=p_promo_id
    and coalesce(stock,0)>=p_qty
    and is_active=true
    and expires_at>now();
  get diagnostics affected=row_count;
  return affected=1;
end;
$$;

grant execute on function public.decrement_promo_stock(text,integer) to anon, authenticated;

-- =====================================================
-- OWNER CENTER: KELOLA ADMIN & MEMBER
-- =====================================================
-- Hanya owner yang dapat menjalankan fungsi-fungsi berikut.

create or replace function public.owner_list_admins()
returns table(
  user_id uuid,
  email text,
  role text
)
language plpgsql
security definer
set search_path = public
as $$
begin
  if not exists (
    select 1 from public.admins a
    where a.user_id = auth.uid()
      and a.role = 'owner'
  ) then
    raise exception 'Akses hanya untuk owner';
  end if;

  return query
  select a.user_id, u.email::text, a.role::text
  from public.admins a
  left join auth.users u on u.id = a.user_id
  order by case when a.role = 'owner' then 0 else 1 end, u.email;
end;
$$;

grant execute on function public.owner_list_admins() to authenticated;


create or replace function public.owner_add_admin_by_email(p_email text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  target_user_id uuid;
  target_email text;
begin
  if not exists (
    select 1 from public.admins a
    where a.user_id = auth.uid()
      and a.role = 'owner'
  ) then
    raise exception 'Akses hanya untuk owner';
  end if;

  select id, email into target_user_id, target_email
  from auth.users
  where lower(email) = lower(trim(p_email))
  limit 1;

  if target_user_id is null then
    raise exception 'Akun dengan email tersebut belum terdaftar di Supabase Auth';
  end if;

  insert into public.admins(user_id, role)
  values(target_user_id, 'admin')
  on conflict (user_id) do update set role = 'admin';

  return jsonb_build_object(
    'user_id', target_user_id,
    'email', target_email,
    'role', 'admin'
  );
end;
$$;

grant execute on function public.owner_add_admin_by_email(text) to authenticated;


create or replace function public.owner_delete_admin(p_user_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
begin
  if not exists (
    select 1 from public.admins a
    where a.user_id = auth.uid()
      and a.role = 'owner'
  ) then
    raise exception 'Akses hanya untuk owner';
  end if;

  if p_user_id = auth.uid() then
    raise exception 'Owner yang sedang login tidak dapat dihapus';
  end if;

  delete from public.admins
  where user_id = p_user_id
    and role = 'admin';

  return true;
end;
$$;

grant execute on function public.owner_delete_admin(uuid) to authenticated;


create or replace function public.owner_delete_member(p_user_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
begin
  if not exists (
    select 1 from public.admins a
    where a.user_id = auth.uid()
      and a.role = 'owner'
  ) then
    raise exception 'Akses hanya untuk owner';
  end if;

  if exists (
    select 1 from public.admins a
    where a.user_id = p_user_id
  ) then
    raise exception 'Akun admin tidak dapat dihapus dari menu member';
  end if;

  delete from public.members
  where user_id = p_user_id;

  -- Hapus akun Auth agar member benar-benar tidak dapat login lagi.
  delete from auth.users
  where id = p_user_id;

  return true;
end;
$$;

grant execute on function public.owner_delete_member(uuid) to authenticated;
