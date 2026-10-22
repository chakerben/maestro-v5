# 05 - Ship

Commit and open the change request.

## Process

1. When maestro-vcs is installed, invoke `maestro-vcs:00-commit` (gates +
   its injected secrets scan). Else grep the staged diff's added lines
   against `${CLAUDE_PLUGIN_ROOT}/skills/02-implement/assets/secret-patterns.md`
   (each row's regex) and stop on any hit before committing.
2. Conventional commit message from the spec objective (00-commit composes
   it; pass the caller's mode so auto does not pause).
3. When maestro-vcs is installed, invoke `maestro-vcs:01-pull-request` — it
   owns the branch-wide secrets scan (every commit of the branch, not only
   the last diff), refuses the default branch, requires a clean tree, and
   writes the PR body: objective, phase summary, review score, task-folder
   path. Else: push the feature branch yourself and open the PR with that
   same body, after scanning `git diff <default>...HEAD` added lines against
   the secret-patterns mirror.
   Interactive: confirm before push. Auto: push and open the PR (a PR is
   reviewable — not a destructive action) but NEVER merge.
4. Final report: folder path, branch, PR link, statuses.

## Test

- The PR body links objective, phases, and the review verdict.
- Auto mode did not merge anything.
