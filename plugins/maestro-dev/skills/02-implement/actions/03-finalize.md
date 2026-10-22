# 03 - Finalize

Close the implementation.

## Process

1. All phases `done` → set plan `status: implemented` as a tiny final commit
   (`chore(<slug>): plan implemented`) — never by amending the last phase
   commit, which may already be pushed.
2. Any phase `blocked` → leave plan `in-progress`, return the blocked summary.
3. Report: phases completed, commits made, validation results, anything the
   reviewer should look at first.

## Test

- Plan status matches reality (`implemented` iff every phase is `done`).
- The report lists every commit hash of this run.
