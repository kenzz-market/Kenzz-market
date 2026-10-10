-- KENZZ STORE FINAL STABILITY + SECURITY PATCH
-- Jalankan SEKALI setelah member_system.sql, member_shop_upgrade.sql,
-- store_upgrade_all.sql, mega_features.sql, owner_center_fix.sql,
-- staff_login_fix.sql, dan store_visuals_upgrade.sql.
-- Patch ini menjadikan create_purchase_order satu-satunya jalur checkout client.

create or replace function public.create_purchase_order(
  p_items jsonb,
  p_voucher_code text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  item jsonb;
  v_id text;
  v_type text;
  v_qty integer;
  v_name text;
  v_price numeric;
  v_image text;
  v_stock integer;
  v_subtotal numeric := 0;
  v_discount numeric := 0;
  v_total numeric := 0;
  v_voucher public.vouchers%rowtype;
  v_items jsonb := '[]'::jsonb;
  v_order_id uuid;
  v_user uuid := auth.uid();
  v_code text;
  v_kind text;
  v_flash public.flash_sales%rowtype;
begin
  if v_user is null then raise exception 'Login member diperlukan.'; end if;
  if p_items is null or jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items)=0 then
    raise exception 'Produk pembelian tidak valid.';
  end if;
  if jsonb_array_length(p_items)>50 then raise exception 'Maksimal 50 baris produk per pesanan.'; end if;
  if not exists(select 1 from public.members m where m.user_id=v_user) then
    raise exception 'Profil member belum tersedia.';
  end if;

  for item in select value from jsonb_array_elements(p_items) loop
    v_id := nullif(trim(item->>'id'),'');
    v_kind := lower(coalesce(item->>'type','product'));
    begin v_qty := (item->>'qty')::integer; exception when others then v_qty := null; end;
    if v_id is null or v_kind not in ('product','promo','flash') or v_qty is null or v_qty<1 or v_qty>1000 then
      raise exception 'Item pembelian tidak valid.';
    end if;

    if v_kind='product' then
      select name,price,image,stock into v_name,v_price,v_image,v_stock
      from public.products where id::text=v_id for update;
      if not found then raise exception 'Produk tidak ditemukan.'; end if;
      if coalesce(v_price,0)<0 then raise exception 'Harga produk tidak valid.'; end if;
      if coalesce(v_stock,0)<v_qty then raise exception 'Stok produk tidak mencukupi: %.',coalesce(v_name,'Produk'); end if;
      update public.products set stock=stock-v_qty where id::text=v_id;

    elsif v_kind='promo' then
      select name,price,image,stock into v_name,v_price,v_image,v_stock
      from public.promo_products
      where id::text=v_id and is_active=true and expires_at>now() for update;
      if not found then raise exception 'Produk promo tidak tersedia atau sudah berakhir.'; end if;
      if coalesce(v_price,0)<0 then raise exception 'Harga promo tidak valid.'; end if;
      if coalesce(v_stock,0)<v_qty then raise exception 'Stok produk promo tidak mencukupi.'; end if;
      update public.promo_products set stock=stock-v_qty where id::text=v_id;

    else
      select * into v_flash from public.flash_sales
      where id::text=v_id and is_active=true and starts_at<=now() and expires_at>now() for update;
      if not found then raise exception 'Flash Sale tidak tersedia atau sudah berakhir.'; end if;
      if coalesce(v_flash.sale_price,0)<0 then raise exception 'Harga Flash Sale tidak valid.'; end if;
      if coalesce(v_flash.stock,0)<v_qty then raise exception 'Stok Flash Sale tidak mencukupi.'; end if;
      select name,image into v_name,v_image from public.products where id::text=v_flash.product_id for update;
      if not found then raise exception 'Produk Flash Sale tidak ditemukan.'; end if;
      v_price:=v_flash.sale_price;
      update public.flash_sales set stock=stock-v_qty where id=v_flash.id;
    end if;

    v_subtotal := v_subtotal + (coalesce(v_price,0)*v_qty);
    v_items := v_items || jsonb_build_array(jsonb_build_object(
      'id',v_id,'name',coalesce(v_name,''),'price',coalesce(v_price,0),
      'qty',v_qty,'image',coalesce(v_image,''),'type',v_kind
    ));
  end loop;

  if nullif(trim(p_voucher_code),'') is not null then
    v_code:=upper(trim(p_voucher_code));
    select * into v_voucher from public.vouchers where upper(code)=v_code for update;
    if not found then raise exception 'Kode voucher tidak ditemukan atau tidak aktif.'; end if;
    if not v_voucher.is_active then raise exception 'Voucher tidak aktif.'; end if;
    if v_voucher.starts_at is not null and v_voucher.starts_at>now() then raise exception 'Voucher belum mulai berlaku.'; end if;
    if v_voucher.expires_at is not null and v_voucher.expires_at<=now() then raise exception 'Voucher sudah kedaluwarsa.'; end if;
    if v_voucher.usage_limit is not null and coalesce(v_voucher.used_count,0)>=v_voucher.usage_limit then raise exception 'Batas penggunaan voucher sudah tercapai.'; end if;
    if v_subtotal<coalesce(v_voucher.min_purchase,0) then raise exception 'Minimal pembelian voucher belum terpenuhi.'; end if;
    if v_voucher.discount_type='percent' then v_discount:=v_subtotal*(v_voucher.discount_value/100); else v_discount:=v_voucher.discount_value; end if;
    if v_voucher.max_discount is not null then v_discount:=least(v_discount,v_voucher.max_discount); end if;
    v_discount:=least(greatest(v_discount,0),v_subtotal);
    update public.vouchers set used_count=coalesce(used_count,0)+1 where id=v_voucher.id;
  end if;

  v_total:=greatest(v_subtotal-v_discount,0);
  insert into public.purchase_history(user_id,items,total,status,source,voucher_code,discount)
  values(v_user,v_items,v_total,'Menunggu konfirmasi','whatsapp',v_code,v_discount)
  returning id into v_order_id;

  return jsonb_build_object('success',true,'order_id',v_order_id,'items',v_items,
    'subtotal',v_subtotal,'discount',v_discount,'voucher_code',v_code,
    'total',v_total,'status','Menunggu konfirmasi');
end;
$$;

-- PostgreSQL memberi EXECUTE ke PUBLIC secara default. Cabut dulu, lalu beri hanya authenticated.
revoke execute on function public.create_purchase_order(jsonb,text) from public, anon;
grant execute on function public.create_purchase_order(jsonb,text) to authenticated;

-- Order tidak boleh dibuat/diubah dari browser secara langsung.
alter table public.purchase_history enable row level security;
drop policy if exists "Members insert own purchase history" on public.purchase_history;
drop policy if exists "Members update own purchase history" on public.purchase_history;
drop policy if exists "Members delete own purchase history" on public.purchase_history;
revoke insert, update, delete on public.purchase_history from public, anon, authenticated;

create or replace function public.update_purchase_status(p_order_id uuid, p_status text)
returns jsonb
language plpgsql
security definer
set search_path=public
as $$
declare v_row public.purchase_history%rowtype;
begin
  if not exists (select 1 from public.admins where user_id=auth.uid() and role='owner') then
    raise exception 'Akses hanya untuk owner.';
  end if;
  if p_order_id is null then raise exception 'ID pesanan tidak valid.'; end if;
  if p_status not in ('Menunggu konfirmasi','Diproses','Siap dikirim','Selesai','Dibatalkan') then
    raise exception 'Status pesanan tidak valid.';
  end if;
  update public.purchase_history set status=p_status where id=p_order_id returning * into v_row;
  if not found then raise exception 'Pesanan tidak ditemukan.'; end if;
  return jsonb_build_object('id',v_row.id,'status',v_row.status);
end;
$$;
revoke execute on function public.update_purchase_status(uuid,text) from public, anon;
grant execute on function public.update_purchase_status(uuid,text) to authenticated;

-- Nonaktifkan semua RPC stok/voucher lama untuk client DAN PUBLIC.
revoke execute on function public.decrement_product_stock(text,integer) from public, anon, authenticated;
revoke execute on function public.decrement_product_stocks(jsonb) from public, anon, authenticated;
revoke execute on function public.decrement_promo_stock(text,integer) from public, anon, authenticated;
revoke execute on function public.increment_voucher_usage(text) from public, anon, authenticated;

-- Validasi data voucher agar owner tidak dapat membuat nilai negatif/usage limit nol.
alter table if exists public.vouchers
  drop constraint if exists vouchers_discount_value_nonnegative,
  drop constraint if exists vouchers_min_purchase_nonnegative,
  drop constraint if exists vouchers_max_discount_nonnegative,
  drop constraint if exists vouchers_usage_limit_positive;
update public.vouchers set
  code=upper(trim(code)),
  discount_value=greatest(coalesce(discount_value,0),0),
  min_purchase=greatest(coalesce(min_purchase,0),0),
  max_discount=case when max_discount is null then null else greatest(max_discount,0) end,
  usage_limit=case when usage_limit is null or usage_limit>=1 then usage_limit else null end,
  used_count=greatest(coalesce(used_count,0),0);
alter table if exists public.vouchers add constraint vouchers_discount_value_nonnegative check (discount_value >= 0);
alter table if exists public.vouchers add constraint vouchers_min_purchase_nonnegative check (min_purchase >= 0);
alter table if exists public.vouchers add constraint vouchers_max_discount_nonnegative check (max_discount is null or max_discount >= 0);
alter table if exists public.vouchers add constraint vouchers_usage_limit_positive check (usage_limit is null or usage_limit >= 1);
alter table if exists public.vouchers drop constraint if exists vouchers_percent_discount_max;
alter table if exists public.vouchers add constraint vouchers_percent_discount_max check (discount_type <> 'percent' or discount_value <= 100);
create unique index if not exists vouchers_code_upper_unique on public.vouchers (upper(code)) where is_active;

-- Validasi voucher hanya membaca/preview. Pemakaian final dilakukan create_purchase_order.
revoke execute on function public.redeem_voucher(text,numeric) from public, anon;
grant execute on function public.redeem_voucher(text,numeric) to authenticated;
revoke execute on function public.redeem_voucher(text,numeric) from anon;

-- Produk: publik hanya membaca; mutasi hanya owner.
alter table public.products enable row level security;
drop policy if exists "Kenzz public view products" on public.products;
create policy "Kenzz public view products" on public.products for select to anon,authenticated using (true);
drop policy if exists "Kenzz owner insert products" on public.products;
create policy "Kenzz owner insert products" on public.products for insert to authenticated
with check (exists(select 1 from public.admins a where a.user_id=auth.uid() and a.role in ('owner','admin')));
drop policy if exists "Kenzz owner update products" on public.products;
create policy "Kenzz owner update products" on public.products for update to authenticated
using (exists(select 1 from public.admins a where a.user_id=auth.uid() and a.role in ('owner','admin')))
with check (exists(select 1 from public.admins a where a.user_id=auth.uid() and a.role in ('owner','admin')));
drop policy if exists "Kenzz owner delete products" on public.products;
create policy "Kenzz owner delete products" on public.products for delete to authenticated
using (exists(select 1 from public.admins a where a.user_id=auth.uid() and a.role in ('owner','admin')));

-- Admin operasional boleh mengelola katalog produk dan promo; fitur owner lain tetap owner-only.
alter table public.promo_products enable row level security;
drop policy if exists "Owner can insert promos" on public.promo_products;
drop policy if exists "Owner can update promos" on public.promo_products;
drop policy if exists "Owner can delete promos" on public.promo_products;
create policy "Catalog staff insert promos" on public.promo_products for insert to authenticated
with check (exists(select 1 from public.admins a where a.user_id=auth.uid() and a.role in ('owner','admin')));
create policy "Catalog staff update promos" on public.promo_products for update to authenticated
using (exists(select 1 from public.admins a where a.user_id=auth.uid() and a.role in ('owner','admin')))
with check (exists(select 1 from public.admins a where a.user_id=auth.uid() and a.role in ('owner','admin')));
create policy "Catalog staff delete promos" on public.promo_products for delete to authenticated
using (exists(select 1 from public.admins a where a.user_id=auth.uid() and a.role in ('owner','admin')));

-- Referral code bukan data publik. Kode tetap dapat diterapkan melalui RPC.
revoke insert, update, delete on public.member_referrals from public, anon, authenticated;
drop policy if exists "Public view referral codes" on public.member_referrals;
drop policy if exists "Members view own referral" on public.member_referrals;
create policy "Members view own referral" on public.member_referrals for select to authenticated using (auth.uid()=user_id);
revoke select on public.member_referrals from anon;

-- Referral hanya boleh ditetapkan sekali; tidak boleh mengganti referrer dan menambah count berkali-kali.
create or replace function public.apply_referral(p_code text)
returns boolean language plpgsql security definer set search_path=public as $$
declare v_ref public.member_referrals%rowtype; v_user uuid:=auth.uid(); v_existing uuid;
begin
 if v_user is null then return false; end if;
 perform pg_advisory_xact_lock(hashtextextended(v_user::text, 9172026));
 select referred_by into v_existing from public.member_referrals where user_id=v_user;
 if v_existing is not null then return false; end if;
 select * into v_ref from public.member_referrals where upper(code)=upper(trim(p_code)) limit 1;
 if v_ref.id is null or v_ref.user_id=v_user then return false; end if;
 insert into public.member_referrals(user_id,code,referred_by)
 values(v_user,'KZ'||upper(substr(replace(v_user::text,'-',''),1,8)),v_ref.user_id)
 on conflict(user_id) do update set referred_by=excluded.referred_by
 where public.member_referrals.referred_by is null;
 update public.member_referrals set referral_count=coalesce(referral_count,0)+1 where user_id=v_ref.user_id;
 return true;
end; $$;
revoke execute on function public.apply_referral(text) from public, anon;
grant execute on function public.apply_referral(text) to authenticated;

-- Flash Sale memakai transaksi checkout yang sama; tidak ada jalur stok terpisah.
create or replace function public.create_flash_order(p_flash_id uuid,p_qty integer default 1)
returns jsonb language plpgsql security definer set search_path=public as $$
begin
  return public.create_purchase_order(jsonb_build_array(jsonb_build_object('id',p_flash_id::text,'type','flash','qty',p_qty)),null);
end; $$;
revoke execute on function public.create_flash_order(uuid,integer) from public, anon;
grant execute on function public.create_flash_order(uuid,integer) to authenticated;

-- Security-definer helpers yang tidak dimaksudkan untuk anonymous.
revoke execute on function public.ensure_member_referral_code() from public, anon;
grant execute on function public.ensure_member_referral_code() to authenticated;
revoke execute on function public.get_store_analytics() from public, anon;
grant execute on function public.get_store_analytics() to authenticated;

notify pgrst,'reload schema';
