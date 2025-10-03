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
