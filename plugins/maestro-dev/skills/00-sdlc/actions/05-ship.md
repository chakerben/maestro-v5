# 05 - Ship

Commit and open the change request.

## Process

1. If `maestro-vcs:00-commit` is installed, delegate to it (gates + secret
   detection). Otherwise use the official commit-commands plugin, and run a
   secret-pattern scan on the diff first.
2. Conventional commit message from the spec objective. Push the feature
   branch. Open the PR with: objective, phase summary, review score, and the
   task-folder path.
3. Interactive: confirm before push. Auto: push and open the PR (a PR is
   reviewable — not a destructive action) but NEVER merge.
4. Final report: folder path, branch, PR link, statuses.

## Test

- The PR body links objective, phases, and the review verdict.
- Auto mode did not merge anything.
