# Changelog

## 5.13.0 — the ladder becomes real (2026-09-26)

The audit that triggered this release was one sentence from Chaker: "j'ai
l'impression qu'on utilise plus sonnet que les autres modèles". He was right,
and checking it turned up something worse than a cost preference — an
escalation that could not happen.

### Fixed

- **Four files promised an opus escalation that frontmatter cannot perform.**
  `checker.md`, `m-architect.md`, `00-sdlc/actions/04-review.md` and
  `04-debug/actions/03-cause.md` said the orchestrator would dispatch the agent
  "with `model: opus`" for a critical change. A frontmatter carries exactly one
  `model:` and a dispatch cannot override it, so `checker` was **always** fable:
  a payment, auth or concurrency change was reviewed on the same tier as a CRUD
  change, and the sentence is precisely what stopped anyone checking
  (PHILOSOPHY rule 5 — a rule described as guaranteed when it is only
  requested). `02-perf-audit` had the same gap in a softer form (it asked the
  user to type `/model opus`). All five now dispatch a real agent.

### Added

- **`checker-critical` (opus, high)** — the review agent for a critical change
  (auth, payment, security, concurrency, data migration, cross-project
  contract) or `gates.json` at `high`/`paranoid`. Criteria pass, then a
  failure-mode pass the fable checker does not run: unauthenticated reach,
  another tenant's id, the second/concurrent/retried call, the halfway state
  and its rollback, attacker-controlled input, money and rounding. Read-only
  tools, `maxTurns: 30`.
- **`m-deep-analyst` (opus, high)** — the rung above `m-analyst`: dispatched
  when the fable analysis came back inconclusive, or when the problem is
  critical from the start (security, concurrency/race, data loss,
  cross-project decision). Reads the previous analysis and attacks the
  assumption it did not question; states the interleaving rather than "a race".
  `04-debug`, `02-perf-audit` and `m-architect` all route their opus step here.

### Changed — the ladder

- **`executor`: sonnet → fable.** The step that writes the code was the
  cheapest step in the framework, on the lowest effort. `01-plan` (fable)
  protects a feature's global shape; it does not protect module boundaries,
  abstractions, error propagation or what becomes a shared helper — those are
  decided inside the executor, file by file, and a review can reject a
  structure but never supply one. `effort` stays `medium` on purpose: it builds
  against a plan already reasoned at `high`.
- **Explicit pins where silence used to inherit the session**: `02-implement`
  and `00-sdlc` → sonnet/medium (orchestration: dispatch, gate, commit — no
  design decision), `00-quality-gate` → sonnet/low (reads config, runs
  commands), `04-debug` → fable/medium (reproduce → isolate → cause is
  reasoning, and the fix must be surgical), `02-design-review` → fable/high
  (visual, UX and RTL judgement). Before this, 21 of 33 skills declared no
  model at all: a session on opus silently ran them all on opus, and a session
  on sonnet ran the design review on sonnet. Neither was a decision.
- The session default stays **sonnet**, and `00-onboard` keeps offering to
  write it: orchestration, commits and docs do not need more, and raising the
  session raises everything. What moved up is the work, not the session.
- Ladder headline: "Sonnet executes, Fable thinks, Opus only when critical"
  → **"Sonnet orchestrates, Fable builds and judges, Opus decides on
  critical."**

### Added — enforcement (`scripts/validate.js`, in `npm test`)

- The opus rung **must exist and be pinned to opus**: `checker-critical`,
  `m-deep-analyst`, `01-security-audit`. Delete one or demote it and `npm test`
  goes red.
- `executor` must be fable or above — the code-writing step cannot be silently
  moved back to the cheapest tier.
- **Enforced-vs-instructed guard**: any text matching "dispatch/spawn … model:
  opus" is refused, and any skill, agent, `routing.md` or `model-policy.md`
  that mentions opus must name an agent genuinely pinned to it. A doc may quote
  the forbidden phrasing in order to forbid it — the negation has to sit in the
  same clause, deliberately narrow: a permissive first version of this check
  was fooled by a "never delegate." three lines above the smuggled promise,
  which is now regression case 8b.
- 6 new cases in `scripts/tests/validate.test.sh` (29 total there): the
  fiction, the quoted counter-example, opus promised with no opus agent named,
  the executor demoted, the opus rung demoted, the opus rung deleted.
- Portability: case 6 used `sed -i '…'`, which on stock macOS (BSD sed) reads
  the expression as a backup suffix — the case stopped breaking its copy and
  passed without testing anything. Rewritten with `node`.

### Changed — docs

`docs/MODEL-POLICY.md` rewritten (why it changed, what it costs, what enforces
it), `references/model-policy.md` (the source of truth the skills read),
`references/routing.md` MODELS block (re-trimmed to stay inside the 2 000-char
session budget), `PHILOSOPHY.md` rule 5 (the ladder is now its worked example),
`README.md` (8 agents), `plugins/maestro-dev/README.md`, `/maestro` menu.

## 5.12.1 — fleet-apply portability fix (2026-09-19)

### Fixed

- **`scripts/fleet-apply.sh` — `doctor`/`scaffold` exited 127 on every project
  on stock macOS.** `run_claude()` called the bare `timeout` binary, which is
  GNU coreutils and does not ship with macOS (`command -v timeout` fails →
  `timeout: command not found` → exit 127, reported as if `claude` itself had
  failed). Fixed with `run_with_timeout()`: uses `timeout` if present, falls
  back to `gtimeout` (`brew install coreutils`), and otherwise a portable
  bash-only wrapper (background the command, `SIGTERM` then `SIGKILL` after
  the deadline, reports 124 like GNU `timeout` does) — works on any POSIX
  shell with no external dependency. New tests in `fleet-apply.test.sh` run
  `run_claude` for real (not just `--dry-run`, which never reached the
  `timeout` line and is why this shipped untested) with `timeout`/`gtimeout`
  both absent from `PATH`, covering both a fast success and a hung process
  that must be killed and reported as a timeout.
- **`scripts/lib/fleet.sh` — `$HOME` itself could be discovered as a
  "project."** `known_projects()` reads every path Claude Code has ever run a
  session in from `~/.claude.json`, which includes the home directory once a
  session has run there. `is_project()` now excludes `$HOME` explicitly
  (this is what produced the phantom 43rd project — `/Users/…` tagged
  `maestro-web` — in the first real fleet run). Test added.

## 5.12.0 — model ladder (2026-09-19)

### Added — fleet

- **`scripts/fleet-apply.sh`** — applies Maestro to every project that uses it,
  without opening 36 sessions: `--settings` (no LLM: merges the canonical
  `permissions.deny` entries and `"model": "sonnet"` into each project's
  `.claude/settings.json`, idempotent, never overwrites an existing value,
  refuses malformed JSON), `--doctor` (`claude -p "/maestro-core:04-doctor check"`,
  read-only), `--scaffold` (`claude -p "/maestro-core:00-onboard scaffold"`
  with `acceptEdits`). `--list`, `--dry-run`, `--jobs N` (default 1 — the
  fleet rule), `--model` (default sonnet: both actions are mechanical), logs
  and a `summary.tsv` under `~/.maestro/fleet/<run>/`. Project discovery moved
  to `scripts/lib/fleet.sh`, shared with `update-projects.sh`. 9 tests.

33 skills, 6 agents, still 2 hooks. One rule, applied everywhere: **Sonnet
executes, Fable thinks, Opus only when critical** — complexity picks the
model, never length. Quality stays where it was (the workflow); the expert
rate is paid only where reasoning changes the outcome.

### Added

- **`maestro-core/references/model-policy.md`** — the source of truth: ladder
  (sonnet / fable / opus), escalation and de-escalation rules, effort table,
  context discipline, fleet rule (one opus dispatch at a time across
  projects, instruction not hook), and the table of what Maestro pins.
  Human version in `docs/MODEL-POLICY.md`, linked from the READMEs.
- **`m-analyst` agent** (fable, advisor, Read/Grep/Glob/Bash, never writes) —
  fresh-context analysis of a bug or a choice the session is stuck on;
  returns cause/approach + a falsifiable plan. `04-debug` action 03 spawns
  it when the cause is not found after isolation, the bug spans layers, or a
  fix failed; re-dispatched on opus only if inconclusive or critical.
- **`routing.md` MODELS block** (routing block still ≤ 2000 chars — the other
  lines were condensed, no rule lost) and **protocols rule 7** (model ladder).
- **`validate.js` "Model policy"**: every agent pins `sonnet | fable | opus |
  inherit`; an opus pin must say `critical` or `security` in its body;
  `01-plan`, `03-brainstorm`, `m-architect`, `m-analyst`, `checker` must be
  fable. Two negative cases in `validate.test.sh` (18 cases).
- **Onboard `04-scaffold` step 4c** offers `"model": "sonnet"` in
  `.claude/settings.json` (never overwrites an existing value); **doctor**
  flags 🟡 a session default that is not sonnet.

### Changed

- **Pins**: `checker`, `m-architect`, `m-devil-advocate` opus → **fable**
  (checker and architect state the opus escalation: critical change or gate
  level high/paranoid, named in the verdict header); `01-plan`,
  `03-brainstorm`, `maestro-pm:00-prd`, `02-specs` → `model: fable`;
  `maestro-quality:02-perf-audit` → fable/high, opus only for concurrency or
  inconclusive complex perf; `04-debug` effort high → medium (classic bugs
  are sonnet work), `02-implement` effort medium. `01-security-audit` stays
  opus. `00-sdlc/04-review` reads `gates.json` and picks the checker's model,
  saying why in one line; `02-plan` names the devil-advocate's model.
- Checker body trimmed to stay within the 6000-char dispatch budget with
  the new rule (PHILOSOPHY rule 5 link → name only; no rule dropped).

## 5.11.0 — independent deep audit, 30 findings closed (2026-09-19)

33 skills (+`maestro-dev:06-protocols`), 5 agents, still 2 hooks. An external
pass read every file, ran `npm test`, and reproduced each defect before it was
listed (`docs/AUDIT-5.10.0.md`). Test cases 134 → 202. Nothing in this
release changes what the framework promises; it makes the promises true.

### Fixed — things that could not work as written

- **maestro-dev**: every `../references/…` path was one level off
  (`skills/references/` does not exist) — now `${CLAUDE_PLUGIN_ROOT}/references/…`.
  `04-review` asked the `checker` to write `review.md` while denying it Write:
  the checker now **returns** the structured verdict and the orchestrator
  writes the file. The secrets fallback pointed at `${CLAUDE_PLUGIN_ROOT}/../maestro-vcs`,
  a path that does not exist in the plugin cache: `02-implement` ships its own
  mirror of `secret-patterns.md` (`validate.js` fails if it drifts) and 05-ship /
  04-debug use the same fallback. `00-sdlc` and `maestro-pm:02-specs` agreed on
  where the spec lives: `tasks/<date>_<slug>/spec.md` always, `specs/spec-<slug>.md`
  only for a new table/collection, external contract or auth change, linked from it.
- **secret-scan.sh**: 91 s → 0.03 s on 3 000 added lines (one `grep` pass over
  a `file<TAB>line<TAB>content` extract instead of 3 forks × 15 patterns per line).
  `\ No newline at end of file` no longer shifts line numbers; quoted (non-ASCII)
  paths are de-quoted; `gate:allow` accepted as `//`, `#`, `--`, `/* */`, `<!-- -->`,
  anchored at end of line, with any secret in the reason masked. Perf test added.
- **secret-patterns.md**: unquoted credentials (`DB_PASSWORD=…` in `.env`/YAML)
  are caught; placeholders (`example`, `changeme`, `<your-…>`, `${…}`) are not;
  added GitHub `gh[opsru]_`, GitLab, npm, SendGrid, Supabase, Twilio, Sentry DSN.
- **bash-guard.js**: `git commit -m "fix: chmod 777 removed"` no longer blocked
  (quoted strings are blanked for the rm / curl|sh / chmod rules only — the
  .env / secret-echo / push rules still read the raw command); now also blocks
  pipes into `/bin/bash`, `python`, `perl`, `node` and writes to
  `/dev/(vd|xvd|mmcblk|rdisk)*`. 95 → 126 cases.
- **install-shortcuts.sh** aborted on `$ARGUMENTS` under `set -u` and wrote
  nothing; fixed and smoke-tested in `npm test`.
- **validate.js** rule #2 was blind to ~65 % of `memory-sync.js` (a backtick
  inside a regex literal was read as a template string): a real `execSync`
  passed. Replaced by a small JS scanner; a negative test suite
  (`validate.test.sh`, 14 cases) injects `child_process`, `dependencies`, a
  bad router reference and expects red.
- **flutter-rtl.md**: `DateFormat` does not do the Umm al-Qura calendar (use
  `hijri`/`hijri_calendar`); Material directional icons already mirror under
  RTL — `Transform.flip` on `Icons.arrow_back` double-flipped them.
- **paths were inverted on Expo Router**: `app/**` loaded the Next.js/Prisma
  rules on `app/(tabs)/index.tsx` while `00-mobile-standards` never loaded.
  Web standards now match App Router file conventions only (+ `proxy.ts`,
  Next 16); mobile standards match `app/**/*.tsx`; `01-rtl-i18n` loads on
  Arabic locale files; UX standards no longer match `.vue`/`.svelte`.
- **memory-sync.js**: file mode preserved across the atomic rewrite (600 stayed
  600), stale hash searched in the fence-masked text, symlinks in the memory
  bank ignored, 4-backtick fences containing 3-backtick fences masked correctly.

### Changed

- **`permissions.deny` is now real**: `00-onboard/04-scaffold` merges the
  canonical entries (rm -rf / ~ $HOME, curl|sh, wget|sh, git push --force) into
  the project's `.claude/settings.json`; `04-doctor` flags their absence.
  `bash-guard.js` header names that layer instead of promising it.
- **`maestro-dev:06-protocols`** (contract skill, ~250 tok) carries the six
  cognitive rules and is preloaded by all five agents — "binding" is now true.
  `m-i18n-checker` carries a standalone RTL mini-checklist, invokes
  `maestro-mobile:01-rtl-i18n` when installed, and is actually spawned by
  `04-review` when an `ar` locale exists. `executor` gets
  `disallowedTools: Task, Agent`; `m-architect` gets `Edit` (append, never
  rewrite `tech-decisions.md`) and reads the stack from the project instead
  of a hardcoded Next/Prisma list. `plan.md` persists `mode:` and
  `iterations:`; review findings become `phase-N+1.md`.
- **Doctor vs onboard**: hooks counted in three buckets — Maestro (≤ 2),
  official plugins (allowed, listed), other (smuggled). Injections test
  existence before piping; malformed JSON is reported as malformed.
- **maestro-mobile**: `03-store-release` is invocable by the model again (the
  human GO is already in the process) and routed; version injection reads
  `app.json` → `expo config` → `pubspec.yaml` → `build.gradle` and honours
  `eas.json appVersionSource: remote`; checklist gains Apple SDK minimum,
  Play `targetSdk`, 16 KB page size, ATT, account-deletion URL,
  `ITSAppUsesNonExemptEncryption`; the tag is created after GO, not before.
  `android:supportsRtl` / Expo `supportsRTL` added. New Architecture replaces
  the Hermes note. `references/zatca.md` (QR TLV phase 1, UBL phase 2) for
  KSA invoices; `references/sar.md` + `assets/sar-icon.svg` replace the
  never-shipped `SarIcon`; U+20C1 documented. Firebase/platform-channel
  sections of `04-flutter-standards` moved to a reference.
- **maestro-web**: `03-motion` gets rung 0 "CSS scroll-driven /
  `@starting-style` first"; design-review criticals go to `maestro-pm:03-ticket`.
- **maestro-pm**: PRD and card templates now exist in EN/FR/AR as the
  description always claimed; `02-specs` is stack-agnostic (Prisma diff or
  Firestore collections, Zod or Dart models); `04-writing` AR/FR sections
  moved to references and its own prose follows its em-dash rule.
- **maestro-vcs**: one path for the scan (`${CLAUDE_PLUGIN_ROOT}/skills/00-commit/scripts/secret-scan.sh`);
  PR base resolution tries `master` too; `02-release` bumps the stack's
  version file and ignores non-semver tags; worktree fallback no longer
  hardcodes the marketplace cache path.
- **Tooling**: `release.sh` commits an explicit file list (no `git add -A`)
  and only touches `gh auth` when `MAESTRO_GIT_USER` is set; `prune-installed.sh`
  sees a `claude` run through node and refuses an unknown schema; CI runs
  commitlint on push and the bash suites on macOS; hook budget relaxed to
  250 ms under `CI`; npm package no longer ships `release.sh` and the audits.
  `validate.js` also checks that every `plugin:skill` and agent named in
  `routing.md`, `/maestro` and `install-shortcuts.sh` exists, warns on
  undocumented frontmatter keys (against the documented list), and keeps the
  dev mirror of `secret-patterns.md` byte-identical.
- All brainstorm/design templates in English (plan and debug already were);
  `design-template.md`, Flutter RTL reference and `01-rtl-i18n` Flutter section translated.

### Not done (on purpose)

- The first real feature through `/sdlc` (ROADMAP prerequisite) still has to
  run on a real project — that pilot, not `npm test`, would have caught #1–#3 above.
- `sar-icon.svg` is a simplified geometric rendering; swap in the official
  SAMA artwork if brand fidelity matters.

## 5.10.0 — Flutter, and deference to the project (2026-09-17)

32 skills. Still 2 hooks, 5 agents. Written against a real Flutter codebase
(a mosque audio-streaming app: GetX, Firebase with a named database,
WebSocket PCM16 capture, Android PiP, 129 inline `isArabic ? … : …`
ternaries and no ARB file), not from a template.

### Added

- **`maestro-mobile:04-flutter-standards`** — structure (a 400-line screen is
  a refactor), state outside widgets whatever the library, and the section
  that matters: **async & lifecycle** — every subscription/timer/controller
  disposed, `mounted` after every `await`, foreground-service and wakelock
  discipline, stream `onError`. Plus named Firebase instances behind one
  accessor (`FirebaseFirestore.instance` in a project with a custom
  `databaseId` is a silent wrong-database bug), platform-channel bridging,
  perf, secrets. Loads by `paths` on `pubspec.yaml` / `lib/**.dart`.
- **`01-rtl-i18n` gains a Flutter section** — none of the web rules transfer:
  `EdgeInsetsDirectional`/`AlignmentDirectional`/`PositionedDirectional`, ARB
  + `gen_l10n` (with the `isArabic ? … : …` ternary named as the anti-pattern
  and a migration path), ICU plurals for the six Arabic categories, and the
  font trap — a Latin family (Space Grotesk, Inter…) has **no Arabic glyphs**,
  so Arabic silently falls back to the system font; declare Cairo/Tajawal/IBM
  Plex Sans Arabic and set `height: 1.6–1.8`. The section ships as
  `references/flutter-rtl.md` — the contract keeps a three-line pointer, so a
  non-Flutter project pays nothing for it (rule 2c, context budget).

### Changed — Maestro defers to the project it is a guest in

A client repository often has its own conventions; imposing Maestro's would
make the framework fight the codebase. Now:

- `00-commit` reads `CLAUDE.md`, `.claude/rules/*.md` and the last 20 commits
  **before composing**, follows a stated message format, version-bump rule or
  language, and says which convention it followed. Conventional commits are
  the default, not a law.
- `02-implement/01-prepare` names branches by the project's stated convention
  (e.g. `{type}/issue-{n}-{desc}`) when there is one.
- The routing block states the precedence out loud.
- `00-mobile-standards` stops claiming Flutter (it is RN/Expo only) and hands
  `pubspec.yaml` / `lib/**.dart` to `04-flutter-standards`; the plugin and
  marketplace descriptions match what ships.

## 5.9.5 — the last stragglers (2026-09-17)

After 5.9.4 the fleet reported 5.9.4 everywhere except a handful of copies
frozen at 5.6.0, with `prune-installed.sh` finding **0 dead entries** — so
those paths exist and were simply never visited.

Cause: `--all` kept only the directories that *declare* a plugin in
`.claude/settings.json` / `settings.local.json`. A `gwt` worktree (and
one project) has an installed copy recorded in `installed_plugins.json` but no
such declaration, so it was filtered out of the list before the update loop —
and stayed at its install-time version forever.

- `plugins_of` now unions three sources: `settings.json`,
  `settings.local.json`, and the plugins recorded for that exact path in
  `installed_plugins.json` (real-path compared, deduped).

## 5.9.4 — fleet hygiene (2026-09-17)

`claude plugin list` after 5.9.3: 59 enabled copies still at 5.5.0/5.6.0 while
`update-projects.sh --all` reported 34 ok. Reading
`~/.claude/plugins/installed_plugins.json` explained all of them.

- **`update-projects.sh` reads the source of truth.** Discovery now starts
  from `installed_plugins.json` (every `--scope project` copy whose path still
  exists), then `PROJECTS_ROOT` at depth 3 (`.worktrees/<repo>/<branch>`),
  then `~/.claude.json`. `plugins_of` reads `settings.local.json` as well as
  `settings.json` — one project declared its five plugins only in the local
  file and was invisible.
- **`scripts/prune-installed.sh`** — removes `scope: project` entries whose
  path no longer exists (≈ 45 dead `/private/tmp/…` worktrees from past
  sessions). Dry-run by default, `--apply` writes after a timestamped backup,
  refuses to run while a `claude` process is alive.
- `release.sh` step 5 mentions the prune.

## 5.9.3 — hotfix: drop plugin `dependencies` (2026-09-17)

`claude plugin list` on the fleet after 5.9.2: ~30 `maestro-web@maestro`
entries `failed to load — Dependency "maestro-core@maestro" is not installed`,
stuck at 5.5.0/5.6.0 because `claude plugin update` refuses a plugin that
does not load. Cause: the `dependencies` field added in 5.7.0. The platform
resolves it **per scope**; on this fleet core is not installed in every
project, so every dependent plugin broke. Nothing in `npm test` could see it
— it is an install-topology fault, visible only on a real machine.

- `dependencies` removed from all 7 manifests; `validate.js` now refuses the
  field; Philosophy **7b** records why.
- `02-execute` / `05-ship` regain their "when maestro-vcs is installed, else
  run the scan yourself" wording — the gate is relocated, never skipped.
- `m-i18n-checker` no longer preloads a cross-plugin skill; it invokes
  `maestro-mobile:01-rtl-i18n` as its first action and stops if absent.

## 5.9.2 — independent audit fixes (2026-09-17)

From `docs/AUDIT-5.9.1.md`: an auditor with the code and no access to the
author's conclusions attacked the day's six releases. 17 findings, all closed;
test cases 98 → 134.

### Fixed

- **validate.js (P1)**: the array form of `plugin.json` `hooks` was not
  counted — three smuggled PreToolUse hooks passed green. Both string and
  array forms are refused AND their targets counted. Also: `role:` is now
  mandatory on every agent (`reviewer | builder | advisor`), a description that
  says review/judge without `role: reviewer` fails, inline `!`cmd`` without
  `allowed-tools` fails, `dependencies` cycles fail.
- **memory-sync.js**: a block inside a fenced code block is documentation, not
  the block (fences masked before matching); CRLF files stay CRLF; a
  `maestro_docs/memory` *file* is not a memory bank (no router appended to a
  foreign repo). 6 new regression cases.
- **memory-sync.test.sh** used `md5sum`, absent on macOS — three cases passed
  vacuously on the release machine. `shasum -a 1`.
- **secret-scan.sh**: `diff.noprefix` no longer loses file names (prefixes
  forced); a git failure reports `skipped`, never `clean`; `++…` and `+++ …`
  added lines are content, not headers (line numbers right); an allowed line
  lists every secret it carries; CR stripped. 6 new cases.
- **bash-guard.js**: 15 bypasses closed (quoted targets, `$HOME/*`, `~/.`,
  `$HOME/..`, redirect/pipe terminators, tabs, `-fu`, `git -c … push`,
  `sudo -E`, options before `.env`, multi-suffix `.env`, `printf`) and 4 false
  positives removed (`#` comment stripped, `.env` path-anchored with doc
  suffixes excluded, secret word must end the variable name). 95 cases.
- **release.sh** refuses to run off `main`.
- **maestro-dev** now depends on **maestro-mobile** (m-i18n-checker preloads
  rtl-i18n; the preload was dangling on web-only installs).
- Injection skills declare `allowed-tools: Bash` (turn-scoped) — pattern
  grants did not cover the builtins/pipes/`$(…)` the injections use.
- **install-shortcuts.sh**: `git wt` alias is opt-in (`--git-alias`), `/menu`
  points at `/maestro`, the final count is honest.
- ARCHITECTURE.md anatomy lists `scripts/`, plugin `references/`, `commands/`.

## 5.9.1 — context budget (2026-09-17)

From `docs/PERF-AUDIT-5.9.0.md`. No rule removed; every number now has a ceiling.

- **Agent preloads trimmed to the stack at hand.** executor preloads
  `05-lean-code` only (≈ 4 000 → 1 340 tok per dispatch, −66 %): web/ux
  standards activate by `paths`, mobile standards and rtl-i18n are invoked when
  the phase or the project calls for them. checker and m-architect likewise.
  On a 5-phase feature with 2 repairs: ≈ 33 600 → 12 400 preload tokens.
- **Routing block halved** (901 → 461 tok per session): keeps only what a
  skill description cannot say.
- **`05-lean-code` shortened** (1 098 → 754 tok) — same ladder, same rules; it
  is the one skill paid on every dispatch.
- executor `maxTurns` 60 → 40.
- **`scripts/context-budget.js` in `npm test`** (also `npm run budget`): fails
  on description > 700 chars, index > 11k, routing > 2k, preloaded skill > 4k,
  agent dispatch > 6k chars, hook > 100 ms; prints the bill every run.
  Philosophy **2c** states the principle.

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
