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
