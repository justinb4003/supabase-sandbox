-- New projects don't auto-grant the API roles (anon = logged out,
-- authenticated = logged in) access to tables. GRANT decides which tables a
-- role can touch at all; RLS policies then decide which rows.
grant select on public.teams to anon, authenticated;
grant select, insert, update, delete on public.members to authenticated;

revoke execute on function public.get_team_roster(int) from public, anon;
grant execute on function public.get_team_roster(int) to authenticated;
