---
name: 01-memory
description: Generate or refresh the project memory bank content (project-brief, tech-decisions, patterns) by reading the actual codebase. Use when memory files need generating, feel stale, or after major architectural changes. Not for the initial scaffold (00-onboard) or reference syncing (the SessionStart hook does that automatically).
argument-hint: generate | review | sync
---

# Skill: memory

Generates and reviews the CONTENT of `maestro_docs/memory/` by reading the
actual codebase. Complements `00-onboard` (structure) and the SessionStart
hook (reference sync).

## Actions

| #  | Action     | Role                                                   | Input          |
|----|------------|--------------------------------------------------------|----------------|
| 01 | `generate` | Read the codebase, write/refresh the memory bank files | project root   |
| 02 | `review`   | Check memory files for staleness and contradictions    | memory dir     |
| 03 | `sync`     | Force a reference re-sync into CLAUDE.md               | memory dir     |

Dispatch by intent: "generate/refresh memory" → 01; "is my memory up to
date" → 02; "the CLAUDE.md block is wrong" → 03.
Before running an action, read its file in `actions/`.

## Memory rules (binding for every action)

- Capture the macro and the non-derivable: decisions, conventions, gotchas,
  the WHY. Never restate a schema or file tree — point to the code.
- One fact, one home. Reference elsewhere, never duplicate.
- Short bullets. Code in backticks. No versions in tech names (`React`, not
  `React 19`).
- Reflect current state only. Delete rather than leave stale sections.
- Every write shows a diff preview and waits for approval.
