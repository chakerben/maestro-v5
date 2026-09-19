# maestro-core

The Maestro 5 foundation. Install this first.

## Router

`references/routing.md` is the plain-prompt map. The SessionStart hook keeps a
`<maestro_routing>` copy current in every project's CLAUDE.md, so nobody types
a skill name.

## Model policy

`references/model-policy.md` is the ladder every skill and agent pins
against: sonnet executes (session default), fable thinks (plan, brainstorm,
architecture, review), opus only when critical. Human version:
[docs/MODEL-POLICY.md](../../docs/MODEL-POLICY.md).

## Skills

- `00-onboard` — full project setup: stack detection, official plugin
  installation, Maestro plugin activation, memory bank scaffold + routing
  block. **Start here.**
- `01-memory` — generate/review memory bank content from the actual codebase
- `02-gardener` — anti-bloat: measure context weight, archive stale content,
  detect contradictions (tier-1 budget: 200 lines)
- `03-condense` — terse output mode (lite/full/ultra)
- `04-doctor` — install health check; flags v4/claude-flow contraband

## Commands

- `/maestro` — the capability menu, grouped by intent

## Hooks

Exactly one (Philosophy rule #1):

- `SessionStart` → `memory-sync.js` — keeps the `<maestro_memory>` block in
  CLAUDE.md in sync with `maestro_docs/memory/`, and the `<maestro_routing>`
  block in sync with `references/routing.md`. Measured at ~40 ms, fail-open,
  no subprocesses.

What that means for your repo:

- **CLAUDE.md is rewritten at session start** whenever the memory bank or the
  router changes — in practice, after every Maestro release. Either keep
  CLAUDE.md out of version control, or expect a `chore: sync CLAUDE.md`
  commit in each project after a release. Never hand-edit the two blocks.
- **Add to `.gitignore`**: `.claude-md.maestro.lock` (the write lock) and
  `CLAUDE.md.*.tmp` (the atomic-write staging file). Both are transient and
  only survive a crash mid-write.
