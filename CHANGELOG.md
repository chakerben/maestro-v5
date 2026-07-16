# Changelog

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
