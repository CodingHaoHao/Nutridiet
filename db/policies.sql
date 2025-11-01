-- Policies for account table --
alter table account enable row level security;

create policy "Allow users to select their own account"
on "public"."account"
to authenticated
using (
  (user_id = auth.uid())
);

create policy "Allow users to insert their own account"
on "public"."account"
to authenticated
with check (
  (user_id = auth.uid())
);

create policy "Allow users to delete their own account"
on "public"."account"
to authenticated
using (
  (user_id = auth.uid())
);

create policy "Allow users to update their own account"
on "public"."account"
to authenticated
using (
  (user_id = auth.uid())
);

create policy "Enable delete for users based on user_id"
on "public"."account"
for delete using (
  (select auth.uid()) = user_id
);

create policy "Enable read access for all users"
on "public"."account"
to public
using (true);

-- Policies for calories_log table --
alter table calories_log enable row level security;

create policy "Users can view their own logs"
on calories_log for select
using (auth.uid() = user_id);

create policy "Users can insert their own logs"
on calories_log for insert
with check (auth.uid() = user_id);

create policy "Users can update their own logs"
on calories_log for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "Users can delete their own logs"
on calories_log for delete
using (auth.uid() = user_id);

-- Policies for password_reset table --
alter table password_reset enable row level security;

create policy "Allow users to check their OTP"
on password_reset
for select
using (
  auth.email() = email
);

create policy "Allow users to mark their OTP as used"
on password_reset
for update
using (
  auth.email() = email
)
with check (
  auth.email() = email
);

create policy "Enable read access for all users"
on "public"."password_reset"
to public
using (
  true
);

create policy "Users can view their own reset requests"
on "public"."password_reset"
to public
using (
  (email = auth.email())
);

create policy "Allow service role to manage password resets"
on "public"."password_reset"
to public
using (
  (auth.role() = 'service_role'::text)
) with check (
  (auth.role() = 'service_role'::text)
);

-- Policies for assistant_sessions table --
alter table assistant_session enable row level security;

create policy "Users can view their own sessions"
on assistant_session
for select
using (auth.uid() = user_id);

create policy "Users can insert their own sessions"
on assistant_session
for insert
with check (auth.uid() = user_id);

create policy "Users can update their own sessions"
on assistant_session
for update
using (auth.uid() = user_id);

create policy "Users can delete their own sessions"
on assistant_session
for delete
using (auth.uid() = user_id);

ALTER TABLE public.calories_log ENABLE ROW LEVEL SECURITY;

-- Policies for calories_log table --
CREATE POLICY "Users can insert their own logs"
ON public.calories_log
FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view their own logs"
ON public.calories_log
FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own logs"
ON public.calories_log
FOR UPDATE
USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own logs"
ON public.calories_log
FOR DELETE
USING (auth.uid() = user_id);

