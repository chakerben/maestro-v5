---
name: 01-plan
description: Turn a request, spec, or ticket into a phased implementation plan with resumable state. Use to plan a feature before building, or to turn a spec into executable phases. Never writes code. Not for reviewing a diff or debugging.
argument-hint: "<spec path or request>"
---

# Skill: plan

Turn a source into an implementation plan and its phase files. Never writes
code. The plan is the persistent state that makes any session resumable.

## Actions

| #  | Action    | Role                                                  | Input             |
|----|-----------|-------------------------------------------------------|-------------------|
| 01 | `gather`  | Resolve and restate the source                        | request/spec path |
| 02 | `explore` | Read the codebase: integration points, conventions, feasibility | gathered source |
| 03 | `plan`    | Break into phases, write plan.md + phase-N.md         | explore output    |

Run `01 → 03`. Before running an action, read its file in `actions/`.

## Transversal rules

- Adopt the domain expert posture (`../references/expert-postures.md`) —
  the plan must contain what the expert would insist on, not just what was asked.
- Apply `../references/cognitive-protocols.md` rule 3: every phase criterion
  is falsifiable.
- Phases are small enough that one executor run completes one phase (rule of
  thumb: ≤ 5 files touched per phase).
- Templates in `assets/` are the required format — frontmatter `status:` is
  what makes resume work. Never omit it.
