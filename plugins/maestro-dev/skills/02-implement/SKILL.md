---
name: 02-implement
description: Build an existing plan's code, phase by phase, each phase gated on its acceptance criteria, with resumable state. Use when an approved plan must become code. Not for planning (01-plan) or judging the result (checker agent).
argument-hint: "<plan path>"
---

# Skill: implement

Loop the plan's phases in order, delegating each to the executor agent,
gating on assertions, persisting state so any session can resume.

## Actions

| #  | Action     | Role                                              | Input     |
|----|------------|---------------------------------------------------|-----------|
| 01 | `prepare`  | Resolve plan, feature branch, mark in-progress    | plan path |
| 02 | `execute`  | Phase loop: dispatch → assert → commit → next     | prepared plan |
| 03 | `finalize` | Mark implemented, summary for the caller          | executed plan |

Run `01 → 03`. Before running an action, read its file in `actions/`.

## Transversal rules

- **Context budget**: each phase is dispatched to a FRESH executor context
  carrying only: the phase file, the plan objective, the memory-bank
  references, and the expert posture — never the full session history.
- The gate is the phase's validation passing, never a self-report
  (protocols rule 6, `${CLAUDE_PLUGIN_ROOT}/skills/06-protocols/SKILL.md`).
- Drift from the plan → protocols rule 5: stop with "replan needed" + the
  specific drift.
- Resume: on entry, read all phase statuses; skip `done` phases; continue
  from the first `pending`/`in-progress`.
