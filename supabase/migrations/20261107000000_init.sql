-- Teams: anyone (even logged out) can read.
create table public.teams (
  id bigint generated always as identity primary key,
  number int not null unique,
  name text not null,
  created_at timestamptz not null default now()
);

-- Members: only logged-in users can read; you can edit/delete rows you created.
create table public.members (
  id bigint generated always as identity primary key,
  team_id bigint not null references public.teams(id) on delete cascade,
  first_name text not null,
  last_name text not null,
  role text not null default 'student' check (role in ('student', 'mentor', 'parent')),
  grad_year int,
  created_by uuid default auth.uid() references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);

alter table public.teams enable row level security;
alter table public.members enable row level security;

create policy "teams are public" on public.teams
  for select to anon, authenticated using (true);

create policy "members visible when logged in" on public.members
  for select to authenticated using (true);
create policy "logged-in users add members" on public.members
  for insert to authenticated with check (created_by = auth.uid());
create policy "edit own members" on public.members
  for update to authenticated using (created_by = auth.uid());
create policy "delete own members" on public.members
  for delete to authenticated using (created_by = auth.uid());

-- An RPC like ARMS's get_my_* functions. security invoker = runs as the
-- caller, so RLS still applies (anon gets nothing back).
create function public.get_team_roster(team_number int)
returns table (first_name text, last_name text, role text, grad_year int)
language sql stable security invoker set search_path = ''
as $$
  select m.first_name, m.last_name, m.role, m.grad_year
  from public.members m join public.teams t on t.id = m.team_id
  where t.number = team_number
  order by m.role, m.last_name;
$$;
