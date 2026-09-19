---
name: 01-pull-request
description: Open a structured pull request from the current feature branch — body built from the task folder (objective, phases, review verdict), reviewers hinted by touched areas. Use to open or update a PR. Not for merging (humans merge) or committing (00-commit).
argument-hint: "[draft]"
allowed-tools: Bash   # turn-scoped: the !`…` injections above use shell builtins, pipes and $(…) that pattern grants do not cover
---

# Skill: pull-request

## Live state (computed at invocation)

Branch and tree:
!`echo "branch: $(git branch --show-current)"; git status --short | head -10; [ -z "$(git status --porcelain)" ] && echo "tree: clean" || echo "tree: DIRTY"`

Commits on this branch vs the default branch:
!`B=""; for b in origin/main main origin/master master; do git rev-parse --verify -q "$b" >/dev/null && { B="$b"; break; }; done; if [ -n "$B" ]; then echo "base: $B"; git log --oneline "$B..HEAD" | head -30; else echo "(no base branch found: origin/main, main, origin/master, master)"; fi`

Secrets scan of the WHOLE branch diff (every commit, whatever created it):
!`bash "${CLAUDE_PLUGIN_ROOT}/skills/00-commit/scripts/secret-scan.sh" branch`

## Process

1. Preconditions: non-default branch, clean tree. Refuse on the default branch.
   On the default branch, do NOT switch the current directory to make the
   precondition pass — another session may be reading it. Move the work to a
   worktree instead (`maestro-vcs:03-worktree`) and open the PR from there.
2. **Last secrets net.** Read the branch scan in "Live state" above (it
   covers every commit on the branch, whatever path created it). `RED` → stop
   and refuse to push: a pushed secret is public history. If the base branch
   was not found, run `secret-scan.sh branch <base>` with the right base
   before going further — never skip.
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

## Writing

The PR body follows `maestro-pm:04-writing` when maestro-pm is installed:
first line carries the point, no filler, no praise of the change.

## Test

- The PR body contains objective + test instructions.
- The branch diff against the default branch was scanned; a branch carrying
  `sk_live_xxxxxxxxxxxxxxxxxxxxxxxx` in any commit was not pushed.
- No merge occurred.
