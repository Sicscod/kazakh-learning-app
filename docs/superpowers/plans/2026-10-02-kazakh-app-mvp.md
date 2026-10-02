# Kazakh Learning App MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the `kazakh-learning-app` Flutter skeleton into MVP v1: sign-up/sign-in, onboarding (learning language + level), skills hub, words (topics, flashcards, quiz, spaced review), progress/streak, profile, and a text AI tutor.

**Architecture:** Flutter client with feature folders; pure-Dart `domain/` logic (SRS, streak, quiz building) covered by unit tests; repositories wrap Supabase (Postgres + Auth + RLS + one Edge Function). The tutor model sits behind an OpenAI-compatible adapter inside the Edge Function, so the model is swapped by changing secrets.

**Tech Stack:** Flutter 3 / Dart ^3.9, flutter_riverpod, go_router, supabase_flutter, flutter_localizations + intl (gen-l10n), shared_preferences; Supabase Free (Postgres 15+, Auth, Edge Functions on Deno); glm-4.7-flash.

**Spec:** `docs/superpowers/specs/2026-10-02-kazakh-app-mvp-design.md`

## Global Constraints

- Free tiers only: Supabase Free, free tutor model. No paid packages or services.
- Learning languages enabled in v1: `ru`, `en`. `zh` is shown disabled with «скоро».
- UI languages in v1: `kk`, `ru`, `en` (ARB files in `lib/l10n/`).
- Levels: `A1, A2, B1, B2, C1, C2`; only A1 and A2 have `is_available = true`.
- Skills hub: Сөздер and Ұстаз active; Reading, Listening, Writing, Speaking locked «скоро».
- Leitner intervals by box: 0 → 0 days, 1 → 1, 2 → 3, 3 → 7, 4 → 14, 5 → 30. Learned = `box >= 3`. Due for review = `box >= 1 && due_at <= now`.
- Quiz: 10 questions, 4 options, odd questions kk→translation, even questions translation→kk.
- Streak counts only on completing cards, quiz or review; device-local date; computed by server RPC.
- Tutor: 30 user messages per user per calendar day (UTC on server), last 20 messages as context, name «Ұстаз».
- Model key never in the app; only in Supabase secrets `TUTOR_BASE_URL`, `TUTOR_API_KEY`, `TUTOR_MODEL`.
- Content: A1 and A2, 5 topics × 20 words each, every word with `example_kk`, translations `ru` and `en`, human-checked before seeding.
- No copyrighted textbook/site text in content; Wikipedia only with attribution.

## Review Focus

1. A topic with fewer than 4 words, or two words with the same translation → quiz must still build 4 distinct options (draw extra distractors from the whole level) and never show a duplicate option. Test in Task 4.
2. Learning language has no translation for a word (e.g. `zh` later, or a missed seed row) → show the English translation, never an empty card or crash. Test in Task 6.
3. Signed-in user whose profile has no `level_code` (killed the app mid-onboarding) → router sends them to onboarding, not to the hub. Test in Task 7.
4. Tutor model call fails → user message is kept and not counted toward the daily limit. Test in Task 11 (SQL) and Task 11 (function).
5. Session crossing midnight / repeated completions in one day → streak changes at most once per local date, never decreases on the same day. Test in Task 2 (SQL) and Task 3 (Dart).

---

## File Structure

```
pubspec.yaml                       deps, assets, l10n flag (modify)
l10n.yaml                          gen-l10n config (create)
lib/main.dart                      bootstrap: Supabase.initialize, ProviderScope (rewrite)
lib/app/app.dart                   MaterialApp.router, locale from provider
lib/app/router.dart                go_router routes + redirect rules
lib/app/theme.dart                 colors from current screen (#32734E, #FBB03B), Inter w800 headings
lib/app/env.dart                   SUPABASE_URL / SUPABASE_ANON_KEY via --dart-define
lib/l10n/app_kk.arb, app_ru.arb, app_en.arb
lib/features/welcome/welcome_screen.dart
lib/features/auth/{auth_repository.dart, sign_in_screen.dart, sign_up_screen.dart}
lib/features/onboarding/{onboarding_screen.dart}
lib/features/profile/{profile.dart, profile_repository.dart, profile_screen.dart}
lib/features/home/home_screen.dart
lib/features/words/domain/{srs.dart, quiz_builder.dart, models.dart}
lib/features/words/data/{words_repository.dart, content_cache.dart}
lib/features/words/{topics_screen.dart, topic_screen.dart, cards_screen.dart, quiz_screen.dart, review_screen.dart, session_result_screen.dart}
lib/features/progress/{streak.dart, progress_repository.dart}
lib/features/tutor/{tutor_repository.dart, tutor_screen.dart}
supabase/migrations/20261002000000_init.sql
supabase/seed/a1.sql, supabase/seed/a2.sql
supabase/tests/*.sql               plain-SQL assertion scripts
supabase/functions/tutor/index.ts
supabase/functions/tutor/prompt.ts
tools/tutor_eval.md                20 evaluation prompts + scoring sheet
.github/workflows/keepalive.yml
test/... mirrors lib/features
```

---

### Task 1: Project cleanup, localization, router shell, adaptive welcome

**Files:**
- Modify: `pubspec.yaml`, `lib/main.dart`
- Create: `l10n.yaml`, `lib/app/{app,router,theme,env}.dart`, `lib/l10n/app_{kk,ru,en}.arb`, `lib/features/welcome/welcome_screen.dart`
- Delete: `test/widget_test.dart`
- Test: `test/features/welcome/welcome_screen_test.dart`

**Interfaces:**
- Produces: `uiLocaleProvider` (`StateProvider<Locale>`, persisted with shared_preferences key `ui_lang`); `AppRoutes` constants `welcome, signIn, signUp, onboarding, home, topics, topic, cards, quiz, review, result, tutor, profile`; `appRouterProvider`.

- [ ] **Step 1:** In `pubspec.yaml` remove the `Inter-Regular.otf` and `Inter-Bold.otf` entries (keep `inter-extra-bold.otf`, weight 800); add `flutter_localizations` (sdk), `intl`, `flutter_riverpod`, `go_router`, `supabase_flutter`, `shared_preferences`; set `flutter: generate: true`. Create `l10n.yaml` with `arb-dir: lib/l10n`, `template-arb-file: app_ru.arb`, `output-localization-file: app_localizations.dart`.
- [ ] **Step 2:** Create the three ARB files. Keys needed now: `greeting` (СӘЛЕМ! / ПРИВЕТ! / HELLO!), `register` (тіркелу / регистрация / register), `login` (кіру / войти / login). Later tasks add keys to all three files together.
- [ ] **Step 3: Write the failing widget test** `welcome_screen_test.dart`:
  - `shows Kazakh greeting by default` → `find.text('СӘЛЕМ!')` findsOneWidget.
  - `language button cycles kk → ru → en → kk` → tap `Key('lang-switch')` once → `ПРИВЕТ!`; twice more → `СӘЛЕМ!`.
  - `fits a 360x640 screen` → `tester.view.physicalSize = Size(360, 640)`, devicePixelRatio 1 → `tester.takeException()` is null (no overflow).
- [ ] **Step 4:** Run `flutter test test/features/welcome` → FAIL (screen missing).
- [ ] **Step 5:** Implement `WelcomeScreen` as a centered `Column` (background `assets/leftsun.jpg` cover, max content width 320, buttons full width of the column, height 47, radius 10). Buttons navigate to `AppRoutes.signUp` / `AppRoutes.signIn`. Language button `Key('lang-switch')` cycles `uiLocaleProvider`.
- [ ] **Step 6:** `lib/main.dart`: `await Supabase.initialize(url: Env.supabaseUrl, anonKey: Env.supabaseAnonKey)`, then `runApp(ProviderScope(child: App()))`. `Env` reads `String.fromEnvironment('SUPABASE_URL')` / `('SUPABASE_ANON_KEY')`.
- [ ] **Step 7:** Run `flutter test` and `flutter analyze` → all pass, no issues.
- [ ] **Step 8:** Commit `chore: clean project, add l10n and router, adaptive welcome screen`.

### Task 2: Supabase schema, RLS, profile trigger, streak RPC

**Files:**
- Create: `supabase/migrations/20261002000000_init.sql`, `supabase/tests/00_auth_stub.sql` (local testing only), `supabase/tests/10_streak.sql`, `supabase/tests/20_rls.sql`

**Interfaces:**
- Produces tables exactly as spec §6 plus: `levels.content_version int not null default 1`; `word_progress` PK `(user_id, word_id)`; `profiles.level_code` nullable (null = onboarding not finished); `learning_lang text check (learning_lang in ('ru','en','zh'))`, `ui_lang check in ('kk','ru','en','zh')`.
- Produces RPC `record_activity(p_local_date date) returns table(streak int, last_active_date date)` (security invoker, uses `auth.uid()`).
- Produces RPC `upsert_progress(p_word_id bigint, p_box int, p_due_at timestamptz, p_correct boolean) returns void` — increments `correct_count` or `wrong_count`, sets box/due_at/updated_at.
- Trigger `on_auth_user_created` inserts `profiles(user_id, display_name)` with `display_name = coalesce(raw_user_meta_data->>'display_name', split_part(email,'@',1))`.

- [ ] **Step 1: Write SQL tests** (`10_streak.sql`, using `do $$ ... assert ... $$`):
  - first call on 2026-10-02 → streak 1.
  - second call same date → streak 1 (unchanged).
  - call 2026-10-03 → 2.
  - call 2026-10-05 → 1 (gap).
  - call with a date earlier than `last_active_date` → unchanged (clock skew guard).
- [ ] **Step 2: Write RLS tests** (`20_rls.sql`): as user A (`set local role authenticated; set local request.jwt.claims = '{"sub":"<A>"}'`) can select own profile, cannot select B's profile/word_progress/chat_messages; anonymous can select `topics`, `words`, `translations`, `levels`; authenticated can insert into `content_reports` but select returns 0 rows.
- [ ] **Step 3:** Run against local Postgres: `psql -f supabase/tests/00_auth_stub.sql -f supabase/migrations/... -f supabase/tests/10_streak.sql -f supabase/tests/20_rls.sql` → FAIL before migration exists.
- [ ] **Step 4:** Write the migration. Streak rule in `record_activity`: if `last_active_date is null` or `p_local_date > last_active_date + 1` → 1; if `p_local_date = last_active_date + 1` → +1; else unchanged (same day or earlier).
- [ ] **Step 5:** Re-run the scripts → every assert passes, exit code 0.
- [ ] **Step 6:** Commit `feat(db): schema, RLS, profile trigger, streak and progress RPCs`.

### Task 3: Pure-Dart SRS and streak logic

**Files:**
- Create: `lib/features/words/domain/srs.dart`, `lib/features/progress/streak.dart`
- Test: `test/features/words/domain/srs_test.dart`, `test/features/progress/streak_test.dart`

**Interfaces:**
- Produces `class SrsState { final int box; final DateTime dueAt; }`
- `SrsState applyAnswer(SrsState s, {required bool correct, required DateTime now})`
- `bool isLearned(SrsState s)`; `bool isDue(SrsState s, DateTime now)`
- `const srsIntervalsDays = [0, 1, 3, 7, 14, 30];`
- `int nextStreak({required int current, required DateTime? lastActive, required DateTime today})` — mirrors the SQL rule; used for optimistic UI only, server value wins.

- [ ] **Step 1: Failing tests** `srs_test.dart`: correct from box 0 → box 1, due now+1d; from box 4 → 5, +30d; from box 5 → stays 5, +30d; wrong from box 4 → box 0, due = now; `isLearned` false at 2, true at 3; `isDue` false for box 0, true for box 2 with dueAt == now. `streak_test.dart`: null lastActive → 1; yesterday → current+1; today → current; 3 days ago → 1; lastActive after today → current.
- [ ] **Step 2:** `flutter test test/features/words/domain test/features/progress` → FAIL.
- [ ] **Step 3:** Implement. Dates compared by calendar day (`DateUtils.dateOnly`-equivalent in pure Dart: `DateTime(y, m, d)`).
- [ ] **Step 4:** Run → PASS.
- [ ] **Step 5:** Commit `feat(words): Leitner SRS and streak rules`.

### Task 4: Quiz builder

**Files:**
- Create: `lib/features/words/domain/models.dart`, `lib/features/words/domain/quiz_builder.dart`
- Test: `test/features/words/domain/quiz_builder_test.dart`

**Interfaces:**
- `class Word { final int id; final int topicId; final String kk; final String exampleKk; final String translation; final String? exampleTranslation; }` (translation already resolved to the learning language, see Task 6)
- `enum QuizDirection { kkToTranslation, translationToKk }`
- `class QuizQuestion { final Word word; final QuizDirection direction; final String prompt; final List<String> options; final int correctIndex; }`
- `List<QuizQuestion> buildQuiz({required List<Word> topicWords, required List<Word> levelWords, int count = 10, required Random random})`

- [ ] **Step 1: Failing tests:** 20 topic words → 10 questions, no repeated `word.id`; every question has 4 options, all distinct, `options[correctIndex]` equals the answer; question index 0, 2, 4… are `kkToTranslation`, 1, 3, 5… are `translationToKk`; topic of 3 words + level of 40 → still 4 distinct options per question and `count` capped at 3; two topic words with identical translation never both appear in one question's options; same seed → identical quiz.
- [ ] **Step 2:** Run → FAIL.
- [ ] **Step 3:** Implement: shuffle topic words with `random`, take `min(count, topicWords.length)`; distractors drawn first from the topic, then from `levelWords`, skipping any whose displayed text equals the answer or an already chosen option.
- [ ] **Step 4:** Run → PASS.
- [ ] **Step 5:** Commit `feat(words): quiz builder`.

### Task 5: Content seed A1 and A2

**Files:**
- Create: `supabase/seed/a1.sql`, `supabase/seed/a2.sql`, `content/README.md` (sources + review checklist), `content/a1.csv`, `content/a2.csv` (human-review source of truth), `tools/csv_to_sql.py`
- Test: `supabase/tests/30_seed.sql`

**Interfaces:**
- CSV columns: `level,topic_slug,topic_kk,topic_ru,topic_en,sort,kk,example_kk,ru,en,example_ru,example_en,reviewed_by`
- Topic slugs A1: `tanysu, otbasy, sandar, tagam, qala`; A2: `uaqyt, aua-raiy, oqu-jumys, sayahat, madeniet`.

- [ ] **Step 1: Failing test** `30_seed.sql`: exactly 10 topics; each has exactly 20 words; every word has `ru` and `en` translations and non-empty `example_kk`; no duplicate `kk` within a level; `levels` A1/A2 `is_available` true, others false.
- [ ] **Step 2:** Run → FAIL.
- [ ] **Step 3:** Fill the CSVs (Claude drafts, human reviews; `reviewed_by` must be non-empty before generating SQL). `csv_to_sql.py` refuses rows with empty `reviewed_by`.
- [ ] **Step 4:** `python tools/csv_to_sql.py content/a1.csv > supabase/seed/a1.sql` (same for a2); run tests → PASS.
- [ ] **Step 5:** Commit `feat(content): A1 and A2 vocabulary seed`.

### Task 6: Repositories and content cache

**Files:**
- Create: `lib/features/auth/auth_repository.dart`, `lib/features/profile/{profile.dart,profile_repository.dart}`, `lib/features/words/data/{words_repository.dart,content_cache.dart}`, `lib/features/progress/progress_repository.dart`
- Test: `test/features/words/data/words_repository_test.dart` (with a fake `ContentSource`)

**Interfaces:**
- `AuthRepository`: `Future<void> signUp(String email, String password, String displayName)`, `signIn(email, password)`, `signOut()`, `Stream<AuthState> authChanges`. Errors mapped to `enum AuthFailure { invalidCredentials, emailTaken, weakPassword, network, unknown }`.
- `Profile { userId, displayName, String? levelCode, String learningLang, String uiLang, int streak, DateTime? lastActiveDate }`; `ProfileRepository`: `Future<Profile> fetch()`, `update({String? levelCode, String? learningLang, String? uiLang})`, `Future<int> recordActivity(DateTime localDate)` (calls RPC, returns streak).
- `WordsRepository`: `Future<List<Topic>> topics(String levelCode)`, `Future<List<Word>> words({required int topicId, required String lang})`, `Future<List<Word>> levelWords(String levelCode, String lang)`, `Future<List<Word>> dueWords(String levelCode, String lang, DateTime now)`.
- `ContentCache`: stores topics/words/translations JSON per level in shared_preferences keyed `content_<level>_v<content_version>`; refetch only when server `content_version` differs.
- `ProgressRepository`: `Future<Map<int, SrsState>> forWords(List<int> ids)`, `Future<void> saveAnswer(int wordId, SrsState next, {required bool correct})` — on network failure keeps the answer in an in-memory queue and flushes it before the next successful call.

- [ ] **Step 1: Failing tests:** translation for `ru` returned when present; falls back to `en` when `ru` missing; cache hit avoids a second fetch with same `content_version`; version bump triggers refetch; `saveAnswer` failure queues and the next call flushes in order.
- [ ] **Step 2:** Run → FAIL. **Step 3:** Implement. **Step 4:** Run → PASS.
- [ ] **Step 5:** Commit `feat(data): repositories with content cache and offline answer queue`.

### Task 7: Auth screens, onboarding, router redirects

**Files:**
- Create: `lib/features/auth/{sign_in_screen,sign_up_screen}.dart`, `lib/features/onboarding/onboarding_screen.dart`
- Modify: `lib/app/router.dart`, ARB files
- Test: `test/app/router_redirect_test.dart`, `test/features/onboarding/onboarding_screen_test.dart`

**Interfaces:**
- `String? redirectFor({required bool signedIn, required Profile? profile, required String location})` (pure, in `router.dart`).

- [ ] **Step 1: Failing tests:** signed out on `/home` → `/welcome`; signed in with `levelCode == null` on `/home` → `/onboarding`; signed in with level on `/welcome` → `/home`; signed in with level on `/onboarding` → null (allowed, used from profile). Onboarding: 中文 tile and B1–C2 tiles are disabled and show «скоро»; choosing Русский then A1 calls `update(learningLang: 'ru', levelCode: 'A1')` and navigates to `/home`.
- [ ] **Step 2:** Run → FAIL. **Step 3:** Implement screens (sign-up fields: name, email, password ≥ 8 chars; each `AuthFailure` has its own ARB message). **Step 4:** Run → PASS.
- [ ] **Step 5:** Commit `feat(auth): sign-up, sign-in, onboarding and redirects`.

### Task 8: Skills hub

**Files:** Create `lib/features/home/home_screen.dart`; Test `test/features/home/home_screen_test.dart`

- [ ] **Step 1: Failing tests:** shows 6 tiles: Сөздер, Ұстаз active; Reading, Listening, Writing, Speaking with lock icon and «скоро» and no navigation on tap; header shows streak and learned-word count from providers.
- [ ] **Step 2–4:** Run FAIL → implement → PASS.
- [ ] **Step 5:** Commit `feat(home): skills hub`.

### Task 9: Words flow — topics, cards, quiz, review, result

**Files:** Create the six screens in `lib/features/words/`; Test `test/features/words/quiz_screen_test.dart`, `test/features/words/cards_screen_test.dart`

**Interfaces:** Consumes Tasks 3, 4, 6. On session end every screen calls `ProfileRepository.recordActivity(DateTime.now())` once.

- [ ] **Step 1: Failing tests:** quiz: tapping the correct option marks it green, wrong marks red and shows the correct one, «Далее» advances; after the last question the result screen shows `n/10` and the list of mistakes; `saveAnswer` called once per question with the result of `applyAnswer`. Cards: tap flips to translation; «Знаю»/«Не знаю» call `saveAnswer(correct: true/false)`; «Сообщить об ошибке» opens a text field and inserts into `content_reports`. Topics list shows «выучено X из 20» and a «Повторить (N)» button that is hidden when N = 0. `recordActivity` called exactly once per finished session.
- [ ] **Step 2–4:** Run FAIL → implement → PASS.
- [ ] **Step 5:** Commit `feat(words): topics, flashcards, quiz, review`.

### Task 10: Profile

**Files:** Create `lib/features/profile/profile_screen.dart`; Test `test/features/profile/profile_screen_test.dart`

- [ ] **Step 1: Failing tests:** shows name, email, level, learning language, UI language, streak, learned count; changing UI language updates `uiLocaleProvider` and `profiles.ui_lang`; changing level navigates through onboarding level picker; «Шығу» signs out and lands on `/welcome`.
- [ ] **Step 2–4:** FAIL → implement → PASS. **Step 5:** Commit `feat(profile): profile and settings`.

### Task 11: AI tutor

**Files:**
- Create: `tools/tutor_eval.md`, `supabase/functions/tutor/{index.ts,prompt.ts}`, `supabase/migrations/20261003000000_tutor.sql`, `supabase/tests/40_tutor_limit.sql`, `lib/features/tutor/{tutor_repository.dart,tutor_screen.dart}`
- Test: `supabase/functions/tutor/index_test.ts` (Deno), `test/features/tutor/tutor_screen_test.dart`

**Interfaces:**
- SQL `tutor_messages_left() returns int` = 30 − count of today's (UTC) `role='user'` rows for `auth.uid()`.
- Edge Function `POST /tutor` body `{ "message": string }` → `200 { "reply": string, "left": int }`; `429 { "error": "limit" }`; `503 { "error": "model_unavailable" }`.
- `buildSystemPrompt(level: string, learningLang: 'ru'|'en'|'zh'): string` in `prompt.ts` — content per spec §7.
- `TutorRepository`: `Future<TutorReply> send(String text)`, `Future<List<ChatMessage>> history()`, `Future<int> left()`.

- [ ] **Step 1: Model gate (before any code).** Write `tools/tutor_eval.md` with 20 prompts (10 A1, 10 A2; greetings, family, food, a deliberate grammar mistake to correct, a question in Russian, a question in English). Run them against `glm-4.7-flash` with the system prompt. Pass = ≥ 17/20 answers in correct Kazakh at the right level with a translation. If it fails, record the result and pick another free model before continuing.
- [ ] **Step 2: Failing tests:** SQL — 30 user rows today → `tutor_messages_left() = 0`; rows from yesterday not counted. Deno — limit reached → 429 and model not called; model throws → 503, the user message is stored, `left` unchanged on next call; success → user and assistant rows stored, reply returned, context includes at most the last 20 messages. Flutter — first open shows Ұстаз greeting; send shows reply; 503 shows «Ұстаз сейчас отдыхает» in the UI language; counter shows `left`.
- [ ] **Step 3:** Run → FAIL. **Step 4:** Implement. Store the user message with a `counted` flag set to true only after the model succeeds; the limit counts only `counted = true`. **Step 5:** Run → PASS.
- [ ] **Step 6:** Commit `feat(tutor): Ұстаз chat via edge function`.

### Task 12: Keep-alive and release checklist

**Files:** Create `.github/workflows/keepalive.yml`, update `README.md`

- [ ] **Step 1:** Workflow on `schedule: cron "0 3 */3 * *"` and `workflow_dispatch`, runs `curl -fsS "$SUPABASE_URL/rest/v1/levels?select=code&limit=1" -H "apikey: $SUPABASE_ANON_KEY"` with repo secrets.
- [ ] **Step 2:** Trigger it manually → job green.
- [ ] **Step 3:** README: what the app is, screenshots, how to run (`flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`), how to apply migrations and seeds, content sources and licence notes.
- [ ] **Step 4:** Full check: `flutter analyze`, `flutter test`, SQL test scripts, Deno tests — all green. Manual run on an Android emulator at 360×640: complete the spec §1 success path end to end.
- [ ] **Step 5:** Commit `chore: keep-alive workflow and README`.
