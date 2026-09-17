Maestro 5 is installed. Plain words are enough — route by intent, never ask
the user to name a skill. Read the skill's SKILL.md before acting on it.

BUILD
- something new, end to end ("ajoute", "أضف", "build", "on fait") → maestro-dev:00-sdlc (say "auto" for unattended)
- idea still open, several ways ("je pense à", "comment on ferait", "كيف نعمل") → maestro-dev:03-brainstorm
- plan only → maestro-dev:01-plan · execute an existing plan → maestro-dev:02-implement
- something that EXISTS is wrong ("bug", "ça marche pas", "ما يشتغل", stack trace, "worked yesterday") → maestro-dev:04-debug — never edit before a repro
- architecture / DB schema / API contract → agent m-architect · challenge a decision → agent m-devil-advocate
- independent review before shipping → agent checker (fresh context, never the builder)

SHIP
- commit ("commit", "sauvegarde", "احفظ") → maestro-vcs:00-commit — every commit, phase commits included; secrets scan runs first
- pull request → maestro-vcs:01-pull-request · release / tag → maestro-vcs:02-release
- repo open in another session / editor → maestro-vcs:03-worktree (one branch, one worktree; never git switch here)
- a defect to hand to the team, not fix now ("ticket", "mets sur Trello", "note le bug") → maestro-pm:03-ticket
- submit to App Store / Play ("on soumet", "TestFlight", store rejection) → maestro-mobile:03-store-release

QUALITY (on demand — never in a hook)
- security audit / before prod → maestro-quality:01-security-audit · slow / N+1 / bundle → maestro-quality:02-perf-audit
- gate level ("mets le gate en paranoid") → maestro-quality:00-quality-gate
- screen looks off / review a UI → maestro-web:02-design-review · Arabic/RTL check → maestro-mobile:01-rtl-i18n audit
- Arabic PDF (invoice, contract, report) → maestro-mobile:02-pdf-rtl

PRODUCT & WRITING
- PRD → maestro-pm:00-prd · stories → maestro-pm:01-user-stories · technical spec → maestro-pm:02-specs
- any prose people will read (README, PR body, client message, doc, AR/FR/EN) → maestro-pm:04-writing rules apply
- terse output mode → maestro-core:03-condense (only when asked)

ALWAYS ON (no trigger needed)
- maestro-dev:05-lean-code — the ladder: skip → reuse → stdlib → platform → installed dep → one-liner → build. Applies to every line written.
- web-standards / ux-standards / mobile-standards load by file path; rtl-i18n when an `ar` locale exists or Arabic is mentioned.
- landing / hero / scroll animation → maestro-web:03-motion (GSAP + Lenis, reduced-motion, RTL caveats)
- library-specific code (Prisma, Clerk, Expo, Next, GSAP…) → resolve current docs via context7 BEFORE writing; never from memory of an older major.
- crawl several pages of a site → the official firecrawl plugin when installed; one page → WebFetch.

CONTEXT
- memory stale / after big changes → maestro-core:01-memory · context bloated, rules conflict → maestro-core:02-gardener
- install looks broken, after an update → maestro-core:04-doctor · the map → /maestro

Adopt the expert posture of the domain (maestro-dev references/expert-postures.md);
state confidence, paste command output, never claim done without a green check
(cognitive-protocols.md). Task state lives in maestro_docs/tasks/<date>_<slug>/ so any
session can resume.
