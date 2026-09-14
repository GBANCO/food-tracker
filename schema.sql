-- ============================================================
-- FUEL://NUTRITION — Supabase schema (dedicated project)
-- Run this in the Supabase SQL Editor, then copy your anon key
-- into index.html (search for SUPABASE_ANON_KEY).
-- ============================================================

-- ---- 1. BUG REPORTS ----
create table if not exists public.bug_reports (
  id bigint generated always as identity primary key,
  type text not null default 'bug',
  text text not null,
  status text not null default 'NEW',
  diag jsonb,
  created_at timestamptz not null default now()
);
alter table public.bug_reports enable row level security;

drop policy if exists "anon insert reports" on public.bug_reports;
create policy "anon insert reports" on public.bug_reports
  for insert with check (true);

drop policy if exists "anon read reports" on public.bug_reports;
create policy "anon read reports" on public.bug_reports
  for select using (true);

-- status changes only via the operator (pin-gated client-side; keep RLS permissive for now)
drop policy if exists "anon update reports" on public.bug_reports;
create policy "anon update reports" on public.bug_reports
  for update using (true) with check (true);

-- ---- 2. COMMUNITY FOODS ----
create table if not exists public.community_foods (
  id bigint generated always as identity primary key,
  name text not null,
  brand text,
  cal numeric not null,
  pro numeric not null,
  unit text not null default '1 serving',
  flags int not null default 0,
  hidden boolean not null default false,
  created_at timestamptz not null default now()
);
alter table public.community_foods enable row level security;

drop policy if exists "anon insert foods" on public.community_foods;
create policy "anon insert foods" on public.community_foods
  for insert with check (true);

-- only visible (non-hidden) foods are readable
drop policy if exists "anon read foods" on public.community_foods;
create policy "anon read foods" on public.community_foods
  for select using (hidden = false);

-- abuse flagging: anyone can increment flags
create or replace function public.flag_community_food(food_id bigint)
returns void language sql security definer set search_path = public as $$
  update public.community_foods set flags = flags + 1 where id = food_id;
$$;
grant execute on function public.flag_community_food to anon, authenticated;
