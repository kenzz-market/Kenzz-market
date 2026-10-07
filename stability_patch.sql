-- KENZZ STORE STABILITY PATCH
-- Jalankan SEKALI setelah SQL sistem sebelumnya.
-- Fokus: checkout atomik, harga/stok server-side, voucher atomik,
-- pending purchase setelah register/Google, dan hardening akses order.

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
  v_voucher vouchers%rowtype;
  v_items jsonb := '[]'::jsonb;
  v_order_id uuid;
  v_user uuid := auth.uid();
  v_code text;
  affected integer;
begin
  if v_user is null then
    raise exception 'Login member diperlukan.';
  end if;

  if p_items is null
     or jsonb_typeof(p_items) <> 'array'
     or jsonb_array_length(p_items) = 0 then
    raise exception 'Produk pembelian tidak valid.';
  end if;

  -- Validasi akun/member terlebih dahulu.
  if not exists (
    select 1 from public.members m
    where m.user_id = v_user
  ) then
    raise exception 'Profil member belum tersedia.';
  end if;

  -- Semua harga, nama, gambar, dan stok diambil dari database.
  -- Data dari browser tidak dipercaya. Manusia telah membuktikan berkali-kali
  -- bahwa field price di HTML bukanlah sistem keamanan finansial.
  for item in select value from jsonb_array_elements(p_items) loop
    v_id := nullif(trim(item->>'id'), '');
    v_type := case when lower(coalesce(item->>'type','product')) = 'promo' then 'promo' else 'product' end;
    v_qty := greatest(coalesce((item->>'qty')::integer,1),1);

    if v_id is null then
      raise exception 'Product ID tidak valid.';
    end if;

    if v_type = 'promo' then
      select name, price, image, stock
      into v_name, v_price, v_image, v_stock
      from public.promo_products
      where id::text = v_id
        and is_active = true
        and expires_at > now()
      for update;

      if not found then
        raise exception 'Produk promo tidak tersedia atau sudah berakhir.';
      end if;

      if coalesce(v_stock,0) < v_qty then
        raise exception 'Stok produk promo tidak mencukupi.';
      end if;

      update public.promo_products
      set stock = stock - v_qty
      where id::text = v_id;
    else
      select name, price, image, stock
      into v_name, v_price, v_image, v_stock
      from public.products
      where id::text = v_id
      for update;

      if not found then
        raise exception 'Produk tidak ditemukan.';
      end if;

      if coalesce(v_stock,0) < v_qty then
        raise exception 'Stok produk tidak mencukupi: %.', coalesce(v_name,'Produk');
      end if;

      update public.products
      set stock = stock - v_qty
      where id::text = v_id;
    end if;

    v_subtotal := v_subtotal + (coalesce(v_price,0) * v_qty);
    v_items := v_items || jsonb_build_array(jsonb_build_object(
      'id', v_id,
      'name', coalesce(v_name,''),
      'price', coalesce(v_price,0),
      'qty', v_qty,
      'image', coalesce(v_image,''),
      'type', v_type
    ));
  end loop;

  -- Voucher divalidasi dan dikunci dalam transaksi yang sama.
  if nullif(trim(p_voucher_code),'') is not null then
    v_code := upper(trim(p_voucher_code));
    select * into v_voucher
    from public.vouchers
    where upper(code) = v_code
    for update;

    if not found then
      raise exception 'Kode voucher tidak ditemukan atau tidak aktif.';
    end if;
    if not v_voucher.is_active then
      raise exception 'Voucher tidak aktif.';
    end if;
    if v_voucher.starts_at is not null and v_voucher.starts_at > now() then
      raise exception 'Voucher belum mulai berlaku.';
    end if;
    if v_voucher.expires_at is not null and v_voucher.expires_at <= now() then
      raise exception 'Voucher sudah kedaluwarsa.';
    end if;
    if v_voucher.usage_limit is not null and v_voucher.used_count >= v_voucher.usage_limit then
      raise exception 'Batas penggunaan voucher sudah tercapai.';
    end if;
    if v_subtotal < coalesce(v_voucher.min_purchase,0) then
      raise exception 'Minimal pembelian voucher belum terpenuhi.';
    end if;

    if v_voucher.discount_type = 'percent' then
      v_discount := v_subtotal * (v_voucher.discount_value / 100);
    else
      v_discount := v_voucher.discount_value;
    end if;
    if v_voucher.max_discount is not null then
      v_discount := least(v_discount, v_voucher.max_discount);
    end if;
    v_discount := least(greatest(v_discount,0), v_subtotal);

    update public.vouchers
    set used_count = used_count + 1
    where id = v_voucher.id;
  end if;

  v_total := greatest(v_subtotal - v_discount, 0);

  insert into public.purchase_history(
    user_id, items, total, status, source, voucher_code, discount
  )
  values(
    v_user, v_items, v_total, 'Menunggu konfirmasi', 'whatsapp', v_code, v_discount
  )
  returning id into v_order_id;

  return jsonb_build_object(
    'success', true,
    'order_id', v_order_id,
    'items', v_items,
    'subtotal', v_subtotal,
    'discount', v_discount,
    'voucher_code', v_code,
    'total', v_total,
    'status', 'Menunggu konfirmasi'
  );
exception when others then
  raise;
end;
$$;

grant execute on function public.create_purchase_order(jsonb,text) to authenticated;

-- Jangan biarkan client memalsukan total/harga dengan INSERT langsung.
drop policy if exists "Members insert own purchase history" on public.purchase_history;
revoke insert on public.purchase_history from anon, authenticated;

-- RPC lama tetap ada untuk kompatibilitas database, tetapi tidak boleh dipanggil client.
revoke execute on function public.decrement_product_stock(text,integer) from anon, authenticated;
revoke execute on function public.decrement_product_stocks(jsonb) from anon, authenticated;
revoke execute on function public.decrement_promo_stock(text,integer) from anon, authenticated;
revoke execute on function public.increment_voucher_usage(text) from anon, authenticated;

-- Hanya RPC checkout atomik yang menjadi jalur transaksi client.
notify pgrst, 'reload schema';
