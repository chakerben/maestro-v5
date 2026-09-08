# 01 - Gate

Run the quality gate on the diff.

## Process

0. **Ownership check, before anything else.** `git branch --show-current` and
   `git status --short`. Changes you did not make in this session = another
   session shares this directory. Then, without exception:
   - never `git add -A` / `git commit -a` — commit the paths you touched:
     `git commit -F <message-file> -- <paths>` (options BEFORE `--`, or the
     pathspec swallows them);
   - never `git switch` here; branch work belongs in a worktree
     (`maestro-vcs:03-worktree`);
   - name the foreign paths in the report.
1. Collect the diff: staged changes (`git diff --cached`); if nothing staged,
   ask whether to stage all tracked modifications — in a shared directory,
   list what you would stage and stage only your own paths.
2. **Secrets scan (always, never skippable).** Match the diff's ADDED lines
   against every pattern in `assets/secret-patterns.md`. Any hit → print the
   file, the masked match (first 8 chars + …), the pattern name → RED, stop.
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
- With another session's staged rename in the tree, the commit carries only the
  paths this session touched.
- No check ran with `--silent`.
- A red gate produced no commit.
