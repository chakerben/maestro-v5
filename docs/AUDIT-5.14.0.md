# Audit 5.14.0 — independent deep pass (2026-10-22)

Scope: `main` at `76bc7eb` (one commit past the `v5.14.0` tag). Every file in
the repo read; `npm test` and each bash suite run; every script defect
reproduced; the platform claims the framework rests on checked against the
current Claude Code docs (sub-agents, skills, permissions, plugins-reference,
hooks, headless, plugin CLI) on the audit day. Four independent read-passes
(platform, maestro-dev, maestro-mobile, core/vcs/quality/web/pm) were then
cross-checked: every H below was reproduced a second time by the author of
this file before being listed.

Severity, as in AUDIT-5.10.0: **H** = cannot work as written, or unsafe, or a
technical claim that would ship a bug; **M** = wrong or inconsistent; **L** =
cosmetic. "Unverified" is said where it applies; nothing else is a guess.

## 0. State of `main`

| # | Sev | Where | Finding | Evidence / fix |
|---|---|---|---|---|
| 0.1 | H | `main` @ `76bc7eb` | **`npm test` is red on `main`** since 2026-10-16: `01-rtl-i18n/SKILL.md` is 5921 chars > 5500 (`scripts/context-budget.js`). The commit went straight to `main` (35 commits, no PR merge in the whole history), so the "PR + CI" rule of CONTRIBUTING protects contributors, not the maintainer. `release.sh 5.15.0` will refuse at step 1b until this is fixed. | Reproduced (`npm test` → `1 budget breach(es)`). Fix: §5.14 below (two moves, lands ≈ 5190 chars). Process: a local `pre-push` git hook running `npm test` (2 s) is not a Claude Code hook and does not touch rule #1. |
| 0.2 | L | `README.md:21` | "nine checks, 219 cases" — today 3 node checks + 6 bash suites = 230 cases (126+33+24+5+29+13). | Count from `npm test` output, or drop the number. |
| 0.3 | L | `docs/ROADMAP.md:18-19` | "maestro-vcs worktree support" listed as a candidate; shipped in 5.8.0 as `03-worktree` + `gwt`. | Strike it like the others. |
| 0.4 | L | `.github/workflows/publish.yml`, `package.json:20` | Every tag publishes `@chakerben/maestro` to GitHub Packages. Nothing in v5 consumes it (`claude plugin` installs from git; the only `npm.pkg.github.com` references are in `docs/archive/` and `scripts/archive/`). A dead channel that can fail a release for a reason unrelated to the marketplace. | Keep (state in README why) or delete the workflow + `publishConfig`. |

## 1. Platform claims — what is enforced, what is not

The framework's rule 5 ("say what is enforced and what is instructed") was
applied to its own text. Checked on 2026-10-22 against code.claude.com/docs.

| # | Sev | Where | Finding | Evidence / fix |
|---|---|---|---|---|
| 1.1 | **H** | `PHILOSOPHY.md:93-101`, `references/model-policy.md:9-12`, `docs/MODEL-POLICY.md`, `CHANGELOG.md` (5.13.0), `scripts/validate.js:349-379`, `00-sdlc/SKILL.md:41-43`, `04-review.md:7-8`, `checker.md:34`, `m-analyst.md:36`, `m-architect.md:35` | **"A frontmatter carries exactly one `model:` and a dispatch cannot override it" is false.** The sub-agents doc resolves the model in this order: (1) the per-invocation `model` parameter Claude passes to the Agent tool, (2) the agent's frontmatter, (3) `CLAUDE_CODE_SUBAGENT_MODEL`, (4) the session model. Consequences: (a) the 5.13.0 narrative inverted reality — "dispatch checker with model: opus" *did* work; (b) the opus rung is **instructed, not enforced**: nothing stops the sonnet orchestrator from dispatching `checker-critical` with `model: sonnet`; (c) `validate.js` refuses a phrasing that is true and lets through the one that is only a wish; (d) `CLAUDE_CODE_SUBAGENT_MODEL_FORCE=1` makes it worse, not better — it ignores *every* frontmatter pin and runs all subagents on one model. | Docs: sub-agents › "Choose a model" (resolution order), permissions › Agent rules. **The enforced fix exists**: a permission rule `Agent(model:*)` matches any dispatch that sets `model` explicitly, so `"deny": ["Agent(model:*)"]` in `.claude/settings.json` makes the frontmatter pin the only path. Add it to the 11 canonical deny entries (`04-scaffold`, `fleet-apply.sh`, `04-doctor`), rewrite rule 5 §3 and `model-policy.md:9-12` to "a pin is a default; the deny rule is what pins it", and make `validate.js` check the deny list instead of hunting the phrase "model: opus". Keep the separate agents — the criteria text is the real value of `checker-critical`. |
| 1.2 | M | `04-scaffold.md:62-64`, `scripts/fleet-apply.sh:143-146`, `bash-guard.js:14-17` | 4 of the 11 "enforced" deny rules are most likely dead: Claude Code splits a compound command at `\|`, `&&`, `;` and matches each subcommand independently, so a rule containing a pipe (`Bash(curl * \| bash)`, `curl * \| sh`, `wget * \| bash`, `wget * \| sh`) can never equal one subcommand. Also `Bash(git push --force*)` matches `--force-with-lease` (the recommended form) while `Bash(rm -rf $HOME)` is a literal string. The docs state that Bash deny rules "aren't a security boundary". Inference on the pipe rules from the documented splitting; **unverified by execution**. | Replace the four with `Bash(curl *)` → `ask` (not deny) or drop them and say bash-guard is the only layer for pipes; fix `--force*` → `--force` and `--force *`; test the list once in a real session and record the result in `04-scaffold`'s `## Test`. |
| 1.3 | **H** | `plugins/maestro-pm/skills/03-ticket/SKILL.md:17` | `${CLAUDE_PLUGIN_OPTION_TRELLO_BOARD}` is read inside a `!` injection, i.e. through the Bash tool. The manifest reference: `CLAUDE_PLUGIN_OPTION_<KEY>` is exported **to hook processes only**, and plugin variables "aren't present in the environment of commands Claude runs through the Bash tool". The live state therefore always prints `<not set — run: claude plugin config maestro-pm>` — and that command does not exist (`claude plugin configure <name@marketplace>` / `/plugin configure`). Lines 36-37 already use the working form `${user_config.TRELLO_LIST}`. | Use `${user_config.TRELLO_BOARD}` on line 17 (substituted in skill content); fix the command text. |
| 1.4 | **H** | `agents/checker.md:7,22`, `m-i18n-checker.md:7,21`, `m-architect.md:7,21` | Reviewer agents are told to "invoke `maestro-mobile:01-rtl-i18n`" / "invoke `maestro-web:00-web-standards`" but their `tools:` allowlist is `Read, Grep, Glob[, Bash]` — the `Skill` tool is not in it, so the invocation cannot happen. Rule 5's own words: "apply X is a wish unless the skill is in the agent's context". | Add `Skill` to the allowlist (and to `REVIEWER_ALLOWLIST` in `validate.js`), or preload conditionally, or have the agent `Read` the checklist by an absolute path the orchestrator passes in. |
| 1.5 | M | `fleet-apply.sh:12,187` | `--doctor` is described as "en lecture seule" but runs `claude -p … --allowedTools "Read,Glob,Grep,Bash"`; Bash writes. Instructed, not enforced — say so, or drop Bash for the doctor run (its `check` action only reads). | One word in the header. |
| 1.6 | L | `01-security-audit:5`, `02-perf-audit:5`, `02-design-review:5` | `allowed-tools:` is a pre-approval, not a restriction (skills doc), yet each `## Test` says "no code was modified" as if enforced. | Add `disallowed-tools: Write, Edit, NotebookEdit` — that key *is* enforced. |
| 1.7 | L | `scripts/validate.js:435` | `version` is listed as a documented SKILL.md key; it is not (it is a `plugin.json` key). Harmless today (no skill uses it). | Remove from `SKILL_KEYS`. |
| 1.8 | L | `scripts/install-shortcuts.sh` (whole) | `~/.claude/commands/*.md` with `$ARGUMENTS`: the skills doc describes `.claude/commands/` as the older format that still works; the user-level location is not listed. Works today, undocumented. | Note it in the header; plan a move to `~/.claude/skills/<name>/SKILL.md`. |

Verified correct against the docs: all other SKILL.md keys in `validate.js`;
all 17 agent keys (`skills:` preloads the full SKILL.md, max 32; `effort`,
`maxTurns` exist); `!` injection aborts without `allowed-tools`; hook
`timeout` in seconds, exit 2 blocks, SessionStart stdout → context;
`plugin.json` `hooks` as path/array merges with `hooks/hooks.json`;
`claude plugin update --scope`, `validate --strict`, `marketplace update`;
`claude -p "/plugin:skill"` with `--allowedTools`, `--permission-mode`,
`--model`; `${CLAUDE_PLUGIN_ROOT}` substituted inline in Markdown; `sonnet`,
`opus`, `fable`, `inherit` aliases. Two platform facts worth using:
`${CLAUDE_PLUGIN_DATA}` (state that survives updates — see 3.12) and a
plugin `bin/` directory whose files are on the Bash PATH while the plugin is
enabled — the right home for `gwt` (see 2.7).

## 2. Hooks and scripts

Both hooks are clean: no subprocess, fail-open, 29–32 ms, paired anchored
match, atomic write under lock, symlink refused, names validated, fenced
blocks masked. `bash-guard.js` is honestly scoped as an accident guard and its
quote-blanking is correct. The findings are in the scripts around them.

| # | Sev | Where | Finding | Evidence / fix |
|---|---|---|---|---|
| 2.1 | M | `scripts/lib/fleet.sh:108-124` | Comment says the scan goes to depth 3 "pour `.worktrees/<repo>/<branche>`"; `find -maxdepth 3 -name .claude` needs `.claude` itself at depth ≤ 3, and a worktree's `.claude` is at depth 4. **gwt worktrees are never discovered by the scan.** They are found only if `installed_plugins.json` lists them, which `gwt new` never causes. | Reproduced with a fixture (`.worktrees/repoA/feat-x/.claude` absent from the list; present at `-maxdepth 4`). Fix `-maxdepth 4`; add the case to `fleet-apply.test.sh`. |
| 2.2 | M | `scripts/fleet-apply.sh:191` | Log file is `$(basename "$proj").$action.log`: two projects with the same basename (every `main` worktree, every `app` repo) overwrite each other's log and `summary.tsv` points at the survivor. | Use a slug of the full path, or `$(basename "$(dirname "$proj")")-$(basename "$proj")`. |
| 2.3 | L | `scripts/tests/fleet-apply.test.sh:31,49` | Two checks cannot fail: line 31 ends in `\| head -0` (always empty → `-z` true); line 49 is `! command -v timeout … \|\| true`. Counted as 2 of the 13 "passed". | Line 31: `! [ -d "$HOME/.maestro/fleet" ]`; line 49: delete (line 48 already proves the fallback). |
| 2.4 | L | `scripts/fleet-apply.sh:233` | `wait -n 2>/dev/null \|\| wait` — on bash 3.2 (`wait -n` unsupported) the fallback waits for *all* jobs, so `--jobs N` degrades to batches of N; harmless, undocumented. | Say it in the `--jobs` comment. |
| 2.5 | L | `scripts/release.sh:152` | `npm test` log at a fixed `/tmp/maestro-release-test.log`. | `mktemp`. |
| 2.6 | L | `scripts/release.sh:207-208` | "CI verte, on tague ?" trusts the operator; `gh run watch` (gh is already a dependency of step 0b) could gate the tag on the real run. | `gh run list --branch main -L1 --json conclusion` before `ask`. |
| 2.7 | M | `scripts/gwt`, `03-worktree/actions/02-create.md:23-28`, `install-shortcuts.sh:88-99` | `gwt` reaches users only through a symlink `install-shortcuts.sh` plants in `~/.local/bin` pointing into *the clone it was run from*; the skill's no-gwt fallback (02-create) does not reproduce it (raw `<branch>` instead of the `feat/x → feat-x` slug, 3 of 7 copied files, wrong base when local is ahead). | Ship it as `plugins/maestro-vcs/bin/gwt` (on PATH while the plugin is enabled, per the manifest reference); delete the fallback. |
| 2.8 | L | `scripts/install-shortcuts.sh:50,70-81` | `/auto` is written twice (by `mk` then by the heredoc); only the second survives. | Drop line 50. |
| 2.9 | L | `scripts/context-budget.js:9-10,28` | "≈ chars/3.6 tokens for this repo's EN/FR/AR mix": Arabic tokenises at roughly 1–2 chars/token, so the AR templates and `04-writing/references/ar.md` are under-counted by 2–3×. The ceilings still hold because they are in chars; the printed "tok" estimates do not. | Say "EN estimate" or weight Arabic ranges. |
| 2.10 | L | `scripts/release.sh:72`, `prune-installed.sh:23` | `pgrep -x git` / `pgrep -f 'node.*claude'`: the second also matches any Node process whose argv contains "claude" (an editor extension, this very audit). | Narrow or warn instead of exit. |

## 3. maestro-core · maestro-vcs · maestro-quality · maestro-web · maestro-pm

| # | Sev | Where | Finding | Evidence / fix |
|---|---|---|---|---|
| 3.1 | **H** | `vcs/00-commit/actions/01-gate.md:36`, `01-pull-request/SKILL.md:54`, `dev/02-implement/actions/02-execute.md:33` | The canonical `## Test` fixture `sk_live_xxxxxxxxxxxxxxxxxxxxxxxx` is **not** a hit: `secret-scan.sh:80` drops any match containing `xxx+` as a placeholder. The three tests that cite it pass or fail depending on which plugin is installed (the no-vcs fallback grep has no placeholder filter). | Reproduced: `SECRET SCAN: clean — 1 added line(s)`. Fixture → `sk_live_4eC39HqLyjWDarjtT1zdp7dc` (verified RED). |
| 3.2 | **H** | `vcs/00-commit/assets/secret-patterns.md:35` (generic rule), `secret-scan.sh:109,130` | **The gate is RED on the very code the framework mandates.** `const apiKey = process.env.OPENAI_API_KEY` (the `env.ts` pattern of `00-web-standards:32-35`), `passwordMinLength = DEFAULT_PASSWORD_LENGTH`, `{ apiKey: env.STRIPE_SECRET_KEY }` all match the generic credential regex (26+ chars of `[A-Za-z0-9+/=_.-]`). The only project-side escape is `gate:allow` on each line, which trains people to bypass the gate. `secret-scan.test.sh` has no false-positive corpus. | Reproduced (4 of 5 lines RED). Drop a match whose value starts with `process.env.`, `env.`, `import.meta.env.`, or is a bare identifier (no quote, no digit); require ≥ 1 digit in a quoted value; add a false-positive corpus to the test. |
| 3.3 | M | `secret-scan.sh:109,130` | `grep -Ei` applies case-insensitivity to every row, not just the generic one: `SK[a-f0-9]{32}` (Twilio) fires on `"task1234567890abcdef…"`, `AKIA[0-9A-Z]{16}` inside any base64 blob. | Reproduced ("Twilio key sk123456…"). Two passes, or a per-row flag column in `secret-patterns.md`. |
| 3.4 | M | `vcs/00-commit/actions/01-gate.md:22-23` vs `02-compose.md:21` | `ALLOWED` lines "go verbatim into the commit body as `Gate-Allow:` (action 02)"; action 02 only knows `Gate-Bypass:`. The trailer is dropped between the two actions. Also `config-conventional` caps body lines at 100 chars; a `Gate-Allow: <file>:<line> — <reason>` line can exceed it. | Add the step to 02; wrap. |
| 3.5 | M | `vcs/00-commit/SKILL.md:51-56` vs `actions/01-gate.md:26-29`; `quality/00-quality-gate/SKILL.md:22,26-27`; `PHILOSOPHY.md:28-31` | Three statements of the level contract disagree: the table puts `lint` at `high`, the action runs it unqualified; the plugin that "owns `gates.json`" never defines what a level runs and delegates `run`/`status` to a plugin that may not be installed (7b); PHILOSOPHY says tests run on "every commit, phase commits included" while the default `standard` runs no tests. | One level table in `00-quality-gate` (owner of the file); 00-commit and PHILOSOPHY point at it. |
| 3.6 | M | `dev/00-sdlc/actions/05-ship.md:7-13`, `dev/00-sdlc/SKILL.md:22` vs `vcs/01-pull-request/SKILL.md:18-31,53-54` | 05-ship pushes and opens the PR itself, bypassing `01-pull-request`'s branch-wide secret scan (`secret-scan.sh branch`), its "never from the default branch" rule and its clean-tree precondition — the only branch scan in the framework. routing.md:6 sends "PR → 01-pull-request". | "When maestro-vcs is installed, invoke `maestro-vcs:01-pull-request`; else …" — the same shape 05-ship already uses for 00-commit. |
| 3.7 | **H** | `core/04-doctor/SKILL.md:12-22` vs `actions/01-check.md:24-28`; `references/third-party-vetting.md:23-24` | The "three buckets" (Maestro / official plugin / other hooks "across active settings + plugin hooks") cannot be computed: the live state parses `.claude/settings.json` only; nothing reads `~/.claude/settings.json` or any plugin's hooks. The one check the vetting grid promises ("04-doctor will flag any hook that appears afterwards") is the one it cannot do. | Inject `claude plugin details <id>` per listed plugin (its component inventory lists hooks) plus `~/.claude/settings.json` into the node snippet. |
| 3.8 | M | `core/04-doctor/actions/02-fix.md:19-20` | `fix` rewrites "the offending settings hooks blocks to `"hooks": {}`" — that wipes every hook in the file, including the user's unrelated ones (Notification, Stop…), while 01-check only identified the offending handlers. | Remove the matched handlers only. |
| 3.9 | M | `core/00-onboard/actions/04-scaffold.md:34-39,52-53` vs `hooks/memory-sync.js:48,155,175` | Step 3b hand-writes the routing block without the hash comment the hook emits and without saying the tags must be alone on their line; a tag written inline becomes a stray tag and the hook bails forever. Step 4 "run the memory-sync logic once" names no command. | Delete 3b; step 4 = `node ${CLAUDE_PLUGIN_ROOT}/hooks/memory-sync.js` (writes both blocks in the exact shape); add the routing block to the Test. |
| 3.10 | M | `core/00-onboard/actions/04-scaffold.md` (whole) vs `plugins/maestro-core/README.md:45-53`, `03-worktree/SKILL.md:49`, `scripts/gwt:119-121` | CLAUDE.md is "versioned, expect a `chore: sync CLAUDE.md` commit in every project after each release" (core README), "ignored by git" (worktree skill, gwt). Neither scaffold nor doctor adds `.claude-md.maestro.lock` / `CLAUDE.md.*.tmp` to `.gitignore`; the fleet-wide churn is stated only in the core README. | One default, stated at scaffold time (step 3b), plus a `.gitignore` merge step with its Test line. |
| 3.11 | M | `core/00-onboard/actions/02-official-plugins.md:39,41,63`, `third-party-vetting.md:25` | `docs/TOOLING-AUDIT-2026-09.md` referenced by a relative path that does not exist in the plugin cache (`docs/` is not shipped in the plugin). The Test "`.claude/settings.json` shows ≤ 2 Maestro hooks" checks the wrong place: Maestro's hooks live in each plugin's `hooks/hooks.json`, never in settings. | `${CLAUDE_PLUGIN_ROOT}/references/third-party-vetting.md`; URL for the doc; Test → `claude plugin details maestro-core@maestro` / `maestro-quality@maestro`. |
| 3.12 | L | `core/04-doctor/actions/02-fix.md:16` | Backup dir `.maestro-doctor-backup-<ts>/` lands in the project, untracked, never ignored (gwt and fleet.sh both special-case it). | Write it under `${CLAUDE_PLUGIN_DATA}` or `~/.maestro/`. |
| 3.13 | M | `quality/01-security-audit/SKILL.md:12,25-26`, `02-perf-audit/SKILL.md:33-36`, `web/00-web-standards:52`, `pm/02-specs:11,33`, `web/03-motion:20,26`, `dev/03-brainstorm/actions/04-handoff.md:20-21`, `dev/05-lean-code:31` | Cross-plugin references with no "when installed, else …" guard (7b): maestro-quality reaches for `maestro-dev references/expert-postures.md`, maestro-vcs secret patterns and `m-deep-analyst`; brainstorm hands off to `maestro-pm:00-prd`/`02-specs`; the others name skills/rungs of other plugins. The 5.10 fix applied the guard where that audit pointed and nowhere else. | Add the guard + one-line fallback in each; `validate.js` could grep `maestro-<other>:` outside a line containing "installed". |
| 3.14 | M | `pm/03-ticket/SKILL.md:38-42` vs `:59` | Step 4 writes `maestro_docs/tickets/*.md`, step 5 appends URLs to `debug.md`/`review.md`; the Test says "`git status` unchanged". | Test → "nothing outside `maestro_docs/` changed". |
| 3.15 | M | `web/01-ux-standards/SKILL.md:6-8,56` | `paths: app/**/*.tsx` fires on Expo Router screens (AUDIT-5.10 #10 fixed `00-web-standards` only); the Test then demands `<label>` and tab order, which do not exist in React Native. | Next conventions (`app/**/{page,layout,…}.tsx`) or "defer to maestro-mobile when `react-native` is in package.json". |
| 3.16 | M | `web/02-design-review/SKILL.md:31,36-37` | "Score /10 per pass" with no rubric → two runs give two numbers and the Test cannot verify one. | `assets/rubric.md` with the deductions. |
| 3.17 | M | `vcs/02-release/SKILL.md:28-32` | On the marketplace repo itself the skill is wrong: it bumps `package.json` only; a Maestro release needs 9 manifests and `release.sh`. Nothing says so, and `disable-model-invocation` does not stop a user running it here. | "If `.claude-plugin/marketplace.json` exists: stop, use `scripts/release.sh`." Also honour routing.md:16 (project's own version rule wins), as 02-compose does. |
| 3.18 | M | `core/02-gardener/SKILL.md:29-34` | Asks to list "corrections the user made more than once in recent sessions" — the model has no access to previous sessions. A wish as a step. | Source it from `maestro_docs/tasks/*/review.md` iterations. |
| 3.19 | L | `vcs/00-commit/SKILL.md:73-74` | "Delegate the raw git mechanics to commit-commands … this skill owns the gate and the message": `/commit` composes its own message and `/commit-push-pr` pushes; incompatible with "owns the message" and "does not push". | Delegate nothing, or only the `git` call after the message is approved. |
| 3.20 | L | six `allowed-tools: Bash   # … the injections above` lines | Comment says "above"; the injections are below the frontmatter. `allowed-tools: Bash` also pre-approves every Bash call of the turn, which the comment under-states. | "below"; consider `Bash(git *)`, `Bash(bash ${CLAUDE_PLUGIN_ROOT}/*)`. |
| 3.21 | L | `core/04-doctor/SKILL.md:22` | `grep -c "maestro_memory"` counts prose mentions as tags. | `grep -cE '^</?maestro_memory>[[:space:]]*$'`. |
| 3.22 | L | `model-policy.md:84-101` vs `03-condense:6` (`effort: low`), `web/03-motion:5` (`effort: medium`) | Two effort pins absent from "How Maestro applies it". Every other pin matches. | Two rows. |
| 3.23 | L | `core/03-condense/SKILL.md:39-41`, `web/03-motion/SKILL.md:64-67`, `quality/00-quality-gate:26`, `02-perf-audit:18-21` | Tests that cannot be run ("byte-identical to what it would have been"), a grep that misses `"chars"`, "working tree" vs the staged diff 00-commit actually scans, Prisma-only data pass in a framework that now supports Firestore/Dart. | Reword each. |
| 3.24 | L | `core/README.md:19`, `pm/plugin.json:4`, `dev/plugin.json:4`, `dev/README.md:20`, `mobile/README.md:7-10`, `pm/03-ticket:17` | Relative link to `../../docs/` (dead in the cache); pm description with two parentheticals back-to-back; dev description lists 5 agents of 8; "6 anti-complacency rules" of 7; mobile README lists 2 of 6 shipped reference/asset files; the Trello default list duplicated in the echo fallback and in `userConfig.default`. | Cosmetic, one pass. |

Verified clean: every `${CLAUDE_PLUGIN_ROOT}`, `assets/`, `references/` path
in these five plugins resolves; every `!` injection ends in an exit-0
construct and declares `allowed-tools`; DENY list and `"model": "sonnet"` are
byte-identical between `04-scaffold` and `fleet-apply.sh`; `gates.json`
schema identical in its three readers; the ≥ high escalation rule identical in
`04-review`, `model-policy`, `checker.md`, `00-sdlc`; `03-worktree` commands
and paths match `gwt`; `proxy.ts` (Next 16) / `middleware.ts` (≤ 15) correct;
GSAP-free-since-Webflow, `lenis/react`, `@gsap/react`/`useGSAP`, SplitText by
words on Arabic correct; the AR PRD and card templates are natural, correctly
inflected Arabic with Arabic punctuation; 00-commit does not push.

## 4. maestro-dev

| # | Sev | Where | Finding | Evidence / fix |
|---|---|---|---|---|
| 4.1 | **H** | `dev/02-implement/actions/02-execute.md:17-19` with `vcs/00-commit/actions/01-gate.md:16-17,30-31`, `02-compose.md:5,19-20` | Phase green → `status: done` is written **then** `00-commit` runs its own level checks and can go RED; 02-execute has no branch for that. Result: `phase-N.md` says `done`, nothing committed, next phase starts on top. Nothing stages the files (00-commit asks "stage?" when nothing is staged → a pause), and 02-compose asks for message approval unless told "auto" — 02-implement never passes the mode, so **`00-sdlc auto` pauses at every phase commit**, contradicting `00-sdlc/SKILL.md:32`. | Order: validate → stage code + phase file → gate → on green only, write `done` and commit; pass `mode` to 00-commit; a red gate = one repair attempt. |
| 4.2 | **H** | `dev/02-implement/actions/02-execute.md:7,17-24`, `SKILL.md:33-34`, `01-prepare.md:16-17`, `01-plan/assets/phase-template.md:2` | Resume has no case for a half-done phase (`in-progress`, uncommitted partial code; the attempt counter lives in prose) and two rules for a `blocked` one (02-execute re-runs it with a reset counter; SKILL.md skips it and builds the next phase on a hole). | 01-prepare: for `in-progress`, inject `git status --short` + the phase `## Log` and pass both to the executor; `attempts:` in frontmatter; `blocked` stops entry unless a human reset it. |
| 4.3 | M | `dev/01-plan/` (whole), `actions/03-plan.md:9,12` | `01-plan` is routed standalone ("plan only") and says the plan is "the persistent state that makes any session resumable", yet no file in the skill names where `plan.md` is written — folder resolution exists only in `00-sdlc/actions/01-spec.md:17`. Standalone runs write wherever the model guesses. | Step 0 in `01-gather`: resolve `maestro_docs/tasks/<date>_<slug>/`, read existing statuses. |
| 4.4 | M | `01-plan/actions/03-plan.md:9,12`, `03-brainstorm/actions/01-frame.md:12` vs `04-debug/01-reproduce.md:8`, `02-execute.md:20` | `assets/plan-template.md` etc. written from inside `actions/*.md` resolve to `actions/assets/` (absent) — AUDIT-5.10 #1 fixed `../references/`, not `assets/`. Three path conventions coexist. | `${CLAUDE_PLUGIN_ROOT}/skills/<skill>/assets/…` everywhere. |
| 4.5 | M | `02-implement/assets/secret-patterns.md:5,39-48` vs its callers | The mirror is addressed to "Executor" but every caller has the orchestrator run the grep; lines 39-48 describe placeholder filtering and `gate:allow` that exist only in the maestro-vcs script — i.e. precisely when this fallback is *not* used. In the fallback `API_KEY=changeme_placeholder_value` is RED and a `gate:allow` line is a hard stop; "stop on any hit" leaves the phase `done` but uncommitted. | Mirror the table only + a 3-line "fallback has no filter and no allow marker" note. |
| 4.6 | M | `02-implement/SKILL.md:33-34`, `01-prepare.md:16`, `00-sdlc/SKILL.md:56-57`, `04-review.md:8` | Rule 2b ("what a skill must know, it computes"): phase statuses, branch, `gates.json` are "read" in prose; `04-debug/SKILL.md:16-21` shows the `!` shape. | Inject live state + `allowed-tools: Bash`. |
| 4.7 | M | `02-implement/actions/01-prepare.md:9-13` vs `routing.md:7`, `00-commit/01-gate.md:7-14` | "On the default branch: create a branch" with no ownership check — in a shared checkout this is the `git switch` routing forbids. | Same foreign-paths check as 00-commit; route to `03-worktree` when installed. |
| 4.8 | M | `03-brainstorm/SKILL.md:26-34` vs `actions/01-frame.md:9-13,33-36`, `04-handoff.md:23,38` | Off-ramp contradiction: before action 01 (no `design.md`) vs step 6 of 01-frame with `status: dropped` — and `dropped` elsewhere means "do not build". | No file for the off-ramp, or a distinct status (`routed`). |
| 4.9 | M | `04-debug/SKILL.md:39-41` vs `actions/01-reproduce.md:13-15,25-26` | "No repro, no edit" allows only `debug.md` + a throwaway script under the task folder; action 01's preferred repro is a new test in the project tree. | Pick one. |
| 4.10 | M | `agents/m-analyst.md:33`, `m-deep-analyst.md:36` vs `04-debug/actions/03-cause.md:15-22`, `04-fix.md:10-12` | Both analysts "hand execution back to the executor"; in 04-debug there is no executor — the session applies the fix. | "back to the caller". |
| 4.11 | M | `agents/checker-critical.md:10-11,44` vs `checker.md:11-12` | Told to "cite the lean-code rung" and "list every `debt:`" without preloading `05-lean-code` (checker does). | Add it to `skills:`. |
| 4.12 | M | `01-plan/actions/03-plan.md:19-20` vs `phase-template.md:18-20`, `02-execute.md:14` | Test accepts "a validation command **or concrete check**"; the gate needs an exit code. A "concrete check" phase self-reports (protocols rule 6). | ≥ 1 command per phase. |
| 4.13 | M | `04-debug/actions/03-cause.md:23-26`, `SKILL.md:58-61` | `cause-found` is both the terminal "needs a decision" state and the normal pre-fix state; resume cannot tell whether to run 04 or wait. | `needs-decision` status. |
| 4.14 | M | `00-sdlc/SKILL.md:33-35` vs `actions/02-plan.md:12`; `04-review.md:25-26` vs `plan-template.md:17-19`; `03-finalize.md:7-8` vs `02-execute.md:17` | Hard-stop list omits the devil-advocate `reconsider`; an `iterate` phase is created but never added to the plan's `## Phases` table (two sources of truth for "implemented iff every phase is done"); "set `implemented` (commits with the last phase)" is impossible after 02-execute already committed it. | Add; append a row; make it a tiny final commit. |
| 4.15 | L | `03-plan.md:10` vs `plan-template.md:3`, `debug-template.md:3`; `phase-template.md:3,22-24`; `00-sdlc/04-review.md:17`; `01-spec.md:11-12`; `design-template.md:5`; `04-debug/SKILL.md:21` | `date` vs `created`; `phase:` read by nobody and a Log comment naming the wrong writer; `*.arb` matches `app_en.arb`; "steps 02-05 read this file and nothing else" (false); `posture:` never filled; the status injection prints the template's inline comment. | One pass. |

Verified clean: every `${CLAUDE_PLUGIN_ROOT}` reference resolves;
`cognitive-protocols.md` pointer correct; the secret-patterns mirror is
byte-identical and `validate.js` enforces it; model/effort of 01–04 match the
policy table; `06-protocols` preloaded by all 8 agents; `02-specs` really
writes `maestro_docs/specs/spec-<slug>.md`.

## 5. maestro-mobile

| # | Sev | Where | Finding | Evidence / fix |
|---|---|---|---|---|
| 5.1 | **H** | `01-rtl-i18n/references/arabic-font-metrics.md:23,29`; `SKILL.md:84`, `00-mobile-standards:54`, `rtl-checklist.md:31`, `flutter-rtl.md:29`; `03-store-release/SKILL.md:29` | `$MAESTRO_MOBILE` is defined nowhere; the four other spellings of the script path (`assets/…`, `01-rtl-i18n/assets/…`) are relative to the skill dir, unresolvable from the project cwd; same for "Copy `assets/checklist.md`". The mandatory metrics check **cannot be run as written**. Glob `@expo-google-fonts/<family>/*.ttf` matches zero files (layout is `<family>/<weight>/<file>.ttf`, verified on 0.4.2). | One canonical `${CLAUDE_PLUGIN_ROOT}/skills/01-rtl-i18n/assets/font-metrics.py`; glob `<family>/*/*.ttf`. |
| 5.2 | **H** | `01-rtl-i18n/SKILL.md:50-57` (commit `76bc7eb`) | The RN phone-input recipe ships the wrong border: "physical `borderRight*` on the prefix" is not physical in RN — with the default `doLeftAndRightSwapInRTL = true`, `borderRight*` / `right` / `marginRight` are rewritten to `End` edges under RTL (`YogaLayoutableShadowNode::swapLeftAndRightInViewProps`, Android `LayoutShadowNode.maybeTransformLeftRightToStartEnd`). Under `row-reverse` the prefix is on the left and its "borderRight" lands on its *outer* edge. `// rtl-ok` is honoured by no tool in the repo. | Wrap the row in a `View` with `direction: 'ltr'` (RN layout prop, the mirror of web `dir="ltr"`), `flexDirection: 'row'`, `borderEndWidth`; drop the physical trick. The owner rule itself (prefix left, digits left-aligned, label RTL) is right. |
| 5.3 | **H** | `01-rtl-i18n/SKILL.md:34-39` | "forceRTL per locale + reload" silently reverts on the next cold start on SDK 54 (expo-localization 17.x) when the config plugin sets `supportsRTL`/`forcesRTL` as lines 37-39 instruct: iOS `OnCreate` → `setRTLPreferences` rewrites `RCTI18nUtil_forceRTL` from the device locale on every launch. Fixed only in expo-localization 58.0.0/58.0.5. `extra.supportsRTL` is an output of the plugin, not an input, and Expo Go resets RTL preferences. | Say which SDK; on ≤ 57 do not pass `supportsRTL`/`forcesRTL` to the plugin when a runtime switcher exists, or require ≥ 58.0.5. |
| 5.4 | **H** | `03-store-release/SKILL.md:17` | `elif ls app.config.js app.config.ts >/dev/null 2>&1` fails whenever only one of the two exists (the normal case) and falls through to "(no app.json … found)". | Reproduced. `elif [ -f app.config.js ] \|\| [ -f app.config.ts ]`. |
| 5.5 | M | `assets/font-metrics.py:7`, `arabic-font-metrics.md:12-13`, `SKILL.md:86`, `flutter-rtl.md:31`, `rtl-checklist.md:31` | "ص / ض 521" is false for IBM Plex Sans Arabic: `uni0635`/`uni0636` yMin = −240, inside the 415 descent. The ي claim holds (−440 Regular / −455 Bold — 455 is the Bold figure). | Remove ص/ض from the five places; ي only. |
| 5.6 | M | `assets/font-metrics.py:56-84`, `SKILL.md:117-119`, `arabic-font-metrics.md:57` | A font with **no Arabic glyphs** reports `OK`, exit 0 — the release Test and DoD are satisfied by shipping Inter, the exact trap `flutter-rtl.md:22` warns about. | Reproduced on GeistMono. `NO-ARABIC`, exit 1. |
| 5.7 | M | `font-metrics.py:95`; `arabic-font-metrics.md:26-27` vs `:90` | `fix` sets `USE_TYPO_METRICS` on OS/2 < v4 without bumping the version (fontTools warns; bit undefined). "grows a little": the fix takes `usWinDescent` when it covers the glyphs — IBM Plex 415 → 601 (+18.6 % em). | Bump to v4 or skip the bit; clamp to `int(-low)+1` or document the real growth. |
| 5.8 | M | `references/flutter-rtl.md:37-38` | "`Icons.arrow_back_ios` does not flip — use `arrow_back_ios_new`" is false: both are `matchTextDirection: true` in `icons.dart` (master, stable, 3.0.0). | Delete the trap. |
| 5.9 | M | `references/sar.md:16-19,48-50`, `SKILL.md:70-73` | "order comes from `formatToParts`" puts the riyal icon **after** the amount in Arabic; SAMA's rule is symbol to the left of the numeral with a space, in all languages. | Render `icon + ' ' + number` explicitly; keep `Intl` for digits/grouping. `﷼` U+FDFC is the *Iranian* rial sign, not a "legacy spelling" of SAR. |
| 5.10 | M | `02-pdf-rtl/references/zatca.md:9,43-47,59` | Tags 6–8 described as simplified-only; per ZATCA's QR structure tags 6 (hash), 7 (signature), 8 (public key) apply to all phase-2 invoices and only tag 9 is simplified-only; for standard invoices the stamped QR comes back from clearance. "QR on every PDF" in phase 1 overstates (mandatory B2C, optional B2B). The 500-char limit is **unverified** (sources say 500 and 700). | Rewrite 41-47 and the check at 59; cite the spec for the limit. |
| 5.11 | M | `03-store-release/assets/checklist.md:11-12` | Missing hard requirement: uploads must target **iOS 13+** (since 2026-09-09); current minimum is Xcode 26 / iOS 26 SDK (since 2026-04-28); Play: API 36 since 2026-08-31 (extension to 2026-11-01). Line 13 (16 KB) correct. | State the live figures with dates. |
| 5.12 | M | `00-mobile-standards/SKILL.md:13-14`, `01-rtl-i18n/SKILL.md:6-11` | `paths: android/**`, `ios/**` fire on every Flutter project (which commits both) despite "Not for Flutter"; `**/ar/**` matches any `ar` directory incl. vendored trees, `lib/l10n/**` and `**/*.arb` fire on Flutter projects with no Arabic. | Expo-specific globs; `**/ar.json`, `**/ar-*.json`, `**/app_ar*.arb`, `messages/ar*`. |
| 5.13 | L | `01-rtl-i18n/SKILL.md:41`, `02-pdf-rtl/SKILL.md:16-17`, `arabic-font-metrics.md:3`, `rtl-checklist.md:15`, `font-metrics.py:5-6` | `writingDirection` is iOS-only (unstated); `await document.fonts.ready` written Node-side (must be `page.evaluate`); a client name and WhatsApp ticket ids shipped inside a public plugin; "covered by fallback" means nothing for plurals; "RN clips every `<Text>` to its line box" **unverified** (no source). | One pass; move the client reference to that project's `maestro_docs`. |

Verified correct: CSS logical properties, Tailwind `ms/me/ps/pe`, `dir="auto"`,
U+2066..2069, 6 CLDR plural categories, `numberingSystem` arab/latn,
`ar-SA-u-ca-islamic-umalqura` (note: `ar-SA` default calendar is `gregory` on
ICU 77), `<bdi>`, `EdgeInsetsDirectional` & co, `matchTextDirection` on
Material icons, `DateFormat` Gregorian-only + `hijri`, U+20C1 / Unicode 17.0,
16 KB page size, Apple 5.1.1(v)/5.1.2, `context.mounted`,
`AppLifecycleListener`; `font-metrics.py --help` runs under `python3 -I`
(needs `fontTools`, stated in the docstring, not in SKILL.md:82-90 where the
check is made mandatory).

### 5.14 — closing the budget breach (0.1) without losing a rule

`01-rtl-i18n/SKILL.md`: move lines 50-57 (phone input, 562 chars, with the
corrected recipe of 5.2) into `references/rtl-checklist.md` next to its
existing lines 25-26, leaving one line; move lines 82-90 (metrics procedure,
627 chars — already verbatim in `references/arabic-font-metrics.md`), leaving
a three-line "mandatory, command, fix" pointer. Lands ≈ 5190 chars; the first
move alone lands at 5489, too close for the next edit.

## 6. Cross-cutting patterns

1. **The platform was assumed, not read, on the one claim everything rests on.**
   5.13.0 built two agents and a validator on "a dispatch cannot override a
   pin"; the docs say the opposite, and the enforced mechanism (`Agent(model:*)`
   in `permissions.deny`) was one page away (1.1). Same family: `userConfig`
   through an env var the Bash tool never sees (1.3), `Skill` absent from a
   reviewer's allowlist (1.4), deny rules with a pipe in them (1.2), `allowed-tools`
   read as a restriction (1.6), Maestro hooks "in settings.json" (3.11).
2. **The gate the whole framework is proud of fails on its own fixture and on
   its own mandated code** (3.1, 3.2, 3.3): `secret-scan.sh` was never run on
   a realistic `env.ts` diff, and the `## Test` sentences were written, not
   executed — the same pattern 5.10 named for `npm test` ("could not see any of
   #1–#3") now at the level of the skills' own tests.
3. **Seams between two files drift**: phase `done` vs commit gate red (4.1),
   half-done / blocked phases (4.2), `Gate-Allow` lost between two actions
   (3.4), three level tables (3.5), ship vs pull-request (3.6), `cause-found`
   doing double duty (4.13). Each time, each file is right about its half.
4. **A 5.10 fix was applied where that audit pointed and nowhere else**:
   `../references/` → `${CLAUDE_PLUGIN_ROOT}` but not `assets/` (4.4), not
   `$MAESTRO_MOBILE` (5.1); the 7b guard added to the obvious cases and not to
   maestro-quality / brainstorm / web (3.13); `paths` fixed on `00-web-standards`
   and not on `01-ux-standards` (3.15). A validator rule per pattern
   (`validate.js` can grep for `assets/` outside `${CLAUDE_PLUGIN_ROOT}`, and
   for `maestro-<other>:` without "installed") is cheaper than a third audit
   finding the fourth instance.
5. **Rules ported from the web mental model to RN/Flutter without opening the
   platform source**: `borderRight` swapped by RN (5.2), the Expo plugin
   overwriting `forceRTL` (5.3), `arrow_back_ios` flipping (5.8),
   `formatToParts` and the riyal (5.9), `ص 521` (5.5). The 5.14.0 release note
   says the client's report was first answered with "that is how the font draws
   it" — the lesson generalises: a rule about a platform earns its place by a
   quoted line of that platform.
6. **`main` is red and the ROADMAP prerequisite is still open** after nine
   releases: the first real `/sdlc` run would have surfaced 4.1 and 4.2 on day
   one (an auto run pauses at the first phase commit). That prerequisite is
   this audit's first recommendation, as it was 5.10's.

## 7. Suggested order for 5.15.0

1. Green `main`: §5.14 (one commit, then `release.sh` works again).
2. Truth before features — 1.1 (`Agent(model:*)` deny + honest wording +
   validator), 1.3, 1.4: the ladder and the reviewers become what the docs
   say they are.
3. The gate: 3.1, 3.2, 3.3 with a false-positive corpus in
   `secret-scan.test.sh` (`env.ts`, `DEFAULT_PASSWORD_LENGTH`, a base64 blob)
   and a true-positive fixture that is not a placeholder.
4. The pipeline seams: 4.1, 4.2, 3.6, 3.4, 3.5 — then **run one feature
   through `/sdlc auto`** on a throwaway repo and file what breaks as 5.15.1.
5. Mobile correctness: 5.1–5.4, then 5.5–5.11.
6. Fleet scripts: 2.1, 2.2, 2.7 (`bin/gwt`), 1.2.
7. Everything L in one "docs: audit 5.14.0 cosmetics" commit.
