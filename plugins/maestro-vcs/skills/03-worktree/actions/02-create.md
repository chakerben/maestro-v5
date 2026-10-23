# 02 - Create

Give the branch its own directory.

## Process

1. Create it — `gwt` only, never `git worktree add` by hand:

```bash
gwt new <branch>              # from origin/<default>
gwt new <branch> --from <base>
cd "$(gwt path <branch>)"
```

   `gwt` ships in this plugin's `bin/`, which the platform puts on the Bash
   PATH while maestro-vcs is enabled — nothing to install. `command -v gwt`
   failing means the plugin is not enabled in this project
   (`claude plugin enable maestro-vcs@maestro --scope project`); stop and say
   so. There is no hand-rolled fallback: the raw commands never reproduced
   the slug (`feat/x` → `feat-x`), the copied files, or the local-ahead base,
   and a half-provisioned worktree is worse than none.

3. Announce the absolute path of the worktree to the user, and work there for
   the whole task — commits, gates, PR.
4. Dev server: pick a free port (`npm run dev -- --port 5174`). Do NOT start a
   second docker compose stack; shared services stay in the main checkout.

## Test

- `gwt ls` shows the main checkout on the default branch plus the new worktree.
- `git -C <worktree> status -sb` shows the branch with NO upstream yet.
- The project's typecheck runs inside the worktree without a fresh install.
