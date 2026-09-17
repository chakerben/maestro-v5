# Changelog

## 5.9.0 — plain prompts route themselves (2026-09-17)

31 skills. Still 2 hooks, 5 agents. Everything here follows
`docs/TOOLING-AUDIT-2026-09.md` — 25 tools from the feeds, judged with the
five-question grid in `maestro-core/references/third-party-vetting.md`.

### Added

- **The router is pushed, not typed.** `maestro-core/references/routing.md`
  is the map "plain words → skill/agent" (FR/AR/EN triggers). The existing
  SessionStart hook (`memory-sync.js`) now also maintains a
  `<maestro_routing>` block in every Maestro project's CLAUDE.md from that
  file — paired-match safety, content hash so an unchanged router costs
  nothing, never appended to a foreign repo, ambiguity → no write. 9 new
  regression cases (19 total). Still one hook.
- **`maestro-dev:05-lean-code`** — Ponytail's ladder (skip → reuse → stdlib →
  platform → installed dep → one-liner → build) fused with Karpathy's four
  principles; `debt:` markers; `audit <path>` mode. Preloaded into executor,
  checker and m-architect; the checker cites the rung per finding and lists
  new `debt:` markers.
- **`maestro-pm:04-writing`** — stop-slop's tells and self-score, the
  "/ghost" and "L99" folklore reduced to what they actually mean (natural
  voice; commit to a recommendation), plus an Arabic section (formulaic
  openers, MSA vs WhatsApp register, digits, «،» «؟», Latin tokens in RTL
  text) and a French one. `rewrite` mode preserves every number and name.
- **`maestro-web:03-motion`** — GSAP (free since Webflow) + Lenis on marketing
  surfaces only; reduced-motion variant first; transforms/opacity only;
  SplitText by words never chars on Arabic; direction-aware offsets.
- `00-onboard`: context7 is now mandatory before library-specific code
  (executor rule too); `firecrawl` (official) on demand; a **vetted
  third-party** table — Impeccable skill-only with its hook refused,
  skills.sh for discovery — and the instruction not to re-suggest anything
  the audit rejected.
- `02-gardener`: skill-gap log (task-observer's idea, no always-on skill).
- `docs/TOOLING-AUDIT-2026-09.md` — the record: 10 absorbed, 4 recommended,
  9 rejected with mechanism-level reasons (claude-mem 6 hooks + daemon + LLM
  in Stop; ECC 21 hooks with Prettier/tsc in PostToolUse; Omniroute model
  switching; Composio overlap + repricing; Meetily has no MCP…), 2 later
  (Strix pentest, Motion AI Kit).

### Changed

- `04-scaffold` writes the routing block from `references/routing.md`
  instead of an inline copy.
- `/maestro` menu says it out loud: you never need the menu.

## 5.8.0 — three skills for the daily loop (2026-09-17)

28 skills (with `03-worktree`, merged from origin — see below). Still 2 hooks, 5 agents.

### Added

- **`maestro-dev:04-debug`** (router, 4 actions) — reproduce → isolate →
  cause → fix. Binding: nothing in the source is edited before a repro exists
  that fails on demand; the cause and the symptom are named separately with
  file:line; the regression test is written red before the fix; defects met
  on the way go to `03-ticket`, never fixed in passing. State in
  `maestro_docs/tasks/<folder>/debug.md` (`reproducing | isolating |
  cause-found | fixed | not-reproducible`). Was on the roadmap since 5.3.
- **`maestro-pm:03-ticket`** (contract) — a finding becomes one Trello card:
  🔴🟠🟡⚪ priority as first character, four sections (Repro · Attendu ·
  Critères · Pistes), labels `quality`/`fast` (+`rtl`), `Trouvé : repo@sha`
  trailer, never an AI attribution. All cards are drafted, shown as a batch,
  approved once, then created through the connected Trello tool; with no
  Trello tool they land in `maestro_docs/tickets/` and the skill says so.
  Board and list are plugin `userConfig` (`TRELLO_BOARD`, `TRELLO_LIST`,
  default `À faire V1`). The skill never fixes the code — that is the point.
- **`maestro-mobile:03-store-release`** (contract, `disable-model-invocation`)
  — go/no-go submission checklist in `maestro_docs/releases/`: Build and
  Compliance are blocking, KSA section (Hijri, SAR, numerals, +966 OTP,
  regulatory notices, charity licence for donation apps), Arabic screenshots
  taken in RTL with real content, a rejection text mapped back to the item it
  violates. `GO` only with zero ❌. Was on the roadmap since 5.4.

### Changed

- `release.sh` step 0b: switches `gh` to the `chakerben` account (override with
  `MAESTRO_GIT_USER`), pins `credential.username` in the repo's local git
  config, and refuses to run without a commit author. Multi-account machines
  no longer push with whichever account happened to be active.
- `checker` separates in-scope from out-of-scope findings; `00-sdlc/04-review`
  routes the second list to `03-ticket` instead of folding it into the
  iteration loop.
- `/maestro` menu, READMEs and plugin descriptions list the three skills.

### Merged from origin/main — 2026-09-09, "one worktree per branch" (pushed as an unreleased "5.6.0" from another machine; the tag v5.6.0 is the audit release below, this work ships in 5.8.0)

- **`maestro-vcs:03-worktree`** — a repository is routinely open in several
  sessions at once (Claude, editor, terminal). In that directory `git switch`
  moves the branch for everybody and `git commit -a` sweeps up the neighbour's
  staged work — both hit us for real while shipping a landing-page PR next to a
  session mid-rename on the admin pages. The skill states the rule (the main
  checkout stays on the default branch, every branch gets its own worktree) and
  drives it through three actions, each with its `## Test`.

- **`scripts/gwt`** — the tool the skill calls, installed to `~/.local/bin/gwt`
  by `install-shortcuts.sh` (symlink, so a marketplace update updates the tool),
  plus the `/wt` shortcut and the `git wt` alias. It carries what makes a
  worktree usable — worktree placed outside the repo, `node_modules` symlinked,
  and the files git does NOT carry copied (`.env*`, `CLAUDE.md`, `AGENTS.md`,
  `.mcp.json`, `.claude/*.local.json`; all ignored, so a worktree was born
  without project instructions or granted permissions) — and three traps found
  by using it:
  - the branch is created `--no-track`, otherwise it follows `origin/<default>`
    and a bare `git push` aims at the default branch;
  - the base is the LOCAL default branch when it is ahead of origin (this repo
    had four unpushed commits — branching from `origin/main` silently amputated
    them);
  - the clean-worktree check ignores what `gwt` itself provisioned, since in a
    repo where `node_modules` is not ignored the symlink alone blocked removal.

- **`maestro-vcs:00-commit`** — the gate opens with an ownership check: foreign
  changes in the tree mean commit by explicit paths (`git commit -F msg -- paths`,
  options before `--`), never `-a`, never a `git switch` to make a precondition
  pass. `01-pull-request` says the same for the default-branch refusal.

- **`maestro-core:00-onboard`** — new projects are scaffolded with the
  convention already written in `patterns.md`, so it is readable before the
  first commit rather than after the first collision.

## 5.7.0 — the platform does the enforcing (2026-09-17)

Every item uses a documented Claude Code plugin/skill/agent feature that
Maestro was not using. No new hook (still 2). No new orchestration layer.

### Added

- **`!` live state in five skills.** `00-commit`, `01-pull-request`,
  `02-release`, `04-doctor`, `00-quality-gate` compute what they need at
  invocation — staged diff, secrets verdict, gate level, runner, commits since
  the last tag, installed plugins, v4 leftovers — before the model reads the
  skill. Philosophy rule **2b** names the principle: *what a skill must know, it
  computes.* Each of these declares `allowed-tools` so the injection cannot be
  aborted by a permission prompt; `validate.js` refuses a `!` without it.
- **`scripts/secret-scan.sh`** (in `00-commit`): the executable form of
  `secret-patterns.md` — parses the table, scans added lines of the staged diff
  (`cached`) or of the whole branch (`branch [base]`), masks matches, lists
  `gate:allow` lines separately for the `Gate-Allow:` commit trailer, always
  exits 0 so it can be injected. 8-case suite in `npm test`.
- **Agents preload the skills they are told to apply** (`skills:`): executor
  gets web/mobile standards + rtl-i18n, checker and m-i18n-checker get
  rtl-i18n, m-architect gets web-standards. Reviewers carry
  `disallowedTools: Write, Edit, MultiEdit, NotebookEdit` on top of their
  `tools:` allowlist, and `maxTurns` (checker 30, i18n 20, devil 15). `effort`
  set per agent (opus reviewers/architect `high`).
- **`paths:` on the three background-knowledge skills** (`00-web-standards`,
  `01-ux-standards`, `00-mobile-standards`): they load when Claude touches
  matching files, not when a description happens to match.
- **`dependencies` in plugin.json**: maestro-dev → core, vcs, quality;
  quality → vcs; web/mobile/pm → core. The platform enables them together, so
  the "if maestro-vcs is installed" branches in `05-ship` and `02-execute`
  are gone — a phase can no longer land through a bare `git commit`.
- `effort: high` on brainstorm, plan; `effort: low` on condense;
  `model: opus` + `effort: high` on security-audit; `arguments: [action, level]`
  on quality-gate.
- `npm run test:platform` → `claude plugin validate --strict` on each plugin
  (needs the CLI; not in CI yet).

### Validator

`validate.js` now also checks: `dependencies` name plugins of this
marketplace; `skills:` preloads in agents name existing `plugin:skill` ids;
reviewers list Write/Edit in `disallowedTools` and carry `maxTurns`; a `!`
injection comes with `allowed-tools`; hooks declared in any skill/agent
frontmatter count against rule #1.

### Deliberately not used

Monitors, `prompt`/`agent` hooks, channels, output styles, `context: fork`
on the audit skills and `isolation: worktree` on the executor — the last two
are worth trying on one project before they become framework policy.

## 5.6.0 — audit fixes (2026-09-17)

Everything below comes from `docs/AUDIT-5.5.0.md`; the letters are its item ids.

### Fixed — the framework now does what it says

- **B-1 · Phase commits go through the secrets gate.** `02-implement` committed
  each phase with a bare `git commit`; the "never skippable" scan in
  `maestro-vcs:00-commit` only ever saw the near-empty diff at ship time.
  `02-execute` now commits every phase via `00-commit` (or runs the scan itself
  when maestro-vcs is absent), and `01-pull-request` scans
  `git diff <default>...HEAD` before pushing — the last net before history
  becomes public. Both actions carry the `sk_live_…` test.
- **B-2 · `bash-guard.js` is an accident guard, and says so.** Header,
  PHILOSOPHY rule #1 and the metrics table now describe it as what it is:
  canonical-spelling blocking, bypassable, with `permissions.deny` as the
  enforced layer. Cheap misses closed: `rm -Rf`, `rm -rf /*`, `${HOME}`,
  trailing `# comment`, `git push -f` / `+ref`, `| sudo bash`,
  `bash <(curl …)`, `chmod -R 777` / `0777`, `dd of=/dev/…`, `mkfs`. The test
  suite (71 cases, JSON built by `JSON.stringify` — C-13) asserts the
  documented bypasses as *passing*, so any future change to that policy is
  deliberate.
- **B-3 · `validate.js` would now see v4 coming back.** Hooks are counted from
  `plugins/**/hooks*.json`, the `hooks` key of every `plugin.json`, and any
  versioned `.claude/settings*.json` (which is forbidden outright). Each hook
  must carry `${CLAUDE_PLUGIN_ROOT}` and a `timeout`. Hook scripts are scanned
  with strings and comments stripped, for `child_process`/`exec*`/`spawn*`
  and for tooling names. Reviewer agents are identified by frontmatter
  `role: reviewer` and checked against an allowlist; an agent whose file name
  looks like a reviewer without that key fails. Skill `name:` must equal the
  directory. Self-test: a `PostToolUse: npx tsc` smuggled into a plugin.json
  fails on three counts.
- **E · Rule #4 has two shapes and is enforced.** Router skill (`actions/`,
  every action with `## Test`) or contract skill (`## Test` in `SKILL.md`).
  Seven skills had neither; each got a `## Test` that checks the artifact.
  `validate.js` refuses a skill with no test anywhere.
- **C-1** CI runs `npm test` instead of re-listing its steps — `check-versions.js`
  now runs on every push, not only at tag time.
- **C-2** `publish.yml` scope `@arabiipte` → `@chakerben`.
- **C-3/C-5** README no longer advertises `review, TDD, debug`; counts say 24 skills.
- **C-4** PHILOSOPHY rule #2 pointed at `maestro-dev:03-review`, which does not exist.
- **C-7/C-8** `marketplace.json`: `strict` (platform default) and `recommended`
  (undocumented, ignored) removed; the validator rejects `recommended`.
- **C-10** `release.sh` fetches `origin/main` before deciding it is not behind.
- **C-14** `03-condense` is `disable-model-invocation: true` — a persistent
  output mode is not something the model should switch on by itself.
- **C-15** `secret-patterns.md` names its executor (`grep -Ei` on added diff
  lines, POSIX ERE, `[[:space:]]`), all 15 patterns verified against samples;
  a `gate:allow` is written into the commit body as `Gate-Allow:` so it is
  visible in `git log`.

### Removed / archived

- `scripts/release-5.4.0.sh`, `scripts/update-projects-5.4.0.sh` — one-shot,
  release done (C-9).
- `migrate-v4-to-v5.sh`, `verify-migration.sh`, `setup-all.sh`
  → `scripts/archive/v4-migration/` (`install-shortcuts.sh` stays live: it
  installs `gwt`) with a README
  listing their known defects; `RUNBOOK-v5.4.0.md`, `MIGRATION-FROM-V4.md`
  → `docs/archive/` (D, C-12). The 32 projects were migrated in July; the
  only live sentence of the runbook moved to the top of `ROADMAP.md`.

### Not changed (decisions left to the owner)

- `owner.name` / `author.name`: `ARABII` → `Ben Moussa Chaker` (C-6, decided 2026-09-17).
- `m-architect` keeps `Write` (needed for tech-decisions.md); PHILOSOPHY #5
  now names it as instructed, not enforced.
- `role: reviewer` is a Maestro-side frontmatter key; the platform ignores
  unknown keys. If `claude plugin validate` ever complains, move it to a
  `<!-- role: reviewer -->` comment and adjust the validator regex.

## 5.5.0 — brainstorm (2026-08-01)

- **`maestro-dev:03-brainstorm`** — from an open idea to a recorded decision.
  Four actions, each with a `## Test` (rule #4, which 15 of the 23 existing
  skills still do not honour). State lands in
  `maestro_docs/tasks/<date>_<slug>/design.md` with `status:` frontmatter, so a
  brainstorm interrupted at question four resumes at question five.

  Absorbed from Superpowers' `brainstorming`, and deliberately diverging from it
  on five points:
  - **Description = triggering conditions only.** Superpowers' own
    `writing-skills` establishes that a description summarising the workflow
    creates a shortcut agents take instead of reading the body — and its
    `brainstorming` description does exactly that ("You MUST use this before any
    creative work…"), which also makes it hijack every request.
  - **Recipes instead of prohibitions.** Their measured A/B: the prohibition arm
    produced *more* of the unwanted content than the no-guidance control. So the
    one-question rule is written as a recipe — ask, wait, journal, choose the
    next from what changed — not as "never ask two questions".
  - **An explicit off-ramp.** Superpowers routes every change through a design,
    "a todo list, a single-function utility, a config change — all of them". A
    skill with no exit is a skill people learn to route around. Three stated
    conditions send the request straight to `01-plan`.
  - **The discipline leaves evidence.** Each journal entry carries a `Change :`
    line, and the stop condition is falsifiable — stop when no remaining unknown
    changes the shape, and name the ones left open. The `## Test` sections check
    the artifact rather than trusting the process.
  - **Routed handoff, four destinations.** Superpowers has exactly one terminal
    state (`writing-plans`) and no path for "we shouldn't build this". Here the
    exit follows what the journal surfaced: `maestro-pm:00-prd`,
    `maestro-pm:02-specs` / `m-architect`, `maestro-dev:01-plan`, or `dropped`.

  Also, unlike Superpowers, the adversarial pass is a real model-pinned agent
  (`m-devil-advocate`, no Edit/Write) rather than the same context arguing with
  itself — with their anti-pre-judging rule applied to the prompt that summons it.

- **Honest plugin descriptions.** `maestro-dev` advertised `TDD, debug,
  brainstorm` in both its manifest and the marketplace entry; only three skills
  existed. Descriptions drive routing, so promising absent capabilities sends
  the model looking for skills that are nowhere. They now list what ships.

## 5.4.0 — Audit fixes + owner move (2026-08-01)

### Breaking: the repository and the npm package moved owner

- Repo: `arabiipte/maestro-v5` → **`chakerben/maestro-v5`**. GitHub redirects the
  old URL, so an existing clone and `claude plugin marketplace update maestro`
  keep working — but re-point them, redirects are a courtesy, not a contract:
  `git remote set-url origin https://github.com/chakerben/maestro-v5.git`
  and re-add the marketplace from the new path.
- npm: `@arabiipte/maestro` → **`@chakerben/maestro`** on GitHub Packages. A
  package scope does NOT follow a repo transfer — this is a new package, starting
  at 5.4.0. The old scope keeps the 5.3.x releases and the archived v4.
- `~/.npmrc` needs the new scope line:
  `@chakerben:registry=https://npm.pkg.github.com`
- The marketplace NAME is unchanged (`maestro`), so `enabledPlugins` entries in
  the 32 migrated projects (`maestro-core@maestro`…) are untouched.

### Fixed — from the 5.3.1 adversarial audit

Every item below was a reproduced corruption, not a hypothetical; each now has a
regression test.

- **memory-sync: stop destroying CLAUDE.md.** The block was located by two
  unpaired `indexOf` calls, so a mention of `<maestro_memory>` in prose deleted
  everything up to the real closing tag, and a closing tag appearing first made
  the hook append a new block every session, forever. The block is now matched
  as a pair, anchored on its own line; 0 or >1 matches, or any stray tag, means
  the hook bails without writing. A stale block costs a sync — a wrong edit
  costs the user's file.
- **memory-sync: atomic, serialised write.** Read-modify-write with no lock
  corrupted CLAUDE.md in 4 of 200 concurrent-session trials (once 45 KB → 89
  bytes), and readers could observe a 0-byte file. Now tmp + rename under a
  lockfile with a stale timeout; 40 concurrent pairs, zero corruption.
- **memory-sync: filename injection, symlinks, unbounded lists.** Entry names
  are validated before interpolation (a filename containing a newline could
  inject instructions into CLAUDE.md); a symlinked CLAUDE.md is left alone; the
  on-demand list is capped at 200 entries.
- **migrate-v4-to-v5: back up what is actually touched.** `.claude/settings.json`,
  `CLAUDE.md` and `maestro_docs/memory-bank` were rewritten or deleted without a
  copy. All three are now in the backup list — the four worst migration failures
  become recoverable.
- **migrate-v4-to-v5: reject unknown options.** `--dryrun`, `-n`, `--dry` were
  silently taken as project names with `DRY_RUN=0` — a typo'd dry run deleted
  files for real. Unknown `-*` now exits 2.
- **PHILOSOPHY rule #5 says what is true.** Reviewer agents carry no Edit/Write,
  which the platform enforces — but `checker` also carries `Bash`, which can
  write. The gap is now named in the rule and in `checker.md`, instead of being
  described as physically prevented.
- **CI: 10-case memory-sync regression suite** replaces the previous
  `grep -q maestro_memory` smoke test, which passed under every bug above.
  Wired into `npm test`.
- **`scripts/check-versions.js`**: the version lives in 9 files by hand (5.2.1
  already shipped one alignment incident). `npm test` now fails on drift, and on
  a tag build it also fails if `v<tag>` and `package.json` disagree.

## 5.3.1 — Field feedback from the 32-project rollout (2026-07-14)

- scripts/verify-migration.sh: batch doctor — runs the contraband/structure
  checks across every project at once (used to validate the full migration:
  32 green, 0 contraband)
- scripts/install-shortcuts.sh: 20 short personal commands (/sdlc, /check,
  /garden, /ship, /rtl...) installed in ~/.claude/commands — no plugin
  namespace, avoids Claude Code built-in collisions (/doctor, /memory, /review)
- migrate-v4-to-v5.sh: Flutter detection via pubspec.yaml (maestro-mobile
  now auto-enabled on Flutter projects)


## 5.3.0 — Official-guidelines conformity (2026-07-14)

Audit against current Claude Code official skill/agent/hook guidance.
Every Philosophy rule that was "instructed" is now ENFORCED by the platform:

- Agents: reviewer agents (checker, m-devil-advocate, m-i18n-checker) carry a
  `tools:` allowlist WITHOUT Edit/Write — the platform physically prevents
  them from modifying code. m-architect gets Write for docs only. validate.js
  now fails CI if a reviewer agent gains edit tools.
- Skills invocation control per official guidance: `disable-model-invocation`
  on 02-release (deliberate human act — Claude can never decide to release);
  `user-invocable: false` on the three standards skills (background knowledge,
  auto-applied, hidden from the / menu to reduce noise).
- Read-only-by-design audit skills (security-audit, perf-audit, design-review)
  declare `allowed-tools: Read, Grep, Glob, Bash`.
- Hooks: platform `timeout` added (memory-sync 10s, bash-guard 5s) — rule #3
  is now runtime-enforced, not just promised.
- Onboard matrix: + playwright (the mandated route for Arabic RTL PDFs and E2E).
- PHILOSOPHY rule #5 updated: "Enforced, not just instructed".
- setup-all.sh: user-scope officials now include code-review and
  pr-review-toolkit; optional pyright-lsp prompt; per-project officials
  (security-guidance, expo, playwright, figma) delegated to onboard.
- migrate-v4-to-v5.sh: post-migration guide now includes the onboard
  official-plugins step per project.


## 5.2.4 — Final pre-rollout audit (2026-07-14)

Second adversarial audit. Fixed:
- macOS bash 3.2 crash: empty-array expansion under set -u in
  migrate-v4-to-v5.sh (--list with zero detections crashed on stock macOS bash)
- npm deprecate: broken quoting produced a literal-quotes argument; added
  explicit --registry for GitHub Packages (deprecate ignores publishConfig)
- /maestro menu: stale "(Phase 2/3)" labels replaced with the full, real
  skill map including quality, mobile, web, pm, delivery entries
- sdlc 05-ship: stale "until Phase 3" mention removed
- README: real install path (arabiipte/maestro-v5); *.tgz gitignored
- Verified: custom (non-Maestro) hooks preserved during migration;
  end-to-end migration re-tested post-fix

Ecosystem optimizations:
- onboard matrix: + code-review, pr-review-toolkit (recommended), skill-creator (optional)
- docs/ROADMAP.md: v5.3/v5.4 candidates + official-ecosystem watchlist (rule #8)


## 5.2.3 — Publication tooling (2026-07-14)

- package.json: npm publication to GitHub Packages as @arabiipte/maestro
  (validated via npm pack: 91 files)
- .github/workflows/publish.yml: auto-publish on v* tag (validates first)
- scripts/setup-all.sh: master script — GitHub publish, npm publish,
  v4 deprecation, global setup (marketplace + official plugins + LSP binary
  + v4 global uninstall), then guided project migration (pilots/all/dry-run)


## 5.2.2 — Migration tooling (2026-07-14)

- scripts/migrate-v4-to-v5.sh: automated per-project migration (backup,
  v4 cleanup preserving custom hooks, memory-bank mapping, gates level
  preservation, stack-based plugin activation with claude-CLI + settings
  fallback, routing injection, verification). Tested: dry-run, real run,
  dirty-tree refusal, idempotence, web and mobile stack detection.
- docs/MIGRATION-FROM-V4.md rewritten around the script + rollout waves.


## 5.2.1 — Deep recheck (2026-07-14)

Adversarial audit before pilot rollout. Fixed:

- bash-guard: 5 bugs — separate rm flags (-r -f) not caught, long flags
  (--recursive --force) not caught, path-prefixed .env reads slipping
  through (cat apps/web/.env), false positives on rm -rf of home SUBpaths
  and on .env.example/.sample/.template. Now guarded by a 34-case test
  suite (scripts/tests/bash-guard.test.sh) wired into CI.
- bash-guard: added head/tail/less/more/bat to secret-file readers; split
  env-var echo rule.
- validate.js: hooks.json parsed safely (was crashing on invalid JSON),
  ${CLAUDE_PLUGIN_ROOT} enforced, agents/commands frontmatter validated
  (name/description/model).
- design-review: RTL pass no longer hard-depends on maestro-mobile being
  installed (graceful fallback checks).
- memory-sync: verified idempotent, add/remove tracking, content-after-block
  preservation, non-Maestro projects untouched, 28ms (7-case audit).
- Versions aligned to 5.2.1 across marketplace + all plugin manifests;
  stale READMEs and .gitkeep files cleaned.


## 5.2.0 — Phase 3: business layer (2026-07-14)

- maestro-vcs: 00-commit (secrets scan 15+ patterns, gate levels, recorded
  bypasses), 01-pull-request, 02-release
- maestro-quality: 00-quality-gate (gates.json), 01-security-audit,
  02-perf-audit
- maestro-mobile: 00-mobile-standards, 01-rtl-i18n (+ rtl-checklist),
  02-pdf-rtl — the Arabic-grade expertise layer
- maestro-web: 00-web-standards, 01-ux-standards, 02-design-review
- maestro-pm: 00-prd (+ template), 01-user-stories, 02-specs
- maestro-dev: m-i18n-checker agent
- sdlc 05-ship now finds maestro-vcs:00-commit installed


## 5.1.0 — Phase 1+2 core (2026-07-14)

- maestro-core: 01-memory, 02-gardener, 04-doctor fully implemented (actions)
- maestro-core: /maestro discovery command; routing block installed by onboard
- maestro-dev: 00-sdlc orchestrator with interactive/auto modes and hard stops
- maestro-dev: 01-plan (gather/explore/plan + state templates), 02-implement
  (fresh-context phase loop, assertion gates, one commit per phase, resume)
- maestro-dev: expert-postures and cognitive-protocols references
- Doctor 01-check flags v4/claude-flow contraband (the RAM-crash guards)


## 5.0.0 — Phase 0 (2026-07-14)

Initial marketplace skeleton.

- Marketplace manifest with 7 plugins (core, dev, quality, mobile, web, pm, vcs)
- PHILOSOPHY.md: the 8 golden rules
- maestro-core: 00-onboard skill (stack detection + official plugin installation),
  SessionStart memory-sync hook
- maestro-quality: PreToolUse bash-guard hook (Node, <20ms)
- CI: JSON validation + structure checks
- Docs: architecture, migration guide from v4

Breaking vs v4: all 14 runtime hooks removed. Quality moved to workflow
(commit/review gates). Distribution via marketplace instead of file propagation.
