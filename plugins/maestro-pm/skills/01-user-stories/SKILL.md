---
name: 01-user-stories
description: Turn a PRD or feature description into user stories with testable acceptance criteria (Given/When/Then), sized and prioritized. Use after a PRD, before planning. Not for the PRD itself (00-prd) or technical specs (02-specs).
argument-hint: "<PRD path or feature>"
---

# Skill: user-stories

## Process

1. Source = PRD path or description. Extract the flows.
2. One story per user-visible capability: `As a <persona>, I want <capability>,
   so that <outcome>`. The persona comes from the PRD — no generic "user"
   when the PRD names better.
3. **Acceptance criteria in Given/When/Then**, each independently testable,
   covering: the happy path, the top failure path, the empty/first-run state,
   and permissions (who must NOT be able to do this).
4. i18n stories are explicit when the market is multilingual ("content
   renders correctly in AR/RTL" is a story with its own criteria, not a footnote).
5. Size (S/M/L by uncertainty, not hours) and order by dependency + value.
6. Save to `maestro_docs/specs/stories-<slug>.md`. Each story is later one
   sdlc run or one plan.

## Test

- Every criterion is Given/When/Then and machine- or reviewer-checkable.
- Permissions criteria exist for every mutating capability.
