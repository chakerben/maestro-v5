# 01 - Reproduce

Turn the report into a command that fails on demand.

## Process

1. Resolve the task folder (`maestro_docs/tasks/<date>_<slug>/`); create
   `debug.md` from `../assets/debug-template.md` with `status: reproducing`.
   Copy the report verbatim into `## Report` — the user's words, the stack
   trace, the failing test path, the screenshot description.
2. Read before assuming: open the file the stack trace names, the route the
   report names, the test that fails. Quote the lines in `## Evidence`.
3. Build the repro. In order of preference: an existing failing test; a new
   test that encodes the report; a script; a documented manual sequence
   (last resort, and say why). Run it. Paste the output tail.
4. Not reproducible → ask the ONE question most likely to unlock it (env,
   data, locale, account). Three failed attempts → `status: not-reproducible`,
   record all three, stop.
5. Reproduced → write the exact command in `## Repro`, set
   `status: isolating`.

## Test

- `## Repro` contains a command and its captured failing output.
- No source file was modified in this action (`git status` shows only
  `maestro_docs/` and, at most, one new test file).
