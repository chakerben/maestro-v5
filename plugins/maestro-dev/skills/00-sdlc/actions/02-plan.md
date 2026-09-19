# 02 - Plan

Delegate plan production.

## Process

1. Invoke `maestro-dev:01-plan` with the spec path.
2. Interactive: present the plan summary (phases + criteria), wait for approval.
   Auto: run the `m-devil-advocate` agent on the plan instead of a human pause;
   apply its "proceed with changes" items when trivially safe, log the rest;
   proceed unless its verdict is "reconsider" (→ hard stop).
3. Set plan frontmatter `status: pending`, `mode: interactive|auto` (the
   mode this run was invoked with), `iterations: 0`.

## Test

- `plan.md` and `phase-N.md` files exist in the feature folder.
- In auto mode, the devil-advocate verdict is recorded in the plan.
- Plan frontmatter carries `mode:` and `iterations: 0`.
