-- =========================================
-- VIBELY: TABLES
-- =========================================

-- 1. PROFILES: one row per user (linked to Supabase login)
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  dob date check (dob <= current_date - interval '18 years'),   -- must be 18+
  gender text check (gender in ('man', 'woman', 'non_binary')),
  interested_in text[] default '{}',                             -- e.g. {'woman'}
  city text,
  area text,
  bio text check (char_length(bio) <= 500),
  intent text check (intent in ('serious', 'open', 'marriage', 'new_in_city')),
  interests text[] default '{}',                                 -- e.g. {'trekking','coffee'}
  pref_age_min int default 21 check (pref_age_min >= 18),
  pref_age_max int default 35 check (pref_age_max <= 60),
  selfie_path text,                                              -- verification selfie
  verification_status text not null default 'unverified'
    check (verification_status in ('unverified', 'verified', 'rejected')),
  is_premium boolean not null default false,
  account_status text not null default 'active'
    check (account_status in ('active', 'flagged', 'banned')),
  is_admin boolean not null default false,
  onboarding_complete boolean not null default false,
  created_at timestamptz not null default now(),
  check (pref_age_min <= pref_age_max)
);

-- 2. PHOTOS: up to 6 photos per user
create table public.photos (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  path text not null,                                            -- file location in storage
  position int not null default 0 check (position between 0 and 5),
  created_at timestamptz not null default now()
);

-- 3. PROMPTS: "A perfect Sunday is..." style answers
create table public.prompts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  question text not null,
  answer text not null check (char_length(answer) between 1 and 300),
  created_at timestamptz not null default now()
);

-- 4. QUESTIONS: the compatibility questionnaire (same for everyone)
create table public.questions (
  id int primary key,
  text text not null,
  options jsonb not null                                         -- list of answer choices
);

-- 5. ANSWERS: each user's answer to each question
create table public.answers (
  user_id uuid references public.profiles(id) on delete cascade,
  question_id int references public.questions(id) on delete cascade,
  answer int not null,                                           -- index of chosen option
  importance int not null default 2 check (importance between 1 and 3),
  primary key (user_id, question_id)                             -- one answer per question
);

-- 6. ACTIONS: likes and passes
create table public.actions (
  from_user uuid references public.profiles(id) on delete cascade,
  to_user uuid references public.profiles(id) on delete cascade,
  action text not null check (action in ('like', 'pass')),
  created_at timestamptz not null default now(),
  primary key (from_user, to_user),
  check (from_user <> to_user)                                   -- can't like yourself
);

-- 7. MATCHES: created when two people like each other
create table public.matches (
  id uuid primary key default gen_random_uuid(),
  user_a uuid not null references public.profiles(id) on delete cascade,
  user_b uuid not null references public.profiles(id) on delete cascade,
  status text not null default 'active' check (status in ('active', 'closed')),
  closed_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  closed_at timestamptz,
  unique (user_a, user_b),
  check (user_a < user_b)                                        -- stops duplicate A-B / B-A rows
);

-- 8. MESSAGES: chat messages inside a match
create table public.messages (
  id uuid primary key default gen_random_uuid(),
  match_id uuid not null references public.matches(id) on delete cascade,
  sender_id uuid not null references public.profiles(id) on delete cascade,
  content text not null check (char_length(content) between 1 and 1000),
  created_at timestamptz not null default now(),
  read_at timestamptz                                            -- null = unread
);
create index messages_match_time_idx on public.messages (match_id, created_at);

-- 9. DAILY PICKS: the 5 curated profiles shown each day
create table public.daily_picks (
  user_id uuid references public.profiles(id) on delete cascade,
  pick_user_id uuid references public.profiles(id) on delete cascade,
  pick_date date not null default current_date,
  score int not null,                                            -- compatibility 0-100
  primary key (user_id, pick_user_id, pick_date)
);

-- 10. REPORTS: users reporting bad behaviour
create table public.reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references public.profiles(id) on delete cascade,
  reported_id uuid not null references public.profiles(id) on delete cascade,
  reason text not null check (reason in
    ('fake_profile', 'harassment', 'inappropriate_content', 'spam', 'underage', 'other')),
  details text check (char_length(details) <= 500),
  status text not null default 'pending'
    check (status in ('pending', 'action_taken', 'dismissed')),
  created_at timestamptz not null default now()
);

-- 11. BLOCKS: blocked users never see each other again
create table public.blocks (
  blocker_id uuid references public.profiles(id) on delete cascade,
  blocked_id uuid references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id)
);