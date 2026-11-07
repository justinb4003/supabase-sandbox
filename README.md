# supabase-sandbox

Learning Supabase before integrating with ARMS. Vite + React + supabase-js (same stack as ARMS), hosted on GitHub Pages.

## Setup
1. `cp .env.example .env.local` and fill in the project URL and publishable/anon key.
2. `npx supabase login && npx supabase link --project-ref <ref>`
3. `npx supabase db push` (applies `supabase/migrations`), then run `supabase/seed.sql` in the SQL editor.
4. `npm run dev`

GitHub Pages builds read `VITE_SUPABASE_URL` / `VITE_SUPABASE_ANON_KEY` from repo **variables**.

## Raw API (PostgREST)
```bash
source .env.local
H=(-H "apikey: $VITE_SUPABASE_ANON_KEY")
curl "$VITE_SUPABASE_URL/rest/v1/teams?select=*" "${H[@]}"
curl "$VITE_SUPABASE_URL/rest/v1/members?select=first_name,teams(number)" "${H[@]}"   # [] when anonymous (RLS)
curl -X POST "$VITE_SUPABASE_URL/rest/v1/rpc/get_team_roster" "${H[@]}" -H 'Content-Type: application/json' -d '{"team_number":4003}'
```

## Dart (how the scouting app would call it)
`cd dart && dart pub get && dart run bin/main.dart`. Uses `package:supabase` (Flutter apps use `supabase_flutter`, same API).
Gotcha: Dart's `.order()` defaults to **descending**; JS defaults to ascending.

## "Service account"
`.env.local` holds `BOT_EMAIL`/`BOT_PASSWORD` for a confirmed user created with the admin API, and `SUPABASE_SECRET_KEY` (bypasses RLS entirely; server-side only, never in the app or git).

## Access model (mirrors ARMS)
ARMS grants the logged-out `anon` role SELECT on ~213/233 tables and relies on RLS for rows. Three tiers, reproduced here:

| Tier | anon grant? | anon RLS policy? | anon result | Sandbox | ARMS example |
|------|-------------|------------------|-------------|---------|--------------|
| 1 Public | yes | yes (`using true`) | rows | `teams` | `tm_teams`, `tm_seasons` |
| 2 Exposed, RLS-empty | yes | no | `[]` (200) | `members` | `tm_persons`, `tm_compliance_records` |
| 3 Ungranted | no | — | denied (401) | `audit_log` | `users`, `v_user_permissions` |

Tier 2 is the one to watch: anon can *reach* the table, so a single missing/wrong RLS policy leaks it. Not granting `anon` at all (tier 3) is the defensive default.
