-- ═══════════════════════════════════════════════════════════
--  TRADEPRINT — DATABASE SETUP
--  
--  HOW TO RUN THIS:
--  1. Go to your Supabase project
--  2. Click "SQL Editor" in the left sidebar
--  3. Click "New Query"
--  4. Copy everything below and paste it in
--  5. Click "Run"
--  6. Done. Your database is ready.
-- ═══════════════════════════════════════════════════════════

-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- ── PROFILES TABLE ──────────────────────────────────────────
-- Stores each trader's personal configuration
create table if not exists profiles (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references auth.users(id) on delete cascade unique not null,
  name text,
  style text,                    -- intraday / swing / positional
  instruments text[],            -- array: equity, options, futures, commodity, forex, crypto
  capital numeric default 100000,
  risk_pct numeric default 1,
  daily_loss_pct numeric default 2,
  min_rr numeric default 2,
  exchange text default 'NSE',
  rules text[],                  -- trader's personal rules
  setups text[],                 -- trader's setup type names
  language text default 'en',   -- en / hi
  onboarding_done boolean default false,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- ── TRADES TABLE ──────────────────────────────────────────────
-- Every trade the trader logs
create table if not exists trades (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references auth.users(id) on delete cascade not null,
  trade_date date not null,
  trade_time time,
  symbol text not null,
  instrument text,               -- Equity / Options-Call / Options-Put / Futures / Commodity / Forex / Crypto
  direction text,                -- Long/Buy or Short/Sell
  setup_type text,               -- from trader's personal setup list
  entry_price numeric,
  exit_price numeric,
  quantity numeric,
  pnl numeric,                   -- calculated profit/loss in ₹
  pnl_pct numeric,               -- P&L as % of capital
  outcome text,                  -- win / loss / breakeven
  rr_planned numeric,            -- planned risk:reward
  emotion text,                  -- calm / confident / anxious / excited / frustrated / fearful / bored / revenge
  rules_followed boolean default true,
  violations text[],             -- which specific rules were broken
  is_revenge boolean default false,
  is_boredom boolean default false,  -- flagged if traded in low-volume window
  is_first_15min boolean default false,
  is_expiry_day boolean default false,
  why_entered text,              -- trader's own reason for entry
  lesson text,                   -- post-trade lesson
  created_at timestamptz default now()
);

-- ── JOURNAL TABLE ────────────────────────────────────────────
create table if not exists journal_entries (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references auth.users(id) on delete cascade not null,
  entry_date date not null,
  pre_session text,
  post_session text,
  key_lesson text,
  mood text,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  unique(user_id, entry_date)
);

-- ── COMMUNITY POSTS TABLE ────────────────────────────────────
create table if not exists community_posts (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references auth.users(id) on delete cascade not null,
  anon_handle text not null,     -- e.g. "Trader#4821" — never real name
  category text not null,        -- edge_insight / discipline / psychology / general
  content text not null,
  is_approved boolean default true,
  is_flagged boolean default false,
  likes integer default 0,
  created_at timestamptz default now()
);

-- ── COMMUNITY LIKES TABLE ────────────────────────────────────
create table if not exists community_likes (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references auth.users(id) on delete cascade not null,
  post_id uuid references community_posts(id) on delete cascade not null,
  created_at timestamptz default now(),
  unique(user_id, post_id)
);

-- ── WEEKLY REVIEWS TABLE ─────────────────────────────────────
create table if not exists weekly_reviews (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references auth.users(id) on delete cascade not null,
  week_start date not null,
  week_end date not null,
  total_trades integer,
  win_rate numeric,
  total_pnl numeric,
  total_pnl_pct numeric,
  discipline_score numeric,
  biggest_mistake text,
  pattern_identified text,
  action_next_week text,
  generated_at timestamptz default now(),
  unique(user_id, week_start)
);

-- ═══════════════════════════════════════════════════════════
--  ROW LEVEL SECURITY (RLS)
--  This is critical — it ensures each trader can ONLY see
--  their own data. No one else can ever access your trades.
-- ═══════════════════════════════════════════════════════════

-- Enable RLS on all tables
alter table profiles enable row level security;
alter table trades enable row level security;
alter table journal_entries enable row level security;
alter table community_posts enable row level security;
alter table community_likes enable row level security;
alter table weekly_reviews enable row level security;

-- PROFILES: users can only read/write their own profile
create policy "Users can view own profile" on profiles for select using (auth.uid() = user_id);
create policy "Users can insert own profile" on profiles for insert with check (auth.uid() = user_id);
create policy "Users can update own profile" on profiles for update using (auth.uid() = user_id);
create policy "Users can delete own profile" on profiles for delete using (auth.uid() = user_id);

-- TRADES: users can only read/write their own trades
create policy "Users can view own trades" on trades for select using (auth.uid() = user_id);
create policy "Users can insert own trades" on trades for insert with check (auth.uid() = user_id);
create policy "Users can update own trades" on trades for update using (auth.uid() = user_id);
create policy "Users can delete own trades" on trades for delete using (auth.uid() = user_id);

-- JOURNAL: private to each user
create policy "Users can view own journal" on journal_entries for select using (auth.uid() = user_id);
create policy "Users can insert own journal" on journal_entries for insert with check (auth.uid() = user_id);
create policy "Users can update own journal" on journal_entries for update using (auth.uid() = user_id);
create policy "Users can delete own journal" on journal_entries for delete using (auth.uid() = user_id);

-- COMMUNITY: approved posts visible to all authenticated users; own posts manageable
create policy "All authenticated users can view approved posts" on community_posts for select using (auth.role() = 'authenticated' and is_approved = true);
create policy "Users can insert own posts" on community_posts for insert with check (auth.uid() = user_id);
create policy "Users can delete own posts" on community_posts for delete using (auth.uid() = user_id);

-- COMMUNITY LIKES
create policy "Users can view likes" on community_likes for select using (auth.role() = 'authenticated');
create policy "Users can manage own likes" on community_likes for insert with check (auth.uid() = user_id);
create policy "Users can remove own likes" on community_likes for delete using (auth.uid() = user_id);

-- WEEKLY REVIEWS
create policy "Users can view own reviews" on weekly_reviews for select using (auth.uid() = user_id);
create policy "Users can insert own reviews" on weekly_reviews for insert with check (auth.uid() = user_id);
create policy "Users can update own reviews" on weekly_reviews for update using (auth.uid() = user_id);

-- ═══════════════════════════════════════════════════════════
--  INDEXES (makes the app faster as data grows)
-- ═══════════════════════════════════════════════════════════
create index if not exists trades_user_id_idx on trades(user_id);
create index if not exists trades_date_idx on trades(trade_date);
create index if not exists trades_user_date_idx on trades(user_id, trade_date);
create index if not exists journal_user_date_idx on journal_entries(user_id, entry_date);
create index if not exists community_created_idx on community_posts(created_at desc);
