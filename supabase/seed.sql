insert into public.teams (number, name) values
  (4003, 'TriSonics'), (9999, 'Sandbox Bots');

insert into public.members (team_id, first_name, last_name, role, grad_year)
select t.id, v.f, v.l, v.r, v.g
from (values
  (4003, 'Ada', 'Lovelace', 'student', 2027),
  (4003, 'Grace', 'Hopper', 'student', 2028),
  (4003, 'Alan', 'Turing', 'mentor', null),
  (9999, 'Linus', 'Torvalds', 'student', 2029)
) as v(n, f, l, r, g)
join public.teams t on t.number = v.n;
