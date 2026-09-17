# 01 - Prepare

Resolve the plan and set the workspace.

## Process

1. Resolve the plan path — must exist and be readable, else stop with
   "plan not found at <path>". Never fabricate a plan.
2. On the default branch: create a branch and announce it. Name it by the
   project's stated convention when it has one (`CLAUDE.md`,
   `.claude/rules/*.md`, or the shape of recent branches —
   e.g. `{type}/issue-{n}-{desc}`); Maestro's default `feat/<slug>` applies
   only when nothing is stated. On a non-default branch: keep it.
3. Set plan frontmatter `status: in-progress` (rides into the first phase
   commit — no separate commit).
4. Read every phase status — announce the resume point if any phase is
   already `done`.

## Test

- Current branch is not the default branch.
- Plan frontmatter reads `status: in-progress`.
- If resuming, `done` phases were not re-executed.
