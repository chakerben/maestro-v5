---
name: 00-sdlc
description: Orchestrate the full development flow — a request becomes specced, planned, implemented, reviewed, shipped code, every step delegated. Use to take a feature end to end. Interactive by default, pausing for approval at each step; say "auto" for unattended execution to completion. Not for a single step (use plan or implement directly).
argument-hint: "<request> [auto]"
---

# Skill: sdlc

Take a request from idea to shipped code, delegating every step. Interactive
by default; autonomous when the caller says `auto`.

## Actions

| #  | Action      | Role                                        | Delegate                       |
|----|-------------|---------------------------------------------|--------------------------------|
| 01 | `spec`      | Consolidate the request into a contract     | self (or `maestro-pm:02-specs` when installed) |
| 02 | `plan`      | Produce the plan + phase files              | `maestro-dev:01-plan`          |
| 03 | `implement` | Build the plan, phase by phase, gated       | `executor` via `maestro-dev:02-implement` |
| 04 | `review`    | Independent verdict: ship or iterate        | `checker` agent                |
| 05 | `ship`      | Commit + open the change request            | `maestro-vcs:00-commit` |

Run `01 → 05`. On `04 = iterate`, loop `03 → 04` (max 3 iterations, then
`blocked`). `01` self-skips when the request already states an objective and
acceptance criteria. Before running an action, read its file in `actions/`.

## Modes

- **interactive** (default): pause for approval after 01, 02, and 04.
- **auto**: no pauses. Decide alone using `references/cognitive-protocols.md`
  rule 4. HARD STOPS that always break auto: a `blocked` status, a gate still
  red after 3 repair attempts, any payment or destructive action, any
  credential need. On a hard stop: write the state into the plan frontmatter,
  summarize what a human must decide, end the turn.

## Transversal rules

- Delegate every step; the orchestrator never writes or judges code itself.
- Adopt the expert posture of the detected domain (`references/expert-postures.md`)
  and pass it to every delegate.
- Every artifact lands in ONE feature folder
  `maestro_docs/tasks/<yyyy_mm_dd>_<slug>/`, resolved at entry.
- Drive plan status `pending → in-progress → implemented → reviewed`, or `blocked`.
- Never auto-branch onto the default branch; a feature branch is created in 03.
- Resume support: if the folder already exists with a plan, read its statuses
  and continue from the first incomplete step — never restart from scratch.
