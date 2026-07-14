# 03 - Implement

Delegate the build.

## Process

1. Invoke `maestro-dev:02-implement` with the plan path (it drives the
   executor agent, phase by phase, gated).
2. On return: `implemented` → continue to 04. `blocked` → interactive: surface
   to the human; auto: HARD STOP with the blocked summary.

## Test

- Every phase file reads `status: done`, or the run stopped at `blocked` with
  a written reason.
