-- Account table --
create table public.account (
  id uuid not null default gen_random_uuid (),
  user_id uuid null,
  username character varying not null,
  gender text null,
  email character varying null,
  birthday date null,
  height numeric null,
  weight numeric null,
  goal_weight numeric null,
  goal_period_days int null,
  activity_level text null,
  created_at timestamp with time zone null default now(),
  constraint account_pkey primary key (id),
  constraint account_email_key unique (email),
  constraint account_username_key unique (username),
  constraint account_user_id_fkey foreign KEY (user_id) references auth.users (id) on delete CASCADE
) TABLESPACE pg_default;

ALTER TABLE public.account
ADD COLUMN IF NOT EXISTS bmr integer null,
ADD COLUMN IF NOT EXISTS tdee integer null,
ADD COLUMN IF NOT EXISTS recommended_calories integer null;

alter table public.account
add constraint account_user_id_unique unique (user_id);

-- Calories log table -- 
CREATE TABLE public.calories_log (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.account(user_id) ON DELETE CASCADE,
  meal_type text,
  name text,
  calories numeric,
  carbs numeric,
  protein numeric,
  fat numeric,
  image_url text,
  log_date date NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- Password reset table --
create table public.password_reset (
  id uuid not null default gen_random_uuid (),
  email text not null,
  otp text not null,
  used boolean null default false,
  expires_at timestamp with time zone not null,
  created_at timestamp with time zone null default now(),
  constraint password_reset_pkey primary key (id)
) TABLESPACE pg_default;

-- Assistant session table --
create table public.assistant_session (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  messages jsonb not null default '[]',
  updated_at timestamp with time zone default now()
);