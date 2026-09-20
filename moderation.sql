-- ============================================================
-- FUEL://NUTRITION — auto-moderation
-- Auto-hides community foods that exceed 5 abuse flags, and
-- logs every auto-hide to `moderation_log` for manual review.
-- Paste into the SAME Supabase project (SQL Editor), then Run.
-- ============================================================

-- 1. Log table: records every auto-hidden food for your review
create table if not exists public.moderation_log (
  id bigint generated always as identity primary key,
  food_id bigint not null,
  food_name text,
  reason text not null default 'auto-flagged (>5 flags)',
  flags_at_hide int,
  action text not null default 'hidden',
  created_at timestamptz not null default now()
);
alter table public.moderation_log enable row level security;
drop policy if exists "anon read moderation" on public.moderation_log;
create policy "anon read moderation" on public.moderation_log
  for select using (true);

-- 2. Trigger: when flags cross 5, auto-hide + write a log row
create or replace function public.auto_hide_flagged_food()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.flags > 5 and old.hidden = false and new.hidden = false then
    new.hidden := true;
    insert into public.moderation_log (food_id, food_name, reason, flags_at_hide, action)
    values (new.id, new.name, 'auto-flagged (>5 flags)', new.flags, 'hidden');
  end if;
  return new;
end;
$$;

drop trigger if exists auto_hide_flagged_food_trigger on public.community_foods;
create trigger auto_hide_flagged_food_trigger
  before update on public.community_foods
  for each row execute function public.auto_hide_flagged_food();
