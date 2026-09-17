# maestro-core

The Maestro 5 foundation. Install this first.

## Router

`references/routing.md` is the plain-prompt map. The SessionStart hook keeps a
`<maestro_routing>` copy current in every project's CLAUDE.md, so nobody types
a skill name.

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
  CLAUDE.md in sync with `maestro_docs/memory/`. Measured at ~30ms,
  fail-open, no subprocesses.
