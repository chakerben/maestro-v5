---
name: 03-worktree
description: Isolate a branch in its own git worktree so concurrent sessions stop overwriting each other. Use before starting branch work in a repository that another session, editor or terminal has open. Not for the branch/commit/PR mechanics themselves (00-commit, 01-pull-request).
argument-hint: "new <branch> | list | remove <branch>"
---

# Skill: worktree

One working directory, several sessions — Claude, the editor, a terminal — is
the normal case, not the exception. In that directory:

- `git switch` moves the branch **for everybody**, mid-edit;
- `git commit -a` (or `git add -A`) sweeps up the neighbour's staged work;
- a rebase or a stash silently rewrites what another session is reading.

A worktree is git's own answer: one directory per branch, one shared `.git`.
No second clone, no remote round-trip, no duplicated history.

**The main checkout stays on the default branch.** It is the shared reference
everyone reads. Branch work happens elsewhere.

## Actions

| #  | Action    | Role                                                        | Input   |
|----|-----------|-------------------------------------------------------------|---------|
| 01 | `assess`  | Is this directory shared? Is a worktree required here?       | repo    |
| 02 | `create`  | Create the worktree and make it runnable                     | branch  |
| 03 | `retire`  | Remove a worktree once its branch is merged                  | branch  |

Run `01` before any branch work. `02` when it says so. `03` after the merge.

## The tool

`gwt` — shipped with this marketplace (`scripts/gwt`), installed to
`~/.local/bin/gwt` by `scripts/install-shortcuts.sh`. Never call
`git worktree add` by hand: `gwt` also carries the parts that make a worktree
actually usable, and the two traps below.

```bash
gwt new feat/x            # worktree + branch, created --no-track
cd "$(gwt path feat/x)"
gwt ls · gwt rm feat/x · gwt clean · gwt --help
```

| It does | Why |
|---|---|
| Places the worktree in `<parent-of-repo>/.worktrees/<repo>/<branch>` | outside the repo → nothing to add to `.gitignore` |
| Symlinks `node_modules`, `.venv`, `venv`, `vendor` | a fresh install per worktree costs minutes for nothing |
| Copies `.env*`, `CLAUDE.md`, `AGENTS.md`, `.mcp.json`, `.claude/*.local.json` | git does not carry them (ignored) — without the copy the worktree has no project instructions and no granted permissions |
| Creates the branch `--no-track` | with tracking, the branch follows `origin/<default>` and a bare `git push` aims at the default branch |
| Refuses `gwt rm` on real uncommitted work | but ignores what `gwt` itself provisioned — in a repo where `node_modules` is not ignored, the symlink alone used to block removal |

## Transversal rules

- Never `git switch` / `git checkout <branch>` in the main checkout.
- Never `git commit -a` / `git add -A` in a directory you do not own alone.
  Commit by explicit paths: `git commit -F <message-file> -- <paths>`.
- One dev server port per worktree (`npm run dev -- --port 5174`); shared
  services (docker compose, database) stay started from the main checkout.
- Worktrees are disposable, branches are not: `gwt rm` removes the directory
  and leaves the branch.
