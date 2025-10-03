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
  period_days int null,
  activity_level text null,
  created_at timestamp with time zone null default now(),
  constraint account_pkey primary key (id),
  constraint account_email_key unique (email),
  constraint account_username_key unique (username),
  constraint account_user_id_fkey foreign KEY (user_id) references auth.users (id) on delete CASCADE
) TABLESPACE pg_default;
