-- Policies for account table --
alter table account enable row level security;

create policy "Enable insert for authenticated users only"
on "public"."account"
for insert to authenticated
with check (true);

create policy "Enable insert for users based on user_id"
on "public"."account"
for insert with check (
  (select auth.uid()) = user_id
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