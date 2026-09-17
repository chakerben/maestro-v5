# 02 - Isolate

Shrink to the smallest failing case.

## Process

1. Remove inputs, steps, and conditions one at a time, re-running the repro
   after each removal. Keep only what is needed for it to still fail.
   Log each step in `## Isolation` as `removed X → still fails / passes`.
2. If the bug appeared over time ("worked yesterday"): `git bisect` between
   a known-good and the current commit using the repro command as the
   oracle. Record the culprit commit and its diff summary.
3. If locale-dependent: run under each locale; record which fail.
4. Write the minimal case in `## Minimal case` — ideally a test of ≤ 15 lines.

## Test

- `## Minimal case` fails with the repro command and is strictly smaller
  than the original report (fewer steps, inputs, or files).
- Every removal in `## Isolation` names its result.
