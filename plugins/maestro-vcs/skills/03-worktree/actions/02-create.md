# 02 - Create

Give the branch its own directory.

## Process

1. Create it — `gwt` only, never `git worktree add` by hand:

```bash
git fetch origin
gwt new <branch>                           # from origin/<default>
gwt new <branch> --from origin/<deployed>  # when the deployed branch is not the default
d=$(gwt path <branch>) && [ -n "$d" ] && cd "$d" || exit 1
git branch --show-current                  # must print <branch>
```

   The base is the branch that is actually deployed — a worktree cut from a
   stale default branch produces a diff against the wrong code. The guarded
   `cd` matters: with an empty path the shell stays in the shared checkout
   and the next git command runs there.

   `gwt` ships in this plugin's `bin/`, which the platform puts on the Bash
   PATH while maestro-vcs is enabled — nothing to install. `command -v gwt`
   failing means the plugin is not enabled in this project
   (`claude plugin enable maestro-vcs@maestro --scope project`); stop and say
   so. There is no hand-rolled fallback: the raw commands never reproduced
   the slug (`feat/x` → `feat-x`), the copied files, or the local-ahead base,
   and a half-provisioned worktree is worse than none.

2. Dependencies. `gwt` links `node_modules` to the main checkout. Keep the
   link for a project with no bundler. For a **mobile or bundler project**
   (Expo / React Native, Metro, Next, Vite, webpack — or any worktree that
   will build, serve or publish), replace it by a real install before
   anything else:

```bash
[ -L node_modules ] && rm node_modules   # the LINK only: no -r, no trailing slash
npm ci                                   # or the lockfile's own manager, frozen
```

   `rm -rf node_modules/` on the link empties the main checkout's install.
   Never run the package manager while the link is in place: it writes into
   the main checkout. One install at a time on the machine.
3. Announce the absolute path of the worktree to the user, and work there for
   the whole task — commits, gates, PR.
4. Dev server: pick a free port (`npm run dev -- --port 5174`). Do NOT start a
   second docker compose stack; shared services stay in the main checkout.

## Test

- `gwt ls` shows the main checkout on the default branch plus the new worktree.
- `git -C <worktree> status -sb` shows the branch with NO upstream yet.
- Mobile or bundler project: `test -L node_modules` fails (a real directory)
  and the main checkout's `node_modules` is untouched. Other projects: the
  typecheck runs inside the worktree on the link, without an install.
- `pwd` is the worktree and `git branch --show-current` prints the branch.
