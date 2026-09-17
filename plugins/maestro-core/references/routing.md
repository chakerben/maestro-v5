Maestro 5. Plain words are enough — never ask the user to name a skill. Skill
descriptions do the routing; this block holds only what a description can't.

DEFAULT PATHS
- new thing, end to end → maestro-dev:00-sdlc · idea still open → 03-brainstorm · plan only → 01-plan
- something that EXISTS is wrong (bug, "ça marche pas", "ما يشتغل", stack trace) → 04-debug — no edit before a repro
- every commit, phase commits included → maestro-vcs:00-commit (secrets scan first) · PR → 01-pull-request
- repo open in another session → maestro-vcs:03-worktree; never `git switch` in a shared directory
- a defect for the team, not for now ("ticket", "mets sur Trello") → maestro-pm:03-ticket
- review before shipping → agent checker (fresh context) · architecture → m-architect · challenge → m-devil-advocate

ALWAYS ON
- lean-code ladder on every line: skip → reuse → stdlib → platform → installed dep → one-liner → build
- library-specific code (Prisma, Clerk, Next, Expo, GSAP…) → context7 first, never memory of an older major
- `ar` locale or Arabic mentioned → maestro-mobile:01-rtl-i18n rules apply; Arabic PDF → 02-pdf-rtl
- prose a human reads (README, PR, client message) → maestro-pm:04-writing; AR register per 04-writing
- one page → WebFetch; many pages → official firecrawl plugin if installed

STATE
- task state in maestro_docs/tasks/<date>_<slug>/ (plan, phases, debug, design) — resume, never restart
- expert posture of the domain (maestro-dev references/expert-postures.md); state confidence; paste
  command output; `done` only after a green check (cognitive-protocols.md)
- install looks off → maestro-core:04-doctor · the full map → /maestro
