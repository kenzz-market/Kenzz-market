-- KENZZ STORE - OWNER CENTER FIX
-- Jalankan di Supabase SQL Editor.
-- Memperbaiki error: "Could not find the function ... in the schema cache"
-- untuk fungsi Owner Center.

-- Daftar admin untuk Owner
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
    select 1
    from public.admins a
    where a.user_id = auth.uid()
      and a.role = 'owner'
  ) then
    raise exception 'Akses hanya untuk owner';
  end if;

  return query
  select
    a.user_id,
    u.email::text,
    a.role::text
  from public.admins a
  left join auth.users u on u.id = a.user_id
  order by
    case when a.role = 'owner' then 0 else 1 end,
    u.email;
end;
$$;

revoke execute on function public.owner_list_admins() from public, anon;
grant execute on function public.owner_list_admins() to authenticated;


-- Tambah admin berdasarkan email akun Auth yang sudah terdaftar
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
    select 1
    from public.admins a
    where a.user_id = auth.uid()
      and a.role = 'owner'
  ) then
    raise exception 'Akses hanya untuk owner';
  end if;

  select id, email
  into target_user_id, target_email
  from auth.users
  where lower(email) = lower(trim(p_email))
  limit 1;

  if target_user_id is null then
    raise exception 'Akun dengan email tersebut belum terdaftar di Supabase Auth';
  end if;

  insert into public.admins(user_id, role)
  values (target_user_id, 'admin')
  on conflict (user_id)
  do update set role = 'admin';

  return jsonb_build_object(
    'user_id', target_user_id,
    'email', target_email,
    'role', 'admin'
  );
end;
$$;

revoke execute on function public.owner_add_admin_by_email(text) from public, anon;
grant execute on function public.owner_add_admin_by_email(text) to authenticated;


-- Hapus admin, hanya Owner yang boleh
create or replace function public.owner_delete_admin(p_user_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
begin
  if not exists (
    select 1
    from public.admins a
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

revoke execute on function public.owner_delete_admin(uuid) from public, anon;
grant execute on function public.owner_delete_admin(uuid) to authenticated;


-- Hapus member + akun Auth member, hanya Owner yang boleh
create or replace function public.owner_delete_member(p_user_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
begin
  if not exists (
    select 1
    from public.admins a
    where a.user_id = auth.uid()
      and a.role = 'owner'
  ) then
    raise exception 'Akses hanya untuk owner';
  end if;

  if exists (
    select 1
    from public.admins a
    where a.user_id = p_user_id
  ) then
    raise exception 'Akun admin tidak dapat dihapus dari menu member';
  end if;

  delete from public.members
  where user_id = p_user_id;

  delete from auth.users
  where id = p_user_id;

  return true;
end;
$$;

revoke execute on function public.owner_delete_member(uuid) from public, anon;
grant execute on function public.owner_delete_member(uuid) to authenticated;

-- Paksa Supabase/PostgREST memuat ulang schema cache.
notify pgrst, 'reload schema';
