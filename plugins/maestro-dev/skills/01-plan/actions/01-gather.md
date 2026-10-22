# 01 - Gather

Resolve and restate the source.

## Process

0. Resolve the feature folder `maestro_docs/tasks/<yyyy_mm_dd>_<slug>/`
   (the caller's when `00-sdlc` passes one; else today + a slug from the
   request). A `plan.md` already there → read its statuses and announce
   "plan exists — resuming at phase <n>"; never write a second plan beside
   it. Every artifact of this skill lands in that folder.
1. Resolve the source: a path must exist and be readable; free text is used
   as-is. Neither → stop with "nothing to plan from". Never fabricate.
2. Restate in your own words: objective, constraints, acceptance criteria.
   List what is NOT stated (unknowns) — they feed 02-explore.
3. Detect the domain(s) and announce the adopted expert posture(s).

## Test

- The restatement contains no claim absent from the source.
- Unknowns are listed, not silently resolved.
- The feature folder is resolved and announced; an existing plan was reused.
