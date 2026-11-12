---
name: 03-worktree
description: Isolate a branch in its own git worktree so concurrent sessions stop overwriting each other. Use before branch work in a repository another session, editor or terminal has open. Not for commit/PR mechanics (00-commit, 01-pull-request).
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

`gwt` — shipped in this plugin's `bin/`, on the Bash PATH wherever
maestro-vcs is enabled (no install step). Never call
`git worktree add` by hand: `gwt` also carries the parts that make a worktree
actually usable, and the two traps below.

```bash
gwt new feat/x            # worktree + branch, created --no-track
d=$(gwt path feat/x) && [ -n "$d" ] && cd "$d" || exit 1
git branch --show-current # must print feat/x before any git command
gwt ls · gwt rm feat/x · gwt clean · gwt --help
```

| It does | Why |
|---|---|
| Places the worktree in `<parent-of-repo>/.worktrees/<repo>/<branch>` (`/` in the branch name becomes `-`) | outside the repo → nothing to add to `.gitignore` |
| Symlinks `node_modules`, `.venv`, `venv`, `vendor` | right for projects with no bundler; a mobile or bundler project replaces the link by a real install (below) |
| Copies `.env*`, `CLAUDE.md`, `AGENTS.md`, `.mcp.json`, `.claude/*.local.json` | git does not carry them (ignored) — without the copy the worktree has no project instructions and no granted permissions |
| Creates the branch `--no-track` | with tracking, the branch follows `origin/<default>` and a bare `git push` aims at the default branch |
| Refuses `gwt rm` on real uncommitted work | but ignores what `gwt` itself provisioned — in a repo where `node_modules` is not ignored, the symlink alone used to block removal |

## Dependencies: real install or symlink

- **Mobile or bundler project** (Expo / React Native, Metro, Next, Vite,
  webpack, any worktree that will build, serve or publish): replace the
  `node_modules` link by a real lockfile install, as the first step
  (action 02) — because symlinked dependencies broke the bundler and the
  mobile packager and shipped a bundle with stale packages.
- **Other projects** (scripts, libraries checked by the compiler only,
  `.venv`, `vendor`): keep the symlink.
- Never run the package manager while `node_modules` is a symlink —
  because it rewrites the main checkout's install under every session.
- This default belongs in `gwt` itself (detect the project, install instead
  of linking); until it ships there, the step above is mandatory prose.

## Transversal rules

- Never `git switch` / `git checkout <branch>` in the main checkout.
- Never `git commit -a` / `git add -A` in a directory you do not own alone.
  Commit by explicit paths: `git commit -F <message-file> -- <paths>`.
- Never `git stash` in a repository several sessions share — because the
  stash is common to all worktrees and another session popped it.
- Guard every `cd "$(gwt path …)"` (exit on failure, then check the branch)
  — because an empty path left the shell in the shared checkout and a
  cherry-pick ran there.
- Cut the worktree from the branch that is actually deployed, after a
  fetch (`--from origin/<deployed>`) — because work started from a stale
  default branch.
- One disposable database per worktree; never reset or migrate a shared
  database to clear a "drift" — because two branches migrated one database.
- Schemas differ between worktrees → each gets its own generated client;
  with two executors in one tree, validate the **staged** schema before
  committing — because a commit captured the neighbour's half-edit.
- Do not deploy from a worktree with a CLI that expects a `.git`
  directory — because it picked up the wrong project state.
- One dev server port per worktree (`npm run dev -- --port 5174`); shared
  services (docker compose) stay started from the main checkout.
- Worktrees are disposable, branches are not: `gwt rm` removes the directory
  and leaves the branch.
