---
name: 00-commit
description: Commit staged or specified changes through the Maestro quality gate — secret detection, configurable checks, conventional message. Use to commit work, especially before a PR. This is WHERE quality checks run in Maestro (never in hooks). Not for pushing force or rewriting history.
argument-hint: "[scope hint or files]"
---

# Skill: commit

The quality checkpoint of the whole framework. Everything v4 tried to enforce
at runtime runs HERE, once, at the moment it matters.

## Actions

| #  | Action    | Role                                                | Input          |
|----|-----------|-----------------------------------------------------|----------------|
| 01 | `gate`    | Run the quality gate on the diff (secrets + level checks) | staged diff |
| 02 | `compose` | Write the conventional commit message               | diff + context |
| 03 | `commit`  | Execute the commit (and only then)                  | gate pass + message |

Run `01 → 03`, strictly in order. A red gate stops everything — no
`--no-verify` equivalent exists here by design. Bypass requires the user to
literally write "bypass gate: <reason>" and the reason is recorded in the
commit body.

## Gate configuration

Read `maestro_docs/gates.json` (fallback: level `standard`):

```json
{ "level": "standard" }
```

| Level | Checks |
|---|---|
| `off` | secrets scan only (never disableable) |
| `standard` | secrets + typecheck (project script) |
| `high` | standard + lint + tests related to changed files |
| `paranoid` | high + full test suite |

## Transversal rules

- Detect the project's package runner from the LOCKFILE (bun.lockb → bun,
  pnpm-lock.yaml → pnpm, yarn.lock → yarn, package-lock.json → npm). Never
  pass `--silent` to runners (it leaks into tsc and breaks it — v4 bug).
- The secrets scan uses `assets/secret-patterns.md` and can never be skipped.
- Delegate the raw git mechanics to the official commit-commands plugin when
  installed; this skill owns the gate and the message.
- The working directory may be shared with another session. Commit by paths,
  never `-a`, and put branch work in a worktree — `maestro-vcs:03-worktree`.
