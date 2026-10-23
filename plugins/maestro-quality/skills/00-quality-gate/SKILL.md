---
name: 00-quality-gate
description: Configure or run the project quality gate levels (off, standard, high, paranoid). Use to set the gate level, check current config, or run the gate on demand outside a commit. The commit-time execution itself lives in maestro-vcs:00-commit.
argument-hint: "status | set <level> | run"
allowed-tools: Bash   # turn-scoped: the !`…` injections below use shell builtins, pipes and $(…) that pattern grants do not cover
model: sonnet
effort: low
---

# Skill: quality-gate

## Live state (computed at invocation)

!`cat maestro_docs/gates.json 2>/dev/null || echo '(no maestro_docs/gates.json → level standard by default)'`

Requested: `$ARGUMENTS` (first word = action, second = level)

Owns `maestro_docs/gates.json`, the level contract below, and the on-demand
gate run.

## The levels (single source — `maestro-vcs:00-commit` applies this table)

| Level | Checks, on the **staged** diff |
|---|---|
| `off` | secrets scan only (never disableable) |
| `standard` | secrets + typecheck (the project's `typecheck` script; skipped with a note when absent — LSP covers real time) |
| `high` | standard + `lint` script + tests touching the changed paths |
| `paranoid` | high + the full test suite |

Default when `gates.json` is absent: `standard`. Tests therefore run at
every commit only from `high` — a project that wants them on every phase
commit sets `high` (`set high`; the guidance below says when). Runner from
the lockfile, never `--silent`.

## Actions (dispatch by argument)

- `status` — print the current level and the row of the table above.
- `set <level>` — validate the level (off|standard|high|paranoid), write
  `maestro_docs/gates.json`, explain what changes. Warn on `off`: "secrets
  scan still always runs at commit".
- `run` — execute the current level's checks NOW, without committing: on
  the staged diff when something is staged, else on the whole working tree
  (say which). Useful before a review or as a health pulse. The secrets
  scan lives in maestro-vcs: when it is installed, invoke
  `maestro-vcs:00-commit` action 01 (`gate`) — its `!` injection runs
  `secret-scan.sh` before the skill is read; when it is not installed, run
  the typecheck/lint/tests of the level yourself and say plainly that the
  secrets scan did NOT run (never report "clean" for a scan that never
  happened).

## Rules

- The secrets scan is constitutional: no level disables it.
- Level guidance: `standard` for solo work, `high` for client deliverables,
  `paranoid` before releases. Recommend, never impose.

## Test

- `set <level>` wrote `maestro_docs/gates.json` with exactly `{ "level": "<level>" }`
  and refused any value outside off|standard|high|paranoid.
- `run` at level `off` still executed the secrets scan (via
  maestro-vcs:00-commit) and printed its result — or stated that maestro-vcs
  is not installed and the scan did not run.
- `run` executed no check with `--silent`, and reported each command with its
  exit code and duration.
