# 05 - Ship

Commit and open the change request.

## Process

1. When maestro-vcs is installed, invoke `maestro-vcs:00-commit` (gates +
   its injected secrets scan). Else grep the staged diff's added lines
   against `${CLAUDE_PLUGIN_ROOT}/skills/02-implement/assets/secret-patterns.md`
   (each row's regex) and stop on any hit before committing.
2. Conventional commit message from the spec objective. Push the feature
   branch. Open the PR with: objective, phase summary, review score, and the
   task-folder path.
3. Interactive: confirm before push. Auto: push and open the PR (a PR is
   reviewable — not a destructive action) but NEVER merge.
4. Final report: folder path, branch, PR link, statuses.

## Test

- The PR body links objective, phases, and the review verdict.
- Auto mode did not merge anything.
