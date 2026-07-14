---
name: 02-specs
description: Write the technical spec for a story or feature — API contracts, data model changes, integration points, non-functional requirements. Use between stories and planning when the change is structurally significant. Not for simple features (sdlc's spec step suffices) or product framing (00-prd).
argument-hint: "<story path or feature>"
---

# Skill: specs

The bridge between WHAT (stories) and the plan (HOW, phased). Written by the
m-architect posture.

## Process

1. Source: story/PRD path or description. Read the memory bank + relevant code
   first (existing patterns win over invented ones).
2. Sections, all evidence-based:
   - **Data model**: Prisma schema diff, migration notes (reversible?),
     locale-aware fields where content is multilingual.
   - **API contract**: routes/server actions with Zod schemas (input AND
     output), auth requirement per endpoint, error shape.
   - **Integration points**: what existing modules change, what stays intact.
   - **Non-functional**: expected volume, latency budget, caching plan,
     RTL/i18n impact, rollback strategy.
   - **Decisions**: each with one alternative considered and the reason —
     mirrored into tech-decisions.md on approval.
3. Devil-advocate pass on the riskiest decision before presenting.
4. Save to `maestro_docs/specs/spec-<slug>.md`; hand off to
   `maestro-dev:01-plan`.

## Test

- Every API endpoint in the spec has an auth requirement stated.
- Every schema change states its migration reversibility.
