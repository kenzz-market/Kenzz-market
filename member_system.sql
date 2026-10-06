create table members (
id uuid primary key default gen_random_uuid(),
user_id uuid,
name text,
email text,
phone text,
provider text,
created_at timestamp default now()
);
