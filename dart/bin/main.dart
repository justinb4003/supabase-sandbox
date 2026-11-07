// dart run bin/main.dart   (reads ../.env.local)
import 'dart:io';
import 'package:supabase/supabase.dart';

Future<void> main() async {
  final env = {
    for (final l in File('../.env.local').readAsLinesSync())
      if (l.contains('=') && !l.startsWith('#')) l.split('=').first: l.substring(l.indexOf('=') + 1),
  };
  final sb = SupabaseClient(env['VITE_SUPABASE_URL']!, env['VITE_SUPABASE_ANON_KEY']!);

  print('anon teams: ${await sb.from('teams').select('number, name').order('number', ascending: true)}');

  // Log in as the bot ("service account" style: a normal user a script signs in as).
  final auth = await sb.auth.signInWithPassword(email: env['BOT_EMAIL']!, password: env['BOT_PASSWORD']!);
  print('logged in as ${auth.user!.email}');

  final members = await sb
      .from('members')
      .select('first_name, last_name, role, teams!inner(number)')
      .eq('teams.number', 4003)
      .order('last_name', ascending: true) // Dart defaults to descending!;
  for (final m in members) {
    print('  ${m['first_name']} ${m['last_name']} (${m['role']})');
  }

  print('rpc: ${await sb.rpc('get_team_roster', params: {'team_number': 9999})}');

  await sb.auth.signOut();
  await sb.dispose();
}
