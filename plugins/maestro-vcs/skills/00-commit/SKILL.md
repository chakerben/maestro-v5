---
name: 00-commit
description: Commit staged or specified changes through the Maestro quality gate — secret detection, configurable checks, conventional message. Use to commit work, especially before a PR. This is WHERE quality checks run in Maestro (never in hooks). Not for pushing force or rewriting history.
argument-hint: "[scope hint or files]"
allowed-tools: Bash(git diff *), Bash(git status *), Bash(git log *), Bash(bash *), Bash(cat *)
---

# Skill: commit

## Live state (computed at invocation — not a claim, a measurement)

Staged diff:
!`git diff --cached --stat --no-color | tail -20; [ -n "$(git diff --cached --name-only)" ] || echo "(nothing staged)"`

Secrets scan of the staged diff (`scripts/secret-scan.sh`, patterns from `assets/secret-patterns.md`):
!`bash "${CLAUDE_SKILL_DIR}/scripts/secret-scan.sh" cached`

Gate level:
!`cat maestro_docs/gates.json 2>/dev/null || echo '{ "level": "standard" }  (default — no maestro_docs/gates.json)'`

Runner (from the lockfile):
!`if [ -f bun.lockb ] || [ -f bun.lock ]; then echo bun; elif [ -f pnpm-lock.yaml ]; then echo pnpm; elif [ -f yarn.lock ]; then echo yarn; elif [ -f package-lock.json ]; then echo npm; else echo "none detected"; fi`

A `SECRET SCAN: RED` above ends action 01 immediately. If the state above says
"(nothing staged)", action 01 starts by asking what to stage.

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
- The secrets scan is `scripts/secret-scan.sh` (its patterns live in
  `assets/secret-patterns.md`); it ran above before you read this line, and it
  can never be skipped. If it was staged after invocation, re-run it: 
  `bash ${CLAUDE_SKILL_DIR}/scripts/secret-scan.sh cached`.
- Delegate the raw git mechanics to the official commit-commands plugin when
  installed; this skill owns the gate and the message.
- The working directory may be shared with another session. Commit by paths,
  never `-a`, and put branch work in a worktree — `maestro-vcs:03-worktree`.
