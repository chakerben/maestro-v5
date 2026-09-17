# 01 - Gate

Run the quality gate on the diff.

## Process

1. Collect the diff: staged changes (`git diff --cached`); if nothing staged,
   ask whether to stage all tracked modifications.
2. **Secrets scan (always, never skippable).** The result is already in the
   skill's "Live state" (it ran `scripts/secret-scan.sh cached` at
   invocation). If anything was staged since, re-run it. `RED` → the output
   already names file:line, pattern, masked match → stop. `ALLOWED` entries
   go verbatim into the commit body as `Gate-Allow:` lines (action 02).
3. Read `maestro_docs/gates.json` (default `standard`). Run the level's
   checks with the lockfile-detected runner:
   - typecheck: the project's `typecheck` script if present (skip with a note
     if absent — LSP already covered real-time)
   - lint: the `lint` script if present
   - tests: `high` → tests touching changed paths; `paranoid` → full suite
4. Log each check: command, exit code, duration. Any red → print the failing
   output tail (20 lines max), stop with "gate RED — fix or 'bypass gate: <reason>'".
5. All green → report the checklist and proceed.

## Test

- A diff containing `sk_live_xxxxxxxxxxxxxxxxxxxxxxxx` is blocked even at level `off`.
- No check ran with `--silent`.
- A red gate produced no commit.
