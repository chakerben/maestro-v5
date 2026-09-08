# Changelog

## 5.6.0 — one worktree per branch (2026-09-09)

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
