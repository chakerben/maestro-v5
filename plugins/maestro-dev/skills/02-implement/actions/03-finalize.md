# 03 - Finalize

Close the implementation.

## Process

1. All phases `done` → set plan `status: implemented` (commits with the last
   phase or as a tiny final commit).
2. Any phase `blocked` → leave plan `in-progress`, return the blocked summary.
3. Report: phases completed, commits made, validation results, anything the
   reviewer should look at first.

## Test

- Plan status matches reality (`implemented` iff every phase is `done`).
- The report lists every commit hash of this run.
