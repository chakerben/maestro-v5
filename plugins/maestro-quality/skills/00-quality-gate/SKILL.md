---
name: 00-quality-gate
description: Configure or run the project quality gate levels (off, standard, high, paranoid). Use to set the gate level, check current config, or run the gate on demand outside a commit. The commit-time execution itself lives in maestro-vcs:00-commit.
argument-hint: "status | set <level> | run"
arguments: [action, level]
allowed-tools: Bash   # turn-scoped: the !`…` injections above use shell builtins, pipes and $(…) that pattern grants do not cover
---

# Skill: quality-gate

## Live state (computed at invocation)

!`cat maestro_docs/gates.json 2>/dev/null || echo '(no maestro_docs/gates.json → level standard by default)'`

Requested: `$action` `$level`

Owns `maestro_docs/gates.json` and the on-demand gate run.

## Actions (dispatch by argument)

- `status` — print the current level, what it checks, last run summary.
- `set <level>` — validate the level (off|standard|high|paranoid), write
  `maestro_docs/gates.json`, explain what changes. Warn on `off`: "secrets
  scan still always runs at commit".
- `run` — execute the current level's checks on the working tree NOW (same
  logic as maestro-vcs:00-commit action 01, without committing). Useful
  before a review or as a health pulse.

## Rules

- The secrets scan is constitutional: no level disables it.
- Level guidance: `standard` for solo work, `high` for client deliverables,
  `paranoid` before releases. Recommend, never impose.

## Test

- `set <level>` wrote `maestro_docs/gates.json` with exactly `{ "level": "<level>" }`
  and refused any value outside off|standard|high|paranoid.
- `run` at level `off` still executed the secrets scan and printed its result.
- `run` executed no check with `--silent`, and reported each command with its
  exit code and duration.
