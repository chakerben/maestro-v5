Maestro 5. Plain words route — never ask the user to name a skill.

PATHS
- new thing, end to end → maestro-dev:00-sdlc · idea still open → 03-brainstorm · plan only → 01-plan
- EXISTING behaviour is wrong (bug, "ça marche pas", "ما يشتغل", stack trace) → 04-debug — no edit before a repro
- every commit, phases too → maestro-vcs:00-commit (secrets scan first) · PR → 01-pull-request
- repo open in another session → maestro-vcs:03-worktree; never `git switch` in a shared dir
- defect for later ("ticket", "Trello") → maestro-pm:03-ticket
- review → agent checker (fresh context) · architecture → m-architect · challenge → m-devil-advocate · stuck (bug, choice) → m-analyst

ALWAYS ON
- lean-code ladder on every line: skip → reuse → stdlib → platform → installed dep → one-liner → build
- library code (Prisma, Clerk, Next, Expo…) → context7 first, never memory of an older major
- `ar` or Arabic → maestro-mobile:01-rtl-i18n (Flutter too); Arabic PDF → 02-pdf-rtl · store submission → 03-store-release
- Flutter (pubspec.yaml) → maestro-mobile:04-flutter-standards by path
- project's own commit/branch/version rule (CLAUDE.md, .claude/rules/) wins; say which you followed
- prose a human reads (README, PR, client message) → maestro-pm:04-writing
- one page → WebFetch; many → official firecrawl plugin if present

MODELS
- session default sonnet; fable thinks (plan, brainstorm, architecture, hard bug), sonnet executes, fable judges (checker); opus only if critical: security, concurrency, major architecture, cross-project, sonnet+fable failed
- escalate for complexity, never length; one line on why when you switch; policy: maestro-core references/model-policy.md

STATE
- state in maestro_docs/tasks/<date>_<slug>/ (plan, phases, debug, design) — resume, never restart
- domain expert posture (maestro-dev references/expert-postures.md); state confidence; paste command output; `done` only after a green check (06-protocols)
- install looks off → maestro-core:04-doctor · map → /maestro
