---
name: 03-trustworthy-gates
description: Use when adding, running or reading a check (tests, typecheck, lint, CI job, verification script, health probe) and before reporting green. Not for setting the gate level (00-quality-gate).
user-invocable: false
---

# Skill: trustworthy-gates

A green that cannot go red certifies nothing. Every rule names the incident
class behind it. **[guard]** = ship this as a test, a CI step or a wrapper
script, not as prose — when the project has none, say so and propose it;
never build it unasked.

## Reading a result

- Never judge a command through a pipe: redirect to a file, print the exit
  code on its own, read the file — because `| tail` and `| tee` returned
  success for a failed typecheck before a push. **[guard]** a `run-check`
  wrapper (log file + explicit exit code).
- A skipped test fails CI; read the runner's executed count — because part
  of a suite had never run anywhere. **[guard]** CI step, skipped count > 0.
- Tests never skip themselves when a dependency is unreachable — because
  the skip is indistinguishable from a pass.
- Re-run a timeout-shaped red alone, and a surprising green alone — because
  CPU contention from parallel sessions fakes both.
- A red CI within seconds on every PR is infrastructure (billing, lockfile,
  runner): check that before the code — because hours went into the code.
- When a gate is already soft, compare error counts against the default
  branch — because "green" hid new type errors.

## Adding a gate

- Prove a new gate can fail: seed one violation, see red, remove it — because
  a guard that fails silently is worse than none.
- Delete fake CI jobs (`|| true`, wrong artefact path) instead of keeping
  them green — because they certify nothing.
- Turn a written convention into a type, a lint rule or a test — because a
  rule that is only written gets broken.
- Ship new enforcement log-only, measure false positives, then enforce —
  because a strict guard on real traffic blocked legitimate users.
- Every incident ends with a guard test that states its own blind spots —
  because the same bug class otherwise returns.

## Tests that mean something

- Mutation-check a regression test (revert the fix, see red) and size
  fixtures past engine thresholds — because the test passed with the bug in.
- Fixtures share id shape and origin with production data; a changed
  decision flips the assertion, never deletes it — because fixtures hid a
  real format mismatch.

## Before claiming

- Verify the commit, not the working tree; re-stage after late edits —
  because the pushed commit lacked the fix.
- Measure the request really sent and the file really produced before
  claiming a defect or a fix — because plans were built on assumed behaviour.
- Validate browser behaviour in a browser, not with an HTTP client — because
  cookies, CORS, caching and hydration differ.

## Test

- Every "green" reported under this skill shows the command, its exit code
  captured apart from any pipe, and the executed / skipped counts.
- A gate added under this skill was seen red once on a seeded violation,
  and the report says so.
- A fix reported under this skill names the commit that carries it, not the
  working tree.
