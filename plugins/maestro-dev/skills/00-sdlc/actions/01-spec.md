# 01 - Spec

Consolidate the request into a testable contract.

## Input

The user request (free text, a ticket, or a file path).

## Output

`spec.md` in the feature folder: objective, scope in/out, acceptance criteria.
Self-skip when the source already states objective + acceptance criteria.

## Process

1. Resolve the feature folder `maestro_docs/tasks/<yyyy_mm_dd>_<slug>/`
   (create it; slug from the request).
2. Extract: objective (one sentence), in-scope, out-of-scope, acceptance
   criteria (each independently checkable), open questions.
3. Interactive: ask the open questions (grouped, once). Auto: resolve each
   with the safest reasonable interpretation and LOG the interpretation in
   the spec under "Assumed in auto mode".
4. Adopt the expert posture of the detected domain; add the criteria that
   posture demands (e.g. auth feature → an authz criterion appears even if
   the user didn't ask).
5. Write `spec.md`.

## Test

- Every acceptance criterion is checkable by a command or a concrete inspection.
- Auto-mode assumptions, if any, are explicitly listed in the spec.
