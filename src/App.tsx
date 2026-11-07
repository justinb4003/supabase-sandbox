import { useEffect, useState } from 'react'
import type { Session } from '@supabase/supabase-js'
import { supabase } from './supabase'

type Team = { id: number; number: number; name: string }
type Member = {
  id: number
  first_name: string
  last_name: string
  role: string
  grad_year: number | null
  teams: { number: number } | null
}

export default function App() {
  const [session, setSession] = useState<Session | null>(null)
  const [teams, setTeams] = useState<Team[]>([])
  const [members, setMembers] = useState<Member[]>([])
  const [error, setError] = useState('')

  useEffect(() => {
    supabase.auth.getSession().then(({ data }) => setSession(data.session))
    const { data } = supabase.auth.onAuthStateChange((_e, s) => setSession(s))
    return () => data.subscription.unsubscribe()
  }, [])

  async function load() {
    const t = await supabase.from('teams').select('id, number, name').order('number')
    // Embedded join via the team_id foreign key.
    const m = await supabase
      .from('members')
      .select('id, first_name, last_name, role, grad_year, teams(number)')
      .order('last_name')
    setError(t.error?.message ?? m.error?.message ?? '')
    setTeams(t.data ?? [])
    setMembers((m.data as unknown as Member[]) ?? [])
  }

  useEffect(() => {
    load()
  }, [session])

  return (
    <main style={{ maxWidth: 720, margin: '2rem auto', fontFamily: 'system-ui', padding: '0 1rem' }}>
      <h1>Supabase Sandbox</h1>
      <Auth session={session} />
      {error && <p style={{ color: 'crimson' }}>{error}</p>}

      <h2>Teams (public)</h2>
      <ul>
        {teams.map((t) => (
          <li key={t.id}>
            {t.number} {t.name}
          </li>
        ))}
      </ul>

      <h2>Members (logged in only)</h2>
      {!session && <p>Log in to see members. RLS returns an empty list to anonymous users.</p>}
      <table>
        <tbody>
          {members.map((m) => (
            <tr key={m.id}>
              <td>{m.teams?.number}</td>
              <td>
                {m.first_name} {m.last_name}
              </td>
              <td>{m.role}</td>
              <td>{m.grad_year ?? ''}</td>
            </tr>
          ))}
        </tbody>
      </table>
      {session && <AddMember teams={teams} onAdded={load} />}
    </main>
  )
}

function Auth({ session }: { session: Session | null }) {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [msg, setMsg] = useState('')

  if (session)
    return (
      <p>
        Logged in as {session.user.email}{' '}
        <button onClick={() => supabase.auth.signOut()}>Log out</button>
      </p>
    )

  async function go(signUp: boolean) {
    const { error } = signUp
      ? await supabase.auth.signUp({ email, password })
      : await supabase.auth.signInWithPassword({ email, password })
    setMsg(error ? error.message : signUp ? 'Check your email to confirm.' : '')
  }

  return (
    <p>
      <input placeholder="email" value={email} onChange={(e) => setEmail(e.target.value)} />{' '}
      <input placeholder="password" type="password" value={password} onChange={(e) => setPassword(e.target.value)} />{' '}
      <button onClick={() => go(false)}>Log in</button> <button onClick={() => go(true)}>Sign up</button> {msg}
    </p>
  )
}

function AddMember({ teams, onAdded }: { teams: Team[]; onAdded: () => void }) {
  const [teamId, setTeamId] = useState<number>()
  const [first, setFirst] = useState('')
  const [last, setLast] = useState('')
  const [msg, setMsg] = useState('')

  async function add() {
    const { error } = await supabase
      .from('members')
      .insert({ team_id: teamId ?? teams[0]?.id, first_name: first, last_name: last })
    setMsg(error?.message ?? '')
    if (!error) {
      setFirst('')
      setLast('')
      onAdded()
    }
  }

  return (
    <p>
      <select onChange={(e) => setTeamId(Number(e.target.value))}>
        {teams.map((t) => (
          <option key={t.id} value={t.id}>
            {t.number}
          </option>
        ))}
      </select>{' '}
      <input placeholder="first" value={first} onChange={(e) => setFirst(e.target.value)} />{' '}
      <input placeholder="last" value={last} onChange={(e) => setLast(e.target.value)} />{' '}
      <button onClick={add}>Add</button> {msg}
    </p>
  )
}
