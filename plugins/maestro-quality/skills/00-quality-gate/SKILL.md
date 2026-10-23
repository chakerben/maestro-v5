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

## The levels — executed by `maestro-check`, never by reading

The gate is a command: `maestro-check` (this plugin's `bin/`, on the Bash
PATH while maestro-quality is enabled). It detects the stack and the runner,
runs the level's checks on the staged diff and prints one JSON verdict; exit
1 on any red. `maestro-check --list` prints the checks of the current level.

| Level | Checks (each a command with an exit code) |
|---|---|
| `off` | `secrets` only — never disableable, and **red when the scan cannot run** |
| `standard` | secrets · `typecheck` · `lint` · `rtl` (rtl-lint, when an `ar` locale exists) · `boundaries` (dependency-cruiser) · `tests-related` (tests touching the changed paths) · `fonts` (Arabic metrics, mobile) |
| `high` | standard + `tests-full` + `lighthouse` (web, when `lighthouserc` exists) |
| `paranoid` | high + `audit` (dependency vulnerabilities) |

Default when `gates.json` is absent: `standard` — tests on the changed paths
run at **every** commit, phase commits included. A check whose tool is
absent is `skipped` with the reason in the verdict, never silently green;
the skill reports every skip, because a skip is a gap the project chose.

## Actions (dispatch by argument)

- `status` — print the current level and `maestro-check --list`.
- `set <level>` — validate the level (off|standard|high|paranoid), write
  `maestro_docs/gates.json`, explain what changes. Warn on `off`: "secrets
  scan still always runs at commit".
- `run` — `maestro-check --scope staged` when something is staged, else
  `--scope all` (say which); print the verdict table and every `skipped`
  reason. The secrets check is maestro-vcs' scan; without maestro-vcs the
  verdict is red on `secrets` — report it as red, never as "clean".

## Rules

- The secrets scan is constitutional: no level disables it.
- Level guidance: `standard` for solo work, `high` for client deliverables,
  `paranoid` before releases. Recommend, never impose.

## Test

- `set <level>` wrote `maestro_docs/gates.json` with exactly `{ "level": "<level>" }`
  and refused any value outside off|standard|high|paranoid.
- `run` printed `maestro-check`'s JSON verdict; at level `off` the `secrets`
  check is in it, red when maestro-vcs is absent.
- Every `skipped` check appears in the report with its reason.
