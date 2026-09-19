# 04 - Fix

Regression test first, then the fix, then nothing else.

## Process

1. Write the regression test from `## Minimal case` in the project's test
   tree, named after the bug (not after the function). Run it: it must be
   RED. Paste the failing output in `## Regression test`.
2. Fix at the cause. Smallest change that makes the test green. Format what
   you touch (executor rule). Run the regression test → GREEN, then the
   related suite (`high` gate scope) → GREEN. Paste both tails.
3. Re-run the original repro from action 01 → passes. If the project has an
   `ar` locale, re-run under `ar`.
4. Set `status: fixed`; fill `## Fix` with the diff summary and what was
   deliberately NOT changed. Move anything from `## Seen on the way` to
   `maestro-pm:03-ticket` when installed, else leave it listed.
5. Commit, message `fix(<scope>): <cause in one clause>` with
   `Refs: maestro_docs/tasks/<folder>`. When maestro-vcs is installed, invoke
   `maestro-vcs:00-commit` (gate + its injected secrets scan). Else grep the
   staged diff's added lines against
   `${CLAUDE_PLUGIN_ROOT}/skills/02-implement/assets/secret-patterns.md`
   (each row's regex) and stop on any hit.

## Test

- The regression test exists, failed before the fix (captured), passes after.
- `git diff --stat` for the fix commit touches the cause site and the test —
  a diff touching > 5 files needs an explicit sentence in `## Fix` saying why.
- The commit went through `00-commit` (gate summary line in the report), or
  the fallback scan's command and empty result are in the report.
