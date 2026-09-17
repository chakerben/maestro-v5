---
name: 02-gardener
description: Maintain CLAUDE.md and the memory bank over time — measure context weight, archive stale content, detect contradictions between rules. Use when context files have grown, sessions feel diluted, or rules contradict each other. Not for generating memory content (01-memory) or initial setup (00-onboard).
argument-hint: measure | archive | contradictions
---

# Skill: gardener

The anti-bloat skill. Keeps the project's AI context lean and coherent so
every session starts sharp. Context weight is a budget, not a trophy.

## Actions

| #  | Action           | Role                                                          | Input        |
|----|------------------|---------------------------------------------------------------|--------------|
| 01 | `measure`        | Report context weight per file, flag the heavy ones           | project root |
| 02 | `archive`        | Move stale content to `internal/archive/` (approval required) | memory dir   |
| 03 | `contradictions` | Detect conflicting rules across context files                 | context files |

Dispatch: "how heavy is my context" → 01; "clean up / archive" → 02;
"my rules conflict" → 03. A full garden run is 01 → 03 → 02.
Before running an action, read its file in `actions/`.

## Binding rules

- Never delete — archive. Archives live in `maestro_docs/memory/internal/archive/`.
- Every edit shows a diff preview and requires explicit approval.
- Target budget: tier-1 (always-loaded) memory ≤ 200 lines total.
- **Skill-gap log** (absorbed from task-observer, no always-on skill): every
  full garden run ends by listing corrections the user made more than once
  in recent sessions (same instruction repeated, same mistake fixed twice)
  into `maestro_docs/memory/internal/skill-gaps.md` — one line each,
  "<what was corrected> → candidate: <existing skill to amend | new skill>".
  Three entries on the same line = a change to the Maestro marketplace, not
  to this project.
