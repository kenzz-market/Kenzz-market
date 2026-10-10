-- KENZZ STORE: FAVORIT + RIWAYAT PEMBELIAN + DASHBOARD OWNER
-- Jalankan setelah SQL member/promo sebelumnya.

create table if not exists public.member_favorites (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  product_id text not null,
  product_name text,
  product_price numeric default 0,
  product_image text,
  created_at timestamptz default now(),
  unique(user_id, product_id)
);

alter table public.member_favorites enable row level security;

drop policy if exists "Members manage own favorites" on public.member_favorites;
create policy "Members manage own favorites"
on public.member_favorites for all to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create table if not exists public.purchase_history (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete set null,
  items jsonb not null default '[]'::jsonb,
  total numeric default 0,
  status text default 'Menunggu konfirmasi',
  source text default 'whatsapp',
  created_at timestamptz default now()
);

alter table public.purchase_history enable row level security;

drop policy if exists "Members view own purchase history" on public.purchase_history;
create policy "Members view own purchase history"
on public.purchase_history for select to authenticated
using (auth.uid() = user_id);

drop policy if exists "Members insert own purchase history" on public.purchase_history;
revoke insert on public.purchase_history from public, anon, authenticated;

drop policy if exists "Owner view purchase history" on public.purchase_history;
create policy "Owner view purchase history"
on public.purchase_history for select to authenticated
using (
  exists (
    select 1 from public.admins
    where admins.user_id = auth.uid() and admins.role = 'owner'
  )
);

create index if not exists purchase_history_user_created_idx
on public.purchase_history(user_id, created_at desc);

create index if not exists purchase_history_created_idx
on public.purchase_history(created_at desc);

notify pgrst, 'reload schema';
