create table if not exists public.work_log_data (
  user_id uuid primary key references auth.users (id) on delete cascade,
  payload jsonb not null default '{"records":[],"settlements":[]}'::jsonb
    check (jsonb_typeof(payload) = 'object'),
  updated_at timestamptz not null default now()
);

alter table public.work_log_data
  add column if not exists payload jsonb not null
    default '{"records":[],"settlements":[]}'::jsonb;

alter table public.work_log_data
  add column if not exists updated_at timestamptz not null default now();

do $migration$
declare
  has_records boolean;
  has_settlements boolean;
begin
  select exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'work_log_data' and column_name = 'records'
  ) into has_records;
  select exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'work_log_data' and column_name = 'settlements'
  ) into has_settlements;

  if has_records and has_settlements then
    execute $sql$
      update public.work_log_data
      set payload = jsonb_build_object(
        'records', coalesce(to_jsonb(records), '[]'::jsonb),
        'settlements', coalesce(to_jsonb(settlements), '[]'::jsonb)
      )
      where payload = '{"records":[],"settlements":[]}'::jsonb
        and (
          coalesce(to_jsonb(records), '[]'::jsonb) <> '[]'::jsonb
          or coalesce(to_jsonb(settlements), '[]'::jsonb) <> '[]'::jsonb
        )
    $sql$;
  end if;
end
$migration$;

create unique index if not exists work_log_data_user_id_uidx
  on public.work_log_data (user_id);

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
