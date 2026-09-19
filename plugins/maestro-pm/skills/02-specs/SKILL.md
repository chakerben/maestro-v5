---
name: 02-specs
description: Write the technical spec for a story or feature — API contracts, data model changes, integration points, non-functional requirements. Use only when the change adds a new table/collection, a new external contract, or changes auth; otherwise maestro-dev:00-sdlc's inline spec suffices. Not for product framing (00-prd).
argument-hint: "<story path or feature>"
---

# Skill: specs

The bridge between WHAT (stories) and the plan (HOW, phased). Written by the
m-architect posture. Trigger rule, shared with `maestro-dev:00-sdlc`: a new
table/collection, a new external contract, or an auth change. Anything else
stays in sdlc's inline `spec.md`.

## Process

1. Source: story/PRD path or description. Read the memory bank + relevant code
   first (existing patterns win over invented ones).
2. Sections, all evidence-based:
   - **Data model**: Prisma diff OR Firestore collections + rules OR SQL
     migration, with migration notes (reversible?) and locale-aware fields
     where content is multilingual.
   - **Contracts**: Zod schemas OR Dart models + rules OR OpenAPI, input AND
     output, auth requirement per endpoint, error shape.
   - **Integration points**: what existing modules change, what stays intact.
   - **Non-functional**: expected volume, latency budget, caching plan,
     RTL/i18n impact, rollback strategy.
   - **Decisions**: each with one alternative considered and the reason —
     mirrored into tech-decisions.md on approval.
3. Devil-advocate pass on the riskiest decision before presenting.
4. Save to `maestro_docs/specs/spec-<slug>.md`. When invoked from sdlc, that
   path is referenced from `maestro_docs/tasks/<date>_<slug>/spec.md` under
   `## Technical spec`; hand off to `maestro-dev:01-plan`.

## Test

- Every API endpoint in the spec has an auth requirement stated.
- Every schema change states its migration reversibility.
