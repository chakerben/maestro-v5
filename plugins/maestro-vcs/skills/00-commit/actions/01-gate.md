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
2. **Secrets scan (always, never skippable).** The result is already in the
   skill's "Live state" (it ran `scripts/secret-scan.sh cached` at
   invocation). If anything was staged since, re-run it. `RED` → the output
   already names file:line, pattern, masked match → stop. `ALLOWED` entries
   go verbatim into the commit body as `Gate-Allow:` lines (action 02).
3. Run the level's checks: `maestro-check --scope staged` (maestro-quality's
   `bin/`, on the PATH when that plugin is enabled — level from
   `maestro_docs/gates.json`, default `standard`: typecheck, lint, rtl,
   boundaries, tests on the changed paths, fonts). Read its JSON verdict,
   not its prose. Without maestro-quality: run the project's `typecheck`
   script yourself and say that lint/rtl/tests did not run.
4. Report the verdict table (name · status · seconds) and every `skipped`
   reason. Any `red` → print that check's output tail, stop with
   "gate RED — fix or 'bypass gate: <reason>'".
5. All green → proceed.

## Test

- A diff containing `sk_live_4eC39HqLyjWDarjtT1zdp7dc` is blocked even at level `off`.
- The report quotes `maestro-check`'s verdict (or says maestro-quality is
  absent and which checks therefore did not run); no check was declared
  green without a command behind it.
- With another session's staged rename in the tree, the commit carries only the
  paths this session touched.
- No check ran with `--silent`.
- A red gate produced no commit.
