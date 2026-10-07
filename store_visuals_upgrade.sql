-- KENZZ STORE: OWNER-CONTROLLED HOMEPAGE VISUALS
-- Foto/video background untuk halaman utama, Hero, Verified/Keterangan,
-- Statistik, Announcement, dan Sosial Media.
-- Pengaturan hanya dapat ditulis oleh OWNER.

create table if not exists public.store_visual_settings (
  id integer primary key default 1 check (id = 1),
  background_image_url text,
  background_video_url text,
  hero_image_url text,
  hero_video_url text,
  verified_image_url text,
  verified_video_url text,
  statistik_image_url text,
  statistik_video_url text,
  announcement_image_url text,
  announcement_video_url text,
  social_image_url text,
  social_video_url text,
  updated_at timestamptz default now()
);

insert into public.store_visual_settings (id)
values (1)
on conflict (id) do nothing;

alter table public.store_visual_settings enable row level security;

-- Pengunjung hanya dapat membaca visual yang dipublikasikan.
drop policy if exists "Public can view store visuals" on public.store_visual_settings;
create policy "Public can view store visuals"
on public.store_visual_settings
for select
to anon, authenticated
using (true);

-- Hanya Owner yang dapat membuat/mengubah visual toko.
drop policy if exists "Owner insert store visuals" on public.store_visual_settings;
create policy "Owner insert store visuals"
on public.store_visual_settings
for insert
to authenticated
with check (
  exists (
    select 1 from public.admins a
    where a.user_id = auth.uid()
      and a.role = 'owner'
  )
);

drop policy if exists "Owner update store visuals" on public.store_visual_settings;
create policy "Owner update store visuals"
on public.store_visual_settings
for update
to authenticated
using (
  exists (
    select 1 from public.admins a
    where a.user_id = auth.uid()
      and a.role = 'owner'
  )
)
with check (
  exists (
    select 1 from public.admins a
    where a.user_id = auth.uid()
      and a.role = 'owner'
  )
);

-- Bucket publik untuk aset visual toko.
insert into storage.buckets (id, name, public)
values ('store-backgrounds', 'store-backgrounds', true)
on conflict (id) do update set public = true;

-- Semua orang boleh melihat aset yang sudah dipublikasikan.
drop policy if exists "Public view store background assets" on storage.objects;
create policy "Public view store background assets"
on storage.objects
for select
to public
using (bucket_id = 'store-backgrounds');

-- Hanya Owner yang boleh upload.
drop policy if exists "Owner upload store background assets" on storage.objects;
create policy "Owner upload store background assets"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'store-backgrounds'
  and exists (
    select 1 from public.admins a
    where a.user_id = auth.uid()
      and a.role = 'owner'
  )
);

-- Hanya Owner yang boleh mengganti file.
drop policy if exists "Owner update store background assets" on storage.objects;
create policy "Owner update store background assets"
on storage.objects
for update
to authenticated
using (
  bucket_id = 'store-backgrounds'
  and exists (
    select 1 from public.admins a
    where a.user_id = auth.uid()
      and a.role = 'owner'
  )
)
with check (
  bucket_id = 'store-backgrounds'
  and exists (
    select 1 from public.admins a
    where a.user_id = auth.uid()
      and a.role = 'owner'
  )
);

-- Hanya Owner yang boleh menghapus file.
drop policy if exists "Owner delete store background assets" on storage.objects;
create policy "Owner delete store background assets"
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'store-backgrounds'
  and exists (
    select 1 from public.admins a
    where a.user_id = auth.uid()
      and a.role = 'owner'
  )
);

notify pgrst, 'reload schema';
