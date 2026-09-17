# Migrating from Maestro v4 to v5

v4 shipped 14 runtime hooks (typecheck/tests/format on every action) that
caused parallel process explosions and RAM crashes, and was distributed by
copying files into every project + an npm package. v5 removes all of it:
2 hooks total, marketplace distribution, quality in the workflow.

## The automated way (recommended)

The migration script lives in this repo: `scripts/migrate-v4-to-v5.sh`.
It handles everything per project: backup, v4 cleanup, memory-bank migration,
gates migration, settings sanitation, plugin activation by detected stack,
routing block injection, and final verification.

```bash
# From the maestro repo clone:
./scripts/migrate-v4-to-v5.sh --list                 # see detected v4 projects
./scripts/migrate-v4-to-v5.sh <project> --dry-run    # preview one project
./scripts/migrate-v4-to-v5.sh <p1> <p2> <p3>         # migrate a wave
./scripts/migrate-v4-to-v5.sh --all                  # migrate everything
```

Safety: refuses dirty git trees (commit first, or `--force-dirty`), backs up
everything it touches into `.maestro-v4-backup-<ts>/`, idempotent (re-running
is harmless).

## What it maps

| v4 | v5 |
|---|---|
| `scripts/hooks/*` (14 hooks) | deleted (backed up) — plugins ship the only 2 hooks |
| `.claude/agents`, `commands`, `skills` | deleted — delivered by plugins now |
| `docs/memory-bank/project-brief.md` etc. | `maestro_docs/memory/` (tier 1) |
| `docs/memory-bank/errors-log.md` | `maestro_docs/memory/internal/` |
| `docs/memory-bank/current-sprint.md` | `maestro_docs/memory/internal/archive/` |
| `.claude/quality-gates.json` (level preserved) | `maestro_docs/gates.json` |
| state files (counters, session-log, loop-detector) | deleted |
| npm `@arabiipte/maestro` global | uninstall once: `npm uninstall -g @arabiipte/maestro` |

## After each project

In a Claude Code session inside the project:

1. `/maestro-core:04-doctor check` — must be fully green
2. `/maestro-core:01-memory review` — sanity-check the migrated memory
3. `git add -A && git commit -m "chore: migrate maestro v4 -> v5"`

Then watch for a week: `ps aux | grep -E "jest|tsc|claude-flow" | grep -v grep`
must stay empty during heavy sessions.

## Rollout strategy

1. **Wave 0 — pilots (day 1)**: one web, one mobile, one backend project.
2. **Rodage (week 1)**: work normally on the pilots; zero phantom processes tolerated.
3. **Waves 1-N (week 2)**: migrate the rest in batches of 5-10 with `--dry-run` first.
4. **Cleanup (week 3)**: delete `.maestro-v4-backup-*` dirs, deprecate the npm
   package: `npm deprecate @arabiipte/maestro "Replaced by the maestro v5 plugin marketplace"`.
