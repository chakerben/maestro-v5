---
name: 01-pull-request
description: Open a structured pull request from the current feature branch — body built from the task folder (objective, phases, review verdict), reviewers hinted by touched areas. Use to open or update a PR. Not for merging (humans merge) or committing (00-commit).
argument-hint: "[draft]"
---

# Skill: pull-request

## Process

1. Preconditions: non-default branch, clean tree, branch pushed
   (push it after confirming). Refuse on the default branch.
2. Build the body from the task folder when one exists:
   - **Objective** (from spec.md, one sentence)
   - **What changed** (phase table with statuses)
   - **Review** (checker verdict + score from review.md, if present)
   - **How to test** (the phases' validation commands)
   - **Task folder**: `maestro_docs/tasks/<...>`
   No task folder → build from the commit list, and say so.
3. Title = conventional subject of the dominant change. `draft` argument →
   draft PR.
4. Open via the official github plugin / `gh pr create`. Report the URL.
5. NEVER merge. Merging is a human act.

## Test

- The PR body contains objective + test instructions.
- No merge occurred.
