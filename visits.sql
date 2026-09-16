-- ============================================================
-- FUEL://NUTRITION — visit counter (anonymous app-open tracking)
-- Paste into the SAME Supabase project (SQL Editor), then Run.
-- ============================================================

-- one row per app open, keyed by an anonymous device id
create table if not exists public.visits (
  id bigint generated always as identity primary key,
  device_id text not null,
  created_at timestamptz not null default now()
);

alter table public.visits enable row level security;

drop policy if exists "anon insert visits" on public.visits;
create policy "anon insert visits" on public.visits
  for insert with check (true);

-- index so "distinct device_id per day" queries are fast
create index if not exists visits_created_at_idx on public.visits (created_at);
