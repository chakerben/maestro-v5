# 01 - Prepare

Resolve the plan and set the workspace.

## Process

1. Resolve the plan path — must exist and be readable, else stop with
   "plan not found at <path>". Never fabricate a plan.
2. On the default branch: the checkout may be shared with another session
   (`git status --short` lists paths that are not yours) — then never
   `git switch`: route to `maestro-vcs:03-worktree` when installed, else stop
   and say so. Own checkout: create a branch and announce it. Name it by the
   project's stated convention when it has one (`CLAUDE.md`,
   `.claude/rules/*.md`, or the shape of recent branches —
   e.g. `{type}/issue-{n}-{desc}`); Maestro's default `feat/<slug>` applies
   only when nothing is stated. On a non-default branch: keep it.
3. Set plan frontmatter `status: in-progress` (rides into the first phase
   commit — no separate commit).
4. Read every phase status — announce the resume point. A phase already
   `in-progress` is half-done: capture `git status --short` and its `## Log`
   (attempts used) for the executor's dispatch in 02. A phase `blocked` →
   stop here with its last failure; a human resets it to `pending`.

## Test

- Current branch is not the default branch.
- Plan frontmatter reads `status: in-progress`.
- If resuming, `done` phases were not re-executed; a `blocked` phase stopped
  the run; an `in-progress` phase's partial diff was handed to the executor,
  not discarded.
