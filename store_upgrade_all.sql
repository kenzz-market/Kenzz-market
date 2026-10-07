-- KENZZ STORE UPGRADE: ORDER STATUS + VOUCHER + NOTIFIKASI + REALTIME
-- Jalankan SEKALI di Supabase SQL Editor setelah SQL sebelumnya.

alter table public.purchase_history
  add column if not exists voucher_code text,
  add column if not exists discount numeric default 0;

alter table public.purchase_history enable row level security;

drop policy if exists "Owner update purchase status" on public.purchase_history;
create policy "Owner update purchase status"
on public.purchase_history
for update
to authenticated
using (exists (select 1 from public.admins where admins.user_id=auth.uid() and admins.role='owner'))
with check (exists (select 1 from public.admins where admins.user_id=auth.uid() and admins.role='owner'));

create table if not exists public.vouchers (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  discount_type text not null default 'percent' check (discount_type in ('percent','fixed')),
  discount_value numeric not null default 0,
  min_purchase numeric not null default 0,
  max_discount numeric,
  usage_limit integer,
  used_count integer not null default 0,
  starts_at timestamptz default now(),
  expires_at timestamptz,
  is_active boolean not null default true,
  created_at timestamptz default now()
);

alter table public.vouchers enable row level security;

drop policy if exists "Authenticated view active vouchers" on public.vouchers;
create policy "Authenticated view active vouchers"
on public.vouchers for select to authenticated
using (is_active=true and (starts_at is null or starts_at<=now()) and (expires_at is null or expires_at>now()));

drop policy if exists "Owner manage vouchers" on public.vouchers;
create policy "Owner manage vouchers"
on public.vouchers for all to authenticated
using (exists (select 1 from public.admins where admins.user_id=auth.uid() and admins.role='owner'))
with check (exists (select 1 from public.admins where admins.user_id=auth.uid() and admins.role='owner'));

create or replace function public.redeem_voucher(p_code text, p_total numeric)
returns jsonb
language plpgsql
security definer
set search_path=public
as $$
declare v vouchers%rowtype; v_discount numeric:=0;
begin
  select * into v from public.vouchers where upper(code)=upper(trim(p_code)) and is_active=true for update;
  if not found then return jsonb_build_object('valid',false,'message','Kode voucher tidak ditemukan atau tidak aktif.'); end if;
  if v.starts_at is not null and v.starts_at>now() then return jsonb_build_object('valid',false,'message','Voucher belum mulai berlaku.'); end if;
  if v.expires_at is not null and v.expires_at<=now() then return jsonb_build_object('valid',false,'message','Voucher sudah kedaluwarsa.'); end if;
  if v.usage_limit is not null and v.used_count>=v.usage_limit then return jsonb_build_object('valid',false,'message','Batas penggunaan voucher sudah tercapai.'); end if;
  if p_total < v.min_purchase then return jsonb_build_object('valid',false,'message','Minimal pembelian Rp '||to_char(v.min_purchase,'FM999G999G999G999')); end if;
  if v.discount_type='percent' then v_discount:=p_total*(v.discount_value/100); else v_discount:=v.discount_value; end if;
  if v.max_discount is not null then v_discount:=least(v_discount,v.max_discount); end if;
  v_discount:=least(greatest(v_discount,0),greatest(p_total,0));
  return jsonb_build_object('valid',true,'code',upper(v.code),'discount',v_discount,'total',greatest(p_total-v_discount,0),'message','Voucher berhasil diterapkan.');
end; $$;
grant execute on function public.redeem_voucher(text,numeric) to authenticated;

create or replace function public.increment_voucher_usage(p_code text)
returns boolean language plpgsql security definer set search_path=public as $$
declare ok boolean;
begin
 update public.vouchers set used_count=used_count+1 where upper(code)=upper(trim(p_code)) and is_active=true and (usage_limit is null or used_count<usage_limit);
 return found;
end; $$;
grant execute on function public.increment_voucher_usage(text) to authenticated;

create or replace function public.notify_new_purchase()
returns trigger language plpgsql security definer set search_path=public as $$
begin
 insert into public.notifications(user_id,title,message,type,is_read)
 select a.user_id,'🛒 Pesanan Baru','Pesanan baru dari member. Total Rp '||to_char(new.total,'FM999G999G999G999')||'.','purchase',false
 from public.admins a where a.role='owner';
 return new;
end; $$;
drop trigger if exists purchase_history_owner_notification on public.purchase_history;
create trigger purchase_history_owner_notification after insert on public.purchase_history for each row execute function public.notify_new_purchase();

create or replace function public.notify_purchase_status_change()
returns trigger language plpgsql security definer set search_path=public as $$
begin
 if new.status is distinct from old.status and new.user_id is not null then
   insert into public.notifications(user_id,title,message,type,is_read)
   values(new.user_id,'📦 Status Pesanan Berubah','Pesanan kamu sekarang: '||coalesce(new.status,'Diproses')||'.','order_status',false);
 end if;
 return new;
end; $$;
drop trigger if exists purchase_status_member_notification on public.purchase_history;
create trigger purchase_status_member_notification after update of status on public.purchase_history for each row execute function public.notify_purchase_status_change();

-- Realtime, aman dijalankan berulang.
do $$ begin
  if not exists (select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='notifications') then
    alter publication supabase_realtime add table public.notifications;
  end if;
  if not exists (select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='purchase_history') then
    alter publication supabase_realtime add table public.purchase_history;
  end if;
exception when undefined_object then null; end $$;

create index if not exists vouchers_active_idx on public.vouchers(is_active,expires_at);
notify pgrst,'reload schema';
