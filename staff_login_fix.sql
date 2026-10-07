-- KENZZ STORE STAFF LOGIN FIX
-- Memungkinkan akun authenticated membaca role miliknya sendiri.
-- Jalankan di Supabase SQL Editor.

alter table public.admins enable row level security;

drop policy if exists "Staff can view own role" on public.admins;
create policy "Staff can view own role"
on public.admins
for select
to authenticated
using (auth.uid() = user_id);

notify pgrst, 'reload schema';
