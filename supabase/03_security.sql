-- =========================================
-- VIBELY: SECURITY (permissions + Row Level Security)
-- =========================================

-- STEP A: Remove all default access, then give back only what's needed
revoke all on all tables in schema public from anon, authenticated;

grant select on public.profiles to authenticated;
grant update (full_name, dob, gender, interested_in, city, area, bio, intent,
              interests, pref_age_min, pref_age_max, selfie_path, onboarding_complete)
  on public.profiles to authenticated;

grant select, insert, update, delete on public.photos, public.prompts,
  public.answers, public.blocks to authenticated;
grant select on public.questions to authenticated;
grant select, insert, update on public.actions to authenticated;
grant select on public.matches, public.daily_picks to authenticated;
grant select, insert on public.messages to authenticated;
grant update (read_at) on public.messages to authenticated;
grant select, insert on public.reports to authenticated;

-- STEP B: Turn on Row Level Security for every table
alter table public.profiles    enable row level security;
alter table public.photos      enable row level security;
alter table public.prompts     enable row level security;
alter table public.questions   enable row level security;
alter table public.answers     enable row level security;
alter table public.actions     enable row level security;
alter table public.matches     enable row level security;
alter table public.messages    enable row level security;
alter table public.daily_picks enable row level security;
alter table public.reports     enable row level security;
alter table public.blocks      enable row level security;

-- STEP C: Policies (rules for WHICH ROWS each user can access)

-- PROFILES
create policy "profiles: read active profiles or own" on public.profiles
  for select to authenticated
  using (id = auth.uid() or account_status = 'active' or public.is_admin());

create policy "profiles: update own" on public.profiles
  for update to authenticated
  using (id = auth.uid()) with check (id = auth.uid());

-- PHOTOS
create policy "photos: read" on public.photos
  for select to authenticated using (true);
create policy "photos: add own" on public.photos
  for insert to authenticated with check (user_id = auth.uid());
create policy "photos: edit own" on public.photos
  for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "photos: delete own" on public.photos
  for delete to authenticated using (user_id = auth.uid());

-- PROMPTS
create policy "prompts: read" on public.prompts
  for select to authenticated using (true);
create policy "prompts: add own" on public.prompts
  for insert to authenticated with check (user_id = auth.uid());
create policy "prompts: edit own" on public.prompts
  for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "prompts: delete own" on public.prompts
  for delete to authenticated using (user_id = auth.uid());

-- QUESTIONS (everyone can read, nobody can change from the app)
create policy "questions: read" on public.questions
  for select to authenticated using (true);

-- ANSWERS (private: only you see your own answers)
create policy "answers: own only" on public.answers
  for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- ACTIONS (you only see and make your own likes/passes)
create policy "actions: own only" on public.actions
  for all to authenticated
  using (from_user = auth.uid()) with check (from_user = auth.uid());

-- MATCHES (only the two people in the match)
create policy "matches: participants only" on public.matches
  for select to authenticated
  using (auth.uid() in (user_a, user_b));

-- MESSAGES
create policy "messages: read if in the match" on public.messages
  for select to authenticated
  using (exists (
    select 1 from public.matches m
    where m.id = match_id and auth.uid() in (m.user_a, m.user_b)
  ));

create policy "messages: send in own active match" on public.messages
  for insert to authenticated
  with check (
    sender_id = auth.uid()
    and exists (
      select 1 from public.matches m
      where m.id = match_id and m.status = 'active'
        and auth.uid() in (m.user_a, m.user_b)
    )
  );

create policy "messages: receiver marks as read" on public.messages
  for update to authenticated
  using (
    sender_id <> auth.uid()
    and exists (
      select 1 from public.matches m
      where m.id = match_id and auth.uid() in (m.user_a, m.user_b)
    )
  );

-- DAILY PICKS (only your own picks)
create policy "daily_picks: own only" on public.daily_picks
  for select to authenticated using (user_id = auth.uid());

-- REPORTS (you can report others; only you and admins see your reports)
create policy "reports: create" on public.reports
  for insert to authenticated
  with check (reporter_id = auth.uid() and reporter_id <> reported_id);
create policy "reports: read own or admin" on public.reports
  for select to authenticated
  using (reporter_id = auth.uid() or public.is_admin());

-- BLOCKS (manage your own block list)
create policy "blocks: own only" on public.blocks
  for all to authenticated
  using (blocker_id = auth.uid()) with check (blocker_id = auth.uid());