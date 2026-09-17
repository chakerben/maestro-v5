# 03 - Retire

Remove the directory once the branch has landed.

## Process

1. Confirm the branch is merged (PR merged, or `git branch --merged`).
2. Remove the worktree:

```bash
gwt rm <branch>          # refuses if real work is uncommitted
gwt rm <branch> --force  # only after the user confirms the loss
```

3. `gwt clean` prunes ghost entries left by a directory deleted by hand.
4. The branch survives on purpose. Delete it separately, and only if the user
   asks: `git branch -d <branch>`.
5. Never remove a worktree you did not create without asking — another session
   may be living in it.

## Test

- A worktree holding an uncommitted file is refused without `--force`.
- After removal, `gwt ls` no longer lists it and the branch still exists.
