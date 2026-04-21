create extension if not exists pgcrypto;

create table if not exists public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  age integer not null default 0,
  full_name text,
  contact_number text,
  photo_url text,
  created_at timestamp without time zone not null default now(),
  updated_at timestamp with time zone not null default now()
);

create table if not exists public.tasks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  title text not null,
  description text,
  date_time timestamp with time zone not null,
  priority text not null default 'medium' check (priority in ('low', 'medium', 'high')),
  recurrence text not null default 'none' check (recurrence in ('none', 'daily', 'weekly')),
  reminder_time timestamp with time zone,
  status text not null default 'pending' check (status in ('pending', 'completed', 'canceled')),
  consecutive_pending_days integer not null default 0,
  consecutive_completed_days integer not null default 0,
  assigned_to_calendar boolean not null default false,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now()
);

create table if not exists public.notes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  title text not null,
  content text not null default '',
  linked_task_id uuid references public.tasks(id) on delete set null,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now()
);

create table if not exists public.habits (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  type text not null check (type in ('waterIntake', 'exercise', 'sleepHours', 'studyHours')),
  value double precision not null default 0,
  unit text not null,
  date date not null,
  created_at timestamp with time zone not null default now(),
  unique (user_id, type, date)
);

create index if not exists idx_tasks_user_id_date_time on public.tasks(user_id, date_time);
create index if not exists idx_notes_user_id_updated_at on public.notes(user_id, updated_at desc);
create index if not exists idx_habits_user_id_date on public.habits(user_id, date);

alter table public.users enable row level security;
alter table public.tasks enable row level security;
alter table public.notes enable row level security;
alter table public.habits enable row level security;

drop policy if exists "users_select_own" on public.users;
create policy "users_select_own"
on public.users
for select
to authenticated
using (auth.uid() = id);

drop policy if exists "users_insert_own" on public.users;
create policy "users_insert_own"
on public.users
for insert
to authenticated
with check (auth.uid() = id);

drop policy if exists "users_update_own" on public.users;
create policy "users_update_own"
on public.users
for update
to authenticated
using (auth.uid() = id)
with check (auth.uid() = id);

drop policy if exists "tasks_manage_own" on public.tasks;
create policy "tasks_manage_own"
on public.tasks
for all
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "notes_manage_own" on public.notes;
create policy "notes_manage_own"
on public.notes
for all
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "habits_manage_own" on public.habits;
create policy "habits_manage_own"
on public.habits
for all
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

insert into storage.buckets (id, name, public)
values ('profiles', 'profiles', true)
on conflict (id) do nothing;

drop policy if exists "profile_images_public_read" on storage.objects;
create policy "profile_images_public_read"
on storage.objects
for select
to public
using (bucket_id = 'profiles');

drop policy if exists "profile_images_manage_own" on storage.objects;
create policy "profile_images_manage_own"
on storage.objects
for all
to authenticated
using (
  bucket_id = 'profiles'
  and auth.uid()::text = (storage.foldername(name))[1]
)
with check (
  bucket_id = 'profiles'
  and auth.uid()::text = (storage.foldername(name))[1]
);
