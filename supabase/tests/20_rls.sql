-- Row Level Security and public content access (spec §6).
\set ON_ERROR_STOP on
begin;
insert into auth.users(id, email, raw_user_meta_data) values
  ('00000000-0000-0000-0000-00000000000a', 'a@test.kz', '{"display_name":"Санжар"}'),
  ('00000000-0000-0000-0000-00000000000b', 'b@test.kz', '{}');

insert into public.topics(id, level_code, slug, sort) values (9001, 'A1', 'rls-test', 99);
insert into public.words(id, topic_id, kk, example_kk, sort) values (9001, 9001, 'сынақ', 'Бұл сынақ.', 1);
insert into public.word_progress(user_id, word_id, box, due_at) values
  ('00000000-0000-0000-0000-00000000000a', 9001, 1, now()),
  ('00000000-0000-0000-0000-00000000000b', 9001, 2, now());
insert into public.chat_messages(user_id, role, content) values
  ('00000000-0000-0000-0000-00000000000b', 'user', 'сәлем');

do $$
begin
  assert (select display_name from public.profiles where user_id = '00000000-0000-0000-0000-00000000000a') = 'Санжар',
    'trigger should use display_name from metadata';
  assert (select display_name from public.profiles where user_id = '00000000-0000-0000-0000-00000000000b') = 'b',
    'trigger should fall back to the email name';
  assert (select level_code from public.profiles where user_id = '00000000-0000-0000-0000-00000000000a') is null,
    'new profile must have no level (onboarding not finished)';
end $$;

-- as user A
set local role authenticated;
set local request.jwt.claims = '{"sub":"00000000-0000-0000-0000-00000000000a"}';
do $$
begin
  assert (select count(*) from public.profiles) = 1, 'A sees only own profile';
  assert (select count(*) from public.word_progress) = 1, 'A sees only own progress';
  assert (select count(*) from public.chat_messages) = 0, 'A cannot see B chat';
  assert (select count(*) from public.levels) = 6, 'levels readable';
  assert (select count(*) from public.words where id = 9001) = 1, 'words readable';
end $$;

update public.profiles set level_code = 'A1', learning_lang = 'ru' where user_id = '00000000-0000-0000-0000-00000000000b';
do $$ begin
  assert (select count(*) from public.profiles where level_code = 'A1') = 0, 'A cannot update B profile';
end $$;

insert into public.content_reports(user_id, word_id, comment)
  values ('00000000-0000-0000-0000-00000000000a', 9001, 'опечатка');
do $$ begin
  perform count(*) from public.content_reports;
  raise exception 'clients must not read reports';
exception when insufficient_privilege then null;  -- reports are write-only for clients
end $$;

-- A cannot write a report pretending to be B
do $$ begin
  insert into public.content_reports(user_id, word_id, comment)
    values ('00000000-0000-0000-0000-00000000000b', 9001, 'x');
  raise exception 'spoofed report should fail';
exception when insufficient_privilege then null;
end $$;

-- A cannot write content
do $$ begin
  insert into public.words(topic_id, kk, example_kk, sort) values (9001, 'жаман', 'x', 2);
  raise exception 'client insert into words should fail';
exception when insufficient_privilege then null;
end $$;

-- upsert_progress counts answers
select public.upsert_progress(9001, 2, now() + interval '3 days', true);
select public.upsert_progress(9001, 0, now(), false);
do $$ begin
  assert (select correct_count from public.word_progress) = 1, 'correct counted';
  assert (select wrong_count from public.word_progress) = 1, 'wrong counted';
  assert (select box from public.word_progress) = 0, 'box from last answer';
end $$;

-- anonymous
reset role;
set local role anon;
set local request.jwt.claims = '{}';
do $$ begin
  assert (select count(*) from public.topics where id = 9001) = 1, 'anon reads topics';
end $$;
do $$ begin
  perform count(*) from public.profiles;
  raise exception 'anon must not read profiles';
exception when insufficient_privilege then null;
end $$;

rollback;
\echo 20_rls OK
