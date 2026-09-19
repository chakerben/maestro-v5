# 02 - Create

Give the branch its own directory.

## Process

1. Create it — `gwt` only, never `git worktree add` by hand:

```bash
gwt new <branch>              # from origin/<default>
gwt new <branch> --from <base>
cd "$(gwt path <branch>)"
```

2. Check it is there: `command -v gwt || echo "gwt missing: run
   install-shortcuts.sh from the maestro-v5 checkout
   (https://github.com/chakerben/maestro-v5)"`. Install it once from that
   checkout (`bash scripts/install-shortcuts.sh`) — the marketplace cache path
   varies per machine, never hard-code it.
   Fall back to the raw commands ONLY if that is impossible, and reproduce what
   `gwt` guarantees — otherwise the worktree is unusable or dangerous:

```bash
git branch --no-track <branch> origin/<default>   # --no-track: a bare push must not aim at main
git worktree add ../.worktrees/<repo>/<branch> <branch>
ln -s "$(git rev-parse --show-toplevel)/node_modules" <worktree>/node_modules
cp .env* CLAUDE.md <worktree>/                    # git does not carry the ignored files
```

3. Announce the absolute path of the worktree to the user, and work there for
   the whole task — commits, gates, PR.
4. Dev server: pick a free port (`npm run dev -- --port 5174`). Do NOT start a
   second docker compose stack; shared services stay in the main checkout.

## Test

- `gwt ls` shows the main checkout on the default branch plus the new worktree.
- `git -C <worktree> status -sb` shows the branch with NO upstream yet.
- The project's typecheck runs inside the worktree without a fresh install.
