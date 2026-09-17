# Maestro 5 — Philosophy

> These 8 rules are the constitution of this framework. Every pull request is
> reviewed against them. When a change conflicts with a rule, the change loses.

## Why these rules exist

Maestro v4 shipped 14 lifecycle hooks that ran typecheck, tests, and formatting
after every single edit. Combined with third-party orchestrators (claude-flow,
ruv-swarm), this spawned unbounded parallel `tsc` and `jest` processes —
33+ GB of Node RAM on a 24 GB machine, Jetsam kills, full system freezes.

The lesson, learned the hard way:

> **Quality belongs in the workflow, not in the runtime.**

## The 8 rules

### 1. Maximum 2 hooks in the entire framework
- `SessionStart` → `memory-sync.js` (maestro-core) — injects project memory.
- `PreToolUse(Bash)` → `bash-guard.js` (maestro-quality) — **accident guard**:
  blocks the canonical spellings of a few irreversible commands. It is not a
  security boundary and is documented as bypassable (the enforced layer is the
  platform's `permissions.deny`, rule #8).

No other hook, ever. Not for quality. Not for convenience. Not "just this once".

### 2. Never typecheck, test, or format inside a hook
- Formatting → the executor agent formats what it touches (agent instruction).
- Typecheck → real-time via official LSP plugins; final gate at commit.
- Tests → gates of `maestro-vcs:00-commit` (every commit, phase commits included) and the `checker` agent at `maestro-dev:00-sdlc` step 04.

### 2b. What a skill must know, it computes
A skill that depends on the repository's state (what is staged, the gate
level, the last tag, the plugins installed) gets that state through `!`
injection at invocation — measured before the model reads the skill, never
recalled or "checked" in prose. The secrets scan is the canonical case:
`scripts/secret-scan.sh` runs before `00-commit` is read, and its verdict is
in the context, not in a promise.

### 2c. Context has a budget, and the budget is tested
The skill index and the routing block are paid in every session; a
preloaded skill is paid in every agent dispatch. `scripts/context-budget.js`
holds the ceilings (index ≤ 11k chars, router ≤ 2k, agent dispatch ≤ 6k,
hooks ≤ 100 ms) and fails `npm test` past them. Standards load for the
stack at hand — a web phase never pays for mobile rules, a project without
Arabic never pays for RTL rules.

### 3. Every hook must prove itself
- < 100 ms wall time.
- `exit 0` on any internal error (fail open, never block on our own bugs).
- No heavy subprocess spawning. No network. Lock required if anything async.

### 4. Every skill states how it is tested
Two shapes, and `validate.js` enforces both:
- **Router skill** — `SKILL.md` (contract + actions table) + `actions/*.md`
  (atomic, each with its own `## Test` section). For anything with more than
  one step or any persistent state.
- **Contract skill** — `SKILL.md` alone, carrying one `## Test` section that
  says what a correct run leaves behind (or what it must never do).
A skill with no `## Test` anywhere is not a skill, it is a wish.

### 5. Agents with model pinning and strict separation
- `executor` (sonnet): builds, never judges its own work.
- `checker` (opus): judges with evidence, never edits the work.
No agent both writes and approves the same change.
**Enforced where the platform allows it**: reviewer agents carry a `tools:`
allowlist without Edit/Write, so the platform prevents them from editing files.
`m-devil-advocate` and `m-i18n-checker` (Read/Grep/Glob only) are fully
enforced. `checker` additionally carries `Bash`, because a verdict without a
validation run is a vibe — and `Bash` can write. That residual gap is
**instructed, not enforced**, and named as such in `checker.md`. Same for
`m-architect`: it carries `Write` to record decisions, and `Write` has no
path restriction — "never production code" is instructed there too.
Every agent declares `role: reviewer | builder | advisor`; that key, not
the file name, is what the validator keys on. They carry both a `tools:`
allowlist and a `disallowedTools:` denylist (belt and braces — the denylist
survives the platform adding new tools), and a `maxTurns` so a verdict that
does not converge stops instead of circling. Agents preload the standards
they are asked to apply through `skills:` — "apply 01-rtl-i18n" is a wish
unless the skill is in the agent's context. Side-effect
skills use `disable-model-invocation`; hooks carry a platform `timeout`.

Say what is enforced and what is instructed. A rule described as guaranteed
when it is only requested is worse than no rule: it stops you checking.

### 6. Persistent state, resumable sessions
Every feature lives in `maestro_docs/tasks/<yyyy_mm_dd>_<slug>/` with
`plan.md` and `phase-N.md` carrying frontmatter `status:` — any session can
pick up exactly where the last one stopped.

### 7. One framework installed at a time
Superpowers, GSD, AIDD, and others are **sources we absorb ideas from**,
never layers we stack. Stacking orchestrators is how the v4 crash happened.

### 8. Never rebuild what Anthropic maintains
Any capability covered by an official plugin (`claude-plugins-official`) is
out of Maestro's scope and becomes a recommendation in `00-onboard`:
- LSP plugins → real-time diagnostics (replaces runtime typecheck hooks)
- `security-guidance` → per-edit vulnerability review (replaces security hooks)
- `frontend-design` → base UI quality (maestro-web layers RTL/AR on top)
- `commit-commands` → base git workflows (maestro-vcs layers gates on top)
- `github`, `context7`, `expo`, `figma`, `prisma` → used as-is

Maestro is a **business layer**, not a platform competitor.

## Success metrics (vs Maestro v4)

| Metric | v4 | v5 target |
|---|---|---|
| Processes spawned per file edit | 5–6 | 0 |
| Processes spawned per bash command | 3 | 1 (bash-guard, ≈ Node start-up, 40–60 ms) |
| Parallel typechecks possible | unbounded (bug) | 0 (LSP handles it) |
| Tests launched on Stop | yes (RAM crash) | never |
| Total hooks | 14 | 2 |
| Node RAM in heavy session | 33 GB (crash) | < 3 GB |
| Updating 33 projects | ~30 min script | 1 command |
