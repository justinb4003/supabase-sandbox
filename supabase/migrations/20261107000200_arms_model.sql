-- Mirror ARMS's access model: three tiers.
--
-- ARMS grants the logged-out `anon` role SELECT on ~213/233 tables and leans on
-- RLS to decide rows. The sandbox originally withheld the grant entirely (the
-- more defensive stance). This migration reshapes it to match ARMS so the two
-- behave the same, and documents each tier.

-- TIER 1 — truly public: anon has the grant AND an RLS policy returns rows.
--   (teams already does this: `grant select ... to anon` + `using (true)`.)
--   anon curl  -> rows. Example in ARMS: tm_teams, tm_seasons, mkt_sponsors.

-- TIER 2 — exposed but RLS-empty: anon has the SELECT grant but NO anon policy,
--   so anon gets [] (HTTP 200, zero rows), not "permission denied". Logged-in
--   users match the authenticated policy and see rows. This is ARMS's dominant
--   pattern (tm_persons, tm_compliance_records, most of the schema).
grant select on public.members to anon;   -- authenticated already had it
--   members has only `to authenticated` policies, so anon now returns [].

-- TIER 3 — ungranted: anon has no grant at all, so even SELECT is refused
--   (HTTP 401 permission denied). ARMS does this for users, v_user_permissions,
--   tm_formation_*, tm_shirt_*, etc. Demonstrate with an internal audit table.
create table if not exists public.audit_log (
  id bigint generated always as identity primary key,
  actor uuid default auth.uid(),
  action text not null,
  at timestamptz not null default now()
);
alter table public.audit_log enable row level security;
-- no grant to anon; authenticated may read their own entries.
grant select, insert on public.audit_log to authenticated;
create policy "own audit rows" on public.audit_log
  for select to authenticated using (actor = auth.uid());
create policy "write own audit rows" on public.audit_log
  for insert to authenticated with check (actor = auth.uid());
