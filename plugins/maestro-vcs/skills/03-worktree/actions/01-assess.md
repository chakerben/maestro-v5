# 01 - Assess

Decide whether this branch work needs a worktree — before touching git.

## Process

1. Read the ground truth, always both:

```bash
git branch --show-current
git status --short
```

2. Classify what `status` shows:
   - **Changes you did not make in this session** (files you never opened,
     staged renames, untracked directories you did not create) → the directory
     is SHARED. Say so to the user, naming two or three of those paths.
   - Clean, or only your own edits → not shared *right now*.
3. Decide:
   - Shared **or** the branch will live longer than a few minutes → action 02.
   - Not shared and the change is a quick fix on the default branch → a
     worktree is optional; say why you are skipping it.
4. If the repository is already a worktree (`git rev-parse --git-common-dir`
   points outside the current directory), you are in the right place: continue.
5. Never resolve a shared directory by stashing, resetting or switching the
   branch. That is the neighbour's work.

## Test

- With another session's staged rename present, the action reports SHARED and
  names the file.
- The action never ran a mutating git command.
