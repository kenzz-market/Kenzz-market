-- KENZZ STORE MEGA FEATURES V1
-- Jalankan setelah SQL stabilitas + store_upgrade_all sebelumnya.

create table if not exists public.product_reviews (
  id uuid primary key default gen_random_uuid(),
  product_id text not null,
  user_id uuid not null references auth.users(id) on delete cascade,
  rating integer not null check (rating between 1 and 5),
  review text default '',
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  unique(product_id,user_id)
);
alter table public.product_reviews enable row level security;
drop policy if exists "Public view product reviews" on public.product_reviews;
create policy "Public view product reviews" on public.product_reviews for select to anon,authenticated using (true);
drop policy if exists "Members manage own product reviews" on public.product_reviews;
create policy "Members manage own product reviews" on public.product_reviews for all to authenticated using (auth.uid()=user_id) with check (auth.uid()=user_id);
drop policy if exists "Owner delete product reviews" on public.product_reviews;
create policy "Owner delete product reviews" on public.product_reviews for delete to authenticated using (exists(select 1 from public.admins a where a.user_id=auth.uid() and a.role='owner'));

create table if not exists public.product_categories (
  id uuid primary key default gen_random_uuid(),
  name text unique not null,
  description text default '',
  created_at timestamptz default now()
);
alter table public.product_categories enable row level security;
drop policy if exists "Public view categories" on public.product_categories;
create policy "Public view categories" on public.product_categories for select to anon,authenticated using (true);
drop policy if exists "Owner manage categories" on public.product_categories;
create policy "Owner manage categories" on public.product_categories for all to authenticated using (exists(select 1 from public.admins a where a.user_id=auth.uid() and a.role='owner')) with check (exists(select 1 from public.admins a where a.user_id=auth.uid() and a.role='owner'));

create table if not exists public.flash_sales (
  id uuid primary key default gen_random_uuid(),
  product_id text not null,
  sale_price numeric not null default 0,
  stock integer not null default 0,
  starts_at timestamptz default now(),
  expires_at timestamptz not null,
  is_active boolean default true,
  created_at timestamptz default now()
);
alter table public.flash_sales enable row level security;
drop policy if exists "Public view active flash sales" on public.flash_sales;
create policy "Public view active flash sales" on public.flash_sales for select to anon,authenticated using (is_active=true and starts_at<=now() and expires_at>now());
drop policy if exists "Owner manage flash sales" on public.flash_sales;
create policy "Owner manage flash sales" on public.flash_sales for all to authenticated using (exists(select 1 from public.admins a where a.user_id=auth.uid() and a.role='owner')) with check (exists(select 1 from public.admins a where a.user_id=auth.uid() and a.role='owner'));

create table if not exists public.store_announcements (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  message text default '',
  image_url text,
  video_url text,
  starts_at timestamptz default now(),
  expires_at timestamptz,
  is_active boolean default true,
  created_at timestamptz default now()
);
alter table public.store_announcements enable row level security;
drop policy if exists "Public view active announcements" on public.store_announcements;
create policy "Public view active announcements" on public.store_announcements for select to anon,authenticated using (is_active=true and starts_at<=now() and (expires_at is null or expires_at>now()));
drop policy if exists "Owner manage announcements" on public.store_announcements;
create policy "Owner manage announcements" on public.store_announcements for all to authenticated using (exists(select 1 from public.admins a where a.user_id=auth.uid() and a.role='owner')) with check (exists(select 1 from public.admins a where a.user_id=auth.uid() and a.role='owner'));

create table if not exists public.member_referrals (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references auth.users(id) on delete cascade,
  code text not null unique,
  referred_by uuid references auth.users(id) on delete set null,
  referral_count integer default 0,
  created_at timestamptz default now()
);
alter table public.member_referrals enable row level security;
drop policy if exists "Public view referral codes" on public.member_referrals;
create policy "Public view referral codes" on public.member_referrals for select to anon,authenticated using (true);
drop policy if exists "Members manage own referral" on public.member_referrals;
create policy "Members manage own referral" on public.member_referrals for insert to authenticated with check (auth.uid()=user_id);
drop policy if exists "Members update own referral" on public.member_referrals;
create policy "Members update own referral" on public.member_referrals for update to authenticated using (auth.uid()=user_id) with check (auth.uid()=user_id);
drop policy if exists "Owner manage referrals" on public.member_referrals;
create policy "Owner manage referrals" on public.member_referrals for all to authenticated using (exists(select 1 from public.admins a where a.user_id=auth.uid() and a.role='owner')) with check (exists(select 1 from public.admins a where a.user_id=auth.uid() and a.role='owner'));

create or replace function public.ensure_member_referral_code()
returns text language plpgsql security definer set search_path=public as $$
declare v_code text; v_user uuid:=auth.uid();
begin
  if v_user is null then raise exception 'Login diperlukan.'; end if;
  select code into v_code from public.member_referrals where user_id=v_user;
  if v_code is not null then return v_code; end if;
  v_code:='KZ'||upper(substr(replace(v_user::text,'-',''),1,8));
  insert into public.member_referrals(user_id,code) values(v_user,v_code) on conflict(user_id) do nothing;
  select code into v_code from public.member_referrals where user_id=v_user;
  return v_code;
end; $$;
grant execute on function public.ensure_member_referral_code() to authenticated;

create or replace function public.apply_referral(p_code text)
returns boolean language plpgsql security definer set search_path=public as $$
declare v_ref public.member_referrals%rowtype; v_user uuid:=auth.uid();
begin
 if v_user is null then return false; end if;
 select * into v_ref from public.member_referrals where upper(code)=upper(trim(p_code)) limit 1;
 if v_ref.id is null or v_ref.user_id=v_user then return false; end if;
 insert into public.member_referrals(user_id,code,referred_by) values(v_user,'KZ'||upper(substr(replace(v_user::text,'-',''),1,8)),v_ref.user_id) on conflict(user_id) do update set referred_by=excluded.referred_by;
 update public.member_referrals set referral_count=coalesce(referral_count,0)+1 where user_id=v_ref.user_id;
 return true;
end; $$;
grant execute on function public.apply_referral(text) to authenticated;

create or replace function public.get_store_analytics()
returns jsonb language plpgsql security definer set search_path=public as $$
declare v jsonb;
begin
 if not exists(select 1 from public.admins where user_id=auth.uid() and role='owner') then raise exception 'Akses hanya untuk owner.'; end if;
 select jsonb_build_object(
   'orders',(select count(*) from public.purchase_history),
   'revenue',(select coalesce(sum(total),0) from public.purchase_history where status<>'Dibatalkan'),
   'members',(select count(*) from public.members),
   'products',(select count(*) from public.products),
   'pending',(select count(*) from public.purchase_history where status='Menunggu konfirmasi'),
   'processing',(select count(*) from public.purchase_history where status='Diproses'),
   'completed',(select count(*) from public.purchase_history where status='Selesai'),
   'cancelled',(select count(*) from public.purchase_history where status='Dibatalkan'),
   'favorites',(select count(*) from public.member_favorites),
   'reviews',(select count(*) from public.product_reviews)
 ) into v;
 return v;
end; $$;
grant execute on function public.get_store_analytics() to authenticated;

create index if not exists product_reviews_product_idx on public.product_reviews(product_id,created_at desc);
create index if not exists flash_sales_product_idx on public.flash_sales(product_id,expires_at desc);
create index if not exists announcements_active_idx on public.store_announcements(is_active,starts_at,expires_at);
create index if not exists referrals_referred_by_idx on public.member_referrals(referred_by);

do $$ begin
  alter publication supabase_realtime add table public.product_reviews;
exception when duplicate_object then null; end $$;
do $$ begin
  alter publication supabase_realtime add table public.flash_sales;
exception when duplicate_object then null; end $$;
do $$ begin
  alter publication supabase_realtime add table public.store_announcements;
exception when duplicate_object then null; end $$;

grant select on public.product_categories, public.flash_sales, public.store_announcements, public.product_reviews, public.member_referrals to anon,authenticated;
notify pgrst,'reload schema';

create or replace function public.create_flash_order(p_flash_id uuid,p_qty integer default 1)
returns jsonb language plpgsql security definer set search_path=public as $$
declare s public.flash_sales%rowtype; p public.products%rowtype; u uuid:=auth.uid(); v_total numeric; v_items jsonb;
begin
 if u is null then raise exception 'Login member diperlukan.'; end if;
 if not exists(select 1 from public.members where user_id=u) then raise exception 'Akun belum terdaftar sebagai member.'; end if;
 if p_qty<1 then raise exception 'Jumlah tidak valid.'; end if;
 select * into s from public.flash_sales where id=p_flash_id and is_active=true and starts_at<=now() and expires_at>now() for update;
 if s.id is null then raise exception 'Flash Sale sudah berakhir.'; end if;
 if s.stock<p_qty then raise exception 'Stok Flash Sale tidak mencukupi.'; end if;
 select * into p from public.products where id::text=s.product_id for update;
 if p.id is null then raise exception 'Produk tidak ditemukan.'; end if;
 update public.flash_sales set stock=stock-p_qty where id=s.id;
 v_total=coalesce(s.sale_price,0)*p_qty;
 v_items=jsonb_build_array(jsonb_build_object('id',p.id::text,'name',p.name,'price',s.sale_price,'qty',p_qty,'image',p.image));
 insert into public.purchase_history(user_id,items,total,status,source) values(u,v_items,v_total,'Menunggu konfirmasi','flash_sale');
 return jsonb_build_object('items',v_items,'total',v_total,'flash_id',s.id);
end; $$;
grant execute on function public.create_flash_order(uuid,integer) to authenticated;
notify pgrst,'reload schema';
