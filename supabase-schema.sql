create table if not exists public.work_log_data (
  user_id uuid primary key references auth.users (id) on delete cascade,
  payload jsonb not null check (jsonb_typeof(payload) = 'object'),
  updated_at timestamptz not null default now()
);

alter table public.work_log_data enable row level security;

revoke all on public.work_log_data from anon;
grant select, insert, update on public.work_log_data to authenticated;

drop policy if exists "Users can read their own work log" on public.work_log_data;
create policy "Users can read their own work log"
  on public.work_log_data for select to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists "Users can insert their own work log" on public.work_log_data;
create policy "Users can insert their own work log"
  on public.work_log_data for insert to authenticated
  with check ((select auth.uid()) = user_id);

drop policy if exists "Users can update their own work log" on public.work_log_data;
create policy "Users can update their own work log"
  on public.work_log_data for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);
