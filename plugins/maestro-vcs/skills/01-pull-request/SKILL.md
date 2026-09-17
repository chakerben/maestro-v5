---
name: 01-pull-request
description: Open a structured pull request from the current feature branch — body built from the task folder (objective, phases, review verdict), reviewers hinted by touched areas. Use to open or update a PR. Not for merging (humans merge) or committing (00-commit).
argument-hint: "[draft]"
---

# Skill: pull-request

## Process

1. Preconditions: non-default branch, clean tree. Refuse on the default branch.
2. **Last secrets net.** Scan `git diff <default-branch>...HEAD -U0` (added
   lines only) against `../00-commit/assets/secret-patterns.md`. This covers
   every commit on the branch, whatever path created it. A hit → stop, print
   file + masked match, and refuse to push: a pushed secret is public history.
3. Push the branch after confirming.
4. Build the body from the task folder when one exists:
   - **Objective** (from spec.md, one sentence)
   - **What changed** (phase table with statuses)
   - **Review** (checker verdict + score from review.md, if present)
   - **How to test** (the phases' validation commands)
   - **Task folder**: `maestro_docs/tasks/<...>`
   No task folder → build from the commit list, and say so.
5. Title = conventional subject of the dominant change. `draft` argument →
   draft PR.
6. Open via the official github plugin / `gh pr create`. Report the URL.
7. NEVER merge. Merging is a human act.

## Test

- The PR body contains objective + test instructions.
- The branch diff against the default branch was scanned; a branch carrying
  `sk_live_xxxxxxxxxxxxxxxxxxxxxxxx` in any commit was not pushed.
- No merge occurred.
