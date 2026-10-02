-- Streak rules (spec §5.2). Run after 00_auth_stub.sql and the migration.
\set ON_ERROR_STOP on
begin;
insert into auth.users(id, email) values ('00000000-0000-0000-0000-00000000000a', 'a@test.kz');

set local role authenticated;
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-00000000000a"}';

do $$
declare s int;
begin
  select streak into s from public.record_activity('2026-10-02');
  assert s = 1, format('first day: expected 1, got %s', s);

  select streak into s from public.record_activity('2026-10-02');
  assert s = 1, format('same day again: expected 1, got %s', s);

  select streak into s from public.record_activity('2026-10-03');
  assert s = 2, format('next day: expected 2, got %s', s);

  select streak into s from public.record_activity('2026-10-01');
  assert s = 2, format('earlier date (clock skew): expected 2, got %s', s);

  select streak into s from public.record_activity('2026-10-05');
  assert s = 1, format('after a gap: expected 1, got %s', s);
end $$;

-- record_activity without a signed-in user must fail
reset role;
set local role anon;
set local request.jwt.claims = '{}';
do $$
begin
  perform public.record_activity('2026-10-06');
  raise exception 'anon call should have failed';
exception when insufficient_privilege or raise_exception then
  if sqlerrm = 'anon call should have failed' then raise; end if;
end $$;

rollback;
\echo 10_streak OK
