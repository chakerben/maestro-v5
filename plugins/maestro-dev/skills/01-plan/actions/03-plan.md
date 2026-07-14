# 03 - Plan

Break into phases and write the files.

## Process

1. Slice into ordered phases (each <= ~5 files, one coherent step: e.g.
   "schema + migration", "service layer", "API route", "UI", "tests hardening").
2. Write `plan.md` from `assets/plan-template.md`: frontmatter
   (`status: pending`, date, slug), objective, phase table, risks (including
   what the devil-advocate would raise), rollback note.
3. Write one `phase-N.md` per phase from `assets/phase-template.md`:
   frontmatter `status: pending`, scope, acceptance criteria (falsifiable),
   validation commands.
4. Summarize the plan in <= 10 lines for the caller.

## Test

- Every phase file has frontmatter `status: pending` and at least one
  validation command or concrete check.
- The phases, executed in order, cover every acceptance criterion of the source.
