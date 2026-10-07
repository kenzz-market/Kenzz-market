-- KENZZ STORE MEMBER SYSTEM
-- Jalankan di Supabase SQL Editor.
-- Password TIDAK disimpan di public.members. Supabase Auth yang mengelolanya.

create table if not exists public.members (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz default now(),
  user_id uuid unique references auth.users(id) on delete cascade,
  name text,
  email text,
  phone text,
  provider text
);

create unique index if not exists members_user_id_unique on public.members(user_id);

alter table public.members enable row level security;

drop policy if exists "Members can view own profile" on public.members;
create policy "Members can view own profile" on public.members
for select to authenticated using (auth.uid() = user_id);

drop policy if exists "Members can insert own profile" on public.members;
create policy "Members can insert own profile" on public.members
for insert to authenticated with check (auth.uid() = user_id);

drop policy if exists "Members can update own profile" on public.members;
create policy "Members can update own profile" on public.members
for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "Owner can view all members" on public.members;
create policy "Owner can view all members" on public.members
for select to authenticated using (
  auth.uid() = user_id
  or exists (
    select 1 from public.admins
    where admins.user_id = auth.uid() and admins.role = 'owner'
  )
);

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public
as $$
begin
  insert into public.members(user_id,name,email,phone,provider)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'name',new.raw_user_meta_data->>'full_name',new.raw_user_meta_data->>'display_name',''),
    new.email,
    new.phone,
    coalesce(new.raw_app_meta_data->>'provider',case when new.phone is not null then 'phone' else 'email' end)
  )
  on conflict (user_id) do update set
    email=excluded.email,
    phone=coalesce(excluded.phone,public.members.phone),
    provider=coalesce(excluded.provider,public.members.provider),
    name=case when public.members.name is null or public.members.name='' then excluded.name else public.members.name end;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
for each row execute function public.handle_new_user();

create or replace function public.get_member_count()
returns bigint language sql security definer set search_path = public
as $$ select count(*) from public.members; $$;
grant execute on function public.get_member_count() to anon, authenticated;


create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz default now(),
  user_id uuid references auth.users(id) on delete cascade,
  title text,
  message text,
  type text default 'info',
  is_read boolean default false
);

alter table public.notifications enable row level security;

drop policy if exists "Owner can view notifications" on public.notifications;
create policy "Owner can view notifications" on public.notifications
for select to authenticated using (
  exists (select 1 from public.admins where admins.user_id = auth.uid() and admins.role='owner')
);

drop policy if exists "Owner can update notifications" on public.notifications;
create policy "Owner can update notifications" on public.notifications
for update to authenticated using (
  exists (select 1 from public.admins where admins.user_id = auth.uid() and admins.role='owner')
) with check (
  exists (select 1 from public.admins where admins.user_id = auth.uid() and admins.role='owner')
);

create or replace function public.notify_new_member()
returns trigger language plpgsql security definer set search_path = public
as $$
begin
  insert into public.notifications(title,message,type,is_read)
  select 'Member baru',
         coalesce(new.name,'Member baru') || ' baru saja mendaftar.',
         'member',false
  where exists (select 1 from public.admins where role='owner');
  return new;
end;
$$;

drop trigger if exists on_member_created_notify_owner on public.members;
create trigger on_member_created_notify_owner
after insert on public.members
for each row execute function public.notify_new_member();
