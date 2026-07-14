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
- `PreToolUse(Bash)` → `bash-guard.js` (maestro-quality) — pure security gate.

No other hook, ever. Not for quality. Not for convenience. Not "just this once".

### 2. Never typecheck, test, or format inside a hook
- Formatting → the executor agent formats what it touches (agent instruction).
- Typecheck → real-time via official LSP plugins; final gate at commit.
- Tests → gates of `maestro-vcs:00-commit` and `maestro-dev:03-review`.

### 3. Every hook must prove itself
- < 100 ms wall time.
- `exit 0` on any internal error (fail open, never block on our own bugs).
- No heavy subprocess spawning. No network. Lock required if anything async.

### 4. Router-based skills
Every skill = `SKILL.md` (contract + actions table) + `actions/*.md` (atomic,
each with a `## Test` section) + optional `assets/` and `references/`.

### 5. Agents with model pinning and strict separation
- `executor` (sonnet): builds, never judges its own work.
- `checker` (opus): judges with evidence, never edits the work.
No agent both writes and approves the same change.
**Enforced, not just instructed**: reviewer agents carry a `tools:` allowlist
without Edit/Write — the platform physically prevents them from modifying code.
Same principle everywhere: side-effect skills use `disable-model-invocation`,
knowledge skills use `user-invocable: false`, hooks carry a platform `timeout`.

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
| Processes spawned per bash command | 3 | 1 (bash-guard, <20 ms) |
| Parallel typechecks possible | unbounded (bug) | 0 (LSP handles it) |
| Tests launched on Stop | yes (RAM crash) | never |
| Total hooks | 14 | 2 |
| Node RAM in heavy session | 33 GB (crash) | < 3 GB |
| Updating 33 projects | ~30 min script | 1 command |
